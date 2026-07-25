# frozen_string_literal: true

class ResultStatusCode < ApplicationRecord
  self.primary_key = %i[result_id status_code]

  belongs_to :result
end
