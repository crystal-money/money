require "uri"
require "uri/params"
require "http/headers"
require "http/client"

class Money::Currency
  # Module containing common HTTP methods used by currency rate providers.
  module RateProvider::HTTP
    # Returns the host URI used by the HTTP `#client` instance.
    abstract def host : URI

    # Returns a new `HTTP::Client` instance.
    protected def client : ::HTTP::Client
      ::HTTP::Client.new(host)
    end

    # Makes a HTTP request to the specified *path* and yields the response.
    protected def request(
      method : String,
      path : String,
      params : Hash | NamedTuple? = nil,
      headers : ::HTTP::Headers? = nil,
      body = nil, &
    )
      path += "?#{URI::Params.encode(params)}" if params

      client.exec(method, path, headers, body) do |response|
        unless response.success?
          raise RateProviderRequestError.new(response.status)
        end
        yield response
      end
    end

    # Makes a `GET` request to the specified *path* and yields the response.
    protected def request(
      path : String,
      params : Hash | NamedTuple? = nil,
      headers : ::HTTP::Headers? = nil, &
    )
      request("GET", path, params, headers) do |response|
        yield response
      end
    end
  end
end
