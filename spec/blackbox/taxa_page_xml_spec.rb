require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

require File.dirname(__FILE__) + '/../../lib/eol_data'
class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data

describe 'Taxa page XML' do

  before(:all) do
    truncate_all_tables # Please don't nest this in an "if find 910093" block; there is something else that
                        # causes this to fail, and I've wasted enough time figuring out this fixed it to dig
                        # into which table(s) need clearing.
    Scenario.load :foundation # Here instead of earlier because of the truncating logic just above.
    HierarchiesContent.delete_all
    @exemplar        = build_taxon_concept(:id => 910093) # That ID is one of the (hard-coded) exemplars.
    @parent          = build_taxon_concept
    @overview        = TocItem.overview
    @overview_text   = 'This is a test Overview, in all its glory'
    @toc_item_2      = TocItem.gen(:view_order => 2)
    @toc_item_3      = TocItem.gen(:view_order => 3)
    @canonical_form  = Factory.next(:species)
    @search_term     = @canonical_form.split[0]
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
                         :common_names    => [@common_name],
                         :iucn_status     => @iucn_status,
                         :map             => {:description => @map_text},
                         :flash           => [{:description => @video_1_text}, {:description => @video_2_text}],
                         :youtube         => [{:description => @video_3_text}],
                         :comments        => [{:body => @comment_1},{:body => @comment_bad},{:body => @comment_2}],
                         # We want more than 10 images, to test pagination, but details don't matter:
                         :images          => [{:object_cache_url => @image_1}, {:object_cache_url => @image_2},
                                              {:object_cache_url => @image_3},
                                              {}, {}, {}, {}, {}, {}, {}, {}, {}, {}],
                         :toc             => [{:toc_item => @overview, :description => @overview_text}, 
                                              {:toc_item => @toc_item_2}, {:toc_item => @toc_item_3}])
    @child1        = build_taxon_concept(:parent_hierarchy_entry_id => @taxon_concept.hierarchy_entries.first.id)
    @child2        = build_taxon_concept(:parent_hierarchy_entry_id => @taxon_concept.hierarchy_entries.first.id)
    @id            = @taxon_concept.id
    @images        = @taxon_concept.images
    @curator       = build_curator(@taxon_concept)
    Comment.find_by_body(@comment_bad).hide! User.last
  end

  after :all do
    truncate_all_tables
  end

  describe 'single taxon' do

    before(:all) do
      # Saves us time if we only make these requests once, so we can test the results multiple times:
      @taxon_concept_xml = Nokogiri::XML(RackBox.request("/pages/#{@taxon_concept.id}.xml").body)
    end

    it 'should serve valid XML on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page').should_not be_empty
    end

    it 'should serve the TaxonConcept with ID NNN on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page/id').first.content.should == @id.to_s
    end

    it 'should include canonical-form on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page/canonical-form').first.content.should == @canonical_form
    end
    
    it 'should include common-names on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page/common-names/item').map { |cn|
        cn.xpath('string').first.content
      }.should == @taxon_concept.all_common_names.map(&:string)
    end

    it 'should include iucn-conservation-status on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page/iucn-conservation-status').first.content.should == @iucn_status
    end

    it 'should include scientific-name on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page/scientific-name').first.content.should == @italicized
    end

    it 'should include overview on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page/overview//description').first.content.should == @overview_text
    end

    it 'should include table-of-contents on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('/taxon-page/table-of-contents/item').map { |ti|
        ti.xpath('label').first.content
      }.should == @taxon_concept.toc.map(&:label)
    end

    it 'should include ancestors on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('//ancestors/taxon-page/id').map { |i| i.content }.should ==
        @taxon_concept.ancestors.map {|a| a.id.to_s }
    end

    # Sorted because order is irrelevant.
    it 'should include children on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('//children/taxon-page/id').map { |i| i.content }.sort.should ==
        @taxon_concept.children.map {|a| a.id.to_s }.sort
    end

    # Sorted because order is irrelevant.
    it 'should include curators on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('//curators/user/id').map { |i| i.content }.sort.should ==
        @taxon_concept.curators.map {|c| c.id.to_s }.sort
    end

    it 'should include comments/count on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('//comments/count').first.content.should == @taxon_concept.comments.length.to_s
    end

    it 'should include images/count on call to /pages/NNN.xml' do
      @taxon_concept_xml.xpath('//images/count').first.content.should == @taxon_concept.images.length.to_s
    end

   it 'should include videos/count on call to /pages/NNN.xml' do
     @taxon_concept_xml.xpath('//videos/count').first.content.should == @taxon_concept.videos.length.to_s
   end

  end


  describe 'images' do

    before(:all) do
      # Saves us time if we only make these requests once, so we can test the results multiple times:
      @images_xml = Nokogiri::XML(RackBox.request("/pages/#{@taxon_concept.id}/images/1.xml").body)
    end

    it 'should return a page of images XML on call to /pages/NNN/images/1.xml' do
      @images_xml.xpath('//images').should_not be_empty
      @images_xml.xpath('//images/image').length.should == 10
    end

    it 'should return second page of images XML on call to /pages/NNN/images/2.xml' do
      # If these two tests are failing, something is wrong with build_taxon_concept.  They must pass for the rest of
      # this test to be valid:
      @taxon_concept.images.length.should > 10
      @taxon_concept.images.length.should < 21
      images_xml_page_2 = Nokogiri::XML(RackBox.request("/pages/#{@taxon_concept.id}/images/2.xml").body)
      images_xml_page_2.xpath('//images').should_not be_empty
      images_xml_page_2.xpath('//images/image').length.should == @taxon_concept.images.length - 10
    end

  end
  
  # Sure, I could test pagination on videos, but I'm going out on a limb and claiming that if one works, the other
  # will, too.
  describe 'videos' do

    before(:all) do
      # Saves us time if we only make these requests once, so we can test the results multiple times:
      @videos_xml = Nokogiri::XML(RackBox.request("/pages/#{@taxon_concept.id}/videos/1.xml").body)
    end

    # This assumes there are LESS than 11 videos on our example TC:
    it 'should return a page of videos XML on call to /pages/NNN/videos/1.xml' do
      @videos_xml.xpath('//videos').should_not be_empty
      @videos_xml.xpath('//videos/video').length.should == @taxon_concept.videos.length
    end

  end

  describe('caching') do

    before(:all) do
      @old_cache_val = ActionController::Base.perform_caching
      ActionController::Base.perform_caching = true
      Rails.cache.clear
    end
    after(:all) do
      ActionController::Base.perform_caching = @old_cache_val
    end

    it 'should cache XML on call to /pages/NNN.xml' do
      # I need to do this to ensure we can capture the to_xml call (to_s is called in the controller in this case):
      TaxonConcept.should_receive(:find).with(@id).at_least(1).times.and_return(@taxon_concept)
      @taxon_concept.should_receive(:to_xml).exactly(1).times.and_return(
        '<?xml version="1.0" encoding="UTF-8"?>\n<taxon-page>Not Empty</taxon-page>\n'
      )
      Nokogiri::XML(RackBox.request("/pages/#{@id}.xml").body).xpath('//taxon-page').should_not
        be_empty
      Nokogiri::XML(RackBox.request("/pages/#{@id}.xml").body).xpath('//taxon-page').should_not
        be_empty
    end

    it 'should cache XML on call to /pages/NNN/images/2.xml' do
      # I need to do this to ensure we can capture the to_xml call:
      TaxonConcept.should_receive(:find).with(@id.to_s).at_least(1).times.and_return(@taxon_concept)
      @taxon_concept.should_receive(:images).exactly(1).times.and_return(@images)
      Nokogiri::XML(RackBox.request("/pages/#{@id}/images/2.xml").body).xpath('//images').should_not
        be_empty
      Nokogiri::XML(RackBox.request("/pages/#{@id}/images/2.xml").body).xpath('//images').should_not
        be_empty
    end

    it "should cache XML on call to /search.xml?q=#{@search_term}" do
      # This hash was just literally copy/pasted from the console (but the ID was changed):
      TaxonConcept.should_receive(:quick_search).with(@search_term, :search_language => '*').exactly(1).times.
        and_return(
          { :common=>[{"preferred"=>"1", "is_vern"=>"1", "matching_italicized_string"=>"frizzlebek[5]",
            "id"=>"#{@id}", "content_level"=>nil, "hierarchy_id"=>"2", "matching_string"=>"frizzlebek[5]"}],
            :scientific=>[], :errors=>nil }
        )
      Nokogiri::XML(RackBox.request("/search.xml?q=#{@search_term}").body).xpath('//taxon-pages').should_not
        be_empty
      Nokogiri::XML(RackBox.request("/search.xml?q=#{@search_term}").body).xpath('//taxon-pages').should_not
        be_empty
    end

  end

  describe 'search' do

    before(:all) do
      EOL::NestedSet.make_all_nested_sets
      recreate_normalized_names_and_links
      @raw_xml    = RackBox.request("/search.xml?q=#{@search_term}").body
      @search_xml = Nokogiri::XML(@raw_xml)
    end

    it 'should be valid XML' do
      @search_xml.xpath('//taxon-pages').should_not be_empty
    end

    it 'should have the ID of our expected TC as a result' do
      #<?xml version=\"1.0\" encoding=\"UTF-8\"?>
      #<results>
      #<taxon-pages type=\"array\">
      #<taxon-page>
      #<id type=\"integer\">2</id>
      #<canonical-form>Autemalius utsimiliqueesi[21]</canonical-form>
      #<common-name>Pink quomolestiaeerox</common-name>
      #<iucn-conservation-status>Endangered (EN)</iucn-conservation-status>
      #<scientific-name>&lt;i&gt;Autemalius utsimiliqueesi[21]&lt;/i&gt; E. Friesen</scientific-name>
      #</taxon-page>
      #</taxon-pages>
      #</results>
      @search_xml.xpath('//taxon-pages/taxon-page/id').should_not be_empty
    end

  end

  describe 'empty search' do

    before(:all) do
      EOL::NestedSet.make_all_nested_sets
      recreate_normalized_names_and_links
    end

    it 'should be valid XML with empty result set for no parameter or non-result searches' do

      @raw_xml    = RackBox.request("/search.xml").body
      @search_xml = Nokogiri::XML(@raw_xml)
      @search_xml.xpath('//results').should_not be_empty
      @search_xml.xpath('//taxon-pages').should be_empty

      @raw_xml    = RackBox.request("/search.xml?q=bogusness").body
      @search_xml = Nokogiri::XML(@raw_xml)
      @search_xml.xpath('//results').should_not be_empty

    end

  end
  
  describe 'exemplars' do

    before(:all) do
      EOL::NestedSet.make_all_nested_sets
      recreate_normalized_names_and_links
      @raw_xml    = RackBox.request("/exemplars.xml").body
      @exemplar_xml = Nokogiri::XML(@raw_xml)
    end

    it 'should be valid XML' do
      @exemplar_xml.xpath('//taxon-pages').should_not be_empty
    end

    it 'should have the ID of our expected TC as a result' do
      @exemplar_xml.xpath('//taxon-pages/taxon-page/id').should_not be_empty
      @exemplar_xml.xpath('//taxon-pages/taxon-page/id').first.content.should == @exemplar.id.to_s
    end

  end

end
