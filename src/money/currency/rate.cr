require "json"

class Money::Currency
  record Rate, from : Currency, to : Currency, value : Int64 do
    JSON.mapping({
      from:  Currency,
      to:    Currency,
      value: Int64,
    })

    def to_json(json : JSON::Builder)
      json.object do
        json.field "from", @from.to_s
        json.field "to", @to.to_s
        json.field "value", to_f
      end
    end

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

    # Returns conversion rate `value` as `Money` object.
    def to_money : Money
      Money.new(@value, @to)
    end

    def to_s(io)
      io << @from << " -> " << @to << ": " << to_big_d
    end
  end
end
