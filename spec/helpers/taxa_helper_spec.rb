require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

# YOU WERE HERE - fix all the fake Name stuff to use EOL::CommonNameDisplay... 

def add_language_to_name(name, language)
  name[:language_label] = language.label
  name[:language_name] = language.name
  name[:language_id] = language.id
end

def add_name_string_to_name(name)
  name[:name_id]     = name.id
  name[:name_string] = name.string
end

def add_preferred_to_name(name, preferred)
  name[:preferred] = preferred
end

def add_synonym_to_name(name, synonym)
  name[:synonym_id] = synonym.id
end

def add_agent_to_name(name, agent)
  name[:agent_id] = agent.id
end

def build_name(string, agent, language, options = {})
  options[:preferred] ||= '1'
  name = Name.find_by_string(string)
  name = Name.gen(:string => string) unless name
  add_language_to_name(name, language)
  add_agent_to_name(name, @agent)
  add_name_string_to_name(name)
  add_preferred_to_name(name, options[:preferred])
  add_synonym_to_name(name, Synonym.gen(:name => name))
  name[:hierarchy_id] = Hierarchy.eol_contributors.id if options[:curator]
  return EOL::CommonNameDisplay.new(name)
end

def expected_hash_from_name(name)
  {:string     => name.string,
   :synonym_id => name.synonym_id,
   :preferred  => name.preferred == '1',
   :id         => name.id,
   :agent_id   => name.agent_id}
end

# Mimicing what comes out of the helper.  Ick!
def expected_array_from_names_in_language(names, language)
  names_array = []
  names.each do |name|
    names_array << expected_hash_from_name(name)
  end
  [language.label,
   {:names => names_array, :language => {:name => language.name, :label => language.label, :id => language.id}}
  ]
end

describe TaxaHelper do

  before(:all) do
    Scenario.load :foundation
  end
  
#  def render_partial
#    @response = helper.paginate_results(@current_page)
#  end
#  
#  it "should have serp_pagination class present" do
#    @current_page = mock("search mock", :current_page => 1, :total_pages => 1)
#    render_partial
#    @response.should =~ /^<div class="serp_pagination">/
#  end
#  
#  it "should have 5 pages of results present" do
#    @current_page = mock("search mock", :current_page => 1, :total_pages => 5)
#    render_partial
#    @response.should_not =~ /page=1/
#    @response.should =~ /page=2/
#    @response.should =~ /page=3/
#    @response.should =~ /page=4/
#    @response.should =~ /page=5/
#    @response.should_not =~ /page=6/
#  end
#
#  it "should reformat projects into 2 dimentional array" do
#    projects = [1,2,3,4,5]
#    helper.reformat_specialist_projects(projects).should == [[[1,2],[3,4],[5,nil]], 2]
#  end
#
#  it "should create link_text for specialis project" do
#    collection_types = [CollectionType.gen(:label => 'Type1'), CollectionType.gen(:label => 'Type2')]
#    collection = Collection.gen(:title => 'Collection title')
#    collection_types.each do |ct|
#      CollectionTypesCollection.gen(:collection_type => ct, :collection => collection)
#    end
#    helper.specialist_project_collection_link(collection).should == "Type1, Type2"
#    empty_collection = Collection.gen(:title => "Empty Collection")
#    helper.specialist_project_collection_link(empty_collection).should == "Empty Collection"
#  end

  describe "#common_names_by_language" do

    before(:all) do
      @language_a = Language.gen(:label => 'Arabic')
      @language_b = Language.gen(:label => 'Breton')
      @language_c = Language.gen(:label => 'Cydonian')
      @agent      = Agent.gen # Don't care much about this right now.
      @names = []
      # So, this is actually an array created with find_by_sql, and adds a lot of non-names stuff, which we need to handle
      # here:
      @name_a_a_string = 'Aardvark'
      @name_b_a_string = 'Antlion'
      @name_c_a_string = 'Anteater'
      @names << @name_a_a = build_name(@name_a_a_string, @agent, @language_a)
      @names << @name_b_a = build_name(@name_b_a_string,  @agent, @language_b)
      @names << @name_c_a = build_name(@name_c_a_string, @agent, @language_c)
      @expected_array = []
      @expected_array << expected_array_from_names_in_language([@name_a_a], @language_a)
      @expected_array << expected_array_from_names_in_language([@name_b_a], @language_b)
      @expected_array << expected_array_from_names_in_language([@name_c_a], @language_c)
    end

    it "should sort names by language" do
      result = helper.common_names_by_language(@names, @language_a.id)
      result.length.should == @names.length
      result[0][0].should == @language_a.label
      result[0][1].length.should == 1
      result[0][1].first.name_string.should == @name_a_a_string
      result[1][0].should == @language_b.label
      result[1][1].length.should == 1
      result[1][1].first.name_string.should == @name_b_a_string
      result[2][0].should == @language_c.label
      result[2][1].length.should == 1
      result[2][1].first.name_string.should == @name_c_a_string
    end

    it "should put the preferred langauge first" do
      result = helper.common_names_by_language(@names, @language_c.id)
      result[0][0].should == @language_c.label
    end

    it 'should put unknown language last' do
      names = [build_name('Englishman', @agent, Language.unknown)] + @names
      result = helper.common_names_by_language(names, @language_a.id)
      result.last[0].should == Language.unknown.label
    end

    it 'should remove names duplicated by curator entries' do
      names = [build_name(@name_a_a_string, @agent, @language_a, :curator => true)] + @names
      result = helper.common_names_by_language(names, @language_a.id)
      result.length.should == @names.length
    end

  end

end
