require "nokogiri"

class HtmlScribe
  class << self
    def extract_data_from(html_string)
      ensure_html_presence(html_string)
      doc = parse_html(html_string)
      package_data(doc)
    end

    private

    def parse_html(html_string)
      Nokogiri::HTML(html_string)
    end

    def package_data(doc)
      {
        title: extract_title(doc),
        table_of_contents: extract_table_of_contents(doc),
        body: extract_body(doc)
      }
    end

    def ensure_html_presence(html_string)
      raise "Empty HTML" if html_string.nil? || html_string.strip.empty?
    end

    def extract_title(doc)
      doc.at_css("title")&.text&.strip.presence ||
      "Untitled Document"
    end

    def extract_table_of_contents(doc)
      toc = try_extracting_explicit_toc(doc)
      return toc if toc.any?

      extract_toc_from_headings(doc)
    end

    def extract_body(doc)
      body_text_content = ""
      body_clone = doc.at_css("body")&.dup

      if body_clone
        body_clone.css("script, style").remove
        raw_text = body_clone.text

        if raw_text && !raw_text.empty?
          body_text_content = raw_text.gsub(/[ \t\r\f]+/, " ")
                                    .gsub(/\n\s*\n+/, "\n\n")
                                    .lines.map(&:strip).reject(&:empty?).join("\n")
        end
      end
      body_text_content
    end

    def try_extracting_explicit_toc(doc)
      explicit_toc_container_selectors = [
        "#toc", ".toc",
        "#table-of-contents", ".table-of-contents"
      ]

      explicit_toc_container_selectors.each do |selector|
        container = doc.at_css(selector)
        next unless container

        list_element = container.at_css("> ul, > ol") || container.at_css("ul, ol")
        next unless list_element

        toc_nodes = parse_toc_list_items_hierarchically(list_element, 1)
        return toc_nodes if toc_nodes.any?
      end
      []
    end

    def parse_toc_list_items_hierarchically(list_element, current_level)
      nodes = []
      list_element.xpath("./li").each do |li_element|
        main_link = li_element.at_xpath("./a")
        item_text = main_link&.text&.strip

        if item_text.nil? || item_text.empty?
          temp_li_for_text = li_element.dup
          temp_li_for_text.xpath("./ul | ./ol").remove
          item_text = temp_li_for_text.text&.strip
        end

        next if item_text.nil? || item_text.empty?

        node = { text: item_text, level: current_level, children: [] }

        nested_list_element = li_element.at_xpath("./ul | ./ol")
        if nested_list_element
          node[:children] = parse_toc_list_items_hierarchically(nested_list_element, current_level + 1)
        end
        nodes << node
      end
      nodes
    end

    def extract_toc_from_headings(doc)
      root_nodes = []
      parent_stack = []

      doc.css("h2, h3, h4").each do |heading_element|
        level = heading_element.name[1].to_i
        text = heading_element.text&.strip
        next if text.nil? || text.empty?

        current_node = { text: text, level: level, children: [] }

        while !parent_stack.empty? && parent_stack.last[:level] >= current_node[:level]
          parent_stack.pop
        end

        if parent_stack.empty?
          root_nodes << current_node
        else
          parent_stack.last[:children] << current_node
        end

        parent_stack << current_node
      end
      root_nodes
    end
  end
end
