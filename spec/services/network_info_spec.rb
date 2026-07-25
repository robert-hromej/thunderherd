# frozen_string_literal: true

require "rails_helper"

RSpec.describe NetworkInfo, :net do
  def stub_sh(map)
    allow(described_class).to receive(:sh) do |cmd|
      map.find { |k, _| cmd.include?(k) }&.last || ""
    end
  end

  describe ".kind" do
    it "detects vpn from a tunnel default interface" do
      stub_sh("route -n get default" => "interface: utun3")
      expect(described_class.kind).to eq("vpn")
    end

    it "detects wifi on macOS via networksetup" do
      stub_sh(
        "route -n get default" => "interface: en0",
        "networksetup" => "Hardware Port: Wi-Fi\nDevice: en0\nEthernet Address: aa:bb"
      )
      expect(described_class.kind).to eq("wifi")
    end

    it "detects ethernet when the default interface is not the wifi device" do
      stub_sh(
        "route -n get default" => "interface: en7",
        "networksetup" => "Hardware Port: Wi-Fi\nDevice: en0\nEthernet Address: aa:bb"
      )
      expect(described_class.kind).to eq("ethernet")
    end

    it "detects wifi on Linux from a wl* interface" do
      stub_sh("ip route show default" => "default via 10.0.0.1 dev wlp3s0 proto dhcp")
      expect(described_class.kind).to eq("wifi")
    end

    it "returns unknown when no default interface is found" do
      stub_sh({})
      expect(described_class.kind).to eq("unknown")
    end
  end

  describe ".ping_avg_ms" do
    it "parses the average RTT" do
      stub_sh("ping" => "round-trip min/avg/max/stddev = 10.1/12.34/15.0/1.2 ms")
      expect(described_class.ping_avg_ms("example.com")).to eq(12.34)
    end

    it "returns nil when ping fails" do
      stub_sh("ping" => "")
      expect(described_class.ping_avg_ms("example.com")).to be_nil
    end
  end

  describe ".coarsen" do
    it "coarsens an IPv4 to /24 and rejects non-IPv4" do
      expect(described_class.coarsen("203.0.113.42")).to eq("203.0.113.0/24")
      expect(described_class.coarsen("2001:db8::1")).to be_nil
      expect(described_class.coarsen(nil)).to be_nil
    end
  end

  describe ".collect" do
    it "returns kind + measured_at and merges rtt for a target host" do
      stub_sh(
        "route -n get default" => "interface: utun3",
        "ping" => "round-trip min/avg/max/stddev = 9.0/11.5/14.0/1.0 ms"
      )
      attrs = described_class.collect(target_host: "example.com")
      expect(attrs[:kind]).to eq("vpn")
      expect(attrs[:rtt_ms]).to eq(11.5)
      expect(attrs[:measured_at]).to be_present
    end

    it "never raises — falls back to unknown" do
      allow(described_class).to receive(:kind).and_raise("boom")
      expect(described_class.collect[:kind]).to eq("unknown")
    end
  end
end
