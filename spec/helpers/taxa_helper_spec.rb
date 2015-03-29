require "spec_helper"

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

  it 'should format data values' do
    expect(helper.format_data_value('111.1111')).to eq('111.11')
    expect(helper.format_data_value('1111.1111')).to eq('1,111.11')
    expect(helper.format_data_value('1000')).to eq('1,000')
    expect(helper.format_data_value('1000.0')).to eq('1,000.0')
    expect(helper.format_data_value('0.111')).to eq('0.11')
    expect(helper.format_data_value('0.0111')).to eq('0.0111')
    expect(helper.format_data_value('0.00111')).to eq('0.00111')
    expect(helper.format_data_value('0.000111')).to eq('0.000111')
    expect(helper.format_data_value('0.0000111')).to eq('1.11e-05')
    expect(helper.format_data_value('0.00000111')).to eq('1.11e-06')
    expect(helper.format_data_value('test')).to eq('test')
    expect(helper.format_data_value('test', capitalize: true)).to eq('Test')
    expect(helper.format_data_value('test with http://www.eol.org links')).
      to eq('test with <a href="http://www.eol.org">http://www.eol.org</a> links')
    expect(helper.format_data_value('test with www.eol.org links')).
      to eq('test with <a href="http://www.eol.org">www.eol.org</a> links')
  end

  it 'keeps the format of the verbatim known uris' do
    known_uri = KnownUri.gen_if_not_exists(uri: Rails.configuration.uri_term_prefix+"verbatim_uri", value_is_verbatim: true)
    expect(helper.format_data_value('14444444.9999999', value_for_known_uri: known_uri)).to eq('14444444.9999999')
  end

  it 'should have superscript if the known uri has karat' do
    expect(helper.adjust_exponent("kilometers^2")).to match(/<sup[ >]/)
  end

end
