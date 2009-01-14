require File.dirname(__FILE__) + '/../spec_helper'

describe CuratorsController do
  
  fixtures :users, :hierarchy_entries, :taxon_concepts
  
  before do
    @cafeteria = hierarchy_entries(:h2_cafeteria).taxon_concept
    @chromista = hierarchy_entries(:h2_chromista).taxon_concept
  end
  
  it 'should meet test data dependencies' do
    @cafeteria.should_not be_nil
    @cafeteria.should be_an_instance_of(TaxonConcept)
    @chromista.should_not be_nil
    @chromista.should be_an_instance_of(TaxonConcept)
  end
  
  it 'should allow curation of TaxonConcept with a direct HierarchyEntry reference' do
    user = login_as(:jrice)    
    controller.is_curator(@cafeteria).should be_true
    controller.is_curator(@cafeteria, user).should be_true
  end
  
  it 'should allow curation of TaxonConcept through a parent of a HierarchyEntry reference' do
    user = login_as(:admin)
    @cafeteria.should_not be_nil
    controller.is_curator(@cafeteria).should be_true
    controller.is_curator(@cafeteria, user).should be_true
  end
  
  it 'should not allow curation of TaxonConcept when not logged in' do
    @cafeteria.should_not be_nil
    controller.is_curator(nil).should be_false
    controller.is_curator(nil, nil).should be_false
    controller.is_curator(@cafeteria).should be_false
    controller.is_curator(@cafeteria, nil).should be_false
    controller.is_curator(@cafeteria).should be_false
  end
  
  it 'should defend itself against junk input' do
    controller.is_curator(:boobs).should be_false    
    controller.is_curator('bad', :stuff).should be_false    
  end
  
  it 'should not allow curation of TaxonConcept when the logged in user is not a curator' do
    login_as(:jrice2)
    controller.is_curator(@chromista).should be_false
    controller.is_curator(@cafeteria).should be_false
  end
  
  it 'should not allow curation of TaxonConcept when the logged in user is a curator of a more specific HierarchyEntry' do
    user = login_as(:jrice)
    user.should_not be_nil
    controller.is_curator(@chromista).should be_false
    controller.is_curator(@chromista, user).should be_false
    controller.is_curator(@chromista, nil).should be_false
  end
  
  
  def login_as(user)
    @request.session[:user] = users(user)
  end
  
end
