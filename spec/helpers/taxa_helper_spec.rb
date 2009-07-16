require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe TaxaHelper do
  
  def render_partial
    @response = helper.paginate_results(@current_page)
  end
  
  it "should have serp_pagination class present" do
    @current_page = mock("search mock", :current_page => 1, :total_pages => 1)
    render_partial
    @response.should =~ /^<div class="serp_pagination">/
  end
  
  it "should have 5 pages of results present" do
    @current_page = mock("search mock", :current_page => 1, :total_pages => 5)
    render_partial
    @response.should_not =~ /page=1/
    @response.should =~ /page=2/
    @response.should =~ /page=3/
    @response.should =~ /page=4/
    @response.should =~ /page=5/
    @response.should_not =~ /page=6/
  end

end
