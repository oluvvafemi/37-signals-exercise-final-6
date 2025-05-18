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
    self.status = Analysis.statuses[:fetching]
    save!
    @html = Harvester.extract_html_from(web_page.url)
  end

  def extract_data
    @data = HtmlScribe.extract_data_from(@html)
    puts "Data extracted, #{@data}"
  end

  def process_data
    @result = Oracle.process(@data)
    puts "Result processed, #{@result}"
  end

  def save_result!
    self.status = @result[:status]
    self.word_count = @result[:word_count]
    self.title = @result[:title]
    self.table_of_contents = @result[:table_of_contents]
    self.top_word_frequencies = @result[:top_word_frequencies]
    save!
  end
end
