require "test_helper"
require "minitest/mock"

class WebPageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "creating a WebPage automatically creates an associated Analysis record with pending status" do
    assert_difference -> { Analysis.count }, 1, "Expected an Analysis record to be created" do
      @web_page = WebPage.create!(url: "http://example.com/test-creation")
    end

    assert_not_nil @web_page.analysis, "WebPage should have an associated analysis"
    assert_equal @web_page, @web_page.analysis.web_page, "Analysis should belong to the correct WebPage"
    assert_equal "pending", @web_page.analysis.status, "Analysis should have a default status of pending"
  end

  test "#initiate_analysis enqueues an AnalysisJob with the web_page's analysis" do
    web_page = WebPage.create!(url: "http://example.com/test-initiate")

    assert_enqueued_with(
      job: AnalysisJob,
      args: [ web_page.analysis ],
      queue: "default"
    ) do
      assert_no_difference -> { Analysis.count } do
        web_page.initiate_analysis
      end
    end
  end

  test "#initiate_analysis allows Job enqueuing errors to propagate and does not affect existing Analysis record" do
    web_page = WebPage.create!(url: "http://example.com/test-enqueue-fail")
    initial_analysis = web_page.analysis

    AnalysisJob.stub(:perform_later, ->(_analysis_arg) { raise StandardError, "Simulated Job Enqueue Error" }) do
      assert_raises StandardError, "Simulated Job Enqueue Error" do
        web_page.initiate_analysis
      end
    end

    web_page.reload
    assert_equal initial_analysis, web_page.analysis, "Analysis record should still exist and be the same"
    assert_equal "pending", web_page.analysis.status, "Analysis status should remain pending"
  end

  test ".most_recently_analyzed returns recently completed analyses" do
    wp1 = WebPage.create!(url: "http://example.com/recent1")
    wp1.analysis.update!(status: :completed, updated_at: 1.hour.ago)

    wp2 = WebPage.create!(url: "http://example.com/recent2")
    wp2.analysis.update!(status: :completed, updated_at: 30.minutes.ago)

    wp3 = WebPage.create!(url: "http://example.com/pending")

    wp4 = WebPage.create!(url: "http://example.com/failed")
    wp4.analysis.update!(status: :failed, updated_at: 10.minutes.ago)

    wp5 = WebPage.create!(url: "http://example.com/recent_older")
    wp5.analysis.update!(status: :completed, updated_at: 2.hours.ago)


    recent_analyses_web_pages = WebPage.most_recently_analyzed
    recent_analyses = recent_analyses_web_pages.map(&:analysis)

    assert_includes recent_analyses, wp2.analysis
    assert_includes recent_analyses, wp1.analysis
    assert_includes recent_analyses, wp5.analysis
    assert_not_includes recent_analyses, wp3.analysis
    assert_not_includes recent_analyses, wp4.analysis

    expected_order = [ wp2.analysis, wp1.analysis, wp5.analysis ].sort_by(&:updated_at).reverse
    returned_order = recent_analyses_web_pages.map(&:analysis).sort_by(&:updated_at).reverse

    assert_equal expected_order, returned_order.take(expected_order.length)
    assert_equal expected_order.length, recent_analyses.count
  end
end
