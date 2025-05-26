class Money::Currency
  record Rate, from : Currency, to : Currency, value : BigDecimal, updated_at : Time = Time.utc do
    include Comparable(Rate)

    def <=>(other : Rate) : Int32
      {from, to, value, updated_at} <=>
        {other.from, other.to, other.value, other.updated_at}
    end

    def to_s(io : IO) : Nil
      io << from << " -> " << to << ": " << value
    end
  end
end
