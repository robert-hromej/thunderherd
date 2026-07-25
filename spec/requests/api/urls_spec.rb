# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Urls", type: :request do
  let(:environment) { create(:environment) }

  describe "GET /api/environments/:environment_id/urls" do
    it "lists the environment's urls ordered by path" do
      create(:url, environment: environment, path: "/b")
      create(:url, environment: environment, path: "/a")

      get "/api/environments/#{environment.id}/urls"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |u| u["path"] }).to eq([ "/a", "/b" ])
    end
  end

  describe "POST /api/environments/:environment_id/urls" do
    it "creates a url and returns 201" do
      post "/api/environments/#{environment.id}/urls",
           params: { url: { method: "POST", path: "/checkout", body: { qty: 2 } } }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include("method" => "POST", "path" => "/checkout", "body" => { "qty" => "2" })
      expect(environment.urls.count).to eq(1)
    end

    it "returns 422 for an invalid method" do
      post "/api/environments/#{environment.id}/urls",
           params: { url: { method: "TRACE", path: "/x" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include("errors")
    end
  end
end
