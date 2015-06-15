require 'spec_helper'

describe CuratorsSuggestedSearch do
 include ApplicationHelper
  before(:all) do
    @mass = KnownUri.gen_if_not_exists({ uri: Rails.configuration.uri_term_prefix + 'mass', name: 'Mass', uri_type_id: UriType.measurement.id })
    @suggested_searches =  5.times{ |i| CuratorsSuggestedSearch.create(label: "label#{i}", uri: @mass)}
  end
  it 'has at least 5 searches' do 
    expect(CuratorsSuggestedSearch.count).to eq(5)
  end

  describe '#suggested_searches' do
    it 'gives'
  end
end
