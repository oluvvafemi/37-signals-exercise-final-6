class Oracle
  class << self
    def process(data)
      compute_results(data)
    end

    private

    def compute_results(data)
      words = extract_words(data[:body])
      {
        word_count: compute_word_count(words),
        title: data[:title],
        table_of_contents: data[:table_of_contents],
        top_word_frequencies: compute_top_word_frequencies(words)
      }
    end

    def extract_words(body)
      return [] if body.nil? || body.strip.empty?
      body.downcase.scan(/\w+/)
    end

    def compute_word_count(words)
      words.length
    end

    def compute_top_word_frequencies(words)
      frequencies = words.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
      sorted_frequencies = frequencies.sort_by { |_, count| -count }
      Hash[sorted_frequencies.first(10)]
    end
  end
end
