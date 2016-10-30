##
# The IncludedResourceParams class is responsible for parsing a string containing
# a comma separated list of associated resources to include with a request. See
# http://jsonapi.org/format/#fetching-includes for additional details although
# this is not required knowledge for the task at hand.
#
# Our API requires specific inclusion of related resourses - that is we do NOT
# want to support wildcard inclusion (e.g. `foo.*`)
#
# The IncludedResourceParams class has three public methods making up its API.
#
# [included_resources]
#   returns an array of non-wildcard included elements.
# [has_included_resources?]
#   Returns true if our supplied param has included resources, false otherwise.
# [model_includes]
#   returns an array suitable to supply to ActiveRecord's `includes` method
#   (http://guides.rubyonrails.org/active_record_querying.html#eager-loading-multiple-associations)
#   The included_resources should be transformed as specified in the unit tests
#   included herein.
#
# All three public methods have unit tests written below that must pass. You are
# free to add additional classes/modules as necessary and/or private methods
# within the IncludedResourceParams class.
#
# Feel free to use the Ruby standard libraries available on codepad in your
# solution.
#
# Create your solution as a private fork, and send us the URL.
#
class IncludedResourceParams

  def initialize(include_param)
    @include_param = include_param
  end

  ##
  # Does our IncludedResourceParams instance actually have any valid included
  # resources after parsing?
  #
  # @return [Boolean] whether this instance has included resources
  def has_included_resources?
    # TODO: implement me
    if @include_param == nil then return false end
    for resource in @include_param.split(',') do
      if (!resource.include? '*') && (!resource.include? '?') then return true end
    end
    return false
  end

  ##
  # Fetches the included resourcs as an Array containing only non-wildcard
  # resource specifiers.
  #
  # @example nil
  #   IncludedResourceParams.new(nil).included_resources => []
  #
  # @example "foo,foo.bar,baz.*"
  #   IncludedResourceParams.new("foo,bar,baz.*").included_resources => ["foo", "foo.bar"]
  #
  # @return [Array] an Array of Strings parsed from the include param with
  # wildcard includes removed
  def included_resources
    # TODO: implement me
    if @include_param == nil then return [] end
    valid_resources = []
    for resource in @include_param.split(',') do
      if (!resource.include? '*') && (!resource.include? '?')
        valid_resources += [resource]
      end
    end
    return valid_resources
  end

  ##
  # Converts the resources to be included from their JSONAPI representation to
  # a structure compatible with ActiveRecord's `includes` methods. This can/should
  # be an Array in all cases. Does not do any verification that the resources
  # specified for inclusion are actual ActiveRecord classes.
  #
  # @example nil
  #   IncludedResourceParams.new(nil).model_includes => []
  #
  # @example "foo"
  #   IncludedResourceParams.new("foo").model_includes => [:foo]
  #
  # @see Following unit tests
  #
  # @return [Array] an Array of Symbols and/or Hashes compatible with ActiveRecord
  # `includes`
  def model_includes
    # TODO: implement me
    if @include_param == nil then return [] end
    array_of_symbols = []
    array_of_params = @include_param.split(',').map { |x| x.split('.') }
    for resource in array_of_params do
      parse_it(resource, array_of_symbols)
    end
    return array_of_symbols
  end

  private
  def parse_it(resource, array_of_symbols)
    k = 0
    for item in array_of_symbols do

      if item.class == Symbol
        if resource[0].to_sym == item
          if resource[1]
            if resource[2]
              array_of_symbols[k] = {item => [{resource[1].to_sym => [resource[2].to_sym]}]}
              return array_of_symbols
            end
            array_of_symbols[k] = {item => [resource[1].to_sym]}
            return array_of_symbols
          end
          return array_of_symbols
        end
      end

      if item.class == Hash
        temp = item[resource[0].to_sym]
        if temp
          if resource.length > 1
            array_of_symbols[k][resource[0].to_sym] = parse_it(resource[1..-1], temp)
            return array_of_symbols
          else
            return array_of_symbols
          end
        end
      end

      k += 1
    end

    if resource[1]
      if resource[2]
        new_item = {resource[0].to_sym => [{resource[1].to_sym => [resource[2].to_sym]}]}
        return array_of_symbols.push(new_item)
      end
      new_item = {resource[0].to_sym => [resource[1].to_sym]}
      return array_of_symbols.push(new_item)
    end
    return array_of_symbols.push(resource[0].to_sym)
  end

end

require 'test/unit'
class TestIncludedResourceParams < Test::Unit::TestCase
  # Tests for #has_included_resources?
  def test_has_included_resources_is_false_when_nil
    r = IncludedResourceParams.new(nil)
    assert r.has_included_resources? == false
  end

  def test_has_included_resources_is_false_when_only_wildcards
    include_string = 'foo.**'
    r = IncludedResourceParams.new(include_string)
    assert r.has_included_resources? == false
  end

  def test_has_included_resources_is_true_with_non_wildcard_params
    include_string = 'foo'
    r = IncludedResourceParams.new(include_string)
    assert r.has_included_resources?
  end

  def test_has_included_resources_is_true_with_both_wildcard_and_non_params
    include_string = 'foo,bar.**'
    r = IncludedResourceParams.new(include_string)
    assert r.has_included_resources?
  end

  # Tests for #included_resources
  def test_included_resources_always_returns_array
    r = IncludedResourceParams.new(nil)
    assert r.included_resources == []
  end

  def test_included_resources_returns_only_non_wildcards
    r = IncludedResourceParams.new('foo,foo.bar,baz.*,bat.**')
    assert r.included_resources == ['foo', 'foo.bar']
  end

  # Tests for #model_includes
  def test_model_includes_when_params_nil
    assert IncludedResourceParams.new(nil).model_includes == []
  end

  def test_model_includes_one_single_level_resource
    assert IncludedResourceParams.new('foo').model_includes == [:foo]
  end

  def test_model_includes_multiple_single_level_resources
    assert IncludedResourceParams.new('foo,bar').model_includes == [:foo, :bar]
  end

  def test_model_includes_single_two_level_resource
    assert IncludedResourceParams.new('foo.bar').model_includes == [{:foo => [:bar]}]
  end

  def test_model_includes_multiple_two_level_resources
    assert IncludedResourceParams.new('foo.bar,foo.bat').model_includes == [{:foo => [:bar, :bat]}]
    assert IncludedResourceParams.new('foo.bar,baz.bat').model_includes == [{:foo => [:bar]}, {:baz => [:bat]}]
  end

  def test_model_includes_three_level_resources
    assert IncludedResourceParams.new('foo.bar.baz').model_includes == [{:foo => [{:bar => [:baz]}]}]
  end

  def test_model_includes_multiple_three_level_resources
    assert IncludedResourceParams.new('foo.bar.baz,foo,foo.bar.bat,bar').model_includes == [{:foo => [{:bar => [:baz, :bat]}]}, :bar]
  end
end
