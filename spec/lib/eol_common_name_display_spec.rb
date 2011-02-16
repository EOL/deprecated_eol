require File.dirname(__FILE__) + '/../spec_helper'

describe EOL::CommonNameDisplay do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @conributors = Hierarchy.gen
    @agent = Agent.gen
    Name.stub!(:find_by_sql).and_return(fake_data)
    Agent.stub!(:find).with($AGENT_ID_OF_DEFAULT_COMMON_NAME_SOURCE).and_return(@agent)
    Agent.stub!(:find_by_sql).and_return([]) # This forces everything to be from uBio.  :\
    Hierarchy.stub!(:eol_contributors).and_return(@conributors)
    @fake_name = fake_name
    @cnd = EOL::CommonNameDisplay.new(@fake_name)
  end

  it 'should build a last of CNDs by taxon concept id, ignoring duplicate names' do
    EOL::CommonNameDisplay.find_by_taxon_concept_id(1).length.should == 3
  end

  it 'should be created with a special variant of Name' do
  end

  it 'should sort based on name_string' do
    a = EOL::CommonNameDisplay.new(fake_name(:name_string => 'Aaa'))
    b = EOL::CommonNameDisplay.new(fake_name(:name_string => 'Bbb'))
    [b,a].sort.should == [a,b]
  end

  it 'should remove duplicates' do
    EOL::CommonNameDisplay.group_by_name([@cnd, @cnd]).length.should == 1
  end

  it 'should merge sources on duplicates' do
    sources = @cnd.sources
    EOL::CommonNameDisplay.group_by_name([@cnd, @cnd]).first.sources.length.should == sources.length * 2
  end

end

# NOTE - Yes, these YAML outputs are fragile.  But it avoids the database, so it's much faster.  Sorry.  If you change the
# sql, you will have to re-write these tests... but the time you take doing so was saved by all the times this DIDN'T have to
# populate the entire damn DB.  ;)
def fake_name(options = {})
  options[:name_string] ||= 'animals'
  options[:language_id] ||= 152
  options[:language_label] ||= 'English'
  YAML.load(%Q{
!ruby/object:Name 
  attributes: 
    iso_639_1: en
    preferred: "1"
    synonym_id: 
    language_label: #{options[:language_label]}
    vetted_id: "0"
    language_id: "#{options[:language_id]}"
    name_string: #{options[:name_string]}
    name_id: "841736"
    language_name: #{options[:language_label]}
  attributes_cache: {}
  })
end

def fake_data
  YAML.load(%q{
--- 
- !ruby/object:Name 
  attributes: 
    iso_639_1: fr
    preferred: "1"
    synonym_id: 
    language_label: French
    vetted_id: "0"
    language_id: "171"
    name_string: Goodeinae
    name_id: "114507"
    language_name: "fran\xC3\xA7ais"
  attributes_cache: {}

- !ruby/object:Name 
  attributes: 
    iso_639_1: en
    preferred: "1"
    synonym_id: 
    language_label: English
    vetted_id: "0"
    language_id: "152"
    name_string: animals
    name_id: "841736"
    language_name: English
  attributes_cache: {}

# Duplicate, should be (essentially) ignored:
- !ruby/object:Name 
  attributes: 
    iso_639_1: en
    preferred: "1"
    synonym_id: 
    language_label: English
    vetted_id: "0"
    language_id: "152"
    name_string: animals
    name_id: "841736"
    language_name: English
  attributes_cache: {}

- !ruby/object:Name 
  attributes: 
    iso_639_1: en
    preferred: "0"
    synonym_id: 
    language_label: English
    vetted_id: "0"
    language_id: "152"
    name_string: Animal
    name_id: "841737"
    language_name: English
  attributes_cache: {}

  })
end
