class Money::Currency
  module Enumeration
    include Enumerable(Currency)

    # Lookup a currency with given *key* an returns a `Currency` instance on
    # success, `nil` otherwise.
    #
    # ```
    # Money::Currency.find?("EUR") # => #<Money::Currency @code="EUR">
    # Money::Currency.find?("FOO") # => nil
    # ```
    def find?(key : String | Symbol) : Currency?
      @@registry_mutex.synchronize do
        registry[key.to_s.downcase]?
      end
    end

    # Alias of `#find?`.
    @[AlwaysInline]
    def []?(key : String | Symbol) : Currency?
      find?(key)
    end

    # Returns given `Currency` instance.
    @[AlwaysInline]
    def []?(key : Currency) : Currency?
      key
    end

    # Lookup a currency with given *key* an returns a `Currency` instance on
    # success, raises `UnknownCurrencyError` otherwise.
    #
    # ```
    # Money::Currency.find("EUR") # => #<Money::Currency @code="EUR">
    # Money::Currency.find("FOO") # => raises UnknownCurrencyError
    # ```
    def find(key : String | Symbol) : Currency
      find?(key) ||
        raise UnknownCurrencyError.new(key)
    end

    # Alias of `#find`.
    @[AlwaysInline]
    def [](key : String | Symbol) : Currency
      find(key)
    end

    # Returns given `Currency` instance.
    @[AlwaysInline]
    def [](key : Currency) : Currency
      key
    end

    # Returns a sorted list of all registered currencies.
    def all : Array(Currency)
      @@registry_mutex.synchronize do
        registry.values.sort!
      end
    end

    # Iterates over all registered currencies.
    def each(& : Currency -> _) : Nil
      all.each do |currency|
        yield currency
      end
    end
  end
end
