# frozen_string_literal: true

class RunLoadTestJob < ApplicationJob
  queue_as :default

  def perform(run_config_id: nil, environment_id: nil, requests_per_url: nil,
              concurrency: nil, timeout_s: nil, label: nil, allow_prod: false, store_samples: false)
    LoadTest::Executor.new(
      run_config: (RunConfig.find(run_config_id) if run_config_id),
      environment: (Environment.find(environment_id) if environment_id),
      requests_per_url:, concurrency:, timeout_s:, label:, allow_prod:, store_samples:
    ).call
  end
end
