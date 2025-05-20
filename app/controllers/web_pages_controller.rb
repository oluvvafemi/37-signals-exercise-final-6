class WebPagesController < ApplicationController
  def index
    @web_pages = WebPage.with_recently_completed_analysis
  end
end
