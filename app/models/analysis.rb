class Analysis < ApplicationRecord
  include Executable, Broadcastable

  belongs_to :web_page

  serialize :table_of_contents, coder: JSON
  serialize :top_word_frequencies, coder: JSON

  enum :status, %w[ pending fetching parsing analyzing failed completed ].index_by(&:itself), default: :pending
end
