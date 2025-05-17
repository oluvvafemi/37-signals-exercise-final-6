class Oracle
  def self.process(data)
    {
      status: "success",
      word_count: 42,
      title: "Oracle's Processed Title",
      table_of_contents: [ "Dummy Section A", "Dummy Section B" ],
      top_word_frequencies: { "the" => 10, "dummy" => 5, "data" => 3 }
    }
  end
end
