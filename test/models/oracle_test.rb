require "test_helper"

class OracleTest < ActiveSupport::TestCase
  test ".process calculates total word count and top frequencies correctly" do
    data_from_scribe = {
      title: "Test Document Title",
      page_content: "This is a test. A simple test with several test words. Hello world.",
      table_of_contents: [ { text: "Chapter 1", level: 1, children: [] } ]
    }

    result = Oracle.process(data_from_scribe)

    assert_equal "Test Document Title", result[:title]
    assert_equal [ { text: "Chapter 1", level: 1, children: [] } ], result[:table_of_contents]
    assert_equal 13, result[:word_count]

    expected_frequencies = {
      "test" => 3,
      "simple" => 1,
      "several" => 1,
      "words" => 1,
      "hello" => 1,
      "world" => 1
    }.sort_by { |_k, v| -v }.to_h
    assert_equal expected_frequencies, result[:top_word_frequencies]
  end

  test ".process handles empty page_content" do
    data_from_scribe = {
      title: "Empty Content Doc",
      page_content: "",
      table_of_contents: []
    }
    result = Oracle.process(data_from_scribe)

    assert_equal "Empty Content Doc", result[:title]
    assert_equal [], result[:table_of_contents]
    assert_equal 0, result[:word_count]
    assert_equal({}, result[:top_word_frequencies])
  end

  test ".process handles page_content with only stop words" do
    data_from_scribe = {
      title: "Stop Words Only",
      page_content: "is a the of and",
      table_of_contents: []
    }
    result = Oracle.process(data_from_scribe)

    assert_equal "Stop Words Only", result[:title]
    assert_equal 5, result[:word_count]
    assert_equal({}, result[:top_word_frequencies])
  end

  test ".process correctly limits top_word_frequencies" do
    unique_alpha_words = ("aa".."ap").to_a.first(15)
    page_content_text = unique_alpha_words.join(" ")

    data_from_scribe = {
      title: "Top 10 Test",
      page_content: page_content_text,
      table_of_contents: []
    }
    result = Oracle.process(data_from_scribe)

    assert_equal 15, result[:word_count]
    assert_equal 10, result[:top_word_frequencies].size
    assert result[:top_word_frequencies].values.all? { |count| count == 1 }
    result[:top_word_frequencies].keys.each do |word|
      assert_includes unique_alpha_words, word
    end
  end

  test ".process handles words with mixed casing and punctuation" do
    data_from_scribe = {
      title: "Mixed Case Punctuation",
      page_content: "Hello! World. hello, again... WoRlD? test-word; test_word",
      table_of_contents: []
    }
    result = Oracle.process(data_from_scribe)

    assert_equal 7, result[:word_count]

    expected_frequencies = {
      "hello" => 2,
      "world" => 2,
      "test" => 2,
      "word" => 2,
      "again" => 1
    }.sort_by { |_k, v| -v }.to_h
    assert_equal expected_frequencies, result[:top_word_frequencies]
  end
end
