class AnalysisJob < ApplicationJob
  queue_as :default

  def perform(analysis)
    analysis.run
  end
end
