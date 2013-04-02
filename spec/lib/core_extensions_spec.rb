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

    it 'should NOT capitalize some small words in English ' do
      I18n.locale = :en
      "tom and jerry".capitalize_all_words_if_language_safe.should == "Tom and Jerry"
      "first of january".capitalize_all_words_if_language_safe.should == "First of January"
      "word and".capitalize_all_words_if_language_safe.should == "Word and"
      "word of".capitalize_all_words_if_language_safe.should == "Word of"
    end
  end

  describe 'fix_old_user_added_text_linebreaks' do
    it 'should replace line breaks with HTML BR tags' do
      "This is\ntext".fix_old_user_added_text_linebreaks.should == 'This is<br/>text'
      "This is\rtext".fix_old_user_added_text_linebreaks.should == 'This is<br/>text'
    end

    it 'should wrap the text in a paragraph tag if requested' do
      "This is\ntext".fix_old_user_added_text_linebreaks.should == 'This is<br/>text'
      "This is\ntext".fix_old_user_added_text_linebreaks(:wrap_in_paragraph => true).should == '<p>This is<br/>text</p>'
    end

    it 'should not convert if there are already breaks in the text' do
      "This is\n<br>text".fix_old_user_added_text_linebreaks.should == "This is\n<br>text"
      "This is\n<br>text".fix_old_user_added_text_linebreaks(:wrap_in_paragraph => true).should == "This is\n<br>text"
      "This is\n<p>text".fix_old_user_added_text_linebreaks.should == "This is\n<p>text"
      "This is\n<p>text".fix_old_user_added_text_linebreaks(:wrap_in_paragraph => true).should == "This is\n<p>text"
    end
  end
end
