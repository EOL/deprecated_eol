require File.dirname(__FILE__) + '/../spec_helper'

# NOTE:
# 
# So, TaxonConcept is pretty tightly coupled to HierarchyEntry, so there are lots and lots of references to that model.
# But remember, we're not testing HierarchyEntry, we're testing TaxonConcept (at least, in THIS file), so a lot of these tests will seem weak.
describe Name do
  fixtures :canonical_forms, :names
  
  before(:each) do
    @name = Name.find(names(:cafeteria_long).id)
  end

  it 'should have an italicized canonical form' do
    form = @name.italicized_canonical
    form.should_not be_nil
    @name.canonical_form.string.split.each do |part|
      form.should match(/#{part}/)
    end
  end

  it 'should say "not assigned" when there is no canonical form' do
    @name.canonical_form = nil
    @name.italicized_canonical.should == 'not assigned'
  end
  
  it 'should say "not assigned" when the canonical form has no string' do
    @name.canonical_form.string = nil
    @name.italicized_canonical.should == 'not assigned'
  end
  
  it 'should say "not assigned" when the canonical form has an empty string' do
    @name.canonical_form.string = ''
    @name.italicized_canonical.should == 'not assigned'
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: names
#
#  id                  :integer(4)      not null, primary key
#  canonical_form_id   :integer(4)      not null
#  namebank_id         :integer(4)      not null
#  canonical_verified  :integer(1)      not null
#  italicized          :string(300)     not null
#  italicized_verified :integer(1)      not null
#  string              :string(300)     not null

