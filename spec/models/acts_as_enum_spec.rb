# TODO move into plugin ...
#
# NOTE this is just a little thing i'm using to give our :id/:label models a bit more common functionality.
#      really, a plugin shouldn't use an apps models ... but i'm doing that here to save some time  :/
#
require File.dirname(__FILE__) + '/../spec_helper'

describe ActsAsEnum do

  before do
    @enum_model = AgentRole
    @enum_model.delete_all
  end

  it 'should have an id and label' do
    @enum_model.column_names.should include('id')
    @enum_model.column_names.should include('label')
  end

  it 'single item should be accessible via [] indexer' do
    @enum_instance = @enum_model.create! :label => 'Neato'
    @enum_model.find_by_label('Neato').should == @enum_instance

    @enum_model['Neato'].should == @enum_instance
    @enum_model['Neatoo'].should be_nil

    @enum_model[:Neato].should == @enum_instance
    @enum_model[:Neatoo].should be_nil
  end

  it 'multiple items should be accessible via [] indexer' do
    @enum_instance1 = @enum_model.create! :label => 'Foo'
    @enum_instance2 = @enum_model.create! :label => 'Bar'

    @enum_model[:Foo, :Bar].length.should == 2
    @enum_model[:Foo, :Bar].should include(@enum_instance1)
    @enum_model[:Foo, :Bar].should include(@enum_instance2)

    @enum_model[:Foo, :Bar, :NoExist, nil].length.should == 2
    @enum_model[:Foo, :Bar, :NoExist, nil].should == @enum_model[:Foo, :Bar]
  end

=begin
# could be nice, but definitely not needed - not including!
  it 'single item should be accessible as a singleton "method"' do
    @enum_instance = @enum_model.create! :label => 'Neato'
    @enum_model.find_by_label('Neato').should == @enum_instance

    @enum_model.Neato.should == @enum_instance
    lambda { @enum_model.Neatoo }.should raise_error(NoMethodError)
  end
=end

end
