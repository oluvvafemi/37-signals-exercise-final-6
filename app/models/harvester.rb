require "open-uri"
require "uri"

class Harvester
  class << self
    def extract_html_from(url)
      fetch_content(url)
    rescue *MONITORED_EXCEPTIONS => e
      classify_and_raise_error(e, url)
    rescue StandardError => e
      classify_and_raise_error(e, url)
    end

    private

    def fetch_content(url)
      params = {
        open_timeout: DEFAULT_TIMEOUT,
        read_timeout: DEFAULT_TIMEOUT,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
      }
      URI.open(url, params).read
    end

    def classify_and_raise_error(error, url)
      original_error_info = "Original: #{error.class} - #{error.message}"

      case error
      when OpenURI::HTTPError
        status_code = nil
        if error.io && error.io.respond_to?(:status) && error.io.status && error.io.status[0]
          status_code = error.io.status[0].to_i
        end
        if status_code && RETRYABLE_HTTP_CODES.include?(status_code)
          raise RetryableError, "Retryable HTTP Error #{status_code} while fetching content from '#{url}'"
        else
          raise FatalError, "Non-retryable HTTP Error #{status_code || 'Unknown'} while fetching content from '#{url}'"
        end

      when Timeout::Error, Errno::ETIMEDOUT
        raise RetryableError, "Timeout error while fetching content from '#{url}'"

      when SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError
        raise RetryableError, "Network/SSL error while fetching content from '#{url}'"

      else
        raise FatalError, "Error while fetching content from '#{url}'"
      end
    end
  end

  DEFAULT_TIMEOUT = 10
  RETRYABLE_HTTP_CODES = [ 408, 429, 500, 502, 503, 504 ].freeze

  MONITORED_EXCEPTIONS = [
    OpenURI::HTTPError,
    Timeout::Error, Errno::ETIMEDOUT,
    SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET,
    Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError
  ].freeze

  class RetryableError < StandardError; end
  class FatalError < StandardError; end
end
