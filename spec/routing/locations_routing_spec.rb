require "spec_helper"

describe LocationsController do
  describe "routing" do

    it "routes to #new" do
      get("/locations/new").should route_to("locations#new")
    end

    it "routes to #create" do
      post("/locations").should route_to("locations#create")
    end

  end
end
