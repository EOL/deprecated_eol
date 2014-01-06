require 'spec_helper'

describe "Locations" do
  describe "GET /locations/new" do
    it "works! (now write some real specs)" do
      get new_location_path
      response.status.should be(200)
    end
  end
end
