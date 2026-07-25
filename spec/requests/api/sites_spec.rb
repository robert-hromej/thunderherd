# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Sites", type: :request do
  describe "GET /api/sites" do
    it "lists sites ordered by key with their environments" do
      env = create(:environment)

      get "/api/sites"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to be_an(Array)
      site_row = body.find { |s| s["id"] == env.site.id }
      expect(site_row).to include("key" => env.site.key, "name" => env.site.name)
      expect(site_row["environments"].first).to include("id" => env.id, "name" => env.name)
    end
  end

  describe "GET /api/sites/:id" do
    it "returns a single site with its environments" do
      env = create(:environment)

      get "/api/sites/#{env.site.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include("id" => env.site.id, "key" => env.site.key)
      expect(body["environments"].map { |e| e["id"] }).to include(env.id)
    end

    it "returns 404 for an unknown site" do
      get "/api/sites/0"
      expect(response).to have_http_status(:not_found)
    end
  end
end
