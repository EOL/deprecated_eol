require File.dirname(__FILE__) + '/../../spec_helper'

describe Taxa::NamesController do

  before(:all) do
    load_foundation_cache
    @testy = {}
    @testy[:taxon_concept] =  build_taxon_concept(images: [], toc: [], sname: [], comments: [],
                              flash: [], sounds: [], gbif_map_id: nil, bhl: [], biomedical_terms: nil)
    @testy[:curator] = build_curator(@testy[:taxon_concept] )
    common_name = Faker::Eol.common_name.firstcap + 'tsty'
    @testy[:taxon_concept].add_common_name_synonym(
      "testy_common_name", agent: @testy[:curator].agent, language: Language.english)
  end

  shared_examples_for 'taxa/names controller' do
    it 'should instantiate section for assistive header' do
      assigns[:assistive_section_header].should be_a(String)
    end
    it 'should instantiate the taxon concept' do
      assigns[:taxon_concept].should == @testy[:taxon_concept]
    end
  end


  describe 'GET related_names' do # default related names
    before :each do
      get :related_names, :taxon_id => @testy[:taxon_concept].id
    end
    it_should_behave_like 'taxa/names controller'
    it 'should instantiate related names' do
      assigns[:related_names].should be_a(Hash)
      assigns[:related_names]['parents'].should be_a(Array)
      assigns[:related_names]['children'].should be_a(Array)
    end
  end

  describe 'POST names' do

    before :each do
      session[:user_id] = @testy[:curator].id
      @approved_languages = Language.approved_languages.collect{|l| l.id}
    end

    # TODO - the rest of the specs here could be replaced in this block (and then this context could be removed), but ensure that there are good model specs
    # before you do that:
    context 'properly mocked' do

      let(:curator) { build_stubbed(User) }
      let(:synonym) { build_stubbed(Synonym) }
      let(:taxon_concept) { TaxonConcept.first }
      
      subject do
        post :create, name: { synonym: { language_id: Language.default.id }, string: 'woofer' },
                      commit_add_common_name: 'Add name', taxon_id: taxon_concept.id
      end

      before do
        # Not the best way to accomplish this, but:
        allow(TaxonConcept).to receive(:find).with(taxon_concept.id) { taxon_concept }
        allow(controller).to receive(:current_user) { curator }
        allow(controller).to receive(:log_action) { curator }
        allow(controller).to receive(:expire_taxa) { curator }
        allow(curator).to receive(:is_curator?) { true }
        allow(curator).to receive(:agent) { build_stubbed(Agent) }
        allow(curator).to receive(:add_agent) { }
        allow(taxon_concept).to receive(:reindex_in_solr) { }
        allow(taxon_concept).to receive(:add_common_name_synonym) { synonym }
        allow(synonym).to receive(:errors) { [] }
      end

      it 'does NOT add agents to users who have one' do
        subject
        expect(curator).to_not have_received(:add_agent)
      end

      it 'adds an agent to users who do NOT have one' do
        allow(curator).to receive(:agent) { nil }
        subject
        expect(curator).to have_received(:add_agent)
      end

      it 'logs the action' do
        subject
        expect(controller).to have_received(:log_action)
      end

      it 'expires taxon' do
        subject
        expect(controller).to have_received(:expire_taxa).with([taxon_concept.id])
      end

      it 'does not flash an error' do
        subject
        expect(flash[:error]).to be_blank
      end

      it 'does NOT log or expire when there are errors' do
        allow(synonym).to receive(:errors) { ['failed!'] }
        subject
        expect(controller).to_not have_received(:log_action)
        expect(controller).to_not have_received(:expire_taxa)
        expect(flash[:error]).to_not be_blank
      end

    end

    it 'should add a new common name in approved languages' do
      approved_language_id = @approved_languages.first
      post :create, :name => { :synonym => { :language_id => approved_language_id }, :string => "snake" }, 
                    :commit_add_common_name => "Add name", :taxon_id => @testy[:taxon_concept].id
      name = Name.find_by_string("snake").should be_true
      TaxonConceptName.find_by_name_id_and_language_id(Name.find_by_string("snake").id, approved_language_id)
      response.should redirect_to(common_names_taxon_names_path(@testy[:taxon_concept].id))
    end

    it 'should add a new common name in non-approved languages' do
      non_approved_language_id = Language.find(:all, :conditions => ["id NOT IN (?)", @approved_languages]).first.id
      post :create, :name => { :synonym => { :language_id => non_approved_language_id }, :string => "nag" }, 
                    :commit_add_common_name => "Add name", :taxon_id => @testy[:taxon_concept].id
      name = Name.find_by_string("nag").should be_true
      TaxonConceptName.find_by_name_id_and_language_id(Name.find_by_string("nag").id, non_approved_language_id)
      response.should redirect_to(common_names_taxon_names_path(@testy[:taxon_concept].id))
    end

  end

  describe 'GET common_names' do
    before :each do
      get :common_names, :taxon_id => @testy[:taxon_concept].id
    end
    it_should_behave_like 'taxa/names controller'
    it 'should instantiate common names' do
      assigns[:common_names].should be_a(Array)
      assigns[:common_names].first.should be_a(EOL::CommonNameDisplay)
    end
  end

  describe 'GET synonyms' do
    before :each do
      get :synonyms, :taxon_id => @testy[:taxon_concept].id
    end
    it_should_behave_like 'taxa/names controller'
    it 'should preload synonym associations' do
      assigns[:taxon_concept].published_hierarchy_entries.first.scientific_synonyms.should be_a(Array)
      assigns[:taxon_concept].published_hierarchy_entries.first.scientific_synonyms.first.should be_a(Synonym)
    end

  describe 'GET delete' do
    it 'can be deleted only by the user that added the name' do
      synonym = @testy[:taxon_concept].add_common_name_synonym(
        'common name', agent: @testy[:curator].agent, language: Language.english)
      new_user = build_curator(@testy[:taxon_concept])
      controller.set_current_user = new_user
      expect{ get :delete, taxon_id: @testy[:taxon_concept].id, synonym_id: synonym.id }.
        to raise_error(EOL::Exceptions::SecurityViolation)
      controller.set_current_user = @testy[:curator]
      expect{ get :delete, taxon_id: @testy[:taxon_concept].id, synonym_id: synonym.id }.
        not_to raise_error
    end
  end

  end

end
