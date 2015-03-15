require File.dirname(__FILE__) + '/../../spec_helper'

describe Taxa::DataController do
  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @user = User.gen
    @user.grant_permission(:see_data)
    @full = FactoryGirl.create(:curator)
    @master = FactoryGirl.create(:master_curator)
    @admin = User.gen(:admin => true)
    @taxon_concept = build_taxon_concept(:comments => [], :images => [], :flash => [], :youtube => [], :sounds => [], :toc => [], :bhl => [])
    pred = "http://purl.obolibrary.org/obo/UO_0000009"
    m_unit = "http://purl.obolibrary.org/obo/UO_0000009"
    res = Resource.find(2)
    adult = "http://purl.obolibrary.org/obo/PATO_0001185"
    larval = "http://www.ebi.ac.uk/efo/EFO_0001272"
    female = "http://eol.org/schema/terms/female"
    male = "http://eol.org/schema/terms/male"
    mean = "http://semanticscience.org/resource/SIO_001109"
    mode = "http://semanticscience.org/resource/SIO_001111"
    sample_size = "http://eol.org/schema/terms/SampleSize"
    instance = DataMeasurement.new(predicate: pred, object: "100", resource: res, subject: @taxon_concept, unit: m_unit, life_stage: adult, sex: female, statistical_method: mean, normalized_value: "100", normalized_unit: m_unit)
    instance.add_to_triplestore
    instance = DataMeasurement.new(predicate: pred, object: "20", resource: res, subject: @taxon_concept, unit: m_unit, life_stage: adult, sex: male, statistical_method: mean, normalized_value: "20", normalized_unit: m_unit)
    instance.add_to_triplestore        
    instance = DataMeasurement.new(predicate: pred, object: "10", resource: res, subject: @taxon_concept, unit: m_unit, life_stage: "", sex: "", statistical_method: mean, normalized_value: "10", normalized_unit: m_unit)
    instance.add_to_triplestore        
    instance = DataMeasurement.new(predicate: pred, object: "30", resource: res, subject: @taxon_concept, unit: m_unit, life_stage: larval, sex: male, statistical_method: mode, normalized_value: "30", normalized_unit: m_unit)
    instance.add_to_triplestore        
    instance = DataMeasurement.new(predicate: pred, object: "50", resource: res, subject: @taxon_concept, unit: m_unit, life_stage: adult, sex: male, statistical_method: sample_size, normalized_value: "50", normalized_unit: m_unit)
    instance.add_to_triplestore
    @controller = Taxa::DataController.new
    @taxon_page = TaxonPage.new(@taxon_concept)    
    @data = @taxon_page.data.get_data    
    @sorted_array = @controller.send(:sort_data, @data)
  end

  before(:each) do
    session[:user_id] = @user.id
  end

  describe 'GET index' do

    it 'should grant access to users with data privilege' do
      session[:user_id] = @user.id
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
    end

    it 'should allow access if the EolConfig is set' do
      opt = EolConfig.find_or_create_by_parameter('all_users_can_see_data')
      opt.value = 'true'
      opt.save
      session[:user_id] = User.gen.id
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
      session[:user_id] = nil
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
      opt.value = 'false'
      opt.save
    end
    
    it 'should have data point uris' do      
      @data.data_point_uris.length.should > 0
    end
    
    it 'should sorted array differs from the original one' do
      @sorted_array.should_not == @data
    end
    
    it 'should be sorted according to the sex first' do
      sorted_sex_array = @data.sort_by do |a|
        a.context_labels[1].to_s.blank? ? 255.chr : a.context_labels[1].to_s
      end           
      s1_array = @sorted_array.map{|a| a.context_labels[1]}-[nil]
      s2_array = sorted_sex_array.map{|b| b.context_labels[1]}-[nil]          
      s1_array.should == s2_array
    end
    
    it 'should not sort on the life stage without considering the sex first' do
      sorted_life_stage_array = @data.sort_by do |a|
        a.context_labels[0].to_s.blank? ? 255.chr : a.context_labels[0].to_s
      end           
      s1_array = @sorted_array.map{|a| a.context_labels[1]}-[nil]      
      s2_array = sorted_life_stage_array.map{|a| a.context_labels[1]}-[nil]      
      s1_array.should_not == s2_array
    end
    
  end
end
