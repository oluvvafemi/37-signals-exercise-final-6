class MockupsController < ApplicationController
  def index
  end

  def show
    render template: "mockups/#{params[:id]}"
  rescue ActionView::MissingTemplate
    render plain: "Mockup not found", status: :not_found
  end
end
