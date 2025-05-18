require "test_helper"
require "minitest/mock"

class WebPageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#initiate_analysis creates an Analysis, enqueues job with it, and returns it" do
    web_page = WebPage.create!(url: "http://example.com/test-main")
    returned_analysis_from_block = nil

    job_args_checker = ->(job_args) {
      job_args.is_a?(Array) &&
      job_args.length == 1 &&
      job_args.first.is_a?(Analysis) &&
      job_args.first == returned_analysis_from_block &&
      !returned_analysis_from_block.nil?
    }

    assert_enqueued_with(
      job: AnalysisJob,
      args: job_args_checker,
      queue: "default"
    ) do
      assert_difference -> { Analysis.count }, 1, "Expected an Analysis record to be created" do
        returned_analysis_from_block = web_page.initiate_analysis
      end
    end

    assert_equal web_page, returned_analysis_from_block.web_page, "Returned analysis should be associated with the web_page"
  end

  test "#initiate_analysis rolls back Analysis creation if job enqueue fails" do
    web_page = WebPage.create!(url: "http://example.com/test-rollback")

    AnalysisJob.stub(:perform_later, ->(_analysis_arg) { raise "Simulated Job Enqueue Error" }) do
      assert_no_difference -> { Analysis.count }, "Expected no new Analysis record if transaction rolls back" do
        assert_raises RuntimeError, "Simulated Job Enqueue Error" do
          web_page.initiate_analysis
        end
      end
    end

    assert_nil web_page.analyses.reload.first, "Analysis record should have been rolled back"
    assert_equal 0, web_page.analyses.count, "Analysis count for the web_page should be 0 after rollback"
  end
end
