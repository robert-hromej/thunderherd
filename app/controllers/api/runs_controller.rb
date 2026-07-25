# frozen_string_literal: true

module Api
  class RunsController < BaseController
    def index
      runs = VRunSummary.order(started_at: :desc).limit(100)
      render json: runs.map { |r| run_summary_json(r) }
    end

    def show
      render json: run_detail_json(find_run_for_detail(params[:id]))
    end

    def create
      environment = resolve_environment
      return render(json: { error: "environment or run_config required" }, status: :unprocessable_entity) unless environment

      if (invalid = invalid_numeric_param)
        return render(json: { error: "#{invalid} must be a positive integer" }, status: :unprocessable_entity)
      end

      if environment.is_production && !truthy?(params[:allow_prod])
        return render(json: { error: "#{environment.label} is PRODUCTION — set allow_prod to run it" }, status: :forbidden)
      end

      RunLoadTestJob.perform_later(
        run_config_id: params[:run_config_id].presence,
        environment_id: environment.id,
        requests_per_url: params[:requests_per_url].presence&.to_i,
        concurrency: params[:concurrency].presence&.to_i,
        timeout_s: params[:timeout_s].presence&.to_i,
        label: params[:label].presence,
        allow_prod: truthy?(params[:allow_prod])
      )
      render json: { enqueued: true, environment: environment.label }, status: :accepted
    end

    def compare
      before = find_run_for_detail(params[:id])
      after = find_run_for_detail(params[:to])
      render json: {
        before: run_detail_json(before),
        after: run_detail_json(after),
        diff: diff_results(before: before, after: after)
      }
    end

    # Only the operator-owned annotations are editable — measurements are immutable.
    def update
      run = Run.find(params[:id])
      run.update!(params.require(:run).permit(:label, :is_baseline, :notes))
      render json: run_detail_json(find_run_for_detail(run.id))
    end

    def destroy
      run = Run.find(params[:id])
      # Deleting a running run would yank the row out from under the in-process
      # job (its next results.create! violates the FK) and lose all measured data.
      if run.status == "running"
        return render(json: { error: "run ##{run.id} is still running" }, status: :conflict)
      end

      run.destroy!
      head :no_content
    end

    private

    def find_run_for_detail(id)
      Run.includes(:environment, :operator, :machine, :run_dynos, :deploy, :run_network,
                   { environment: :site }, { results: :result_status_codes }).find(id)
    end

    def invalid_numeric_param
      %i[requests_per_url concurrency timeout_s].find do |key|
        value = params[key].presence
        next false unless value

        !value.to_s.match?(/\A\d+\z/) || value.to_i <= 0
      end
    end

    def resolve_environment
      # The explicit environment field wins (it is pre-filled from the config but
      # stays overridable); fall back to the config's environment otherwise.
      return Environment.find(params[:environment_id]) if params[:environment_id].present?
      return RunConfig.find(params[:run_config_id]).environment if params[:run_config_id].present?

      nil
    end

    def diff_results(before:, after:)
      after_by_key = after.results.index_by { |r| [ r[:method], r.path ] }
      before.results.filter_map do |b|
        a = after_by_key[[ b[:method], b.path ]]
        next unless a

        { method: b[:method], path: b.path,
          before_avg: b.avg_ms.to_f, after_avg: a.avg_ms.to_f, avg_delta: (a.avg_ms - b.avg_ms).to_f,
          before_p95: b.p95_ms.to_f, after_p95: a.p95_ms.to_f, p95_delta: (a.p95_ms - b.p95_ms).to_f,
          before_rps: b.rps.to_f, after_rps: a.rps.to_f }
      end
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
