require File.dirname(__FILE__) + '/../../spec_helper'

describe Taxa::MediaController do

  before(:all) do
    populate_tables(:data_types)
  end

  let(:taxon_concept) { TaxonConcept.gen }
  let(:user) { FactoryGirl.build_stubbed(User) }
  let(:taxon_page) { double(TaxonPage, scientific_name: 'Whatever somethingus', hierarchy_provider: "providedBy", preferred_scientific_name: "blahbalh") }
  let(:data_object_1) { FactoryGirl.build_stubbed(DataObject) }
  let(:data_object_2) { FactoryGirl.build_stubbed(DataObject) }
  let(:data_object_3) { FactoryGirl.build_stubbed(DataObject) }
  let(:taxon_media) { double(TaxonMedia, empty?: false, paginated: [data_object_1, data_object_2, data_object_3].paginate) }

  before do
    allow(controller).to receive(:current_user) { user }
    allow(TaxonPage).to receive(:new) { taxon_page }
    allow(taxon_page).to receive(:media) { taxon_media }
  end

  context 'with no media' do

    let(:taxon_media) { double(TaxonMedia, empty?: true, paginated: [].paginate) }

    before do
      allow(taxon_page).to receive(:media) { taxon_media }
    end

    it 'sets meta description as empty' do
      get :index, id: taxon_concept.id
      # NOTE - this is weird, but we're testing a private method using this syntax, since we need to check that this pseudo-helper (method) works:
      # TODO - these meta_description methods really should be helpers.
      expect(controller.meta_description).to match(/No multimedia is available/)
    end

  end

  it 'indicates pictures, video, and audio in meta description' do
    get :index, id: taxon_concept.id
    # NOTE - this is weird, but we're testing a private method using this syntax, since we need to check that this pseudo-helper (method) works:
    # TODO - these meta_description methods really should be helpers.
    expect(controller.meta_description).to match(/pictures/i)
    expect(controller.meta_description).to match(/video/i)
    expect(controller.meta_description).to match(/audio/i)
  end

  it 'should instantiate the taxon concept' do
    get :index, id: taxon_concept.id
    expect(assigns(:taxon_concept)).to eq(taxon_concept)
  end

  it 'should instantiate the taxon page' do
    get :index, id: taxon_concept.id
    expect(assigns(:taxon_page)).to eq(taxon_page)
  end

  it 'should instantiate a TaxonMedia object' do
    get :index, id: taxon_concept.id
    expect(taxon_page).to have_received(:media) # TODO - this could / should also test the user and HE (if any) passed in.
    expect(assigns(:taxon_media)).to eq(taxon_media)
  end

  it 'should instantiate an assistive header' do
    get :index, id: taxon_concept.id
    expect(assigns(:assistive_section_header)).to eq(I18n.t(:assistive_media_header))
  end

end
