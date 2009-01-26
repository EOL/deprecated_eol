require File.dirname(__FILE__) + '/../spec_helper'

describe RandomTaxon do
  
  it 'should return ten unique, random taxa on call to random_set' do
    list = RandomTaxon.random_set
    assert 10, list.length
    copy = list.clone
    while taxon = copy.shift do
      assert_kind_of RandomTaxon, taxon
      assert_not_nil taxon.name_id
      assert_not_nil taxon.image_url
      assert_not_nil taxon.thumb_url
      assert_not_nil taxon.name
      assert_not_nil taxon.quick_common_name
      assert_not_nil taxon.quick_scientific_name
      assert !(copy.find {|item| item.name == taxon.name}), 'Found duplicate in random taxon set'
    end
  end

  it 'should only return five random taxa when an argument of 5 is passed to get_random_taxa' do
    list = RandomTaxon.random_set(5)
    assert 5, list.length
  end
  
end

describe RandomTaxon, 'with fixtures' do

  fixtures :taxa, :hierarchy_entries

  before(:each) do
    @cafeteria = RandomTaxon.find_by_name_id(taxa(:cafeteria_taxon_1).name_id)
  end

  it 'should have a taxon_concept_id' do
    @cafeteria.taxon_concept_id.should == hierarchy_entries(:roenbergensis).taxon_concept_id
  end


end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: random_taxa
#
#  id               :integer(4)      not null, primary key
#  data_object_id   :integer(4)      not null
#  language_id      :integer(4)      not null
#  name_id          :integer(4)      not null
#  taxon_concept_id :integer(4)
#  common_name_en   :string(255)     not null
#  common_name_fr   :string(255)     not null
#  content_level    :integer(4)      not null
#  image_url        :string(255)     not null
#  name             :string(255)     not null
#  thumb_url        :string(255)     not null
#  created_at       :timestamp       not null

