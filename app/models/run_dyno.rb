# frozen_string_literal: true

class RunDyno < ApplicationRecord
  belongs_to :run

  validates :process_type, :size, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
