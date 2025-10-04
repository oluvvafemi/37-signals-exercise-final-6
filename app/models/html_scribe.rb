require "nokogiri"

class HtmlScribe
  class << self
    def extract_data_from(html_string)
      ensure_html_presence(html_string)
      doc = parse_html(html_string)
      package_data(doc)
    rescue StandardError => e
      Rails.logger.error("Error while parsing HTML: #{e.message}")
      raise ParseError, "Error while parsing HTML"
    end

    private

    def parse_html(html_string)
      Nokogiri::HTML(html_string)
    end

    def package_data(doc)
      {
        title: extract_title(doc),
        table_of_contents: extract_table_of_contents(doc),
        page_content: extract_page_content(doc)
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
      try_extracting_explicit_toc(doc).presence || extract_toc_from_headings(doc)
    end

    def extract_page_content(doc)
      root = get_content_root(doc)
      return "" unless root

      root = root.dup
      remove_non_content_elements!(root)
      replace_br_with_newlines!(root)
      normalize_whitespace(root.inner_text)
    end

    def try_extracting_explicit_toc(doc)
      toc_container_candidates = find_toc_container_candidates(doc)

      extract_toc_from(toc_container_candidates)
    end

    def extract_toc_from_headings(doc)
      root = get_content_root(doc)
      root_nodes = []
      parent_stack = []

      heading_selector = HEADING_LEVELS_FOR_TOC.map { |l| "h#{l}[id]" }.join(",")

      root.css(heading_selector).each do |heading_element|
        level = heading_element.name[1].to_i
        text = heading_element.text&.strip
        text&.gsub(/^\d+(((\.\d+)+)\.?|\.)\s*/, "")
        next if text.nil? || text.empty?

        node = { text: text, level: level, children: [] }
        parent_stack.pop while parent_stack.any? && parent_stack.last[:level] >= level
        (parent_stack.empty? ? root_nodes : parent_stack.last[:children]) << node
        parent_stack << node
      end
      root_nodes
    end

    def select_css_safely(node, selector)
      node.css(selector)
    rescue Nokogiri::CSS::SyntaxError
      []
    end

    def get_content_root(doc)
      doc.at_css("main")             ||
      doc.at_css("article")          ||
      doc.at_css('[role="main"]')    ||
      doc.at_css("body")             ||
      doc
    end

    def remove_non_content_elements!(node)
      node.css(NOISE_SELECTORS.join(",")).each(&:remove)
    end

    def find_toc_container_candidates(doc)
      select_css_safely(doc, TOC_CONTAINER_SELECTORS.join(","))
    end

    def extract_toc_from(container_candidates)
      container_candidates.each do |container|
        next unless all_links_are_fragments?(container)

        list_element = get_list_from(container)
        next unless list_element

        toc_nodes = parse_toc_list_items_hierarchically(list_element, 1)
        return toc_nodes if toc_nodes.any?
      end
      []
    end

    def parse_toc_list_items_hierarchically(list_element, current_level)
      list_items = get_list_items_from(list_element)
      build_toc_nodes(list_items, current_level)
    end

    def build_toc_nodes(list_items, current_level)
      nodes = []
      list_items.each do |li_item|
        item_text = get_text_from(li_item)
        next if item_text.nil? || item_text.empty?

        node = { text: item_text, level: current_level, children: [] }
        nested_list_element = extract_nested_list_from(li_item)

        if nested_list_element
          node[:children] = parse_toc_list_items_hierarchically(nested_list_element, current_level + 1)
        end
        nodes << node
      end
      nodes
    end

    def all_links_are_fragments?(container)
      links = container.css("a")
      links.any? && links.all? { |a| a["href"].to_s.start_with?("#") }
    end

    def get_list_from(element)
      element.at_xpath("./ul | ./ol") || element.at_xpath(".//ul | .//ol")
    end

    def get_list_items_from(list_element)
      list_element.xpath("./li") || list_element.xpath(".//li")
    end

    def get_text_from(list_item)
      extract_text_from_link_in(list_item) ||
      extract_text_of(list_item)
    end

    def extract_text_from_link_in(list_item)
      link = list_item.at_xpath("./a")
      text = link&.text&.strip
      text&.gsub(/^\d+(((\.\d+)+)\.?|\.)\s*/, "")
    end

    def extract_text_of(list_item)
      temp_li_for_text = li_item.dup
      temp_li_for_text.xpath("./ul | ./ol").remove
      text = temp_li_for_text.text&.strip
      text&.gsub(/^\d+(((\.\d+)+)\.?|\.)\s*/, "")
    end

    def extract_nested_list_from(list_item)
      get_list_from(list_item)
    end

    def replace_br_with_newlines!(node)
      node.css("br").each { |br| br.replace("\n") }
    end

    def normalize_whitespace(str)
      str.gsub(/[ \t\r\f]+/, " ")
         .gsub(/\n\s*\n+/, "\n\n")
         .lines.map(&:strip)
         .reject(&:empty?)
         .join("\n")
    end
  end

  TOC_CONTAINER_SELECTORS = %w[
    #toc .toc
    #table-of-contents .table-of-contents
    nav[role="doc-toc"] nav[aria-label="Table of contents"]
    aside.toc
  ].freeze

  HEADING_LEVELS_FOR_TOC = (2..6).freeze

  NOISE_SELECTORS = %w[
    script style noscript iframe
    header footer nav aside form
    #toc .toc #table-of-contents .table-of-contents
    [hidden]
    [style*="display:none"]
    [style*="visibility:hidden"]
  ].freeze

  class ParseError < KnownDomainError; end
end
