# :nodoc:
#
# Yields given block if the given constant *name* is defined
# in the top-level scope.
#
# ```
# class Foo
#   if_defined?(:JSON) do
#     include JSON::Serializable
#   end
#   if_defined?(:YAML) do
#     include YAML::Serializable
#   end
# end
# ```
macro if_defined?(name, &block)
  {% if @top_level.has_constant?(name) %}
    {{ yield }}
  {% end %}
end
