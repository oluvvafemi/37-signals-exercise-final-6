class AnalysisJob < ApplicationJob
  queue_as :default

  def perform(analysis)
    # analysis.perform_analysis
  end
end
