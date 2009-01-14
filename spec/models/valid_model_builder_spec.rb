require File.dirname(__FILE__) + '/../spec_helper'

describe ValidModelBuilder do

  it 'should have some specs for testing ValidModelBuilder!!!!'

  # Here's a good thing to spec out and fix first ... 
  #
  # if User has :dog as a dependency ...
  #
  # User.create_valid :dog => @some_dog will NOT work!
  #
  # User.create_valid :dog_id => @some_dog.id works
  #
  # we add a :dog argument, but don't override the :dog_id

end
