require File.dirname(__FILE__) + '/../spec_helper'

describe CategoryContentBuilder do
  it 'should filter out names in unknown language if they also exist as names with known language' do 
    Scenario.load :foundation
    ccb = CategoryContentBuilder.new
    agent = Agent.gen
    tc = build_taxon_concept
    cn = "A name"
    tc.add_common_name_synonym(cn, agent, :language => Language.unknown)
    tc.add_common_name_synonym(cn, agent, :language => Language.english)
    res = ccb.content_for(TocItem.common_names, :taxon_concept_id => tc.id)
  end
end
