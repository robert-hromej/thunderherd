# frozen_string_literal: true

# The engineer's network context at run time (1:1 with a run). Latency depends on it.
class RunNetwork < ApplicationRecord
  KINDS = %w[ethernet wifi cellular vpn unknown].freeze

  self.primary_key = "run_id"
  belongs_to :run

  validates :kind, inclusion: { in: KINDS }
end
