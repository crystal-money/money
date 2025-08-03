class Money::Currency
  struct Rate
    include Comparable(Rate)

    getter base : Currency
    getter target : Currency
    getter value : BigDecimal
    getter updated_at : Time

    def initialize(@base, @target, @value, @updated_at = Time.utc)
      after_initialize
    end

    protected def after_initialize
      validate!
    end

    protected def validate!
      raise ArgumentError.new("Invalid rate: #{value}") unless value.positive?
    end

    def_hash base, target, value, updated_at

    def <=>(other : Rate) : Int32
      {base, target, other.updated_at, other.value} <=>
        {other.base, other.target, updated_at, value}
    end

    def to_s(*, include_updated_at = false) : String
      String.build do |io|
        to_s(io, include_updated_at: include_updated_at)
      end
    end

    def to_s(io : IO, *, include_updated_at = false) : Nil
      io << base << " -> " << target << ": " << value
      io << " (" << updated_at << ')' if include_updated_at
    end
  end
end
