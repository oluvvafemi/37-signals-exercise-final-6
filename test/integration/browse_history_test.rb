require "test_helper"

class BrowseHistoryTest < ActionDispatch::IntegrationTest
  setup do
    @page1_url = "http://example.com/analyzed-page-1"
    @page1_title = "Analyzed Page 1 Title"
    web_page1 = WebPage.create!(url: @page1_url)
    @analysis1 = web_page1.analysis
    @analysis1.update!(status: :completed, title: @page1_title, word_count: 100)

    @page2_url = "http://example.com/analyzed-page-2"
    @page2_title = "Analyzed Page 2 Title"
    web_page2 = WebPage.create!(url: @page2_url)
    @analysis2 = web_page2.analysis
    @analysis2.update!(status: :completed, title: @page2_title, word_count: 200)

    pending_web_page = WebPage.create!(url: "http://example.com/pending-page-for-history-test")
    @pending_analysis = pending_web_page.analysis
  end

  test "should list recently analyzed pages on the root path and allow navigation" do
    get root_url
    assert_response :success

    assert_select "main section ul li a[href=?]", analysis_path(@analysis1), text: @page1_title
    assert_select "main section ul li a[href=?]", analysis_path(@analysis2), text: @page2_title

    get analysis_path(@analysis1)
    assert_response :success
    assert_select "div.completed-state header h1", @page1_title
    assert_select "div.completed-state header p a[href=?]", @page1_url, text: @page1_url
  end

  test "should not list pages with pending analysis on the root path" do
    get root_url
    assert_response :success

    assert_select "main section ul li a[href=?]", analysis_path(@pending_analysis), count: 0
  end

  test "should show a message if no pages have been analyzed" do
    Analysis.delete_all
    WebPage.delete_all

    get root_url
    assert_response :success
    assert_select "main section p", text: "No analyzed web pages yet."
    assert_select "main section ul li", count: 0
  end
end
