require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResourcesController do
  describe "route generation" do

    it "should map { :controller => 'resources', :action => 'index' } to /content_partner/resources" do
      route_for(:controller => "resources", :action => "index").should == "/content_partner/resources"
    end
  
    it "should map { :controller => 'resources', :action => 'new' } to /content_partner/resources/new" do
      route_for(:controller => "resources", :action => "new").should == "/content_partner/resources/new"
    end
  
    it "should map { :controller => 'resources', :action => 'show', :id => 1 } to /content_partner/resources/1" do
      route_for(:controller => "resources", :action => "show", :id => 1).should == "/content_partner/resources/1"
    end
  
    it "should map { :controller => 'resources', :action => 'edit', :id => 1 } to /content_partner/resources/1/edit" do
      route_for(:controller => "resources", :action => "edit", :id => 1).should == "/content_partner/resources/1/edit"
    end
  
    it "should map { :controller => 'resources', :action => 'update', :id => 1} to /content_partner/resources/1" do
      route_for(:controller => "resources", :action => "update", :id => 1).should == "/content_partner/resources/1"
    end
  
    it "should map { :controller => 'resources', :action => 'destroy', :id => 1} to /content_partner/resources/1" do
      route_for(:controller => "resources", :action => "destroy", :id => 1).should == "/content_partner/resources/1"
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'resources', action => 'index' } from GET /content_partner/resources" do
      params_from(:get, "/content_partner/resources").should == {:controller => "resources", :action => "index"}
    end
  
    it "should generate params { :controller => 'resources', action => 'new' } from GET /content_partner/resources/new" do
      params_from(:get, "/content_partner/resources/new").should == {:controller => "resources", :action => "new"}
    end
  
    it "should generate params { :controller => 'resources', action => 'create' } from POST /content_partner/resources" do
      params_from(:post, "/content_partner/resources").should == {:controller => "resources", :action => "create"}
    end
  
    it "should generate params { :controller => 'resources', action => 'show', id => '1' } from GET /content_partner/resources/1" do
      params_from(:get, "/content_partner/resources/1").should == {:controller => "resources", :action => "show", :id => "1"}
    end
  
    it "should generate params { :controller => 'resources', action => 'edit', id => '1' } from GET /content_partner/resources/1;edit" do
      params_from(:get, "/content_partner/resources/1/edit").should == {:controller => "resources", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'resources', action => 'update', id => '1' } from PUT /content_partner/resources/1" do
      params_from(:put, "/content_partner/resources/1").should == {:controller => "resources", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'resources', action => 'destroy', id => '1' } from DELETE /content_partner/resources/1" do
      params_from(:delete, "/content_partner/resources/1").should == {:controller => "resources", :action => "destroy", :id => "1"}
    end
  end
end
