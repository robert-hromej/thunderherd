# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunLoadTestJob do
  describe "#perform" do
    it "invokes the executor with the resolved environment" do
      environment = create(:environment)
      executor = instance_double(LoadTest::Executor, call: create(:run))
      expect(LoadTest::Executor).to receive(:new)
        .with(hash_including(environment: environment, run_config: nil))
        .and_return(executor)

      described_class.perform_now(environment_id: environment.id)
    end

    it "resolves a run_config by id and passes it through" do
      config = create(:run_config)
      executor = instance_double(LoadTest::Executor, call: create(:run))
      expect(LoadTest::Executor).to receive(:new)
        .with(hash_including(run_config: config))
        .and_return(executor)

      described_class.perform_now(run_config_id: config.id)
    end

    it "drives a real executor to create a completed run" do
      environment = create(:environment)
      create(:url, environment: environment)
      stats = {
        requests: 10, error_count: 0, rps: 5.0, min_ms: 10, avg_ms: 20, p50_ms: 18,
        p90_ms: 25, p95_ms: 30, p99_ms: 40, max_ms: 50, stddev_ms: 3,
        dns_ms: 1, connect_ms: 2, server_ms: 15, transfer_ms: 1,
        codes: { 200 => 10 }, samples: []
      }
      allow(LoadTest::HeyRunner).to receive(:version).and_return("hey 0.1.5")
      allow(LoadTest::HeyRunner).to receive(:available?).and_return(true)
      allow_any_instance_of(LoadTest::HeyRunner).to receive(:call).and_return(stats)
      allow(Infra::Heroku).to receive(:dyno_formation).and_return([])
      allow(Infra::Heroku).to receive(:latest_release).and_return(nil)
      allow(HostInfo).to receive(:machine_attrs).and_return(
        fingerprint: "fp-job", hostname: "h", os: "o", arch: "a",
        cpu_model: "c", cpu_cores: 4, ram_mb: 8000
      )
      allow(HostInfo).to receive(:operator_attrs).and_return(name: "Op", email: nil)

      expect { described_class.perform_now(environment_id: environment.id) }
        .to change(Run, :count).by(1)
      expect(Run.last.status).to eq("completed")
    end
  end
end
