class Money
  module Parse
    class Error < Money::Error
    end

    PATTERNS = {
      # 10,23 PLN
      /(?<sign>\+|\-)?(?<amount>\d+(?:[.,]\d+)?)\s*(?<symbol>[^0-9,.]+)/,
      # $10.23
      /(?<sign>\+|\-)?(?<symbol>[^0-9,.]+)\s*(?<amount>\d+(?:[.,]\d+)?)/,
    }

    def parse(str : String, allow_ambigous = true) : Money
      parse(str, allow_ambigous) { |ex| raise ex }
    end

    def parse?(str : String, allow_ambigous = true) : Money?
      parse(str, allow_ambigous) { nil }
    end

    private def parse(str : String, allow_ambigous : Bool)
      matched_pattern = PATTERNS.each do |pattern|
        if str =~ pattern
          break $~["amount"], $~["symbol"], $~["sign"]?
        end
      end

      if matched_pattern
        amount, symbol, sign = matched_pattern
      else
        raise Error.new %(Invalid format)
      end

      found_currencies = Currency.select do |c|
        next true if c.symbol == symbol
        next true if c.alternate_symbols.try(&.includes?(symbol))
      end

      amount = amount.gsub(',', '.')
      amount = "#{sign}#{amount}" if sign
      currency = case found_currencies.size
                 when 0
                   Currency.find(symbol)
                 when 1
                   found_currencies.first
                 else
                   unless allow_ambigous
                     raise Error.new %(Symbol "#{symbol}" matches multiple currencies: #{found_currencies.map(&.to_s)})
                   end
                   found_currencies.first
                 end

      Money.from_amount(amount, currency)
    rescue ex : Money::Error
      return yield Error.new %(Cannot parse "#{str}" => #{ex}), ex
    end
  end
end
