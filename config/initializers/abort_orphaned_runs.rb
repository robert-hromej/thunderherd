# frozen_string_literal: true

# Web-triggered runs execute in-process (async adapter), so no job survives a server
# restart: any run still "running" when a server boots is an orphan. Mark them aborted
# so they don't sit in the UI as running forever. Runs on `rails server` boots (and
# anywhere else with ABORT_ORPHANED_RUNS=1, e.g. a bare-puma production boot).
Rails.application.config.after_initialize do
  next unless defined?(Rails::Server) || ENV["ABORT_ORPHANED_RUNS"] == "1"

  begin
    count = Run.where(status: "running").update_all(
      status: "aborted", finished_at: Time.current,
      notes: "Orphaned: the server restarted while this run was in progress."
    )
    Rails.logger.info("thunderherd: aborted #{count} orphaned run(s) at boot") if count.positive?
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    # db:create / db:migrate boot paths — table may not exist yet.
  end
end
