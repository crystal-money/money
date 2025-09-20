struct Money
  module Exchange
    # Exchanges `self` to a new `Money` object in *other_currency*.
    #
    # ```
    # Money.default_exchange.rate_store["USD", "EUR"] = 1.23
    # Money.default_exchange.rate_store["EUR", "USD"] = 0.82
    #
    # Money.new(1_00, "USD").exchange_to("EUR") # => Money(@amount=1.23, @currency="EUR")
    # Money.new(1_00, "EUR").exchange_to("USD") # => Money(@amount=0.82, @currency="USD")
    # ```
    def exchange_to(other_currency : String | Symbol | Currency, exchange = Money.default_exchange) : Money
      other_currency = Currency[other_currency]
      case
      when other_currency == currency
        self
      when zero?
        with_currency(other_currency)
      else
        exchange.exchange(self, other_currency)
      end
    end

    # Yields *other* `Money` object exchanged to `self.currency`.
    def with_same_currency(other : Money, &)
      yield other.exchange_to(currency)
    end
  end
end
