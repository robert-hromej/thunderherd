# frozen_string_literal: true

module Api
  class EnvironmentsController < BaseController
    def index
      environments = Environment.includes(:site).order("sites.key", :name)
      url_counts = Url.group(:environment_id).count
      run_counts = Run.group(:environment_id).count
      render json: environments.map { |e| environment_json(e, url_counts: url_counts, run_counts: run_counts) }
    end

    def show
      environment = Environment.includes(:site, :urls).find(params[:id])
      render json: environment_json(environment).merge(
        urls: environment.urls.order(:path).map { |u| url_json(u) }
      )
    end

    def create
      environment = resolve_site.environments.create!(environment_params)
      render json: environment_json(environment), status: :created
    end

    def update
      environment = Environment.find(params[:id])
      environment.update!(environment_params)
      render json: environment_json(environment)
    end

    def destroy
      Environment.find(params[:id]).destroy!
      head :no_content
    end

    private

    # A new environment can reference an existing site (site_id) or name a site to
    # find-or-create (site_key + optional site_name) so you never leave the page.
    def resolve_site
      return Site.find(params.dig(:environment, :site_id)) if params.dig(:environment, :site_id).present?

      key = params[:site_key].presence || "default"
      Site.find_or_create_by!(key: key) { |s| s.name = params[:site_name].presence || key }
    end

    def environment_params
      params.require(:environment).permit(:name, :base_url, :heroku_app, :is_production, :description)
    end

    def environment_json(environment, url_counts: nil, run_counts: nil)
      {
        id: environment.id, site_id: environment.site_id, site: environment.site.key,
        site_name: environment.site.name, name: environment.name, base_url: environment.base_url,
        heroku_app: environment.heroku_app, is_production: environment.is_production,
        description: environment.description,
        urls_count: url_counts ? url_counts.fetch(environment.id, 0) : environment.urls.size,
        runs_count: run_counts ? run_counts.fetch(environment.id, 0) : environment.runs.size
      }
    end

    # Same shape as Api::UrlsController#url_json — the edit modal needs every field.
    def url_json(url)
      { id: url.id, environment_id: url.environment_id, method: url[:method], path: url.path,
        full_url: url.full_url, is_active: url.is_active, body: url.body, description: url.description }
    end
  end
end
