require File.dirname(__FILE__) + '/../../spec_helper'

def details_do_show
  get :show, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::DetailsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
  end

  describe 'GET show' do

    it 'should instantiate the taxon concept' do
      details_do_show
      assigns[:taxon_concept].should be_a(TaxonConcept)
    end
    it 'should instantiate the details Array containing text data objects and special content' do
      details_do_show
      assigns[:details].should be_a(Array)
      datos = assigns[:details].collect{|h| h[:data_objects]}.compact.flatten
      datos.take_while{|d| d.should be_a(DataObject)}.should == datos
      # Content summary is example of 'special content'
      content_summary = assigns[:details].collect{|h| h if h[:content_type] == 'content_summary'}.compact
      content_summary[0][:items][0].should be_a(HierarchyEntry)
    end
    it 'should not add special content to details Array if special content is empty' do
      # Nucleotide sequences is used as example of special content that is part of
      # taxon details but has no content associated with this test taxon.
      details_do_show
      assigns[:details].collect{|h| h if h[:content_type] == 'nucleotide_sequences'}.compact.should be_empty
    end
    it 'should instantiate a table of contents' do
      details_do_show
      assigns[:toc].should be_a(Array)
      assigns[:toc].include?(@testy[:overview]).should be_true # TocItem with content should be included
      assigns[:toc].include?(@testy[:toc_item_3]).should be_false # TocItem without content should be excluded
    end
    it 'should instantiate an exemplar image'
    it 'should instantiate an assistive header' do
      details_do_show
      assigns[:assistive_section_header].should be_a(String)
    end

  end

end
