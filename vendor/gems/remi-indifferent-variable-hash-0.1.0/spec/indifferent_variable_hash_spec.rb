require File.dirname(__FILE__) + '/spec_helper'

describe IndifferentVariableHash do

  it "obviously, classes and instances shouldn't have these features without including IndifferentVariableHash" do
    klass    = Class.new
    instance = klass.new

    lambda { instance.variables }.should raise_error(NoMethodError, /undefined method `variables'/)
    lambda { instance.foo       }.should raise_error(NoMethodError, /undefined method `foo'/)

    lambda { klass.variables    }.should raise_error(NoMethodError, /undefined method `variables'/)
    lambda { klass.foo          }.should raise_error(NoMethodError, /undefined method `foo'/)
  end

  it 'should add a in indifferent hash of variables to instances of a class' do
    klass    = Class.new { include IndifferentVariableHash }
    instance = klass.new

    instance.variables.should be_a_kind_of(Hash)
    instance.foo.should be_nil
    instance.foo = 'Hello There'
    instance.foo.should == 'Hello There'

    # klass should *not* have variables, just instances
    lambda { klass.variables }.should raise_error(NoMethodError, /undefined method `variables'/)
  end

  it 'should add a in indifferent hash of variables to a class' do
    klass    = Class.new { extend IndifferentVariableHash }
    instance = klass.new

    klass.variables.should be_a_kind_of(Hash)
    klass.foo.should be_nil
    klass.foo = 'Hello There'
    klass.foo.should == 'Hello There'

    # instance should *not* have variables, just instances
    lambda { instance.variables }.should raise_error(NoMethodError, /undefined method `variables'/)
  end

  it 'should add a in indifferent hash of variables to a class and instances of the same class' do
    klass    = Class.new { extend IndifferentVariableHash; include IndifferentVariableHash }
    instance = klass.new

    [ klass, instance ].each do |obj|
      obj.variables.should be_a_kind_of(Hash)
      obj.foo.should be_nil
      obj.foo = 'Hello There'
      obj.foo.should == 'Hello There'
    end
  end

  it 'should be easy[-ish] to give your own custom name for the hash variable' do
    klass = Class.new { extend IndifferentVariableHash }
    klass.foo = 'Hello There'

    klass.foo.should == 'Hello There'
    klass.variables.foo.should == 'Hello There'

    klass.instance_eval { alias config variables } # just add an alias!  nothing custom needed to do this.
    klass.config.foo.should == 'Hello There'
    klass.config['foo'].should == 'Hello There'
    klass.config[:foo].should == 'Hello There'
  end

  it 'should not make *all* Hashes indifferent' do
    custom_hash = IndifferentVariableHash::Hash.new
    custom_hash.foo.should be_nil
    custom_hash.foo = 'bar'
    custom_hash.foo.should == 'bar'

    regular_hash = Hash.new
    lambda { regular_hash.foo }.should raise_error(NoMethodError, /undefined method `foo'/)
  end

  it "should really be 'indifferent' (shouldn't matter whether a string or a symbol is used)" do
    custom_hash = IndifferentVariableHash::Hash.new
    
    custom_hash.foo = 'bar'
    custom_hash.foo.should == 'bar'
    custom_hash['foo'].should == 'bar'
    custom_hash[:foo].should == 'bar'

    custom_hash[:foo] = 'BAR'
    custom_hash.foo.should == 'BAR'
    custom_hash['foo'].should == 'BAR'
    custom_hash[:foo].should == 'BAR'
  end

end
