require "spec_helper"

describe EOL::CommonNameDisplay do

  before(:all) do
    load_foundation_cache
    Language.gen_if_not_exists(iso_639_1: 'en')
    Language.gen_if_not_exists(label: 'Unknown')
    Hierarchy.gen_if_not_exists(label: "Encyclopedia of Life Contributors")
    Visibility.gen_if_not_exists(label: 'visible')
    @fake_name = fake_name
    @cnd = EOL::CommonNameDisplay.new(@fake_name)
  end

  it 'should build a last of CNDs by taxon concept id, ignoring duplicate names' do
    TaxonConceptName.gen(taxon_concept_id: 1, vern: 1, language: Language.english)
    TaxonConceptName.gen(taxon_concept_id: 1, vern: 1, language: Language.english)
    TaxonConceptName.gen(taxon_concept_id: 1, vern: 1, language: Language.english)
    EOL::CommonNameDisplay.find_by_taxon_concept_id(1).length.should == 3
  end

  it 'should be created with a special variant of Name' do
  end
  
  it 'should sort based on name_string' do
    a = EOL::CommonNameDisplay.new(fake_name(name_string: 'Aaa'))
    b = EOL::CommonNameDisplay.new(fake_name(name_string: 'Bbb'))
    [b,a].sort.should == [a,b]
  end
  
  it 'should remove duplicates' do
    EOL::CommonNameDisplay.group_by_name([@cnd, @cnd]).length.should == 1
  end
  
  it 'should merge sources on duplicates' do
    agents = @cnd.agents
    EOL::CommonNameDisplay.group_by_name([@cnd, @cnd]).first.agents.length.should == agents.length * 2
  end

end

# NOTE - Yes, these YAML outputs are fragile.  But it avoids the database, so it's much faster.  Sorry.  If you change the
# sql, you will have to re-write these tests... but the time you take doing so was saved by all the times this DIDN'T have to
# populate the entire damn DB.  ;)
def fake_name(options = {})
  options[:name_string] ||= 'animals'
  options[:language_id] ||= 152
  name = Name.find_or_create_by_string(options[:name_string])
  syn = Synonym.gen(name: name,
    language_id: options[:language_id], preferred: 1, hierarchy: Hierarchy.eol_contributors)
  TaxonConceptName.gen(synonym: syn, name: name, language_id: options[:language_id], preferred: 1, 
    vern: 1)
#   options[:name_string] ||= 'animals'
#   options[:language_id] ||= 152
#   options[:language_label] ||= 'English'
#   YAML.load(%Q{
# !ruby/object:Name 
#   attributes: 
#     iso_639_1: en
#     preferred: "1"
#     synonym_id: 
#     language_label: #{options[:language_label]}
#     vetted_id: "0"
#     language_id: "#{options[:language_id]}"
#     name_string: #{options[:name_string]}
#     name_id: "841736"
#     language_name: #{options[:language_label]}
#   attributes_cache: {}
#   })
end
