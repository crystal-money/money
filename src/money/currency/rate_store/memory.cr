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
      @index[rate_key_for(rate.base, rate.target)] = rate
    end

    protected def get_rate?(base : Currency, target : Currency) : Rate?
      @index[rate_key_for(base, target)]?
    end

    protected def each_rate(& : Rate ->)
      @index.each_value { |rate| yield rate }
    end

    protected def clear_rates : Nil
      @index.clear
    end

    protected def clear_rates(base : Currency) : Nil
      @index.reject! { |_, rate| rate.base == base }
    end

    private def rate_key_for(base : Currency, target : Currency)
      {base.code, target.code}.join(INDEX_KEY_SEPARATOR)
    end
  end
end
