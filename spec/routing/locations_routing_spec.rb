require "spec_helper"

describe LocationsController do
  describe "routing" do

    it "routes to #new" do
      get("/locations/new").should route_to("locations#new")
    end

    it "routes to #edit" do
      get("/locations/1/edit").should route_to("locations#edit", :id => "1")
    end

    it "routes to #create" do
      post("/locations").should route_to("locations#create")
    end

    it "routes to #update" do
      put("/locations/1").should route_to("locations#update", :id => "1")
    end

  end
end
