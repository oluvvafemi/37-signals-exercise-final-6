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

  after_update_commit :broadcast_update

  private

  def broadcast_update
    broadcast_replace_later target: "analysis_status_details",
                            partial: "analyses/analysis_status",
                            locals: { analysis: self }
  end
end
