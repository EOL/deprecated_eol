require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../scenario_helpers'

describe License do

  before(:all) do
    load_foundation_cache
  end

  it 'should not require rights for public domain' do
    License.public_domain.show_rights_holder?.should_not be_true
  end
  
  it 'should not require rights for no-known-restrictions' do
    License.no_known_restrictions.show_rights_holder?.should_not be_true
  end
  
  it 'should require rights for cc' do # and all the rest, but I don't care to check them all.
    License.cc.show_rights_holder?.should be_true
  end
  
end
