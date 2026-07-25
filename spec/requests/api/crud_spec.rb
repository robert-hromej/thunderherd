# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api CRUD", type: :request do
  describe "environments" do
    it "creates an environment, finding-or-creating the site" do
      expect do
        post "/api/environments", params: {
          site_key: "acme", site_name: "Acme",
          environment: { name: "staging", base_url: "https://staging.acme.test" }
        }
      end.to change(Environment, :count).by(1).and change(Site, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("site" => "acme", "name" => "staging")
    end

    it "updates and deletes an environment" do
      env = create(:environment)
      patch "/api/environments/#{env.id}", params: { environment: { base_url: "https://new.test" } }
      expect(response).to have_http_status(:ok)
      expect(env.reload.base_url).to eq("https://new.test")

      delete "/api/environments/#{env.id}"
      expect(response).to have_http_status(:no_content)
      expect(Environment.exists?(env.id)).to be(false)
    end
  end

  describe "urls" do
    let(:environment) { create(:environment) }

    it "creates, updates and deletes a url" do
      post "/api/environments/#{environment.id}/urls", params: { url: { method: "GET", path: "/health" } }
      expect(response).to have_http_status(:created)
      url = Url.find(response.parsed_body["id"])

      patch "/api/urls/#{url.id}", params: { url: { path: "/status" } }
      expect(url.reload.path).to eq("/status")

      delete "/api/urls/#{url.id}"
      expect(response).to have_http_status(:no_content)
      expect(Url.exists?(url.id)).to be(false)
    end
  end

  describe "run configs" do
    let(:environment) { create(:environment) }

    it "creates, updates and deletes a config" do
      post "/api/run_configs", params: {
        run_config: { name: "smoke", environment_id: environment.id, requests_per_url: 10, concurrency: 2 }
      }
      expect(response).to have_http_status(:created)
      config = RunConfig.find(response.parsed_body["id"])

      patch "/api/run_configs/#{config.id}", params: { run_config: { concurrency: 5 } }
      expect(config.reload.concurrency).to eq(5)

      delete "/api/run_configs/#{config.id}"
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "sites" do
    it "creates a site and deletes an empty one" do
      post "/api/sites", params: { site: { key: "widget", name: "Widget" } }
      expect(response).to have_http_status(:created)
      site = Site.find(response.parsed_body["id"])

      delete "/api/sites/#{site.id}"
      expect(response).to have_http_status(:no_content)
    end

    it "refuses to delete a site that still has environments" do
      env = create(:environment)
      delete "/api/sites/#{env.site_id}"
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Site.exists?(env.site_id)).to be(true)
    end
  end

  describe "runs" do
    it "deletes a run and its results" do
      run = create(:run)
      create(:result, run: run)
      delete "/api/runs/#{run.id}"
      expect(response).to have_http_status(:no_content)
      expect(Run.exists?(run.id)).to be(false)
    end
  end
end
