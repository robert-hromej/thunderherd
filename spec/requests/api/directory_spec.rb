# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api directory endpoints", type: :request do
  it "lists operators with run counts" do
    operator = create(:operator, name: "Alice")
    create(:run, operator: operator)

    get "/api/operators"
    expect(response).to have_http_status(:ok)
    row = response.parsed_body.find { |o| o["id"] == operator.id }
    expect(row).to include("name" => "Alice", "runs_count" => 1)
    expect(row["last_run_at"]).to be_present
  end

  it "lists machines with hardware facts and run counts" do
    machine = create(:machine, hostname: "builder-1", cpu_cores: 8)
    create(:run, machine: machine)

    get "/api/machines"
    row = response.parsed_body.find { |m| m["id"] == machine.id }
    expect(row).to include("hostname" => "builder-1", "cpu_cores" => 8, "runs_count" => 1)
  end

  it "lists deploys newest-first with environment labels" do
    deploy = create(:app_deploy, heroku_release: "v42", git_sha: "abcdef1234")
    create(:run, environment: deploy.environment, deploy: deploy)

    get "/api/app_deploys"
    row = response.parsed_body.find { |d| d["id"] == deploy.id }
    expect(row).to include("heroku_release" => "v42", "runs_count" => 1)
    expect(row["environment"]).to eq(deploy.environment.label)
  end
end
