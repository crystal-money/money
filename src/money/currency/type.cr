class Money::Currency
  # Currency type.
  enum Type
    Metal
    Fiat
    Crypto
    Special
  end
end
