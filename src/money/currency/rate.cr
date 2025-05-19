class Money::Currency
  record Rate, from : Currency, to : Currency, value : BigDecimal do
    def to_s(io : IO) : Nil
      io << from << " -> " << to << ": " << value
    end
  end
end
