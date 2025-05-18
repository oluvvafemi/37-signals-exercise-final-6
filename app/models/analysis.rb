class Analysis < ApplicationRecord
  belongs_to :web_page
  include Executable

  enum :status, %w[
    pending
    fetching
    parsing
    processing
    failed
    completed
  ].index_by(&:itself), default: :pending
end
