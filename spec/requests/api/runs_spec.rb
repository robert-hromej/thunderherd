# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Runs", type: :request do
  describe "GET /api/runs" do
    it "lists run summaries" do
      run = create(:run, status: "completed")
      create(:result, run: run)

      get "/api/runs"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to be_an(Array)
      expect(body.first).to include("id" => run.id, "status" => "completed")
      expect(body.first).to include("pages", "total_errors", "avg_p95_ms")
    end
  end

  describe "GET /api/runs/:id" do
    it "returns the detailed run payload" do
      run = create(:run, status: "completed")
      result = create(:result, run: run, path: "/home")
      create(:result_status_code, result: result, status_code: 200, count: 50)

      get "/api/runs/#{run.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include("id" => run.id, "status" => "completed", "duration_s" => run.duration_s)
      expect(body["summary"]).to include("pages" => 1)
      expect(body["results"].first).to include("path" => "/home", "status_codes" => { "200" => 50 })
    end

    it "returns 404 for an unknown run" do
      get "/api/runs/0"
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to include("error")
    end
  end

  describe "POST /api/runs" do
    it "enqueues a load-test job and returns 202" do
      environment = create(:environment)

      expect do
        post "/api/runs", params: { environment_id: environment.id }
      end.to have_enqueued_job(RunLoadTestJob)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body).to include("enqueued" => true, "environment" => environment.label)
    end

    it "resolves the environment from a run_config" do
      config = create(:run_config)

      expect do
        post "/api/runs", params: { run_config_id: config.id }
      end.to have_enqueued_job(RunLoadTestJob)

      expect(response).to have_http_status(:accepted)
    end

    it "returns 422 when neither environment nor run_config is given" do
      expect do
        post "/api/runs", params: {}
      end.not_to have_enqueued_job(RunLoadTestJob)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "refuses a production environment without allow_prod" do
      environment = create(:production_environment)

      expect do
        post "/api/runs", params: { environment_id: environment.id }
      end.not_to have_enqueued_job(RunLoadTestJob)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("PRODUCTION")
    end

    it "runs a production environment when allow_prod is truthy" do
      environment = create(:production_environment)

      expect do
        post "/api/runs", params: { environment_id: environment.id, allow_prod: "1" }
      end.to have_enqueued_job(RunLoadTestJob)

      expect(response).to have_http_status(:accepted)
    end
  end

  describe "GET /api/runs/:id/compare" do
    it "diffs matching results across two runs" do
      before_run = create(:run, status: "completed")
      after_run = create(:run, status: "completed")
      create(:result, run: before_run, method: "GET", path: "/home", avg_ms: 100, p95_ms: 150, rps: 10)
      create(:result, run: after_run, method: "GET", path: "/home", avg_ms: 120, p95_ms: 180, rps: 9)

      get "/api/runs/#{before_run.id}/compare", params: { to: after_run.id }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["before"]).to include("id" => before_run.id)
      expect(body["after"]).to include("id" => after_run.id)
      expect(body["diff"].first).to include(
        "method" => "GET", "path" => "/home", "avg_delta" => 20.0, "p95_delta" => 30.0
      )
    end
  end
end
