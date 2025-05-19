class AnalysisJob < ApplicationJob
  queue_as :default
  retry_on Harvester::RetryableError, wait: 5.seconds, attempts: 3

  after_discard do |job, error|
    mark_analysis_as_failed(job, error)
  end

  def perform(analysis)
    analysis.run
  end

  private

  def mark_analysis_as_failed(job, error)
    if job.arguments.first
      job.arguments.first.update(
        status: "failed",
        error_message: error.message
      )
    end
  end
end
