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
      index[Rate.key(rate.base, rate.target)] = rate
    end

    protected def get_rate?(base : Currency, target : Currency) : Rate?
      index[Rate.key(base, target)]?
    end

    protected def each_rate(& : Rate ->)
      index.each_value { |rate| yield rate }
    end

    protected def clear_rates : Nil
      index.clear
    end

    protected def clear_rates(base : Currency?, target : Currency?) : Nil
      index.reject! do |_, rate|
        (!base || (base && rate.base == base)) &&
          (!target || (target && rate.target == target))
      end
    end

    protected def clear_rates(rates : Enumerable(Rate)) : Nil
      index.reject! do |_, rate|
        rate.in?(rates)
      end
    end
  end
end
