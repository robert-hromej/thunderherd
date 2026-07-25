# frozen_string_literal: true

require "digest"

# Best-effort facts about the machine + operator running a test. Latency depends on
# both, so we record them. Cross-platform-ish (macOS/Linux); everything is optional.
module HostInfo
  module_function

  def machine_attrs
    host = sh("hostname")
    os   = "#{sh('uname -s')} #{sh('uname -r')}".strip
    arch = sh("uname -m")
    cpu  = sh("sysctl -n machdep.cpu.brand_string").presence || cpu_from_proc
    cores = sh("sysctl -n hw.ncpu").presence&.to_i || sh("nproc").presence&.to_i
    ram  = ram_mb
    {
      fingerprint: Digest::SHA256.hexdigest([ host, os, arch, cpu ].join("|"))[0, 32],
      hostname: host.presence, os: os.presence, arch: arch.presence,
      cpu_model: cpu.presence, cpu_cores: cores, ram_mb: ram
    }
  end

  def operator_attrs
    name  = ENV["THUNDERHERD_OPERATOR"].presence || sh("git config user.name").presence || ENV["USER"]
    email = ENV["THUNDERHERD_OPERATOR_EMAIL"].presence || sh("git config user.email").presence
    { name: name.presence || "unknown", email: email.presence }
  end

  def sh(cmd)
    `#{cmd} 2>/dev/null`.strip
  rescue StandardError
    ""
  end

  def cpu_from_proc
    File.readable?("/proc/cpuinfo") ? File.read("/proc/cpuinfo")[/model name\s*:\s*(.+)/, 1].to_s.strip : nil
  end

  def ram_mb
    bytes = sh("sysctl -n hw.memsize").presence&.to_i
    return (bytes / 1_048_576) if bytes&.positive?

    kb = sh("grep MemTotal /proc/meminfo")[/(\d+)/, 1]&.to_i
    kb&.positive? ? (kb / 1024) : nil
  end
end
