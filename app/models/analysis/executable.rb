module Analysis::Executable
  extend ActiveSupport::Concern

  def run
    extract_html
    extract_data
    process_data
    save_result!
  end

  private

  def extract_html
    update_analysis_status(:fetching)
    @html = Harvester.extract_html_from(web_page.url)
  end

  def extract_data
    update_analysis_status(:parsing)
    @data = HtmlScribe.extract_data_from(@html)
  end

  def process_data
    update_analysis_status(:analyzing)
    @result = Oracle.process(@data)
  end

  def save_result!
    self.status = :completed
    self.word_count = @result[:word_count]
    self.title = @result[:title]
    self.table_of_contents = @result[:table_of_contents]
    self.top_word_frequencies = @result[:top_word_frequencies]
    save!
  end

  def update_analysis_status(status)
    self.status = status
    save!
  end
end
