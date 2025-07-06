struct Money
  module Parse
    # Exception class for parse errors.
    class Error < Money::Error
    end

    private PATTERNS = {
      # 10,23 PLN
      /(?<sign>\+|\-)?(?<amount>\d+(?:[.,_]\d+)*)\s*(?<symbol>[^0-9,._)]+)/,
      # $10.23
      /(?<sign>\+|\-)?(?<symbol>[^0-9,._]+)\s*(?<amount>\d+(?:[.,_]\d+)*)/,
    }

    # Creates a `Money` instance from a string.
    def parse(str : String, allow_ambiguous = true) : Money
      parse(str, allow_ambiguous) { |ex| raise ex }
    end

    # Creates a `Money` instance from a string, or returns `nil` on failure.
    def parse?(str : String, allow_ambiguous = true) : Money?
      parse(str, allow_ambiguous) { nil }
    end

    private def parse(str : String, allow_ambiguous : Bool, &)
      amount, symbol = parse_amount_and_symbol(str)
      currency = parse_currency(symbol, allow_ambiguous)

      if thousands_separator = currency.thousands_separator
        amount = amount.gsub(thousands_separator, '_')
      end

      Money.from_amount(amount, currency)
    rescue ex : Money::Error
      yield Error.new "Cannot parse #{str.inspect}", ex
    end

    private def parse_amount_and_symbol(str : String)
      matched_pattern =
        PATTERNS.find_value do |pattern|
          {$~["amount"], $~["symbol"], $~["sign"]?} if str =~ pattern
        end ||
          raise Error.new "Invalid format"

      amount, symbol, sign = matched_pattern
      amount = "#{sign}#{amount}" if sign

      {amount, symbol}
    end

    private def parse_currency(symbol : String, allow_ambiguous : Bool) : Currency
      matches = parse_currencies(symbol)

      case matches.size
      when 0
        raise Error.new "Symbol #{symbol.inspect} didn't matched any currency"
      when 1
        matches.first
      else
        unless allow_ambiguous
          raise Error.new "Symbol #{symbol.inspect} matches multiple currencies: #{matches.map(&.to_s)}"
        end
        matches.first
      end
    end

    private def parse_currencies(symbol : String) : Array(Currency)
      matches = Currency.select(&.==(symbol))
      matches = Currency.select(&.symbol.==(symbol)) if matches.empty?
      matches = Currency.select(&.disambiguate_symbol.==(symbol)) if matches.empty?
      matches = Currency.select(&.alternate_symbols.try(&.includes?(symbol))) if matches.empty?
      matches
    end
  end
end
