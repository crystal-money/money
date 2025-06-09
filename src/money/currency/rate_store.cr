class Money::Currency
  abstract class RateStore
    include Enumerable(Rate)

    @mutex = Mutex.new(:reentrant)
    @ttl : Time::Span?

    def initialize(*, @ttl : Time::Span? = nil)
    end

    # Wraps block execution in a concurrency-safe transaction.
    def transaction(*, mutable : Bool = false, & : -> _)
      @mutex.synchronize { yield }
    end

    # Returns `true` if the rate is stale.
    protected def stale_rate?(rate : Rate) : Bool
      !!@ttl.try { |ttl| rate.updated_at < Time.utc - ttl }
    end

    # See also `#[]=`.
    protected abstract def set_rate(rate : Rate) : Nil

    # See also `#<<`.
    protected def set_rates(rates : Enumerable(Rate)) : Nil
      rates.each do |rate|
        set_rate(rate)
      end
    end

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

      transaction(mutable: true) do
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
      transaction(mutable: true) do
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
      transaction(mutable: true) do
        set_rates(rates)
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
        if rate = get_rate?(from, to)
          stale_rate?(rate) ? nil : rate.value
        end
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
    protected abstract def each_rate(& : Rate -> _)

    # Iterates over list of `Rate` objects.
    #
    # ```
    # store.each do |rate|
    #   puts rate
    # end
    # ```
    def each(& : Rate -> _) : Nil
      transaction do
        each_rate do |rate|
          yield rate unless stale_rate?(rate)
        end
      end
    end

    # Alias of `#to_a`.
    @[AlwaysInline]
    def rates : Array(Rate)
      to_a
    end

    # See also `#clear`.
    protected abstract def clear_rates : Nil

    # Empties currency rate index.
    def clear : Nil
      transaction(mutable: true) do
        clear_rates
      end
    end

    # See also `#clear(base)`.
    protected abstract def clear_rates(base : Currency) : Nil

    # Removes rates for the given *base* currency.
    def clear(base : String | Symbol | Currency) : Nil
      transaction(mutable: true) do
        clear_rates(Currency.wrap(base))
      end
    end
  end
end

require "./rate_store/*"
