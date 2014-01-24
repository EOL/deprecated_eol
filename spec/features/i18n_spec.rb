require File.dirname(__FILE__) + '/../spec_helper'

describe 'Switching Languages' do
  before(:all) do
    load_foundation_cache
  end
  
  before(:each) do
    @user_fr = User.gen(language_id: Language.find_by_iso_639_1('fr').id)
  end
  
  it 'should use the default language' do
    visit('/logout')
    I18n.locale.to_s.should == Language.default_code
  end
  
  it 'should set the default language' do
    visit('/set_language?language=fr')
    I18n.locale.to_s.should == 'fr'
  end

  it 'should use the users language' do
    login_as @user_fr
    I18n.locale.to_s.should == 'fr'
  end
  
  it 'should set the users language' do
    login_as @user_fr
    I18n.locale.to_s.should == 'fr'
    visit('/set_language?language=en')
    I18n.locale.to_s.should == Language.default_code
    visit('/')
    @user_fr.reload.language.iso_code.should == Language.default_code
  end
end
