class AnalysesController < ApplicationController
  before_action :remove_url_fragments_and_query_params, only: %i[create]
  before_action :redirect_if_analyzed, only: %i[create]
  before_action :create_web_page, only: %i[create]
  before_action :set_analysis, except: %i[create]

  def create
    @web_page.initiate_analysis
    redirect_to analysis_path(@web_page.analysis)
  end

  def show
  end

  def update
    @analysis.web_page.initiate_analysis
  end

  private

  def analysis_params
    params.require(:analysis).permit(:url)
  end

  def redirect_if_analyzed
    web_page = WebPage.find_by(url: @url)

    if web_page
      redirect_to analysis_path(web_page.analysis)
    end
  end

  def create_web_page
    @web_page = WebPage.create!(url: @url)
  end

  def remove_url_fragments_and_query_params
    @url = Harvester.clean_url(analysis_params[:url])
  end

  def set_analysis
    @analysis = Analysis.find(params[:id])
  end
end
