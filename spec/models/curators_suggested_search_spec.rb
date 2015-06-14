require 'spec_helper'

render_views
describe CuratorsSuggestedSearch do
  before(:all) do
   @suggested_searches =  5.times{ |i| CuratorsSuggestedSearch.create(label: "label#{i}", uri: KnownUri.gen)}
  end
  it 'has 5 searches' do 
    expect (CuratorsSuggestedSearch.count).to eq(5)
  end
end
