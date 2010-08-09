RSpec Custom Matchers
=====================

This gem makes it really easy to define your own 
RSpec custom matchers in 1 line of code.

This class / project is created by [xdotcommer][].  
I forked it to make it an easy-to-install RubyGem


Install
-------

    sudo gem install remi-rspec-custom-matchers -s http://gems.github.com

Usage
-----

Wherever you want to include the `matcher` method, `include CustomMatcher::Helper`

Remember, if you want to be able to call `matcher(:foo)` in the body of a class, 
you might want to `extend CustomMatcher::Helper` instead of including it.

Personally, I like to keep all of my own custom matchers for a project in 
a module, so I do ...

    require 'rspec-custom-matchers'

    module MyMatchers
      extend CustomMatcher::Helper

      matcher(:be_divisible_by) { |number, divisor| number % divisor == 0 }
      matcher(:be_even)         { |even| even % 2 == 0 }
      matcher(:be_odd)          { |odd|  odd % 2 != 0  }
      matcher(:be_equal_to)
    end

and then, in my `spec_helper.rb`

    require 'my_matchers'

    Spec::Runner.configure do |config|
      config.include MyMatchers # this will make the matchers available to your specs
    end

That's how I do it!


[xdotcommer]:  http://github.com/xdotcommer
