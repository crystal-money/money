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
        table[key.to_s.downcase]?
      end

      # ditto
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
        table[key.to_s.downcase]? || raise UnknownCurrencyError.new("Can't find currency: #{key}")
      end

      # ditto
      def [](key : String | Symbol) : Currency
        find(key)
      end

      def all : Array(Currency)
        table.values.sort
      end

      def each : Nil
        all.each do |*args|
          yield *args
        end
      end
    end
  end
end
