require File.dirname(__FILE__) + '/../spec_helper'
require "rake"

describe 'Sitemaps' do
  before(:all) do
    truncate_all_tables
    load_foundation_cache
    
    License.destroy_all
    ContentPage.destroy_all
    Community.destroy_all
    Collection.destroy_all
    ContentPartner.destroy_all
    User.destroy_all
    TaxonConcept.destroy_all
    DataObject.destroy_all
    
    @objects_to_include = []
    @objects_to_exclude = []
    @objects_to_include << ContentPage.gen(:page_name => 'test_page_active', :active => true)
    @objects_to_exclude << ContentPage.gen(:page_name => 'test_page_inavtive', :active => false)
    @objects_to_include << Community.gen(:published => true)
    @objects_to_exclude << Community.gen(:published => false)
    @objects_to_include << Collection.gen(:published => true)
    @objects_to_exclude << Collection.gen(:published => false)
    @objects_to_include << ContentPartner.gen(:public => true)
    @objects_to_exclude << ContentPartner.gen(:public => false)
    @objects_to_include << User.gen(:active => true)
    @objects_to_exclude << User.gen(:active => false)
    @objects_to_exclude << User.gen(:active => true, :hidden => true)
    taxon_concept = TaxonConcept.gen(:published => true, :vetted_id => Vetted.trusted.id)
    @objects_to_include << taxon_concept
    @objects_to_exclude << TaxonConcept.gen(:published => false, :vetted_id => Vetted.trusted.id)
    @objects_to_exclude << TaxonConcept.gen(:supercedure_id => taxon_concept.id, :vetted_id => Vetted.trusted.id)
    
    @cc_license = License.gen(:title => 'cc-by-sa 1.0', :source_url => 'http://creativecommons.org/licenses/by-sa/1.0/')
    @non_cc_license = License.gen(:title => 'not applicable', :source_url => 'http://who.cares')
    @published_image_cc_license = DataObject.gen(:data_type => DataType.image, :license => @cc_license, :published => 1, :object_cache_url => '201201190911111')
    @published_image_non_cc_license = DataObject.gen(:data_type => DataType.image, :license => @non_cc_license, :published => 1, :object_cache_url => '201201190922222')
    @unpublished_image = DataObject.gen(:data_type => DataType.image, :license => @cc_license, :published => 0, :object_cache_url => '201201190933333')
    
    @rake = Rake::Application.new
    Rake.application = @rake
    load Rails.root + 'lib/tasks/sitemap.rake'
    Rake::Task.define_task(:environment)
  end
  
  it 'should be able to create txt sitemaps' do
    @rake['sitemap:destroy'].execute
    @rake['sitemap:build'].execute
    sitemap_contents = File.open(File.join(RAILS_ROOT, 'public', 'sitemap', 'sitemap_1.txt')).read
    @objects_to_include.each do |obj|
      urls_for_object(obj).each do |url|
        sitemap_contents.should include(url)
      end
    end
    @objects_to_exclude.each do |obj|
      urls_for_object(obj).each do |url|
        sitemap_contents.should_not include(url)
      end
    end
  end
  
  it 'should be able to destroy sitemaps' do
    @rake['sitemap:destroy'].execute
    @rake['sitemap:build'].execute
    # we only care about files with extensions - so ignore all directories
    Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', '*.*')).should_not be_empty
    @rake['sitemap:destroy'].execute
    Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', '*.*')).should be_empty
  end
  
  it 'should be able to create xml sitemaps' do
    @rake['sitemap:destroy'].execute
    @rake['sitemap:build_xml'].execute
    sitemap_contents = File.open(File.join(RAILS_ROOT, 'public', 'sitemap', 'sitemap_1.xml')).read
    @objects_to_include.each do |obj|
      urls_for_object(obj).each do |url|
        sitemap_contents.should include(url)
      end
    end
    @objects_to_exclude.each do |obj|
      urls_for_object(obj).each do |url|
        sitemap_contents.should_not include(url)
      end
    end
  end
  
  # Following tests are for image sitemaps
  it 'should be able to create xml image sitemaps' do
    @rake['sitemap:destroy_images'].execute
    @rake['sitemap:build_images_xml'].execute
    sitemap_contents = File.open(File.join(RAILS_ROOT, 'public', 'sitemap', 'images', 'sitemap_1.xml')).read
    
    sitemap_contents.should include(DataObject.image_cache_path(@published_image_cc_license.object_cache_url, '580_360', $SINGLE_DOMAIN_CONTENT_SERVER))
    sitemap_contents.should include(@published_image_cc_license.license.source_url)
    sitemap_contents.should include(DataObject.image_cache_path(@published_image_non_cc_license.object_cache_url, '580_360', $SINGLE_DOMAIN_CONTENT_SERVER))
    
    sitemap_contents.should_not include(@published_image_non_cc_license.license.source_url)
    sitemap_contents.should_not include(DataObject.image_cache_path(@unpublished_image.object_cache_url, '580_360', $SINGLE_DOMAIN_CONTENT_SERVER))
  end
  
  it 'should be able to destroy image sitemaps' do
    @rake['sitemap:destroy_images'].execute
    @rake['sitemap:build_images_xml'].execute
    # we only care about files with extensions - so ignore all directories
    Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', 'images', '*.*')).should_not be_empty
    @rake['sitemap:destroy_images'].execute
    Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', 'images', '*.*')).should be_empty
  end
  
  
end

def urls_for_object(object)
  # eol.org is hardcoded as the host in the library. I couldn't figure out a nice way
  # to get the current host from within a library or rake task
  urls = []
  if object.class == ContentPage
    urls << EOL::URLHelper.get_url('cms_page_url', object.page_name, :host => 'eol.org')
  elsif object.class == Collection
    urls << EOL::URLHelper.get_url('collection_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('collection_newsfeed_url', object.id, :host => 'eol.org')
  elsif object.class == Community
    urls << EOL::URLHelper.get_url('community_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('community_newsfeed_url', object.id, :host => 'eol.org')
  elsif object.class == ContentPartner
    urls << EOL::URLHelper.get_url('content_partner_url', object.id, :host => 'eol.org')
  elsif object.class == TaxonConcept
    urls << EOL::URLHelper.get_url('taxon_overview_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_details_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_media_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_maps_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_names_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_communities_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_resources_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_literature_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('taxon_updates_url', object.id, :host => 'eol.org')
  elsif object.class == User
    urls << EOL::URLHelper.get_url('user_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('user_newsfeed_url', object.id, :host => 'eol.org')
    urls << EOL::URLHelper.get_url('user_activity_url', object.id, :host => 'eol.org')
  end
  return urls
end
