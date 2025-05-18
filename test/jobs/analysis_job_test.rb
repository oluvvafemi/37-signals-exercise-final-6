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
    assert_equal "default", AnalysisJob.new.queue_name, "Should be enqueued in the default queue"
  end
end
