# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoadTest::Executor do
  let(:stats) do
    {
      requests: 50, error_count: 1, rps: 12.5, min_ms: 100, avg_ms: 200, p50_ms: 190,
      p90_ms: 250, p95_ms: 300, p99_ms: 350, max_ms: 400, stddev_ms: 30,
      dns_ms: 5, connect_ms: 10, server_ms: 150, transfer_ms: 2,
      codes: { 200 => 49, 500 => 1 },
      samples: [ { seq: 1, response_ms: 200, status_code: 200, offset_ms: 0 } ]
    }
  end

  let(:runner_class) do
    result = stats
    Class.new do
      define_method(:initialize) { |**| }
      define_method(:call) { |method:, url:, body:| result }
    end
  end

  let(:machine_attrs) do
    { fingerprint: "fp-executor", hostname: "runner-host", os: "TestOS", arch: "arm64",
      cpu_model: "Test CPU", cpu_cores: 8, ram_mb: 16_000 }
  end

  before do
    allow(LoadTest::HeyRunner).to receive(:version).and_return("hey 0.1.5")
    allow(Infra::Heroku).to receive(:dyno_formation).and_return([])
    allow(Infra::Heroku).to receive(:latest_release).and_return(nil)
    allow(HostInfo).to receive(:machine_attrs).and_return(machine_attrs)
    allow(HostInfo).to receive(:operator_attrs).and_return(name: "Tester", email: "tester@example.com")
  end

  describe "#call on a staging environment" do
    let(:environment) { create(:environment) }
    let!(:url) { create(:url, environment: environment, path: "/home") }

    subject(:run) do
      described_class.new(environment: environment, runner_class: runner_class).call
    end

    it "creates a completed run" do
      expect(run).to be_persisted
      expect(run.status).to eq("completed")
      expect(run.finished_at).to be_present
    end

    it "persists one result per url with the runner's metrics" do
      run
      result = run.results.sole
      expect(result.path).to eq("/home")
      expect(result[:method]).to eq("GET")
      expect(result.requests).to eq(50)
      expect(result.error_count).to eq(1)
    end

    it "persists the status-code distribution" do
      run
      distribution = run.results.sole.result_status_codes.to_h { |c| [ c.status_code, c.count ] }
      expect(distribution).to eq(200 => 49, 500 => 1)
    end

    it "records the operator and machine" do
      expect(run.operator.email).to eq("tester@example.com")
      expect(run.machine.fingerprint).to eq("fp-executor")
    end

    it "creates run_dynos from the Heroku dyno formation" do
      allow(Infra::Heroku).to receive(:dyno_formation)
        .and_return([ { process_type: "web", quantity: 2, size: "Standard-2X" } ])
      expect(run.run_dynos.map(&:process_type)).to eq([ "web" ])
    end

    it "attaches the deploy when a release is present" do
      allow(Infra::Heroku).to receive(:latest_release)
        .and_return(heroku_release: "v99", git_sha: "abc1234", description: "Deploy abc",
                    deployed_at: Time.current)
      expect(run.deploy.heroku_release).to eq("v99")
    end

    it "stores raw samples only when requested" do
      run_with_samples = described_class.new(
        environment: environment, runner_class: runner_class, store_samples: true
      ).call
      expect(run_with_samples.results.sole.result_samples.count).to eq(1)
    end
  end

  describe "#call on a production environment" do
    let(:environment) { create(:production_environment) }
    let!(:url) { create(:url, environment: environment) }

    it "refuses to run without allow_prod" do
      expect { described_class.new(environment: environment, runner_class: runner_class).call }
        .to raise_error(described_class::ProductionNotAllowed)
    end

    it "runs when allow_prod is set" do
      run = described_class.new(
        environment: environment, runner_class: runner_class, allow_prod: true
      ).call
      expect(run.status).to eq("completed")
    end
  end

  describe "#call when the runner raises" do
    let(:environment) { create(:environment) }
    let!(:url) { create(:url, environment: environment) }
    let(:failing_runner_class) do
      Class.new do
        define_method(:initialize) { |**| }
        define_method(:call) { |method:, url:, body:| raise "runner boom" }
      end
    end

    it "marks the run failed and re-raises" do
      expect do
        described_class.new(environment: environment, runner_class: failing_runner_class).call
      end.to raise_error("runner boom")

      run = Run.last
      expect(run.status).to eq("failed")
      expect(run.notes).to eq("runner boom")
    end
  end

  describe "argument handling" do
    it "requires an environment or run_config" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "derives the environment from a run_config" do
      config = create(:run_config)
      create(:url, environment: config.environment)
      run = described_class.new(run_config: config, runner_class: runner_class).call
      expect(run.environment).to eq(config.environment)
      expect(run.run_config).to eq(config)
    end
  end
end
