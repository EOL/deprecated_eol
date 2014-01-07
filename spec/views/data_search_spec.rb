require 'spec_helper'# {{{# }}}

describe 'data_search/index' do

  before(:all) do
    Language.create_english
    @user = EOL::AnonymousUser.new(Language.default)
  end

  before(:each) do
    view.stub(:current_user) { @user }
    view.stub(:current_language) { Language.default }
    view.stub(:logged_in?) { false }
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
      tc.stub(:latest_version).and_return(tc)
      result = double(DataPointUri, id: 8, comments: [], taxon_concept: tc, anchor: 'anchored', predicate_uri: 'uriHere',
                     new_record?: false, association?: false, object_uri: 'objURI', unit_of_measure_uri: 'unitURI',
                     source: nil, user_added_data: nil)
      results = [result].paginate
      assign(:results, results)
    end

    # TODO ...later...

  end

end
