# frozen_string_literal: true

# Optional raw per-request sample (opt-in; high volume). Enables true histograms.
class ResultSample < ApplicationRecord
  belongs_to :result
end
