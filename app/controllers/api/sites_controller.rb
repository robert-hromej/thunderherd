# frozen_string_literal: true

module Api
  class SitesController < BaseController
    def index
      render json: Site.includes(:environments).order(:key).map { |s| site_json(s) }
    end

    def show
      render json: site_json(Site.includes(:environments).find(params[:id]))
    end

    def create
      site = Site.create!(site_params)
      render json: site_json(site), status: :created
    end

    def update
      site = Site.find(params[:id])
      site.update!(site_params)
      render json: site_json(site)
    end

    def destroy
      Site.find(params[:id]).destroy!
      head :no_content
    end

    private

    def site_params
      params.require(:site).permit(:key, :name)
    end

    def site_json(site)
      {
        id: site.id, key: site.key, name: site.name,
        environments: site.environments.order(:name).map do |e|
          { id: e.id, name: e.name, base_url: e.base_url, is_production: e.is_production }
        end
      }
    end
  end
end
