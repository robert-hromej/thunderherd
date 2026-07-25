# frozen_string_literal: true

# Read-only, backed by the Scenic view v_run_summary (one row per run + context).
class VRunSummary < ApplicationRecord
  self.table_name = "v_run_summary"
  self.primary_key = "id"

  def readonly? = true
end
