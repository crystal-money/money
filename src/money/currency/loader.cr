require "baked_file_system"

class Money::Currency
  private class FileStorage
    extend BakedFileSystem

    if_defined?(:JSON) do
      bake_folder "../../../data/currencies"
    end
  end

  module Loader
    # Loads and returns the currencies stored in JSON files
    # inside of `data/currencies` directory.
    def load_defaults : Hash(String, Currency)
      currency_table = {} of String => Currency

      if_defined?(:JSON) do
        FileStorage.files.each do |file|
          currency = Currency.from_json(file)
          currency_table[currency.code] = currency
        ensure
          file.rewind
        end
      end
      currency_table
    end
  end
end
