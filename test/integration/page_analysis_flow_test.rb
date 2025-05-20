require "test_helper"
require "minitest/mock"

class PageAnalysisFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "should navigate to home, submit a URL, and see analysis page" do
    get root_url
    assert_response :success
    assert_select "header h1", "Web Page Analyzer"
    assert_select "form[action=?] input[name=?]", analyses_path, "analysis[url]"

    new_url = "http://example.com/new-page-for-simple-nav-test"
    mock_title_for_nav_test = "Simple Nav Test Title"
    assert_nil WebPage.find_by(url: new_url), "WebPage should not exist before test"

    assert_difference [ "WebPage.count", "Analysis.count" ], 1 do
      assert_enqueued_jobs 1, only: AnalysisJob do
        post analyses_url, params: { analysis: { url: new_url } }
      end
    end

    created_web_page = WebPage.find_by(url: new_url)
    assert_not_nil created_web_page
    new_analysis = created_web_page.analysis
    assert_not_nil new_analysis

    Harvester.stub(:extract_html_from, "<html><head><title>#{mock_title_for_nav_test}</title></head><body>Mock body for nav</body></html>") do
      HtmlScribe.stub(:extract_data_from, { title: mock_title_for_nav_test, body: "Mock body for nav test", table_of_contents: [] }) do
        Oracle.stub(:process, { title: mock_title_for_nav_test, word_count: 4, table_of_contents: [], top_word_frequencies: { "mock"=>1, "body"=>1 } }) do
          perform_enqueued_jobs
        end
      end
    end

    new_analysis.reload
    assert_equal "completed", new_analysis.status
    assert_equal mock_title_for_nav_test, new_analysis.title

    assert_redirected_to analysis_path(new_analysis)
    follow_redirect!

    assert_response :success
    assert_select "div.completed-state header h1", mock_title_for_nav_test
    assert_select "div.completed-state header p a[href=?]", new_url, text: new_url
  end

  test "submitting a URL, performs analysis, and displays results" do
    new_url = "http://example.com/test-analysis-completion"
    get root_path

    mock_html_content = "<html><head><title>Test Title Complete</title></head><body><p>Hello world. This is a test for display.</p><h1>Main Heading Display</h1><ul><li>Item A</li><li>Item B</li></ul></body></html>"

    mock_extracted_data_for_scribe = {
      title: "Test Title Complete",
      body: "Hello world. This is a test for display. Main Heading Display Item A Item B",
      table_of_contents: [ { text: "Main Heading Display", level: 1, children: [] } ]
    }

    mock_analysis_result_for_oracle = {
      title: "Test Title Complete",
      word_count: 7,
      table_of_contents: [ { "text" => "Main Heading Display", "level" => 1, "children" => [] } ],
      top_word_frequencies: { "hello" => 1, "world" => 1, "this"=>1, "test" => 1, "for"=>1, "display" => 1 }
    }

    Harvester.stub(:extract_html_from, mock_html_content) do
      HtmlScribe.stub(:extract_data_from, mock_extracted_data_for_scribe) do
        Oracle.stub(:process, mock_analysis_result_for_oracle) do
          assert_enqueued_jobs 1, only: AnalysisJob do
            post analyses_url, params: { analysis: { url: new_url } }
          end
          perform_enqueued_jobs
        end
      end
    end

    analysis = Analysis.find_by(web_page: WebPage.find_by(url: new_url))
    assert_not_nil analysis
    analysis.reload

    assert_equal "completed", analysis.status
    assert_equal "Test Title Complete", analysis.title
    assert_equal mock_analysis_result_for_oracle[:word_count], analysis.word_count
    assert_equal mock_analysis_result_for_oracle[:table_of_contents], analysis.table_of_contents
    assert_equal mock_analysis_result_for_oracle[:top_word_frequencies], analysis.top_word_frequencies

    get analysis_path(analysis)
    assert_response :success
    assert_select "div.completed-state header h1", "Test Title Complete"
    assert_select "div.completed-state header p a[href=?]", new_url, text: new_url
    assert_select "div.completed-state section h2", "Total Word Count"
    assert_select "div.completed-state section p", "#{mock_analysis_result_for_oracle[:word_count]} words"
    assert_select "div.completed-state section h2", "Table of Contents"
    assert_select "div.completed-state section ol li", { count: 1, text: "Main Heading Display" }
    assert_select "div.completed-state section h2", "Top 10 Most Frequent Words"
    assert_select "div.completed-state section table tbody tr td", text: "Hello"
    assert_select "div.completed-state section table tbody tr td", text: "1"
    assert_select "div.completed-state section table tbody tr td", text: "Display"
  end

  test "submitting an already analyzed URL redirects to its analysis page without creating new records" do
    existing_url = "http://example.com/already-analyzed-for-integration"
    web_page = WebPage.create!(url: existing_url)
    analysis = web_page.analysis
    analysis.update!(status: :completed, title: "Old Analysis Title")

    get root_path
    assert_response :success

    assert_no_difference [ "WebPage.count", "Analysis.count" ] do
      assert_no_enqueued_jobs do
        post analyses_url, params: { analysis: { url: existing_url } }
      end
    end

    assert_redirected_to analysis_path(analysis)
    follow_redirect!
    assert_response :success
    assert_select "div.completed-state header h1", "Old Analysis Title"
    assert_select "div.completed-state header p a[href=?]", existing_url, text: existing_url
  end

  test "submitting an invalid URL from home page results in unprocessable_content" do
    get root_path
    assert_response :success

    assert_no_difference [ "WebPage.count", "Analysis.count" ] do
      assert_no_enqueued_jobs do
        post analyses_url, params: { analysis: { url: "" } }
      end
    end

    assert_response :unprocessable_content
  end
end
