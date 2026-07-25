# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api run annotations", type: :request do
  let(:run) { create(:run) }

  it "marks and unmarks a run as the baseline" do
    patch "/api/runs/#{run.id}", params: { run: { is_baseline: true } }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["is_baseline"]).to be(true)
    expect(run.reload.is_baseline).to be(true)

    patch "/api/runs/#{run.id}", params: { run: { is_baseline: false } }
    expect(run.reload.is_baseline).to be(false)
  end

  it "updates the label and notes" do
    patch "/api/runs/#{run.id}", params: { run: { label: "before-caching", notes: "off-peak" } }
    expect(response.parsed_body).to include("label" => "before-caching", "notes" => "off-peak")
  end

  it "refuses to rewrite measurements" do
    original = run.requests_per_url
    patch "/api/runs/#{run.id}", params: { run: { requests_per_url: 9999, status: "failed" } }
    expect(response).to have_http_status(:ok)
    expect(run.reload.requests_per_url).to eq(original)
    expect(run.status).to eq("completed")
  end

  it "404s for an unknown run" do
    patch "/api/runs/0", params: { run: { is_baseline: true } }
    expect(response).to have_http_status(:not_found)
  end
end
