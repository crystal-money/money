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
      validate_subunit_to_unit
      validate_iso_numeric
      validate_smallest_denomination
    end

    private def validate_code
      return if code.presence &&
                code.size >= 3 &&
                code[0].ascii_uppercase? &&
                code.chars.all? { |char| char.ascii_uppercase? || char.ascii_number? }

      raise ArgumentError.new \
        "Code must be all uppercase letters and/or digits: #{code.inspect}"
    end

    private def validate_subunit_to_unit
      return if subunit_to_unit.positive?

      raise ArgumentError.new \
        "Subunit to unit value must be positive: #{subunit_to_unit}"
    end

    private def validate_iso_numeric
      return if !(value = iso_numeric) || value.positive?

      raise ArgumentError.new \
        "ISO numeric value must be positive: #{value}"
    end

    private def validate_smallest_denomination
      return if !(value = smallest_denomination) || value.positive?

      raise ArgumentError.new \
        "Smallest denomination value must be positive: #{value}"
    end
  end
end
