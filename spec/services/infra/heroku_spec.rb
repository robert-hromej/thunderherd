# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infra::Heroku do
  let(:ok) { instance_double(Process::Status, success?: true) }

  before { allow(described_class).to receive(:available?).and_return(true) }

  describe ".dyno_formation" do
    it "parses the ps:scale output into structured entries" do
      allow(Open3).to receive(:capture3)
        .and_return([ "web=2:Standard-2X worker=1:Standard-1X\n", "", ok ])

      expect(described_class.dyno_formation("my-app")).to eq([
        { process_type: "web", quantity: 2, size: "Standard-2X" },
        { process_type: "worker", quantity: 1, size: "Standard-1X" }
      ])
    end

    it "returns [] for a blank app" do
      expect(described_class.dyno_formation("")).to eq([])
    end

    it "returns [] when the heroku CLI is unavailable" do
      allow(described_class).to receive(:available?).and_return(false)
      expect(described_class.dyno_formation("my-app")).to eq([])
    end

    it "returns [] when the command fails" do
      allow(Open3).to receive(:capture3)
        .and_return([ "", "boom", instance_double(Process::Status, success?: false) ])
      expect(described_class.dyno_formation("my-app")).to eq([])
    end
  end

  describe ".latest_release" do
    it "parses the releases JSON into a release hash" do
      json = '[{"version":123,"description":"Deploy abc","created_at":"2026-07-24T00:00:00Z"}]'
      allow(Open3).to receive(:capture3).and_return([ json, "", ok ])

      expect(described_class.latest_release("my-app")).to include(
        heroku_release: "v123", description: "Deploy abc", deployed_at: "2026-07-24T00:00:00Z"
      )
    end

    it "returns nil for a blank app" do
      expect(described_class.latest_release(nil)).to be_nil
    end

    it "returns nil when the JSON is empty" do
      allow(Open3).to receive(:capture3).and_return([ "[]", "", ok ])
      expect(described_class.latest_release("my-app")).to be_nil
    end

    it "returns nil on malformed JSON" do
      allow(Open3).to receive(:capture3).and_return([ "not json", "", ok ])
      expect(described_class.latest_release("my-app")).to be_nil
    end
  end
end
