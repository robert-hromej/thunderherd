# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Dashboard", type: :request do
  describe "GET /api/dashboard" do
    it "returns counts, latest runs and slowest pages" do
      run = create(:run, status: "completed")
      create(:result, run: run, p95_ms: 900, error_count: 2)
      create(:running_run)

      get "/api/dashboard"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["counts"]).to include(
        "sites" => Site.count, "environments" => Environment.count,
        "runs" => Run.count, "completed_runs" => 1
      )
      expect(body["latest_runs"]).to be_an(Array)
      slowest = body["slowest_pages"]
      expect(slowest).to be_an(Array)
      expect(slowest.first).to include("run_id" => run.id, "p95_ms" => 900.0, "error_count" => 2)
    end
  end
end
