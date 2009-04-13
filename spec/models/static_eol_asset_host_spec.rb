require File.dirname(__FILE__) + '/../spec_helper'

describe StaticEolAssetHost do
  
  before(:each) do
    @asset_host = StaticEolAssetHost.asset_host_proc
    @asset_host.should_not be_nil
  end
  
  it "should use static1 for CSS assets" do
    css = "/stylesheets/test.css?1230601161"
    assert @asset_host.call(css) =~ /static1/
  end
  
  it "should use static2 for JS assets" do
    css = "/js/test.js?1230601161"
    assert @asset_host.call(css) =~ /static2/
  end
  
  it "should use not use static1 or static2 for image assets" do
    css = "/images/test.png?1230601161"
    assert @asset_host.call(css) !=~ /static1/
    assert @asset_host.call(css) !=~ /static2/
  end

end