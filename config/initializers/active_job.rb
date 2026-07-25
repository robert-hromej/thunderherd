# frozen_string_literal: true

# Run web-triggered load tests in-process (no separate worker needed). Tests use the
# :test adapter (Rails default) so runs never fire automatically during specs.
Rails.application.config.active_job.queue_adapter = :async unless Rails.env.test?
