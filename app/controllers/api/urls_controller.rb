# frozen_string_literal: true

module Api
  class UrlsController < BaseController
    def index
      environment = Environment.find(params[:environment_id])
      render json: environment.urls.order(:path).map { |u| url_json(u) }
    end

    def create
      environment = Environment.find(params[:environment_id])
      url = environment.urls.create!(url_params)
      render json: url_json(url), status: :created
    end

    def update
      url = Url.find(params[:id])
      url.update!(url_params)
      render json: url_json(url)
    end

    def destroy
      Url.find(params[:id]).destroy!
      head :no_content
    end

    private

    def url_params
      permitted = params.require(:url).permit(:method, :path, :is_active, :description)
      # `permit(body: {})` silently drops null (clearing a body) and JSON arrays —
      # pass the raw jsonb value through instead.
      permitted[:body] = permit_json(params[:url][:body]) if params[:url].key?(:body)
      permitted
    end

    def permit_json(value)
      case value
      when ActionController::Parameters then value.permit!.to_h
      when Array then value.map { |v| permit_json(v) }
      else value
      end
    end

    def url_json(url)
      { id: url.id, environment_id: url.environment_id, method: url[:method], path: url.path,
        full_url: url.full_url, is_active: url.is_active, body: url.body, description: url.description }
    end
  end
end
