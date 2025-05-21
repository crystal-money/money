class Money::Currency
  abstract class RateStore
    include Enumerable(Rate)

    # Wraps block execution in a concurrency-safe transaction.
    abstract def transaction(& : -> _)

    # See also `#[]=`.
    protected abstract def set_rate(rate : Rate) : Nil

    # Registers a conversion rate.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store["USD", "CAD"] = 1.24515
    # store["CAD", "USD"] = 0.803115
    # ```
    def []=(from : String | Symbol | Currency, to : String | Symbol | Currency, value : Number) : Nil
      from, to =
        Currency.wrap(from), Currency.wrap(to)

      transaction do
        set_rate(Rate.new(from, to, value.to_big_d))
      end
    end

    # Registers a conversion rate.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store << Rate.new(
    #   Money::Currency.find("USD"),
    #   Money::Currency.find("CAD"),
    #   1.24515.to_big_d
    # )
    # store << Rate.new(
    #   Money::Currency.find("CAD"),
    #   Money::Currency.find("USD"),
    #   0.803115.to_big_d
    # )
    # ```
    def <<(rate : Rate) : self
      transaction do
        set_rate(rate)
      end
      self
    end

    # Registers multiple conversion rates.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store << [
    #   Rate.new(
    #     Money::Currency.find("USD"),
    #     Money::Currency.find("CAD"),
    #     1.24515.to_big_d
    #   ),
    #   Rate.new(
    #     Money::Currency.find("CAD"),
    #     Money::Currency.find("USD"),
    #     0.803115.to_big_d
    #   ),
    # ]
    # ```
    def <<(rates : Enumerable(Rate)) : self
      transaction do
        rates.each do |rate|
          set_rate(rate)
        end
      end
      self
    end

    # See also `#[]?`.
    protected abstract def get_rate?(from : Currency, to : Currency) : Rate?

    # Retrieves the rate for the given currency pair or `nil` if not found.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store["USD", "CAD"] = 1.24515
    #
    # store["USD", "CAD"]? # => 1.24515
    # store["CAD", "USD"]? # => nil
    # ```
    def []?(from : String | Symbol | Currency, to : String | Symbol | Currency) : BigDecimal?
      from, to =
        Currency.wrap(from), Currency.wrap(to)

      transaction do
        get_rate?(from, to).try(&.value)
      end
    end

    # Retrieves the rate for the given currency pair or raises
    # `UnknownRateError` if not found.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store["USD", "CAD"] = 1.24515
    #
    # store["USD", "CAD"] # => 1.24515
    # store["CAD", "USD"] # raises UnknownRateError
    # ```
    def [](from : String | Symbol | Currency, to : String | Symbol | Currency) : BigDecimal
      self[from, to]? ||
        raise UnknownRateError.new("No conversion rate known for #{from} -> #{to}")
    end

    # Same as `#each`, but doesn't use concurrency-safe transaction.
    protected abstract def unsafe_each(& : Rate -> _)

    # Iterates over list of `Rate` objects.
    #
    # ```
    # store.each do |rate|
    #   puts rate
    # end
    # ```
    def each(& : Rate -> _) : Nil
      transaction do
        unsafe_each { |rate| yield rate }
      end
    end

    # Returns list of `Rate` objects.
    def rates : Array(Rate)
      transaction do
        rates = [] of Rate
        unsafe_each { |rate| rates << rate }
        rates
      end
    end

    # See also `#clear`.
    protected abstract def clear_rates : Nil

    # Empties currency rate index.
    def clear : Nil
      transaction { clear_rates }
    end

    # See also `#clear(base_currency)`.
    protected abstract def clear_rates(base_currency : Currency) : Nil

    # Empties currency rate index.
    def clear(base_currency : String | Symbol | Currency) : Nil
      transaction do
        clear_rates(Currency.wrap(base_currency))
      end
    end
  end
end

require "./rate_store/*"
