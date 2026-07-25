# frozen_string_literal: true

module LoadTest
  # Orchestrates a whole run: creates the Run, captures context (operator, machine,
  # dyno formation, deployed version), measures every target URL via a runner, and
  # persists Results + status-code distributions. Production targets require opt-in.
  class Executor
    class ProductionNotAllowed < StandardError; end

    def initialize(run_config: nil, environment: nil, requests_per_url: nil, concurrency: nil,
                   timeout_s: nil, label: nil, urls: nil, allow_prod: false, store_samples: false,
                   runner_class: HeyRunner)
      @environment = environment || run_config&.environment
      raise ArgumentError, "environment or run_config required" unless @environment

      @run_config = run_config
      @requests_per_url = (requests_per_url || run_config&.requests_per_url || 50).to_i
      @concurrency = (concurrency || run_config&.concurrency || 10).to_i
      @timeout_s = (timeout_s || run_config&.timeout_s || 30).to_i
      @label = label
      @urls = urls || config_urls || @environment.urls.active.to_a
      @allow_prod = allow_prod
      @store_samples = store_samples
      @runner_class = runner_class
    end

    def call
      guard_production!
      run = create_run
      begin
        capture_context(run)
        @urls.each { |url| measure(run: run, url: url) }
        finish(run: run, status: "completed")
      rescue StandardError => e
        finish(run: run, status: "failed", notes: e.message)
        raise
      end
      run.reload
    end

    private

    # The config's URL selection only applies when the run actually targets the
    # config's environment — an explicit override must never fire at another
    # environment's URLs (Url#full_url builds on the URL's own environment).
    def config_urls
      return nil unless @run_config
      return nil unless @run_config.environment_id == @environment.id

      @run_config.target_urls
    end

    # Compare-and-set: only a still-running run may be finished, so an external
    # abort (UI, orphan sweep at boot) is never overwritten with "completed".
    def finish(run:, status:, notes: nil)
      updates = { status: status, finished_at: Time.current }
      updates[:notes] = notes if notes
      Run.where(id: run.id, status: "running").update_all(updates)
    end

    def guard_production!
      return unless @environment.is_production
      return if @allow_prod

      raise ProductionNotAllowed,
            "#{@environment.label} is PRODUCTION — pass allow_prod: true (ALLOW_PROD=1) to proceed"
    end

    def create_run
      Run.create!(
        environment: @environment, run_config: @run_config,
        requests_per_url: @requests_per_url, concurrency: @concurrency, timeout_s: @timeout_s,
        label: @label, tool: "hey", tool_version: HeyRunner.version,
        harness_version: Thunderherd::VERSION, status: "running", started_at: Time.current
      )
    end

    def capture_context(run)
      run.update!(operator: find_operator, machine: find_machine)
      capture_network(run)

      Infra::Heroku.dyno_formation(@environment.heroku_app).each { |d| run.run_dynos.create!(d) }

      release = Infra::Heroku.latest_release(@environment.heroku_app)
      return unless release

      deploy = @environment.app_deploys
                           .find_or_create_by!(heroku_release: release[:heroku_release]) do |d|
        d.assign_attributes(release.except(:heroku_release))
      end
      run.update!(deploy: deploy)
    end

    def capture_network(run)
      host = URI.parse(@environment.base_url).host
      attrs = NetworkInfo.collect(target_host: host)
      run.create_run_network!(attrs) if attrs.present?
    rescue StandardError
      nil
    end

    def find_operator
      attrs = HostInfo.operator_attrs
      if attrs[:email].present?
        Operator.find_or_create_by!(email: attrs[:email]) { |o| o.name = attrs[:name] }
      else
        Operator.find_or_create_by!(name: attrs[:name], email: nil)
      end
    end

    def find_machine
      attrs = HostInfo.machine_attrs
      Machine.find_or_create_by!(fingerprint: attrs[:fingerprint]) do |m|
        m.assign_attributes(attrs.except(:fingerprint))
      end
    end

    def measure(run:, url:)
      stats = @runner_class.new(requests: @requests_per_url, concurrency: @concurrency, timeout: @timeout_s)
                           .call(method: url[:method], url: url.full_url, body: url.body&.to_json)

      result = run.results.create!(
        stats.slice(:requests, :error_count, *Result::METRICS)
             .merge(url: url, method: url[:method], path: url.path)
      )

      if stats[:codes].any?
        ResultStatusCode.insert_all!(stats[:codes].map { |code, count| { result_id: result.id, status_code: code, count: count } })
      end
      if @store_samples && stats[:samples].any?
        ResultSample.insert_all!(stats[:samples].map { |s| s.merge(result_id: result.id) })
      end
      result
    end
  end
end
