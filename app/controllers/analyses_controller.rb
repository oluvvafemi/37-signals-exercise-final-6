class AnalysesController < ApplicationController
  before_action :redirect_if_analyzed, only: %i[create]
  before_action :set_web_page, only: %i[create]

  def create
    analysis = @web_page.initiate_analysis
    redirect_to analysis_path(analysis)
  end

  def show
    @analysis = Analysis.find(params[:id])
  end

  private

  def analysis_params
    params.require(:analysis).permit(:url)
  end

  def redirect_if_analyzed
    web_page = WebPage.find_by(url: analysis_params[:url])

    if web_page
      latest_analysis = web_page.analyses.order(created_at: :desc).first!
      redirect_to analysis_path(latest_analysis)
    end
  end

  def set_web_page
    @web_page = WebPage.create!(url: analysis_params[:url])
  end
end
