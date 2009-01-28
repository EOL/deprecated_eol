require 'rspec-custom-matchers'

# a place for us to define our custom matchers
module EOL::Spec::Matchers
  extend CustomMatcher::Helper

  matcher(:be_awesome) {|x|
    true # everything is awesome  :P
  }

end
