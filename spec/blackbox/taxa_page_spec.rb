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
                         :comments        => [{:body => @comment_1},{:body => @comment_bad},{:body => @comment_2}],
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

    @curator       = Factory(:curator, :curator_hierarchy_entry => @taxon_concept.entry)
    Comment.find_by_body(@comment_bad).hide!
    @result        = RackBox.request("/pages/#{@id}") # cache the response the taxon page gives before changes

  end

  after :all do
    truncate_all_tables
  end

  it 'should be able to ping the collection host' do
    @result.body.should include(@ping_url)
  end

end

