struct Money
  module Allocate
    # Splits a given amount in parts. The allocation is based on the parts' proportions.
    # The results should always add up to the original amount.
    protected def self.generate(amount, parts, *, whole_amounts = true) : Array(BigDecimal)
      raise ArgumentError.new("Need at least one part") if parts.empty?

      parts =
        if parts.all?(&.zero?)
          Array.new(parts.size, 1.to_big_d)
        else
          Array.new(parts.size) { |idx| parts[idx].to_big_d }
        end

      result = [] of BigDecimal
      remaining_amount = amount

      until parts.empty?
        parts_sum = parts.sum
        part = parts.pop

        if parts_sum.positive?
          current_split = remaining_amount * part / parts_sum
          current_split = current_split.round(:to_zero) if whole_amounts
        else
          current_split = 0.to_big_d
        end

        result.unshift current_split
        remaining_amount -= current_split
      end

      result
    end

    # Splits a given amount in parts without losing pennies.
    #
    # The left-over pennies will be distributed round-robin amongst the parties.
    # This means that parts listed first will likely receive more pennies than
    # ones listed later.
    #
    # Pass `{2, 1, 1}` as input to give twice as much to _part1_ as _part2_ or _part3_
    # which results in **50%** of the cash assigned to _part1_, **25%** to _part2_,
    # and **25%** to _part3_.
    #
    # The results should always add up to the original amount.
    #
    # ```
    # Money.new(5, "USD").allocate(3, 7).map(&.cents)      # => [2, 3]
    # Money.new(100, "USD").allocate(1, 1, 1).map(&.cents) # => [34, 33, 33]
    # ```
    def allocate(parts : Enumerable(Number)) : Array(Money)
      # FIXME: Doesn't work with `Money.infinite_precision?` yet
      Money::Allocate
        .generate(fractional, parts, whole_amounts: !Money.infinite_precision?)
        .map { |amount| copy_with(fractional: amount.to_i) }
    end

    # :ditto:
    def allocate(*parts : Number) : Array(Money)
      allocate(parts)
    end

    # Splits money evenly amongst parties without losing pennies.
    #
    # ```
    # Money.new(100, "USD").split(2).map(&.cents) # => [50, 50]
    # Money.new(100, "USD").split(3).map(&.cents) # => [34, 33, 33]
    # ```
    def split(parts : Int) : Array(Money)
      unless parts.positive?
        raise ArgumentError.new("Need at least one part")
      end
      allocate(Array.new(parts, 1))
    end
  end
end
