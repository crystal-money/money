class Money::Currency
  # Raised when trying to find an unknown currency.
  class NotFoundError < Error
    def initialize(key)
      super("Unknown currency: #{key}")
    end
  end
end
