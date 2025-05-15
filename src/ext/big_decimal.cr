# https://github.com/crystal-lang/crystal/issues/15778
struct BigDecimal < Number
  def to_s(*, scientific_notation = true) : String
    String.build do |io|
      to_s io, scientific_notation: scientific_notation
    end
  end

  # ameba:disable Metrics/CyclomaticComplexity
  def to_s(io : IO, *, scientific_notation = true) : Nil
    factor_powers_of_ten

    cstr = LibGMP.get_str(nil, 10, @value)
    length = LibC.strlen(cstr)
    buffer = Slice.new(cstr, length)

    # add negative sign
    if buffer[0]? == 45 # '-'
      io << '-'
      buffer = buffer[1..]
      length -= 1
    end

    decimal_exponent = length.to_i - @scale
    point = decimal_exponent
    exp = point
    exp_mode = scientific_notation && (point > 15 || point < -3)
    point = 1 if exp_mode

    # add leading zero
    io << '0' if point < 1

    # add integer part digits
    if decimal_exponent > 0 && !exp_mode
      # whole number but not big enough to be exp form
      io.write_string buffer[0, {decimal_exponent, length}.min]
      buffer = buffer[{decimal_exponent, length}.min...]
      (point - length).times { io << '0' }
    elsif point > 0
      io.write_string buffer[0, point]
      buffer = buffer[point...]
    end

    io << '.'

    # add leading zeros after point
    if point < 0
      (-point).times { io << '0' }
    end

    # remove trailing zeroes
    while buffer.size > 1 && buffer.last === '0'
      buffer = buffer[0..-2]
    end

    # add fractional part digits
    io.write_string buffer

    # print trailing 0 if whole number or exp notation of power of ten
    if (decimal_exponent >= length && !exp_mode) || (exp != point && length == 1)
      io << '0'
    end

    # exp notation
    if exp != point
      io << 'e'
      io << '+' if exp > 0
      (exp - 1).to_s(io)
    end
  end
end
