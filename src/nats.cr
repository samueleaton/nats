require "uri"
require "json"
require "socket"
require "uuid"
require "openssl"
require "log"

require "./ext"
require "./error"
require "./nuid"
require "./nkeys"
require "./client"

# NATS is a pub/sub message bus.
#
# ```
# require "nats"
#
# # Connect to a NATS server running on localhost
# nats = NATS::Client.new
#
# # Connect to a single remote NATS server
# nats = NATS::Client.new(URI.parse(ENV["NATS_URL"]))
#
# # Connect to a NATS cluster, specified by the NATS_URLS environment variable
# # as a comma-separated list of URLs
# servers = ENV["NATS_URLS"]
#   .split(',')
#   .map { |url| URI.parse(url) }
# nats = NATS::Client.new(servers: %w[
#   nats://nats-1
#   nats://nats-2
#   nats://nats-3
# ])
# ```
module NATS
  VERSION = "1.1.0"

  alias Payload = String | Bytes

  struct ServerInfo
    include JSON::Serializable

    getter server_id : String
    getter server_name : String
    getter version : String
    getter proto : Int32
    getter host : String
    getter port : Int32
    getter? headers : Bool = false
    getter? tls_required : Bool = false
    getter max_payload : Int32
    getter client_id : Int32
    getter client_ip : String
    getter? auth_required : Bool = false
    getter nonce : String?
    getter cluster : String?
    getter connect_urls : Array(String) = [] of String
  end

  LOG = ::Log.for(self)

  struct Message
    # See the Crystal [HTTP::Headers API](https://crystal-lang.org/api/latest/HTTP/Headers.html)
    alias Headers = HTTP::Headers

    getter subject : String
    # Returns the raw byte payload
    getter raw_data : Bytes
    # Returns the string representation of `raw_data`
    getter data : String { String.new raw_data }
    getter reply_to : String?
    # Returns the parsed headers data
    getter headers : Headers { HTTP::Headers.new }

    def initialize(@subject, data : String | Bytes, @reply_to = nil, headers : Client::Headers? = nil)
      case data
      in Bytes
        @raw_data = data
      in String
        @raw_data = data.to_slice
        @data = data
      end

      case headers
      when Headers
        @headers = headers
      when Hash
        @headers = http_headers_from_hash headers
      end
    end

    @[Deprecated("Instantiating a new IO::Memory for each message made them heavier than intended, so we're now recommending using `String.new(msg.raw_data)`")]
    def body_io
      @body_io ||= IO::Memory.new(@body)
    end

    @[Deprecated("`body` deprecated in favor of `data` or `raw_data` to conform with NATS protocol nomenclature")]
    def body : Bytes
      @raw_data
    end

    private def http_headers_from_hash(hash : Hash(String, Array(String) | String))
      hash.reduce(HTTP::Headers.new) { |hdrs, kv| hdrs.add kv[0], kv[1] }
    end
  end
end
