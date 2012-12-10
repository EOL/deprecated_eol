require File.dirname(__FILE__) + '/../spec_helper'

# TODO - UHHH... a LOT.  I just added this because I thought it was trivially easy to check the change I was
# making... and was kinda shocked that we didn't have a spec for extensions already. So... really... we should.  :|
describe "Core Extensions" do

  describe "#capitalize_all_words_if_language_safe" do

    before(:all) do
      @locale = I18n.locale 
      @lower = "this is some string"
      @upper = "This Is Some String"
    end

    after(:each) do
      I18n.locale = @locale
    end

    it 'should capitalize all words in a string in Romance and Germanic languages' do
      ['de', :en, :es, :fr, :nl].each do |lang|
        I18n.locale = lang
        @lower.capitalize_all_words_if_language_safe.should == @upper
      end
    end

    it 'should NOT capitalize any words in a string from an Asian language' do
      I18n.locale = :ko
      @lower.capitalize_all_words_if_language_safe.should == @lower
    end

  end

end
