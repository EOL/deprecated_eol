require 'rspec-custom-matchers'

# a place for us to define our custom matchers
#
# do you want a custom matcher that has prettier 
# and smarter failure messages?  if so, you can 
# make full blown matchers *or* i recommend 
# checking our Spec::Matchers.create.  this is 
# either built into RSpec or is added by Merb.
# eg: http://github.com/wycats/merb/blob/84f61f3976193e38d45e5288609c8056c8e1a56f/merb-core/lib/merb-core/test/matchers/request_matchers.rb
#
module EOL::Spec::Matchers
  extend CustomMatcher::Helper

  matcher(:be_a_curator_of) {|user, clade| user.can_curate? clade }

  matcher(:include) {|array, block| array.include? block }

  class OnlyInclude
    def initialize(fields)
      @expected_fields = fields
    end
    
    def matches?(array)
      @array = array
      @array.sort == @expected_fields.sort
    end
    
    def description
      "only include"
    end
    
    def failure_message
      if @expected_fields.length != @array.length
        "expected to have #{@expected_fields.length} entries, but had #{@array.length}: #{@array.inspect}"
      else
        "expected #{@array.inspect} to include #{(@expected_fields - @array).inspect}"
      end
    end
    
    def negative_failure_message
      " #{@array.inspect} expected to include other entries"
    end
  end

  def only_include(*args)
    OnlyInclude.new args
  end

end
