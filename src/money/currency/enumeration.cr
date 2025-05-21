struct Money
  class Currency
    module Enumeration
      include Enumerable(Currency)

      # Lookup a currency with given *key* an returns a `Currency` instance on
      # success, `nil` otherwise.
      #
      # ```
      # Money::Currency.find("EUR") # => #<Money::Currency @id="eur">
      # Money::Currency.find("FOO") # => nil
      # ```
      def find?(key : String | Symbol) : Currency?
        @@table_mutex.synchronize do
          table[key.to_s.downcase]?
        end
      end

      # Alias of `#find?`.
      @[AlwaysInline]
      def []?(key : String | Symbol) : Currency?
        find?(key)
      end

      # Lookup a currency with given *key* an returns a `Currency` instance on
      # success, raises `UnknownCurrencyError` otherwise.
      #
      # ```
      # Money::Currency.find("EUR") # => #<Money::Currency @id="eur">
      # Money::Currency.find("FOO") # => raises UnknownCurrencyError
      # ```
      def find(key : String | Symbol) : Currency
        find?(key) ||
          raise UnknownCurrencyError.new("Can't find currency: #{key}")
      end

      # Alias of `#find`.
      @[AlwaysInline]
      def [](key : String | Symbol) : Currency
        find(key)
      end

      # Returns a sorted list of all registered currencies.
      def all : Array(Currency)
        @@table_mutex.synchronize do
          table.values.sort!
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
end
