require "open-uri"
require "uri"
require "ipaddr"
require "resolv"

class Harvester
  class << self
    def extract_html_from(url)
      ensure_safe_url(url)
      fetch_content(url)
    rescue *MONITORED_EXCEPTIONS => e
      classify_and_raise_error(e, url)
    rescue StandardError => e
      classify_and_raise_error(e, url)
    end

    def clean_url(raw_url)
      uri = URI.parse(raw_url)
      uri.fragment = nil
      uri.query = nil
      uri.to_s
    end

    private

    def ensure_safe_url(url)
      uri = URI.parse(url)

      ip = Resolv.getaddress(uri.hostname)
      ip_addr = IPAddr.new(ip)

      raise UnsafeURLError, "URL is not safe: #{uri.host}" if ip_addr.loopback? || ip_addr.private?
    end

    def fetch_content(url)
      params = {
        open_timeout: DEFAULT_TIMEOUT,
        read_timeout: DEFAULT_TIMEOUT,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
      }
      URI.open(url, params).read
    end

    def classify_and_raise_error(error, url)
      case error
      when OpenURI::HTTPError
        status_code = nil
        if error.io && error.io.respond_to?(:status) && error.io.status && error.io.status[0]
          status_code = error.io.status[0].to_i
        end
        if status_code && RETRYABLE_HTTP_CODES.include?(status_code)
          Rails.logger.info("RetryableError: Retryable HTTP Error #{status_code} while fetching content from '#{url}'")
          raise RetryableError, "Retryable HTTP Error #{status_code} while fetching content from '#{url}'"
        else
          Rails.logger.info("FatalError: Non-retryable HTTP Error #{status_code || 'Unknown'} while fetching content from '#{url}'")
          raise FatalError, "Non-retryable HTTP Error #{status_code || 'Unknown'} while fetching content from '#{url}'"
        end

      when Timeout::Error, Errno::ETIMEDOUT
        Rails.logger.info("RetryableError: Timeout error while fetching content from '#{url}'")
        raise RetryableError, "Timeout error while fetching content from '#{url}'"

      when SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError
        Rails.logger.info("RetryableError: Network/SSL error while fetching content from '#{url}'")
        raise RetryableError, "Network/SSL error while fetching content from '#{url}'"

      when URI::InvalidURIError
        Rails.logger.info("FatalError: Invalid URL #{url}")
        raise FatalError, "Invalid URL #{url}"

      when Resolv::ResolvError
        Rails.logger.info("FatalError: DNS resolution error for #{url}")
        raise FatalError, "DNS resolution error for #{url}"

      when UnsafeURLError
        Rails.logger.info("FatalError: Unsafe URL #{url}")
        raise FatalError, "Unsafe URL #{url}"

      else
        Rails.logger.info("FatalError: Unknown error while fetching content from '#{url}'")
        raise FatalError, "Unknown error while fetching content from '#{url}'"
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

  class RetryableError < KnownDomainError; end
  class FatalError < KnownDomainError; end
  class UnsafeURLError < KnownDomainError; end
end
