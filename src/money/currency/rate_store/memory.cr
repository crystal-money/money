class Money::Currency
  # Class for concurrency-safe storage of exchange rate pairs.
  # Used by instances of `Currency::VariableExchange`.
  #
  # ```
  # store = Money::Currency::RateStore::Memory.new
  # store["USD", "CAD"] = 0.98
  # store["USD", "CAD"] # => 0.98
  #
  # # Iterates rates
  # store.each do |rate|
  #   puts rate
  # end
  # ```
  class RateStore::Memory < RateStore
    private INDEX_KEY_SEPARATOR = '_'

    @index = {} of String => Rate
    @mutex = Mutex.new(:reentrant)

    def transaction(& : -> _)
      @mutex.synchronize { yield }
    end

    protected def add_rate(from : Currency, to : Currency, value : Int64) : Nil
      @index[rate_key_for(from, to)] = Rate.new(from, to, value)
    end

    protected def get_rate?(from : Currency, to : Currency) : Rate?
      @index[rate_key_for(from, to)]?
    end

    protected def unsafe_each(&)
      @index.each_value { |rate| yield rate }
    end

    protected def clear_rates : Nil
      @index.clear
    end

    private def rate_key_for(from : Currency, to : Currency)
      {from.id, to.id}.join(INDEX_KEY_SEPARATOR)
    end
  end
end
