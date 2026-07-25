# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::RunConfigs", type: :request do
  describe "GET /api/run_configs" do
    it "lists configs ordered by name" do
      create(:run_config, name: "b-config")
      create(:run_config, name: "a-config")

      get "/api/run_configs"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |c| c["name"] }).to eq([ "a-config", "b-config" ])
    end
  end

  describe "POST /api/run_configs" do
    it "creates a config and returns 201" do
      environment = create(:environment)

      post "/api/run_configs", params: {
        run_config: {
          name: "nightly", environment_id: environment.id,
          requests_per_url: 100, concurrency: 20, timeout_s: 15
        }
      }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include(
        "name" => "nightly", "environment" => environment.label,
        "requests_per_url" => 100, "concurrency" => 20, "timeout_s" => 15
      )
    end

    it "returns 422 for an invalid config" do
      environment = create(:environment)

      post "/api/run_configs", params: {
        run_config: { name: "", environment_id: environment.id }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include("errors")
    end
  end
end
