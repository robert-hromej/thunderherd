# frozen_string_literal: true

module Api
  class RunConfigsController < BaseController
    def index
      configs = RunConfig.includes(environment: :site).order(:name)
      render json: configs.map { |c| config_json(c) }
    end

    def create
      config = nil
      ActiveRecord::Base.transaction do
        config = RunConfig.create!(config_params)
        sync_urls!(config)
      end
      render json: config_json(config), status: :created
    end

    def update
      config = RunConfig.find(params[:id])
      ActiveRecord::Base.transaction do
        config.update!(config_params)
        purge_foreign_urls!(config) if config.saved_change_to_environment_id?
        sync_urls!(config)
      end
      render json: config_json(config)
    end

    def destroy
      RunConfig.find(params[:id]).destroy!
      head :no_content
    end

    private

    def config_params
      params.require(:run_config).permit(:name, :environment_id, :requests_per_url,
                                         :concurrency, :timeout_s, :description)
    end

    # Optional URL subset: absent key = leave as is; [] = clear (config targets every
    # active URL of the environment); [ids] = target exactly those URLs.
    def sync_urls!(config)
      raw = params[:run_config]
      return unless raw&.key?(:url_ids)

      # Blank entries appear when an empty array arrives url-encoded ([""]).
      requested = Array(raw[:url_ids]).reject { |v| v.to_s.strip.empty? }.map(&:to_i)
      ids = requested & config.environment.urls.pluck(:id)
      # A wholly invalid selection must not silently widen the config to every
      # active URL of the environment (the [] = clear semantics).
      raise UnprocessableError, "url_ids do not belong to the config's environment" if requested.any? && ids.empty?

      config.run_config_urls.where.not(url_id: ids).delete_all
      existing = config.run_config_urls.pluck(:url_id)
      (ids - existing).each { |url_id| config.run_config_urls.create!(url_id: url_id) }
    end

    # Selections must always belong to the config's environment: re-pointing a
    # config at another environment drops stale cross-environment URLs, otherwise
    # the next run would fire at the OLD environment (Url#full_url uses the URL's
    # own environment) while being guarded and recorded against the new one.
    def purge_foreign_urls!(config)
      config.run_config_urls.where.not(url_id: config.environment.urls.select(:id)).delete_all
    end

    def config_json(config)
      {
        id: config.id, name: config.name, environment_id: config.environment_id,
        environment: config.environment.label, requests_per_url: config.requests_per_url,
        concurrency: config.concurrency, timeout_s: config.timeout_s,
        description: config.description,
        url_ids: config.run_config_urls.pluck(:url_id),
        target_urls_count: config.target_urls.size
      }
    end
  end
end
