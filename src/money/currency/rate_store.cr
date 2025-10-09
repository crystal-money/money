class Money::Currency
  abstract class RateStore
    extend Money::Registry

    # Raised when trying to find an unknown rate store.
    class NotFoundError < Registry::NotFoundError
      def initialize(*, key : String)
        super("Unknown rate store: #{key}")
      end
    end

    include Enumerable(Rate)

    if_defined?(:JSON) { @[JSON::Field(ignore: true)] }
    if_defined?(:YAML) { @[YAML::Field(ignore: true)] }
    private getter! mutex : Mutex

    if_defined?(:JSON) { @[JSON::Field(converter: Time::Span::StringConverter)] }
    if_defined?(:YAML) { @[YAML::Field(converter: Time::Span::StringConverter)] }
    property ttl : Time::Span?

    def initialize(*, @ttl : Time::Span? = nil)
      after_initialize
    end

    protected def after_initialize
      @mutex = Mutex.new(:reentrant)
    end

    # Wraps block execution in a concurrency-safe transaction.
    def transaction(*, mutable : Bool = false, & : -> _)
      mutex.synchronize { yield }
    end

    # Returns `true` if the rate is stale.
    protected def stale_rate?(rate : Rate) : Bool
      !!ttl.try { |ttl| rate.updated_at < Time.utc - ttl }
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
    def []=(base : String | Symbol | Currency, target : String | Symbol | Currency, value : Number) : Nil
      base, target =
        Currency[base], Currency[target]

      transaction(mutable: true) do
        set_rate(Rate.new(base, target, value.to_big_d))
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
    protected abstract def get_rate?(base : Currency, target : Currency) : Rate?

    # Retrieves the rate for the given currency pair or `nil` if not found.
    #
    # ```
    # store = Money::Currency::RateStore::Memory.new
    # store["USD", "CAD"] = 1.24515
    #
    # store["USD", "CAD"]? # => 1.24515
    # store["CAD", "USD"]? # => nil
    # ```
    def []?(base : String | Symbol | Currency, target : String | Symbol | Currency) : BigDecimal?
      base, target =
        Currency[base], Currency[target]

      transaction do
        if rate = get_rate?(base, target)
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
    # store["CAD", "USD"] # raises Money::UnknownRateError
    # ```
    def [](base : String | Symbol | Currency, target : String | Symbol | Currency) : BigDecimal
      self[base, target]? ||
        raise UnknownRateError.new(base, target)
    end

    # Same as `#each`, but doesn't use concurrency-safe transaction.
    protected abstract def each_rate(& : Rate ->)

    # Iterates over list of `Rate` objects.
    #
    # ```
    # store.each do |rate|
    #   puts rate
    # end
    # ```
    def each(*, include_stale : Bool = false, & : Rate ->) : Nil
      transaction do
        each_rate do |rate|
          yield rate if include_stale || !stale_rate?(rate)
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

    # See also `#clear(base)`.
    protected abstract def clear_rates(base : Currency?, target : Currency?) : Nil

    # See also `#compact`.
    protected abstract def clear_rates(rates : Enumerable(Rate)) : Nil

    # Removes rates for the given *base* (and if given, *target*) currencies.
    # Removes all rates if no arguments are given.
    def clear(base : Currency? = nil, target : Currency? = nil) : Nil
      transaction(mutable: true) do
        if base || target
          clear_rates(base, target)
        else
          clear_rates
        end
      end
    end

    # :nodoc:
    def clear(base = nil, target = nil) : Nil
      clear(base && Currency[base], target && Currency[target])
    end

    # Removes stale rates (only if `#ttl` is set).
    def compact : Nil
      return unless ttl

      stale_rates = ([] of Rate).tap do |ary|
        each(include_stale: true) do |rate|
          ary << rate if stale_rate?(rate)
        end
      end
      return if stale_rates.empty?

      transaction(mutable: true) do
        clear_rates(stale_rates)
      end
    end
  end
end

require "./rate_store/*"
