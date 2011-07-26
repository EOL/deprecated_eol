require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partners' do

  before :all do
    load_foundation_cache
  end

  it 'content partner should have a gallery' do
    user = User.gen(:given_name => 'test_username')
    cp = ContentPartner.gen(:user => user, :display_name => 'gallery_test_agent')
    image = build_data_object('Image', "the image description", :content_partner => cp)

    # the data_object builder doesn't properly associate the image's taxon with the resource, so that's done here
    cp.resources.first.harvest_events.each do |he|
      he.hierarchy_entries << image.hierarchy_entries[0]
    end

    visit("/content_partner/content/#{cp.id}")
    body.should have_tag('div#content_partner_stats', :text => /#{cp.display_name}\s+has contributed to a total of\s+1\s+page/)
    body.should include("pages/#{image.hierarchy_entries[0].taxon_concept.id}")
  end

end

