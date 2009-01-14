require File.dirname(__FILE__) + '/../profile_test_helper'

class MyControllerTest < Test::Unit::TestCase
  include RubyProf::Test

  fixtures :all

  def setup
    @controller = TaxaController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_get
    get(:show, :id => 101)
  end
end
