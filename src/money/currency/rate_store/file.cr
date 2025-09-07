require "./memory"

class Money::Currency
  # Class for storage of exchange rate pairs in a JSON file.
  #
  # NOTE: Exchange rates are stored in memory and are automatically loaded from
  # (upon initialization), and persisted to a JSON file (on every mutable
  # transaction commit).
  #
  # ```
  # store = Money::Currency::RateStore::File.new("path/to/file.json")
  # store["USD", "CAD"] = 0.98
  # store["USD", "CAD"] # => 0.98
  #
  # # Iterates rates
  # store.each do |rate|
  #   puts rate
  # end
  #
  # # Save rates
  # store.save
  # ```
  class RateStore::File < RateStore::Memory
    getter filepath : Path

    def filepath=(filepath : Path)
      filepath = filepath.expand(home: true)
      return if @filepath == filepath

      @filepath = filepath
      load
    end

    def initialize(filepath : Path | String, *, ttl : Time::Span? = nil)
      @filepath = Path[filepath]
      super(ttl: ttl)
    end

    protected def after_initialize
      super
      @filepath = filepath.expand(home: true)
      load
    end

    # Wraps block execution in a concurrency-safe transaction.
    def transaction(*, mutable : Bool = false, & : -> _)
      super do
        yield.tap do
          save if mutable
        end
      end
    end

    # Loads rates from a JSON file.
    def load : Nil
      # Intentionally omits `mutable` argument so that the file
      # is not saved immediately after (re)loading
      transaction do
        return unless ::File.exists?(filepath)

        ::File.open(filepath) do |file|
          rates =
            Array(Rate).from_json(file)

          clear_rates
          set_rates(rates)
        end
      end
    end

    # Saves rates to a JSON file.
    def save : Nil
      # Intentionally omits `mutable` argument so that it won't
      # trigger an infinite loop from within `transaction`
      transaction do
        # Create directory if it doesn't exist
        ::Dir.mkdir_p(filepath.dirname)

        # Save rates to a JSON file
        ::File.open(filepath, "w") do |file|
          rates.to_pretty_json(file)
        end
      end
    end
  end
end
