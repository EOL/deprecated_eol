require File.dirname(__FILE__) + '/../spec_helper'

describe EOLWebService do
  before(:all) do 
    @url = "http://usr:pass@example.eol/some_path"
    @params = "?param1=1&param2=something&param3=1and2"
  end

  describe "#uri_remove_param" do
    it "should return same url if there are no params given" do
      EOLWebService.uri_remove_param(@url).should == @url
      EOLWebService.uri_remove_param(@url + @params).should == @url + @params
    end

    it "should remove any parameter" do
      url = @url + @params
      EOLWebService.uri_remove_param(url, 'param1').should == @url + "?param2=something&param3=1and2"
      EOLWebService.uri_remove_param(url, 'param2').should == @url + "?param1=1&param3=1and2"
      EOLWebService.uri_remove_param(url, 'param3').should == @url + "?param1=1&param2=something"
    end
    
    it "should remove any parameter with escaped amps" do
      url = @url + @params.gsub('&', '&amp;')
      EOLWebService.uri_remove_param(url, 'param1').should == @url + "?param2=something&amp;param3=1and2"
      EOLWebService.uri_remove_param(url, 'param2').should == @url + "?param1=1&amp;param3=1and2"
      EOLWebService.uri_remove_param(url, 'param3').should == @url + "?param1=1&amp;param2=something"
    end

    it "should remove more than one parameter" do
      url = @url + @params
      EOLWebService.uri_remove_param(url, ['param1', 'param3']).should == @url + "?param2=something"
    end

    it "should remove ? at the end of url if no params left" do
      url = @url + @params
      EOLWebService.uri_remove_param(url, ['param1', 'param2', 'param3']).should == @url
    end
  end



end
