class AnalysisJob < ApplicationJob
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
      error_message = set_error_message(error)
      job.arguments.first.update(
        status: "failed",
        error_message: error_message
      )
    end
  end

  def set_error_message(error)
    if error.is_a?(KnownDomainError)
      error.message
    else
      "Internal server error"
    end
  end
end
