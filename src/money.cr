require "big"
require "json"
{% if flag?(:docs) %}
  require "yaml"
{% end %}

struct Money
end

require "./core_ext/**"
require "./money/error"
require "./money/registry"
require "./money/*"
