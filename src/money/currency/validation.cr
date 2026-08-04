class Money::Currency
  module Validation
    protected def normalize! : Nil
      @name = @name.presence
      @symbol = @symbol.presence
      @disambiguate_symbol = @disambiguate_symbol.presence
      @subunit = @subunit.presence
      @format = @format.presence
    end

    protected def validate! : Nil
      validate_code
      validate_positive_number subunit_to_unit, "Subunit to unit"
      validate_positive_number iso_numeric, "ISO numeric"
      validate_positive_number smallest_denomination, "Smallest denomination"
    end

    private def validate_positive_number(value : Number?, label : String)
      return if value.nil? || value.positive?

      raise ArgumentError.new \
        "#{label} value must be positive: #{value}"
    end

    private def validate_code
      return if code.presence &&
                code.size >= 3 &&
                code[0].ascii_uppercase? &&
                code.chars.all? { |char| char.ascii_uppercase? || char.ascii_number? }

      raise ArgumentError.new \
        "Code must be all uppercase 3+ letters and/or digits: #{code.inspect}"
    end
  end
end
