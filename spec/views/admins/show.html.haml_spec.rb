require 'spec_helper'

describe 'admins/show' do
  
  before(:all) do
    load_foundation_cache
  end  
  
  describe "running harvestings" do
    
    it "displays harvestings info" do
      render
      expect(response).to  render_template(:partial => '_current_harvest')
    end
    
    context "when no harvestings is currently running" do
      it "displays no harvestings statement" do
        render
        expect(response).to have_selector("p", text: I18n.t(:no_harvesting_events_running_now))
      end
    end
    
    context "when no harvestings is currently running" do
      
      before(:all) do
        @harvesting_resource = Resource.first
        @current_harvesting = HarvestEvent.gen(completed_at: nil, resource: @harvesting_resource)
      end
      
      it "displays resource title of currently running harvest" do
        render
        expect(response).to have_selector("b", text: I18n.t(:harvest_resource))
        expect(response).to have_selector("td", text: @harvesting_resource.title)
      end
      
      it "displays duration of currently running harvest" do
        render
        expect(response).to have_selector("b", text: I18n.t(:harvest_duration))
        expect(response).to have_selector("td", text: time_diff(@current_harvesting.began_at, Time.now))
      end
    end
    
    after(:all) do
        @current_harvesting.destroy if @current_harvesting
      end    
   
  end
  
end