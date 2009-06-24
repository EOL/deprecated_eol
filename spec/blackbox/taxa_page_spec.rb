require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Taxa page (HTML)' do

  before(:all) do

    RandomTaxon.delete_all # this should make us green again
    Scenario.load :foundation
    HierarchiesContent.delete_all

    # Long list of items to test:
    begin
      @exemplar        = build_taxon_concept(:id => 910093) # That ID is one of the (hard-coded) exemplars.
    rescue
      #there's already a tc with that id
    end
    @parent          = build_taxon_concept
    @overview        = TocItem.overview
    @overview_text   = 'This is a test Overview, in all its glory'
    # TODO - add a reference to the text object
    @toc_item_2      = TocItem.gen(:view_order => 2)
    @toc_item_3      = TocItem.gen(:view_order => 3)
    @canonical_form  = Factory.next(:species)
    @attribution     = Faker::Eol.attribution
    @common_name     = Faker::Eol.common_name.firstcap
    @scientific_name = "#{@canonical_form} #{@attribution}"
    @italicized      = "<i>#{@canonical_form}</i> #{@attribution}"
    @iucn_status     = Factory.next(:iucn)
    @map_text        = 'Test Map'
    @image_1         = Factory.next(:image)
    @image_2         = Factory.next(:image)
    @image_3         = Factory.next(:image)
    @video_1_text    = 'First Test Video'
    @video_2_text    = 'Second Test Video'
    @video_3_text    = 'YouTube Test Video'
    @comment_1       = 'This is totally awesome'
    @comment_bad     = 'This is totally inappropriate'
    @comment_2       = 'And I can comment multiple times'
    @user            = User.gen

    @taxon_concept   = build_taxon_concept(
       :parent_hierarchy_entry_id => @parent.hierarchy_entries.first.id,
       :rank            => 'species',
       :canonical_form  => @canonical_form,
       :attribution     => @attribution,
       :scientific_name => @scientific_name,
       :italicized      => @italicized,
       :common_name     => @common_name,
       :iucn_status     => @iucn_status,
       :map             => {:description => @map_text},
       :flash           => [{:description => @video_1_text}, {:description => @video_2_text}],
       :youtube         => [{:description => @video_3_text}],
       :comments        => [{:user => @user, :body => @comment_1},{:user => @user, :body => @comment_bad},{:user => @user, :body => @comment_2}],
       # We want more than 10 images, to test pagination, but details don't matter:
       :images          => [{:object_cache_url => @image_1}, {:object_cache_url => @image_2},
                            {:object_cache_url => @image_3}, {}, {}, {}, {}, {}, {}, {}, {}, {}],
       :toc             => [{:toc_item => @overview, :description => @overview_text}, 
                            {:toc_item => @toc_item_2}, {:toc_item => @toc_item_3}])

    @child1        = build_taxon_concept(:parent_hierarchy_entry_id => @taxon_concept.hierarchy_entries.first.id)
    @child2        = build_taxon_concept(:parent_hierarchy_entry_id => @taxon_concept.hierarchy_entries.first.id)
    @id            = @taxon_concept.id

    # This is kind of confusing, but basically the next six lines will cause us to ping a host:
    @ping_url      = 'TEST_with_%ID%'
    @ping_id       = '424242'
    @name          = @taxon_concept.taxon_concept_names.first.name
    @collection    = Collection.gen(:ping_host_url => @ping_url)
    @mapping       = Mapping.gen(:collection => @collection, :name => @name, :foreign_key => @ping_id)
    @ping_url.sub!(/%ID%/, @ping_id) # So we can test that it was replaced by the code.
    
    description       = 'user wants <b>bold</b> and <i>italics</i> and <a href="link">links</a>'
    @description_bold = /user wants <(b|strong)>bold<\/(b|strong)>/
    @description_ital = /and <(i|em)>italics<\/(i|em)>/
    @description_link = /and <a href="link">links<\/a>/
    @taxon_concept.add_user_submitted_text(:description => description, :vetted => true)

    @curator       = Factory(:curator, :curator_hierarchy_entry => @taxon_concept.entry)
    Comment.find_by_body(@comment_bad).hide! User.last
    @result        = RackBox.request("/pages/#{@id}") # cache the response the taxon page gives before changes

  end

  after :all do
    truncate_all_tables
  end

  it 'should be able to ping the collection host' do
    @result.body.should include(@ping_url)
  end

  it 'should show the Overview text by default' do
    @result.body.should have_tag('h3', :text => 'Overview')
    @result.body.should include(@overview_text)
  end

  it 'should NOT show references for the overview text when there aren\'t any' do
    Ref.delete_all ; @taxon_concept.overview[0].refs = [] # Just to make sure nothing shows up.
    @result.body.should_not have_tag('div.references')
  end

  it 'should show references for the overview text (with URL and DOI identifiers ONLY) when present' do
    full_ref = 'This is the reference text that should show up'
    # TODO - When we add "helper" methods to Rails classes for testing, then "add_reference" could be
    # extracted to do this:
    url_identifier = 'some/url.html'
    doi_identifier = '10.12355/foo/bar.baz.230'
    bad_identifier = 'you should not see this identifier'
    @taxon_concept.overview[0].refs << ref = Ref.gen(:full_reference => full_ref)
    # I heard you like RSpec, so we put a lot of tests in your test so you could spec while you're
    # speccing.There are actually a lot of 'tests' in this test.  For one, we're testing that URLs will have http://
    # added to them if they are blank.  We're also testing the regex that pulls DOIs out of potentially
    # messy DOI identifiers:
    ref.add_identifier('url', url_identifier)
    ref.add_identifier('doi', "doi: #{doi_identifier}")
    ref.add_identifier('bad', bad_identifier)
    new_result = RackBox.request("/pages/#{@id}")
    new_result.body.should have_tag('div.references')
    new_result.body.should include(full_ref)
    new_result.body.should have_tag("a[href=http://#{url_identifier}]")
    new_result.body.should_not include(bad_identifier)
    new_result.body.should have_tag("a[href=http://dx.doi.org/#{doi_identifier}]")
  end

  it 'should allow html in user-submitted text' do
    @result.body.should match @description_bold
    @result.body.should match @description_ital
    @result.body.should match @description_link
  end

end

