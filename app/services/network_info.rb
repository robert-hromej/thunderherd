# frozen_string_literal: true

require "open3"
require "timeout"
require "json"
require "shellwords"

# Best-effort facts about the network a test ran over — latency depends on it.
# Local-only by default: connection kind (wifi/ethernet/vpn) + ping RTT to the target
# host. Set THUNDERHERD_NET_LOOKUP=1 to also resolve ISP/geo via ipinfo.io (one
# external call); the public IP is stored coarsened to /24, never raw.
module NetworkInfo
  module_function

  def collect(target_host: nil)
    attrs = { kind: kind, measured_at: Time.current }
    rtt = target_host && ping_avg_ms(target_host)
    attrs[:rtt_ms] = rtt if rtt
    attrs.merge!(isp_geo) if ENV["THUNDERHERD_NET_LOOKUP"] == "1"
    attrs
  rescue StandardError
    { kind: "unknown", measured_at: Time.current }
  end

  def kind
    iface = default_interface
    return "unknown" if iface.blank?
    return "vpn" if iface.match?(/\A(utun|tun|tap|ppp|wg)/)
    return "wifi" if wifi_interface?(iface)

    "ethernet"
  end

  def default_interface
    mac = sh("route -n get default")[/interface:\s*(\S+)/, 1]
    return mac if mac.present?

    sh("ip route show default")[/\bdev\s+(\S+)/, 1]
  end

  def wifi_interface?(iface)
    ports = sh("networksetup -listallhardwareports")
    if ports.present?
      wifi_dev = ports[/Hardware Port: (?:Wi-?Fi|AirPort)\s*\nDevice: (\S+)/i, 1]
      return iface == wifi_dev
    end

    iface.start_with?("wl") || File.exist?("/sys/class/net/#{iface}/wireless")
  end

  def ping_avg_ms(host)
    out = Timeout.timeout(8) { sh("ping -c 3 -q #{host.to_s.shellescape}") }
    out[%r{=\s*[\d.]+/([\d.]+)/}, 1]&.to_f&.round(2)
  rescue Timeout::Error
    nil
  end

  def isp_geo
    raw = Timeout.timeout(6) { sh("curl -s --max-time 4 https://ipinfo.io/json") }
    data = JSON.parse(raw)
    { isp: data["org"], city: data["city"], country: data["country"],
      public_ip_cidr: coarsen(data["ip"]) }.compact
  rescue StandardError
    {}
  end

  def coarsen(ip)
    return nil unless ip&.match?(/\A\d+\.\d+\.\d+\.\d+\z/)

    ip.sub(/\.\d+\z/, ".0/24")
  end

  def sh(cmd)
    `#{cmd} 2>/dev/null`.strip
  rescue StandardError
    ""
  end
end
