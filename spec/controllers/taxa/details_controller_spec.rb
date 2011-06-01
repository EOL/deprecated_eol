require File.dirname(__FILE__) + '/../../spec_helper'

def do_show
  get :show, :taxon_id => @testy[:taxon_concept].id.to_i
end

describe Taxa::DetailsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
  end

  describe 'GET show' do

    it 'should instantiate the details Array containing text data objects and special content' do
      do_show
      assigns[:details].should be_a(Array)
      datos = assigns[:details].collect{|h| h[:data_objects]}.compact.flatten
      datos.take_while{|d| d.should be_a(DataObject)}.should == datos
      # TODO: Check for special content
    end
    it 'should not add special content to details Array if special content is empty'
    it 'should instantiate a table of contents' do
      do_show
      assigns[:toc].should be_a(Array)
      # TODO: array should not contain toc items that don't have datos
    end
    it 'should instantiate an assistive header' do
      do_show
      assigns[:assistive_section_header].should be_a(String)
    end
  end

end
