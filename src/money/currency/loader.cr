require "json"

class Money::Currency
  module Loader
    private DATA_PATH = Path["../../../data/currencies"].expand(__DIR__)

    # Loads and returns the currencies stored in JSON files
    # inside of `data/currencies` directory.
    def load_currencies
      currency_table = {} of String => Currency
      Dir.each_child(DATA_PATH) do |filename|
        if currency = parse_currency_file(filename)
          currency_table[currency.id] = currency
        end
      end
      currency_table
    end

    private def parse_currency_file(filename)
      filepath = DATA_PATH / filename
      if File.file?(filepath)
        File.open(filepath) do |file|
          Currency.from_json(file)
        end
      end
    rescue ex
    end
  end
end
