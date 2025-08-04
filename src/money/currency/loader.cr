class Money::Currency
  module Loader
    private DATA_PATH = Path["../../../data/currencies"].expand(__DIR__)

    # Loads and returns the currencies stored in JSON files
    # inside of `data/currencies` directory.
    def load_defaults : Hash(String, Currency)
      currency_table = {} of String => Currency
      if_defined?(:JSON) do
        Dir.each_child(DATA_PATH) do |filename|
          if currency = parse_currency_file(filename)
            currency_table[currency.code] = currency
          end
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
    end
  end
end
