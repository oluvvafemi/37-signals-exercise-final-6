class WebPagesController < ApplicationController
  def index
    @web_pages = WebPage.most_recently_analyzed
  end
end
