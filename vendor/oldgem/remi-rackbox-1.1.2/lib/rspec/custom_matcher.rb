# created by: http://github.com/xdotcommer
# from: http://github.com/xdotcommer/rspec-custom-matchers/blob/0ecfccd659d5038cdfc88fdc1fee08373e1ee75c/custom_matcher.rb
class CustomMatcher
  def self.create(class_name, &block)
    klass = Class.new(CustomMatcher)
    klass.send(:define_method, :matcher, &block) if block_given?
    Object.const_set(build_class_name(class_name), klass)
  end
  
  def initialize(expected = nil)
    @expected = expected
  end
  
  def failure_message
    message
  end

  def negative_failure_message
    message(false)
  end
  
  def matcher(target, expected)
    target == expected
  end
  
  def matches?(target)
    @target = target
    if self.method(:matcher).arity == 2
      matcher(@target, @expected)
    else
      matcher(@target)
    end
  end
  
private
  def message(positive = true)
    "#{positive ? 'Expected' : 'Did not expect'} #{@target.inspect} to #{class_display_name} #{@expected.inspect if self.method(:matcher).arity == 2}"
  end
  
  def class_display_name
    self.class.to_s.gsub(/[A-Z]/) {|m| ' ' + m.downcase }.lstrip
  end
  
  def self.build_class_name(class_name)
    class_name.to_s.split('_').map {|s| s.capitalize}.join
  end
end

def matcher(name, context = self.class, &block)
  klass = CustomMatcher.create(name, &block)
  context.send(:define_method, name) { |*args| klass.new(*args) }
end
