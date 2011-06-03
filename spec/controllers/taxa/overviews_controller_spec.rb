require File.dirname(__FILE__) + '/../../spec_helper'

def do_show
  get :show, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::OverviewsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
  end

  describe 'GET show' do

    it 'should instantiate the taxon concept' do
      do_show
      assigns[:taxon_concept].should be_a(TaxonConcept)
    end
    it 'should instantiate summary text' do
      do_show
      assigns[:summary_text][0].should be_a(DataObject)
    end
    it 'should instantiate summary media' do
      do_show
      assigns[:media][0].should be_a(DataObject)
    end
    it "should instantiate a feed item for the taxon and current user" do
      do_show
      assigns[:feed_item].should be_a(FeedItem)
    end
    it 'should instantiate an assistive header' do
      do_show
      assigns[:assistive_section_header].should be_a(String)
    end
  end

end
