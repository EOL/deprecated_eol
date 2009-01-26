require File.dirname(__FILE__) + '/../../spec_helper'

describe ContentPartner::ReportsController do
  # integrate_views
  fixtures :agents
  
  before do
    login_as_agent :quentin
  end

  it 'any URL should goto catch_all action and set correct params' do
    _params = params_from(:get, '/content_partner/reports/states')
    _params[:report].should == 'states'
  end

  it 'should find the report from the report parameter' do
    get :catch_all, :report => 'states'
    assigns[:report].should == 'states'
    assigns[:totals].should be_a_kind_of(Array)
    assigns[:log_daily_class].should == StateLogDaily
    response.code.should == "200"
  end

  it 'should 404 with an error message with a bad report parameter' do
    get :catch_all, :report => 'no_exist'
    assigns[:report].should be_nil
    assigns[:totals].should be_nil
    assigns[:log_daily_class].should be_nil
    response.code.should == "404"
    response.body.should include("Report not found for no_exist")
  end

  def login_as_agent(agent)
    @request.session[:agent_id] = agents(agent).id
  end
end
