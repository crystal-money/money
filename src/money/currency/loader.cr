require "json"

class Money
  class Currency
    module Loader
      DATA_PATH = File.expand_path("../../../../data/currencies", __FILE__)

      # Loads and returns the currencies stored in JSON files
      # inside of `data/currencies` directory.
      def load_currencies
        currency_table = {} of String => Currency
        Dir.each_child(DATA_PATH) do |filename|
          parse_currency_file(filename).try do |currency|
            currency_table[currency.id] = currency
          end
        end
        currency_table
      end

      private def parse_currency_file(filename)
        filepath = File.join(DATA_PATH, filename)
        if File.file?(filepath)
          currency_json = File.read(filepath)
          currency = Currency.from_json(currency_json)
        end
      rescue ex
      end
    end
  end
end
