require File.dirname(__FILE__) + '/../../spec_helper'
describe Administrator::ContentPartnerReportController do
  before(:all) do
    Scenario.load :foundation
  end

  it "should send monthly report email" do
    Agent.should_receive(:content_partners_contact_info).exactly(2).times.and_return([{:username => "johndoe", :email => "johndoe@example.com", :full_name => "John Doe"}])
    # expect
    Notifier.should_receive(:deliver_monthly_stats).with({:username=>"johndoe", :email=>"johndoe@example.com", :full_name=>"John Doe"}, "12", "2009")
    # when

    admin = User.gen(:username => "admin", :password => "admin")
    admin.roles = Role.find(:all, :conditions => 'title LIKE "Administrator%"')
    admin.save!
    session[:user] = admin
    session[:user_id] = admin.id

    get :monthly_stats_email
  end
end
