require "test_helper"

class HtmlScribeTest < ActiveSupport::TestCase
  test ".extract_data_from returns correct data for basic HTML" do
    html = <<-HTML
      <html>
        <head><title>Test Title</title></head>
        <body>
          <h1>Main Heading</h1>
          <p>Some body text. With more content.</p>
          <h2>Sub Heading</h2>
          <article>
            <p>Article content</p>
            <h3>Article Sub Heading H3</h3>
          </article>
          <script>console.log('noise');</script>
        </body>
      </html>
    HTML

    data = HtmlScribe.extract_data_from(html)

    assert_equal "Test Title", data[:title]
    expected_page_content = "Article content\nArticle Sub Heading H3"
    assert_equal expected_page_content, data[:page_content]
    assert_equal [], data[:table_of_contents]
  end

  test ".extract_data_from extracts title and identified headings for TOC" do
    html = <<-HTML
      <html>
        <head><title>Complex Page</title></head>
        <body>
          <h2 id='intro'>Introduction</h2>
          <p>Text here.</p>
          <h3 id='details'>Details</h3>
          <h4>No ID H4</h4>
          <h2 id='conclusion'>Conclusion</h2>
            <h3 id='summary'>Summary</h3>
        </body>
      </html>
    HTML
    data = HtmlScribe.extract_data_from(html)

    assert_equal "Complex Page", data[:title]
    expected_page_content = "Introduction\nText here.\nDetails\nNo ID H4\nConclusion\nSummary"
    assert_equal expected_page_content, data[:page_content]

    expected_toc = [
      { text: "Introduction", level: 2, children: [
        { text: "Details", level: 3, children: [] }
      ] },
      { text: "Conclusion", level: 2, children: [
        { text: "Summary", level: 3, children: [] }
      ] }
    ]
    assert_equal expected_toc, data[:table_of_contents]
  end

  test ".extract_data_from handles HTML with an explicit TOC (e.g., #toc ul li a)" do
    html = <<-HTML
      <html>
        <head><title>Explicit TOC Test</title></head>
        <body>
          <div id="toc">
            <ul>
              <li><a href="#section1">Section 1</a>
                <ul>
                  <li><a href="#subsection1.1">Subsection 1.1</a></li>
                </ul>
              </li>
              <li><a href="#section2">Section 2</a></li>
            </ul>
          </div>
          <h2 id="section1">Actual Section 1</h2>
          <h3 id="subsection1.1">Actual Subsection 1.1</h3>
          <h2 id="section2">Actual Section 2</h2>
        </body>
      </html>
    HTML
    data = HtmlScribe.extract_data_from(html)
    expected_page_content = "Actual Section 1\nActual Subsection 1.1\nActual Section 2"
    assert_equal expected_page_content, data[:page_content]

    expected_toc = [
      { text: "Section 1", level: 1, children: [
        { text: "Subsection 1.1", level: 2, children: [] }
      ] },
      { text: "Section 2", level: 1, children: [] }
    ]
    assert_equal expected_toc, data[:table_of_contents]
  end

  test ".extract_data_from returns 'Untitled Document' if no title tag" do
    html = "<html><body><p>No title here.</p></body></html>"
    data = HtmlScribe.extract_data_from(html)
    assert_equal "Untitled Document", data[:title]
    assert_equal "No title here.", data[:page_content]
  end

  test ".extract_data_from handles empty body for text extraction gracefully" do
    html = "<html><head><title>Empty Body</title></head><body><script>var x=1;</script><!-- comment --></body></html>"
    data = HtmlScribe.extract_data_from(html)
    assert_equal "Empty Body", data[:title]
    assert_equal "", data[:page_content]
  end

  test ".extract_data_from scrubs noise elements like script, style, nav, footer, etc." do
    html = <<-HTML
      <html><head><title>Scrub Test</title></head>
        <body>
          <header>Site Header</header>
          <nav>Navigation Menu</nav>
          <main>
            <p>Visible content.</p>
            <script>alert('hello');</script>
            <style>.hide { display:none; }</style>
            <p>More visible content.</p>
          </main>
          <footer>Site Footer</footer>
          <aside>Sidebar</aside>
        </body>
      </html>
    HTML
    data = HtmlScribe.extract_data_from(html)
    assert_equal "Visible content.\nMore visible content.", data[:page_content]
  end

  test ".extract_data_from raises ParseError for nil or empty HTML string" do
    assert_raises HtmlScribe::ParseError do
      HtmlScribe.extract_data_from(nil)
    end
    assert_raises HtmlScribe::ParseError do
      HtmlScribe.extract_data_from("   ")
    end
  end
end
