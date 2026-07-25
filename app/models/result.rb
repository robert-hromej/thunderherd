# frozen_string_literal: true

# Aggregated metrics for one URL within one run (the core fact row).
class Result < ApplicationRecord
  belongs_to :run
  belongs_to :url, optional: true
  has_many :result_status_codes, dependent: :destroy
  has_many :result_samples, dependent: :destroy

  # The measured columns, in report order — one source of truth for what the runner
  # persists and what the API serializes.
  METRICS = %i[
    rps min_ms avg_ms p50_ms p90_ms p95_ms p99_ms max_ms stddev_ms
    dns_ms connect_ms server_ms transfer_ms
  ].freeze

  validates :method, inclusion: { in: Url::METHODS }
  validates :path, presence: true
  validates :requests, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :completed_runs, -> { joins(:run).where(runs: { status: "completed" }) }
end
