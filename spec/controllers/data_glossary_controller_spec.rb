require "spec_helper"

describe DataGlossaryController do

  before(:all) do
    load_foundation_cache
    @user = User.gen
    @user.grant_permission(:see_data)
    @full = FactoryGirl.create(:curator)
    @master = FactoryGirl.create(:master_curator)
    @admin = User.gen(:admin => true)
  end

  before(:each) do
    session[:user_id] = @user.id
  end

  describe 'GET index' do

    it 'should grant access to users with data privilege' do
      session[:user_id] = @user.id
      expect { get :show }.not_to raise_error
    end

    it 'should allow access if the EolConfig is set' do
      opt = EolConfig.find_or_create_by_parameter('all_users_can_see_data')
      opt.value = 'true'
      opt.save
      session[:user_id] = User.gen.id
      expect { get :show }.not_to raise_error
      session[:user_id] = nil
      expect { get :show }.not_to raise_error
      opt.value = 'false'
      opt.save
    end

  end

end
