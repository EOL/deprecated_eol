# a place for us to define our custom matchers

RSpec::Matchers.define :only_include do |fields|
  match do |array|
    if array.nil?
      return true if fields.nil?
      return false
    end
    fields = [fields] unless fields.class == Array
    array = [array] unless array.class == Array
    array.sort == fields.sort
  end

  failure_message_for_should do |array|
    if fields.length != array.length
      "expected to have #{fields.length} entries, but had #{array.length}: #{array.inspect}"
    else
      "expected #{array.inspect} to include #{(fields.sort - array).inspect}"
    end
  end

  failure_message_for_should_not do |array|
    "expected #{array.inspect} NOT to equal #{fields.sort.inspect}"
  end

  description do
    "only include #{fields.sort.inspect}"
  end
end

# TODO - this could work now, so I'm omitting it; if you're reading this, delete it!
# matcher(:include) {|array, block| array.include? block }
