require File.dirname(__FILE__) + '/../spec_helper'


def get_media_tab
  get :show, :id => @data[:taxon_concept_id], :section => 'media'
end

describe TaxaController do

  integrate_views

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @first_image = @data[:taxon_concept].images.first
    @first_video = @data[:taxon_concept].videos.first
  end

  it 'should show the media tab' do
    # TODO - we do eventually want this to be /pages/1/media, without a question mark:
    get_media_tab
    response.should have_tag('h1', :text => /media/i)
  end

  it 'should show images for a taxon' do
    get_media_tab
    response.should have_tag('img', :src => /#{ContentServer.cache_url_to_path(@first_image.object_cache_url)}/)
  end

  it 'should show videos for a taxon' do
    get_media_tab
    response.should have_tag('a', :href => /data_objects\/#{@first_video.id}/)
  end

  it 'should show sounds for a taxon'

  it 'should be paginated with 40 items' do
    get_media_tab
    response.should have_tag('ul#media') do
      with_tag('li', :count => 40)
    end
  end

  it 'should sort media by rating'

end
