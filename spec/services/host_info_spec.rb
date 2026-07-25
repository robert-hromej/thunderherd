# frozen_string_literal: true

require "rails_helper"

RSpec.describe HostInfo do
  before do
    allow(described_class).to receive(:sh) do |cmd|
      {
        "hostname" => "test-host",
        "uname -s" => "Darwin",
        "uname -r" => "23.0.0",
        "uname -m" => "arm64",
        "sysctl -n machdep.cpu.brand_string" => "Apple M1",
        "sysctl -n hw.ncpu" => "8",
        "sysctl -n hw.memsize" => "17179869184",
        "git config user.name" => "Test User",
        "git config user.email" => "test@example.com"
      }.fetch(cmd, "")
    end
  end

  describe ".machine_attrs" do
    it "collects host facts with a stable 32-char fingerprint" do
      attrs = described_class.machine_attrs
      expect(attrs[:hostname]).to eq("test-host")
      expect(attrs[:os]).to eq("Darwin 23.0.0")
      expect(attrs[:arch]).to eq("arm64")
      expect(attrs[:cpu_model]).to eq("Apple M1")
      expect(attrs[:cpu_cores]).to eq(8)
      expect(attrs[:ram_mb]).to eq(16_384)
      expect(attrs[:fingerprint]).to match(/\A[0-9a-f]{32}\z/)
    end

    it "produces the same fingerprint for the same host" do
      expect(described_class.machine_attrs[:fingerprint])
        .to eq(described_class.machine_attrs[:fingerprint])
    end
  end

  describe ".operator_attrs" do
    around do |example|
      original = ENV.to_hash.slice("THUNDERHERD_OPERATOR", "THUNDERHERD_OPERATOR_EMAIL")
      ENV.delete("THUNDERHERD_OPERATOR")
      ENV.delete("THUNDERHERD_OPERATOR_EMAIL")
      example.run
      original.each { |k, v| ENV[k] = v }
    end

    it "returns the git-configured name and email" do
      attrs = described_class.operator_attrs
      expect(attrs[:name]).to eq("Test User")
      expect(attrs[:email]).to eq("test@example.com")
    end

    it "falls back to 'unknown' when nothing identifies the operator" do
      allow(described_class).to receive(:sh).and_return("")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("USER").and_return(nil)
      expect(described_class.operator_attrs).to eq(name: "unknown", email: nil)
    end
  end
end
