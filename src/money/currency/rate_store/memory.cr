class Money::Currency
  # Class for in-memory concurrency-safe storage of exchange rate pairs.
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

    protected def set_rate(rate : Rate) : Nil
      @index[rate_key_for(rate.from, rate.to)] = rate
    end

    protected def get_rate?(from : Currency, to : Currency) : Rate?
      @index[rate_key_for(from, to)]?
    end

    protected def each_rate(& : Rate -> _)
      @index.each_value { |rate| yield rate }
    end

    protected def clear_rates : Nil
      @index.clear
    end

    protected def clear_rates(base : Currency) : Nil
      @index.reject! { |_, rate| rate.from == base }
    end

    private def rate_key_for(from : Currency, to : Currency)
      {from.id, to.id}.join(INDEX_KEY_SEPARATOR)
    end
  end
end
