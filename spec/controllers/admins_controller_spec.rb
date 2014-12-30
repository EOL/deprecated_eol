require "spec_helper"

describe AdminsController do
  include ApplicationHelper
  render_views  
  
  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @admin = User.gen
    @admin.grant_admin
  end
  
  describe "GET 'show'" do
    
    before(:each) do
      session[:user_id] = @admin.id
    end
    
    describe "running harvestings" do
      it "displays harvestings info" do
        get :show
        expect(response.body).to  render_template(:partial => '_current_harvest')
      end
    
      context "when no harvestings is currently running" do
        it "displays no harvestings statement" do
          get :show
          expect(response.body).to have_selector("p", text: I18n.t(:no_harvesting_events_running_now))
        end
      end
      
      context "when there is running harvesting" do
        before(:all) do
          @current_harvesting = HarvestEvent.first
          @current_harvesting.update_attributes(completed_at: nil)
          @harvesting_resource = Resource.find(@current_harvesting.resource_id)
          @harvest_process_log = HarvestProcessLog.gen(completed_at: nil, process_name: "Harvesting")
        end
      
        it "displays resource title of currently running harvest" do
          get :show
          expect(response.body).to have_selector("b", text: I18n.t(:harvest_resource))
          expect(response.body).to have_selector("td", text: @harvesting_resource.title)
        end
      
        it "displays duration of currently running harvest" do
          get :show
          expect(response.body).to have_selector("b", text: I18n.t(:harvest_duration))
          expect(response.body).to have_selector("td", include: time_diff(@harvest_process_log.began_at, Time.now))
        end
        
        after(:all) do
          @harvest_process_log.destroy if @harvest_process_log
        end
        
      end
    end
  end
end