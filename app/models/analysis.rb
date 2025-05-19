class Analysis < ApplicationRecord
  belongs_to :web_page
  include Executable

  serialize :table_of_contents, coder: JSON
  serialize :top_word_frequencies, coder: JSON

  enum :status, %w[
    pending
    fetching
    parsing
    analyzing
    failed
    completed
  ].index_by(&:itself), default: :pending

  after_update_commit :broadcast_update, if: -> { saved_change_to_status? }

  private

  def broadcast_update
    broadcast_replace target: "analysis_details",
                     partial: "analyses/analysis",
                     locals: { analysis: self }
  end
end
