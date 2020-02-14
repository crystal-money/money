require "big"

# See https://github.com/crystal-lang/crystal/issues/8789
{% if compare_versions(Crystal::VERSION, "0.34.0") < 0 %}
  struct BigDecimal
    def in_scale(new_scale : UInt64) : BigDecimal
      previous_def
    end

    def ceil : BigDecimal
      previous_def.in_scale(0)
    end
  end
{% end %}

struct Money
end

require "./money/*"
