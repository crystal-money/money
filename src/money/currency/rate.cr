class Money::Currency
  record Rate, from : Currency, to : Currency, value : Int64 do
    # Returns conversion rate `value` as `Int64`.
    def to_i64 : Int64
      @value
    end

    # Returns conversion rate `value` as `Float64`.
    def to_f64 : Float64
      to_big_d.to_f
    end

    # Returns conversion rate `value` as `BigDecimal` object.
    def to_big_d : BigDecimal
      BigDecimal.new(@value, @to.exponent)
    end

    def to_s(io : IO) : Nil
      io << @from << " -> " << @to << ": " << to_big_d
    end
  end
end
