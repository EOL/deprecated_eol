require File.dirname(__FILE__) + '/../spec_helper'

describe SearchController do
  describe 'index' do
    before(:all) do
      truncate_all_tables
      Language.create_english
    end
  end

  it "should find no results on an empty search" do
    Language.create_english
    get :index, :q => ''
    assigns[:all_results].should == []
  end
end
