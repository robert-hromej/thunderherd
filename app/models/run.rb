# frozen_string_literal: true

class Run < ApplicationRecord
  STATUSES = %w[running completed aborted failed].freeze

  belongs_to :environment
  belongs_to :run_config, optional: true
  belongs_to :operator, optional: true
  belongs_to :machine, optional: true
  belongs_to :deploy, class_name: "AppDeploy", optional: true

  has_many :run_dynos, dependent: :destroy
  has_one :run_network, dependent: :destroy
  has_many :results, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :requests_per_url, :concurrency, numericality: { only_integer: true, greater_than: 0 }

  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(started_at: :desc) }

  def duration_s
    return nil unless finished_at && started_at

    (finished_at - started_at).round(1)
  end

  def dyno_formation
    run_dynos.order(:process_type).map { |d| "#{d.process_type}=#{d.quantity}:#{d.size}" }.join(" ")
  end
end
