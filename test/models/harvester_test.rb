require "test_helper"
require "minitest/mock"

class HarvesterTest < ActiveSupport::TestCase
  test ".clean_url should remove fragment and query parameters" do
    assert_equal "http://example.com/path", Harvester.clean_url("http://example.com/path?query=123#fragment")
    assert_equal "https://my.example.com/deep", Harvester.clean_url("https://my.example.com/deep?a=b&c=d#section-2")
    assert_equal "http://example.com/path", Harvester.clean_url("http://example.com/path#fragment-only")
    assert_equal "http://example.com/path", Harvester.clean_url("http://example.com/path?query=only")
  end

  test ".clean_url should return an already clean URL as is" do
    assert_equal "http://example.com/path", Harvester.clean_url("http://example.com/path")
  end

  test ".extract_html_from successfully fetches content for a valid and safe URL" do
    safe_url = "http://public-example.com/page1"
    expected_html = "<html><body><h1>Hello</h1></body></html>"

    Resolv.stub(:getaddress, "8.8.8.8") do
      mock_io = StringIO.new(expected_html)
      URI.stub(:open, mock_io) do
        html_content = Harvester.extract_html_from(safe_url)
        assert_equal expected_html, html_content
      end
    end
  end

  test ".extract_html_from raises FatalError for an unsafe (loopback) URL" do
    unsafe_url = "http://localhost/secret-page"

    Resolv.stub(:getaddress, "127.0.0.1") do
      assert_raises Harvester::FatalError do
        Harvester.extract_html_from(unsafe_url)
      end
    end
  end

  test ".extract_html_from raises FatalError for an unsafe (private) URL" do
    unsafe_url = "http://192.168.1.100/router-admin"

    Resolv.stub(:getaddress, "192.168.1.100") do
      assert_raises Harvester::FatalError do
        Harvester.extract_html_from(unsafe_url)
      end
    end
  end

  test ".extract_html_from raises FatalError for HTTP 404 Not Found" do
    url = "http://public-example.com/nonexistent"

    mock_io_404 = StringIO.new("Error page")
    def mock_io_404.status; [ "404", "Not Found" ]; end
    http_error = OpenURI::HTTPError.new("404 Not Found", mock_io_404)

    Resolv.stub(:getaddress, "8.8.8.8") do
      URI.stub(:open, ->(_url, _options) { raise http_error }) do
        assert_raises Harvester::FatalError do
          Harvester.extract_html_from(url)
        end
      end
    end
  end

  test ".extract_html_from raises RetryableError for HTTP 503 Service Unavailable" do
    url = "http://public-example.com/temp-down"

    mock_io_503 = StringIO.new("Server down")
    def mock_io_503.status; [ "503", "Service Unavailable" ]; end
    http_error = OpenURI::HTTPError.new("503 Service Unavailable", mock_io_503)

    Resolv.stub(:getaddress, "8.8.8.8") do
      URI.stub(:open, ->(_url, _options) { raise http_error }) do
        assert_raises Harvester::RetryableError do
          Harvester.extract_html_from(url)
        end
      end
    end
  end

  test ".extract_html_from raises RetryableError for Timeout::Error" do
    url = "http://public-example.com/slow-page"
    Resolv.stub(:getaddress, "8.8.8.8") do
      URI.stub(:open, ->(_url, _options) { raise Timeout::Error }) do
        assert_raises Harvester::RetryableError do
          Harvester.extract_html_from(url)
        end
      end
    end
  end

  test ".extract_html_from raises FatalError for URI::InvalidURIError" do
    assert_raises Harvester::FatalError do
      URI.stub(:parse, ->(_url) { raise URI::InvalidURIError }) do
        Harvester.extract_html_from("http://[]")
      end
    end
  end
end
