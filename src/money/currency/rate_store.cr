class Money::Currency
  abstract class RateStore
    include Enumerable(Rate)

    # Wraps block execution in a concurrency-safe transaction.
    abstract def transaction(& : -> _)

    # See also `#[]=`.
    protected abstract def set_rate(from : Currency, to : Currency, value : BigDecimal) : Nil

    # Registers a conversion rate and returns it.
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
        set_rate(from, to, value.to_big_d)
      end
    end

    # See also `#[]?`.
    protected abstract def get_rate?(from : Currency, to : Currency) : Rate?

    # Retrieve the rate for the given currency pair.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store["USD", "CAD"] = 1.24515
    # store["USD", "CAD"]? # => 1.24515
    # ```
    def []?(from : String | Symbol | Currency, to : String | Symbol | Currency) : BigDecimal?
      from, to =
        Currency.wrap(from), Currency.wrap(to)

      transaction do
        get_rate?(from, to).try(&.value)
      end
    end

    # :ditto:
    def [](from : String | Symbol | Currency, to : String | Symbol | Currency) : BigDecimal
      self[from, to]? ||
        raise UnknownRateError.new("No conversion rate known for #{from} -> #{to}")
    end

    # Same as `#each`, but doesn't use concurrency-safe transaction.
    protected abstract def unsafe_each(& : T -> _)

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

    # See also `#clear`.
    protected abstract def clear_rates : Nil

    # Empties currency rate index.
    def clear : Nil
      transaction { clear_rates }
    end
  end
end

require "./rate_store/*"
