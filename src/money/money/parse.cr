struct Money
  module Parse
    # Exception class for parse errors.
    class Error < Money::Error
    end

    private PATTERNS = {
      # 10,23 PLN
      /(?<sign>\+|\-)?(?<amount>\d+(?:[.,]\d+)?)\s*(?<symbol>[^0-9,.]+)/,
      # $10.23
      /(?<sign>\+|\-)?(?<symbol>[^0-9,.]+)\s*(?<amount>\d+(?:[.,]\d+)?)/,
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
      matched_pattern = PATTERNS.each do |pattern|
        if str =~ pattern
          break $~["amount"], $~["symbol"], $~["sign"]?
        end
      end

      if matched_pattern
        amount, symbol, sign = matched_pattern
      else
        raise Error.new "Invalid format"
      end

      currency = begin
        matches = Currency.select(&.==(symbol))
        matches = Currency.select(&.symbol.==(symbol)) if matches.empty?
        matches = Currency.select(&.disambiguate_symbol.==(symbol)) if matches.empty?
        matches = Currency.select(&.alternate_symbols.try(&.includes?(symbol))) if matches.empty?

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

      amount = amount.gsub(',', '.')
      amount = "#{sign}#{amount}" if sign

      Money.from_amount(amount, currency)
    rescue ex : Money::Error
      yield Error.new "Cannot parse #{str.inspect}", ex
    end
  end
end
