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

    private def validate_positive_number(value : Number?, label : String)
      if value && !value.positive?
        raise ArgumentError.new "#{label} value must be positive: #{value}"
      end
    end

    private def validate_code
      return if code.presence &&
                code.size >= 3 &&
                code[0].ascii_uppercase? &&
                code.chars.all? { |char| char.ascii_uppercase? || char.ascii_number? }

      raise ArgumentError.new \
        "Code must be all uppercase 3+ letters and/or digits: #{code.inspect}"
    end

    private def validate_subunit_to_unit
      validate_positive_number subunit_to_unit, "Subunit to unit"
    end

    private def validate_iso_numeric
      validate_positive_number iso_numeric, "ISO numeric"
    end

    private def validate_smallest_denomination
      validate_positive_number smallest_denomination, "Smallest denomination"
    end
  end
end
