require File.dirname(__FILE__) + '/../../spec_helper'
describe Administrator::ContentPartnerReportController do
  before(:all) do
    load_foundation_cache
    @admin = User.gen(:username => "admin", :password => "admin")
    @admin.grant_admin
  end

end
