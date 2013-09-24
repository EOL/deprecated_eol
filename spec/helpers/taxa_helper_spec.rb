require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

def add_language_to_name(name, language)
  name[:language_label] = language.label
  name[:language_name] = language.source_form
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
  name[:synonym_ids] = [synonym.id]
end

def add_agent_to_name(name, agent)
  name[:agent_id] = agent.id
end

def build_name(string, agent, language, options = {})
  options[:preferred] ||= 1
  name = Name.find_by_string(string)
  name = Name.gen(:string => string) unless name
  hierarchy_id = Hierarchy.eol_contributors.id if options[:curator]
  hierarchy_id ||= Hierarchy.first.id
  
  synonym = Synonym.gen(:name => name, :preferred => options[:preferred],
    :hierarchy_id => hierarchy_id, :language => language)
  AgentsSynonym.gen(:synonym => synonym, :agent => agent)
  tcn = TaxonConceptName.gen(:name => name, :synonym => synonym, :preferred => synonym.preferred, :language => synonym.language, :vern => 1)
  return EOL::CommonNameDisplay.new(tcn)
end

describe TaxaHelper do

  before(:all) do
    load_foundation_cache
  end

  describe "#common_names_by_language" do

    before(:all) do
      @language_a = Language.gen_if_not_exists(:label => 'Arabic')
      @language_b = Language.gen_if_not_exists(:label => 'Breton')
      @language_c = Language.gen_if_not_exists(:label => 'Cydonian')
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

    it "should put the preferred language first" do
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
