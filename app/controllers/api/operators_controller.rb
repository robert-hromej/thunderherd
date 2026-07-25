# frozen_string_literal: true

module Api
  class OperatorsController < BaseController
    def index
      counts = Run.group(:operator_id).count
      last_runs = Run.group(:operator_id).maximum(:started_at)
      operators = Operator.order(:name).map do |o|
        { id: o.id, name: o.name, email: o.email,
          runs_count: counts.fetch(o.id, 0), last_run_at: last_runs[o.id] }
      end
      render json: operators
    end
  end
end
