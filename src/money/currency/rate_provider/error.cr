class Money::Currency
  abstract class RateProvider
    # Base class for errors raised by rate providers.
    class Error < Money::Error
    end

    # Raised when a rate provider is missing a required option.
    class RequiredOptionError < Error
    end

    # Raised when a request to a rate provider fails.
    class RequestError < Error
      def initialize(status)
        super("Request failed with status: #{status}")
      end
    end

    # Raised when a rate provider returns an error.
    class ResponseError < Error
      def initialize(code, detail = nil)
        if detail = detail.try(&.to_s.presence)
          super("Rate provider error (#{code}): #{detail}")
        else
          super("Rate provider error (#{code})")
        end
      end
    end
  end
end
