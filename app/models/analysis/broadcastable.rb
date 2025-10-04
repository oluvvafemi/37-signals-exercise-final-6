module Analysis::Broadcastable
  extend ActiveSupport::Concern

  included do
    after_update_commit :broadcast_update, if: -> { saved_change_to_status? }
  end

  private

  def broadcast_update
    broadcast_replace target: "analysis_details",
                      partial: "analyses/analysis",
                      locals: { analysis: self }
  end
end
