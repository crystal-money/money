class Money::Currency
  abstract class RateStore
    include Enumerable(Rate)

    # Wraps block execution in a concurrency-safe transaction.
    abstract def transaction(&block : -> _)

    # See `#[]=`.
    abstract def add_rate(from : Currency, to : Currency, value : Int64) : Void

    # Registers a conversion rate and returns it.
    # NOTE: Uses `transaction` to synchronize data access.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store["USD", "CAD"] = 1.24515
    # store["CAD", "USD"] = 0.803115
    # ```
    def []=(from, to, value : Number) : Void
      from, to = Currency.wrap(from), Currency.wrap(to)
      value = (value.to_big_d * to.subunit_to_unit).round
      transaction { add_rate(from, to, value.to_i64) }
    end

    # See `#[]?`.
    abstract def get_rate?(from : Currency, to : Currency) : Rate?

    # Retrieve the rate for the given currencies.
    # NOTE: Uses `transaction` to synchronize data access.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store["USD", "CAD"] = 1.24515
    # store["USD", "CAD"]? # => 1.24515
    # ```
    def []?(from, to) : BigDecimal?
      from, to = Currency.wrap(from), Currency.wrap(to)
      transaction { get_rate?(from, to).try(&.to_big_d) }
    end

    # ditto
    def [](from, to) : BigDecimal
      from, to = Currency.wrap(from), Currency.wrap(to)
      self[from, to]? || raise UnknownRateError.new("No conversion rate known for #{from} -> #{to}")
    end

    # Iterates over list of `Rate` objects.
    #
    # ```
    # store.each do |rate|
    #   puts rate
    # end
    # ```
    abstract def each(&block : T -> _)

    # See `#clear`.
    abstract def clear_rates : Void

    # Empties currency rate index.
    # NOTE: Uses `transaction` to synchronize data access.
    def clear : Void
      transaction { clear_rates }
    end
  end
end

require "./rate_store/*"
