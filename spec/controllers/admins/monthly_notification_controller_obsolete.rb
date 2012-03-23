require File.dirname(__FILE__) + '/../../spec_helper'
describe Admins::MonthlyNotificationController do
  before(:all) do
    load_foundation_cache
    @admin = User.gen(:username => "admin", :password => "admin")
    @admin.grant_admin
  end

  it "should send monthly notification email" do
    ContentPartner.should_receive(:contacts_for_monthly_stats).exactly(1).times.and_return([
      {:partner_full_name => "johndoe organization", :email => "johndoe@example.com", :full_name => "John Doe"}])
    # expect
    last_month = 1.month.ago
    Notifier.should_receive(:deliver_monthly_stats).with(
      {:partner_full_name=>"johndoe organization", :email=>"johndoe@example.com", :full_name=>"John Doe"}, last_month.month.to_s, last_month.year.to_s)
    # when

    session[:user_id] = @admin.id

    get :send_email
  end
end
