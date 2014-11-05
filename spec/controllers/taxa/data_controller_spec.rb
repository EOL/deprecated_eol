require File.dirname(__FILE__) + '/../../spec_helper'

describe Taxa::DataController do
  render_views
  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @user = User.gen
    @user.grant_permission(:see_data)
    @full = FactoryGirl.create(:curator)
    @master = FactoryGirl.create(:master_curator)
    @admin = User.gen(:admin => true)
    @taxon_concept = build_taxon_concept
  end

  before(:each) do
    session[:user_id] = @user.id
  end

  describe 'GET index' do

    it 'should grant access to users with data privilege' do
      session[:user_id] = @user.id
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
    end

    it 'should allow access if the EolConfig is set' do
      opt = EolConfig.find_or_create_by_parameter('all_users_can_see_data')
      opt.value = 'true'
      opt.save
      session[:user_id] = User.gen.id
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
      session[:user_id] = nil
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
      opt.value = 'false'
      opt.save
    end

    it "does not display duplicate attributes" do
      DataPointUri.gen(taxon_concept_id: @taxon_concept.id, predicate: ' http://eol.org/schema/terms/eats', object: 'carrot')
      DataPointUri.gen(taxon_concept_id: @taxon_concept.id, predicate: ' http://eol.org/schema/terms/eats', object: 'carrot')
      curator = User.gen(curator_level_id: 1, curator_approved: 1, :credentials => 'Blah', :curator_scope => 'More blah')   
      session[:user_id] = curator.id
      allow(controller).to receive(:current_user) { curator }
      get :index, :taxon_id => @taxon_concept.id
      expect(response.body).to have_tag('div.term', text: /Eats/, count: 1)
      expect(response.body).to have_tag('span.term', text: /carrot/, count: 1)
    end
  end

end
