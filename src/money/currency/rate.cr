class Money::Currency
  record Rate, from : Currency, to : Currency, value : BigDecimal, updated_at : Time = Time.utc do
    include Comparable(Rate)

    def <=>(other : Rate) : Int32
      {from, to, value, updated_at} <=>
        {other.from, other.to, other.value, other.updated_at}
    end

    def to_s(*, include_updated_at = false) : String
      String.build do |io|
        to_s(io, include_updated_at: include_updated_at)
      end
    end

    def to_s(io : IO, *, include_updated_at = false) : Nil
      io << from << " -> " << to << ": " << value
      io << " (" << updated_at << ')' if include_updated_at
    end
  end
end
