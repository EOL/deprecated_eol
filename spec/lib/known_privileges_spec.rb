require 'spec_helper'

# NOTE: I don't want to handle ALL of the known privileges here.  So the tests are a bit flexible and just make sure that the
# lib basically works the way it's intended.
describe KnownPrivileges do

  before(:all) do
    Privilege.delete_all
  end

  it 'should have a list of community priv defs' do
    KnownPrivileges.community.length.should >= 10
  end

  it 'should have a list of special priv defs' do
    KnownPrivileges.special.length.should >= 10
  end

  it 'should have a long list of symbols' do
    syms = KnownPrivileges.symbols
    syms.length.should >= 20
    syms.each do |s|
      s.should be_a Symbol
    end
  end

  it 'should create all of those privileges' do
    Privilege.count.should == 0
    KnownPrivileges.create_all
    Privilege.count.should >= 20
  end

end

