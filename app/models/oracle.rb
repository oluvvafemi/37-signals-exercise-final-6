class Oracle
  class << self
    def process(data)
      compute_results(data)
    rescue StandardError => e
      Rails.logger.error("Error while analyzing page data: #{e.message}")
      raise AnalysisError, "Error while analyzing page data"
    end

    private

    def compute_results(data)
      raw_words_list = extract_raw_words(data[:page_content])
      significant_words_list = extract_significant_words(data[:page_content])

      {
        word_count: compute_raw_word_count(raw_words_list),
        title: data[:title],
        table_of_contents: data[:table_of_contents],
        top_word_frequencies: compute_top_word_frequencies(significant_words_list)
      }
    end

    def extract_raw_words(page_content)
      return [] if page_content.nil? || page_content.strip.empty?
      page_content.split(/\s+/).reject(&:empty?)
    end

    def compute_raw_word_count(raw_words)
      raw_words.length
    end

    def extract_significant_words(page_content)
      return [] if page_content.nil? || page_content.strip.empty?
      page_content.downcase.scan(WORD_RE).reject { |word| STOP_WORDS.include?(word) }
    end

    def compute_top_word_frequencies(significant_words)
      word_counts = Hash.new(0)
      significant_words.each do |word|
        word_counts[word] += 1
      end

      sorted_word_count_pairs = word_counts.sort_by { |_word, count| -count }
      top_10_pairs = sorted_word_count_pairs.first(10)
      top_10_pairs.to_h
    end
  end

  STOP_WORDS = Set.new(%w[
    a an and are as at be but by for from had has have he her hers him his i if in is
    it its of on or that the their them they this to was were will with you your
  ]).freeze

  WORD_RE = /[[:alpha:]]{2,}/u

  class AnalysisError < StandardError; end
end
