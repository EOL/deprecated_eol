require File.dirname(__FILE__) + '/../../spec_helper'

describe Users::OpenAuthenticationsController do

  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_defaults
    @user = User.gen
  end

  describe 'GET index' do
    it 'should do some stuff'
  end

  describe 'GET new' do
    it 'should do some stuff'

  end

  describe 'POST create' do
    it 'should do some stuff'

  end

  describe 'POST destroy' do
    it 'should do some stuff'

  end
end
