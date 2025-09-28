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
    private getter! index : Hash(String, Rate)

    protected def after_initialize
      super
      @index ||= {} of String => Rate
    end

    protected def set_rate(rate : Rate) : Nil
      index[rate_key_for(rate.base, rate.target)] = rate
    end

    protected def get_rate?(base : Currency, target : Currency) : Rate?
      index[rate_key_for(base, target)]?
    end

    protected def each_rate(& : Rate ->)
      index.each_value { |rate| yield rate }
    end

    protected def clear_rates : Nil
      index.clear
    end

    protected def clear_rates(base : Currency) : Nil
      index.reject! { |_, rate| rate.base == base }
    end

    protected def clear_stale_rates : Nil
      index.reject! { |_, rate| stale_rate?(rate) }
    end

    private def rate_key_for(base : Currency, target : Currency)
      "#{base.code}_#{target.code}"
    end
  end
end
