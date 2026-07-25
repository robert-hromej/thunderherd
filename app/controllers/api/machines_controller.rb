# frozen_string_literal: true

module Api
  class MachinesController < BaseController
    def index
      counts = Run.group(:machine_id).count
      last_runs = Run.group(:machine_id).maximum(:started_at)
      machines = Machine.order(:hostname).map do |m|
        { id: m.id, hostname: m.hostname, os: m.os, arch: m.arch,
          cpu_model: m.cpu_model, cpu_cores: m.cpu_cores, ram_mb: m.ram_mb,
          runs_count: counts.fetch(m.id, 0), last_run_at: last_runs[m.id] }
      end
      render json: machines
    end
  end
end
