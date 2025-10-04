require "test_helper"
require "minitest/mock"

class AnalysisJobTest < ActiveJob::TestCase
  test "perform calls run on the analysis object" do
    analysis_mock = Minitest::Mock.new
    analysis_mock.expect :run, nil

    job = AnalysisJob.new
    job.perform(analysis_mock)

    assert analysis_mock.verify
  end

  test "is enqueued in the default queue" do
    assert_equal "default", AnalysisJob.new.queue_name
  end

  test "after_discard marks analysis as failed with Harvester::FatalError message" do
    analysis = Analysis.create!(web_page: WebPage.create!(url: "http://example.com/discard-fatal"), status: :fetching)
    error = Harvester::FatalError.new("Simulated fatal harvester error")

    job = AnalysisJob.new(analysis)
    job.send(:mark_analysis_as_failed, job, error)

    analysis.reload
    assert_equal "failed", analysis.status
    assert_equal "Simulated fatal harvester error", analysis.error_message
  end

  test "after_discard marks analysis as failed with HtmlScribe::ParseError message" do
    analysis = Analysis.create!(web_page: WebPage.create!(url: "http://example.com/discard-parse"), status: :parsing)
    error = HtmlScribe::ParseError.new("Simulated parse error")

    job = AnalysisJob.new(analysis)
    job.send(:mark_analysis_as_failed, job, error)

    analysis.reload
    assert_equal "failed", analysis.status
    assert_equal "Simulated parse error", analysis.error_message
  end

  test "after_discard marks analysis as failed with Oracle::AnalysisError message" do
    analysis = Analysis.create!(web_page: WebPage.create!(url: "http://example.com/discard-analysis-err"), status: :analyzing)
    error = Oracle::AnalysisError.new("Simulated oracle analysis error")

    job = AnalysisJob.new(analysis)
    job.send(:mark_analysis_as_failed, job, error)

    analysis.reload
    assert_equal "failed", analysis.status
    assert_equal "Simulated oracle analysis error", analysis.error_message
  end

  test "after_discard marks analysis as failed with a generic message for other StandardError types" do
    analysis = Analysis.create!(web_page: WebPage.create!(url: "http://example.com/discard-generic"), status: :analyzing)
    error = StandardError.new("Some unexpected error")

    job = AnalysisJob.new(analysis)
    job.send(:mark_analysis_as_failed, job, error)

    analysis.reload
    assert_equal "failed", analysis.status
    assert_equal "Internal server error", analysis.error_message
  end

  test "after_discard does nothing if job has no analysis argument (edge case)" do
    job = AnalysisJob.new
    error = StandardError.new("Some error")

    assert_nothing_raised do
      job.send(:mark_analysis_as_failed, job, error)
    end
  end
end
