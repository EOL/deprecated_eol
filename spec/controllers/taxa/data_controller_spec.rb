require File.dirname(__FILE__) + '/../../spec_helper'

describe Taxa::DataController do

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

    it 'should deny access to normal or non-logged-in users' do
      session[:user_id] = User.gen.id
      expect { get :index, :taxon_id => @taxon_concept.id }.to raise_error(EOL::Exceptions::SecurityViolation)
      session[:user_id] = nil
      expect { get :index, :taxon_id => @taxon_concept.id }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow access if the SiteConfigurationOption is set' do
      opt = SiteConfigurationOption.find_or_create_by_parameter('all_users_can_see_data')
      opt.value = 'true'
      opt.save
      session[:user_id] = User.gen.id
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
      session[:user_id] = nil
      expect { get :index, :taxon_id => @taxon_concept.id }.not_to raise_error
      opt.value = 'false'
      opt.save
    end

    it 'should deny access to curators and admins without data privilege' do
      session[:user_id] = @full.id
      expect { get :index, :taxon_id => @taxon_concept.id }.to raise_error(EOL::Exceptions::SecurityViolation)
      session[:user_id] = @master.id
      expect { get :index, :taxon_id => @taxon_concept.id }.to raise_error(EOL::Exceptions::SecurityViolation)
      session[:user_id] = @admin.id
      expect { get :index, :taxon_id => @taxon_concept.id }.to raise_error(EOL::Exceptions::SecurityViolation)
    end


  end

end
