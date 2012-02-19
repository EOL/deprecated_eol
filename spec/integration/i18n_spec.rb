require File.dirname(__FILE__) + '/../spec_helper'

describe 'Switching Languages' do
  before :all do
    load_foundation_cache
    Capybara.reset_sessions!
  end
  
  after(:each) do
    visit('/logout')
    Capybara.reset_sessions!
  end

  it 'should use the default language' do
    visit('/')
    I18n.locale.to_s.should == Language.english.iso_code
  end
  
  it 'should set the default language' do
    visit('/set_language?language=fr')
    I18n.locale.to_s.should == 'fr'
  end

  it 'should use the users language' do
    user = User.gen(:language => Language.gen_if_not_exists(:iso_639_1 => 'sp'))
    I18n.locale = 'en'
    login_as user
    visit('/set_language?language=sp')
    I18n.locale.to_s.should == 'sp'
  end
  
  it 'should set the users language' do
    user = User.gen(:language => Language.gen_if_not_exists(:iso_639_1 => 'fr'))
    I18n.locale = 'en'
    login_as user
    visit('/fr/')
    I18n.locale.to_s.should == 'fr'
    visit('/set_language?language=sp')
    I18n.locale.to_s.should == 'sp'
    user.reload.language.iso_code.should == 'sp'
  end
end
