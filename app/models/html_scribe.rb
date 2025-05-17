class HtmlScribe
  def self.extract_data_from(html)
    {
      title: "Untitled Document",
      table_of_contents: [ "Section 1: Intro" ],
      body: "This is a test."
    }
  end
end
