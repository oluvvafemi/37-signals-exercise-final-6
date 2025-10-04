require "test_helper"
require "minitest/mock"

class AnalysesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "POST #create with a new, valid URL creates WebPage, initiates analysis, and redirects" do
    new_url = "http://example.com/new-page-for-analysis"
    assert_nil WebPage.find_by(url: new_url)

    assert_difference -> { WebPage.count }, 1 do
      assert_difference -> { Analysis.count }, 1 do
        assert_enqueued_jobs 1, only: AnalysisJob do
          post analyses_url, params: { analysis: { url: new_url } }
        end
      end
    end

    created_web_page = WebPage.find_by(url: new_url)
    assert_not_nil created_web_page
    assert_not_nil created_web_page.analysis, "WebPage should have an associated analysis"
    new_analysis = created_web_page.analysis
    assert_not_nil new_analysis

    assert_redirected_to analysis_path(new_analysis)
  end

  test "POST #create with an existing URL redirects to its analysis and does not create new records or jobs" do
    existing_url = "http://example.com/already-analyzed"
    web_page = WebPage.create!(url: existing_url)
    existing_analysis = web_page.analysis

    clear_enqueued_jobs

    assert_no_difference [ "WebPage.count", "Analysis.count" ] do
      assert_no_enqueued_jobs do
        post analyses_url, params: { analysis: { url: existing_url } }
      end
    end

    assert_redirected_to analysis_path(existing_analysis)
  end

  test "POST #create with an invalid URL (e.g., blank) results in unprocessable_content response" do
    assert_no_difference [ "WebPage.count", "Analysis.count" ] do
      assert_no_enqueued_jobs do
        post analyses_url, params: { analysis: { url: "" } }
      end
    end
    assert_response :unprocessable_content
  end

  test "POST #create with a malformed URL results in unprocessable_content response" do
    assert_no_difference [ "WebPage.count", "Analysis.count" ] do
      assert_no_enqueued_jobs do
        post analyses_url, params: { analysis: { url: "not_a_valid_url" } }
      end
    end
    assert_response :unprocessable_content
  end

  test "GET #show for an existing analysis displays analysis details" do
    web_page = WebPage.create!(url: "http://example.com/show-test-for-analysis")
    analysis = web_page.analysis

    get analysis_path(analysis)

    assert_response :success
  end

  test "GET #show for a non-existent analysis results in not_found response" do
    non_existent_analysis_id = 0
    Analysis.delete(non_existent_analysis_id) if Analysis.exists?(non_existent_analysis_id)

    get analysis_path(non_existent_analysis_id)
    assert_response :not_found
  end
end
