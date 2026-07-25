# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Environments", type: :request do
  describe "GET /api/environments" do
    it "lists environments with their site context" do
      env = create(:environment)

      get "/api/environments"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to be_an(Array)
      expect(body.first).to include(
        "id" => env.id, "site" => env.site.key, "name" => env.name, "is_production" => false
      )
    end
  end

  describe "GET /api/environments/:id" do
    it "returns the environment with its urls" do
      env = create(:environment)
      create(:url, environment: env, path: "/home")

      get "/api/environments/#{env.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include("id" => env.id, "base_url" => env.base_url)
      expect(body["urls"].first).to include("path" => "/home", "full_url" => "#{env.base_url}/home")
    end
  end
end
