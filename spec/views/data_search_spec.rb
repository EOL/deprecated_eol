require 'spec_helper'

describe 'data_search/index' do

  before(:all) do
    # Later
  end

  before(:each) do
    # Later
  end

  context 'with no results' do

    context 'when server unavailable' do

      it 'should have a warning' do
        render
        expect(rendered).to have_content I18n.t(:data_server_unavailable)
      end

    end

  end

  context 'with results' do

    before(:each) do
      image = double(DataObject, thumb_or_object: 'thumb for image')
      tc = double(TaxonConcept, id: 2015, exemplar_or_best_image_from_solr: image, collected_name: 'taxoname',
                                preferred_common_name_in_language: 'Cloudy name')
      tc.stub(:latest_version).with(tc)
      result = double(DataPointUri, comments: [], taxon_concept: tc)
      results = [result].paginate
      assign(:results, results)
    end

    it "should include a drop-down with all attributes" do
      render
      expect(rendered).to have_tag('select#attribute')
    end

  end

end
