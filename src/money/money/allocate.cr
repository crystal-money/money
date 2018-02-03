class Money
  module Allocate
    # Splits money amongst parties evenly without losing pennies.
    #
    # ```
    # Money.new(100, "USD").split(3) # => [Money.new(34), Money.new(33), Money.new(33)]
    # ```
    def split(num : Int) : Array(Money)
      raise ArgumentError.new("Need at least one party") if num < 1

      low = Money.new(fractional / num, currency)
      high = Money.new(low.fractional + 1, currency)

      remainder = fractional % num

      Array(Money).new(num) do |index|
        index < remainder ? high : low
      end
    end

    # Allocates money between different parties without losing pennies.
    # After the mathematical split has been performed, leftover pennies will
    # be distributed round-robin amongst the parties. This means that parties
    # listed first will likely receive more pennies than ones that are listed later.
    #
    # ```
    # # Give 50% of the cash to party 1, 25% to party 2, and 25% to party 3.
    # Money.new(10_00, "USD").allocate([0.5, 0.25, 0.25]) # => [Money.new(5_00), Money.new(2_50), Money.new(2_50)]
    # Money.new(5, "USD").allocate({0.3, 0.7})            # => [Money.new(2), Money.new(3)]
    # Money.new(100, "USD").allocate(0.33, 0.33, 0.33)    # => [Money.new(34), Money.new(33), Money.new(33)]
    # ```
    def allocate(splits : Enumerable(Number)) : Array(Money)
      allocations = allocations_from_splits(splits)
      raise ArgumentError.new("Splits add to more then 100%") if allocations > 1.0

      amounts, left_over = amounts_from_splits(allocations, splits)
      delta = left_over > 0 ? 1 : -1

      size = amounts.size
      # Distribute left over pennies amongst allocations
      left_over.to_i64.abs.times do |i|
        amounts[i % size] += delta
      end
      amounts.map { |fractional| Money.new(fractional, currency) }
    end

    # ditto
    def allocate(*splits : Number) : Array(Money)
      allocate(splits)
    end

    private def allocations_from_splits(splits)
      splits.reduce(0.to_big_d) { |sum, n| sum + n.to_big_d }
    end

    private def amounts_from_splits(allocations, splits)
      left_over = fractional.to_big_d
      amounts = splits.map do |ratio|
        (fractional.to_big_d * ratio.to_big_d / allocations).round.tap do |fraction|
          left_over -= fraction
        end
        # fractional.to_big_d * ratio.to_big_d
      end
      {amounts.to_a, left_over}
    end
  end
end
