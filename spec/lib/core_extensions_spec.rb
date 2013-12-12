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
      "This is\ntext".fix_old_user_added_text_linebreaks(wrap_in_paragraph: true).should == '<p>This is<br/>text</p>'
    end

    it 'should not convert if there are already breaks in the text' do
      "This is\n<br>text".fix_old_user_added_text_linebreaks.should == "This is\n<br>text"
      "This is\n<br>text".fix_old_user_added_text_linebreaks(wrap_in_paragraph: true).should == "This is\n<br>text"
      "This is\n<p>text".fix_old_user_added_text_linebreaks.should == "This is\n<p>text"
      "This is\n<p>text".fix_old_user_added_text_linebreaks(wrap_in_paragraph: true).should == "This is\n<p>text"
    end
  end

  describe 'add_missing_hyperlinks' do
    it 'should link http URLs' do
      'Some http://eol.org link'.add_missing_hyperlinks.should == 'Some <a href="http://eol.org">http://eol.org</a> link'
      'Some ("http://eol.org") link'.add_missing_hyperlinks.should == 'Some ("<a href="http://eol.org">http://eol.org</a>") link'
      'Some http://eol.org/ link'.add_missing_hyperlinks.should == 'Some <a href="http://eol.org/">http://eol.org/</a> link'
      'Some http://eol.org/info link'.add_missing_hyperlinks.should == 'Some <a href="http://eol.org/info">http://eol.org/info</a> link'
      'Some http://eol.org/info.html link'.add_missing_hyperlinks.should == 'Some <a href="http://eol.org/info.html">http://eol.org/info.html</a> link'
    end

    it 'should link https URLs' do
      'Some https://eol.org link'.add_missing_hyperlinks.should == 'Some <a href="https://eol.org">https://eol.org</a> link'
      'Some https://eol.org/ link'.add_missing_hyperlinks.should == 'Some <a href="https://eol.org/">https://eol.org/</a> link'
      'Some https://eol.org/info link'.add_missing_hyperlinks.should == 'Some <a href="https://eol.org/info">https://eol.org/info</a> link'
      'Some https://eol.org/info.html link'.add_missing_hyperlinks.should == 'Some <a href="https://eol.org/info.html">https://eol.org/info.html</a> link'
    end

    it 'should link www URLs' do
      'Some www.eol.org link'.add_missing_hyperlinks.should == 'Some <a href="http://www.eol.org">www.eol.org</a> link'
      'Some www.eol.org/ link'.add_missing_hyperlinks.should == 'Some <a href="http://www.eol.org/">www.eol.org/</a> link'
      'Some www.eol.org/info link'.add_missing_hyperlinks.should == 'Some <a href="http://www.eol.org/info">www.eol.org/info</a> link'
      'Some www.eol.org/info.html link'.add_missing_hyperlinks.should == 'Some <a href="http://www.eol.org/info.html">www.eol.org/info.html</a> link'
    end

    it 'should link DOIs' do
      'Some doi:10.4319/lo.2013.58.1.0254 DOI'.add_missing_hyperlinks.should ==
        'Some <a href="http://dx.doi.org/doi:10.4319/lo.2013.58.1.0254">doi:10.4319/lo.2013.58.1.0254</a> DOI'
      'Some 10.4319/lo.2013.58.1.0254 DOI'.add_missing_hyperlinks.should ==
        'Some <a href="http://dx.doi.org/10.4319/lo.2013.58.1.0254">10.4319/lo.2013.58.1.0254</a> DOI'
      'Some ("doi:10.4319/lo.2013.58.1.0254") DOI'.add_missing_hyperlinks.should ==
        'Some ("<a href="http://dx.doi.org/doi:10.4319/lo.2013.58.1.0254">doi:10.4319/lo.2013.58.1.0254</a>") DOI'
    end

    it 'should not link already linked URLs' do
      'Some <a href="http://eol.org>http://eol.org</a> link'.add_missing_hyperlinks.should == 'Some <a href="http://eol.org>http://eol.org</a> link'
    end
  end

  it 'should know when strings are numeric' do
    '1'.is_numeric?.should == true
    '-1'.is_numeric?.should == true
    '0.1'.is_numeric?.should == true
    '1.0'.is_numeric?.should == true
    '-1.0'.is_numeric?.should == true
    '3e+08'.is_numeric?.should == true # interpreted as 3.0 X 10^8
    '3.1e+08'.is_numeric?.should == true # interpreted as 3.1 X 10^8
    'one'.is_numeric?.should == false
    '1.0a'.is_numeric?.should == false
  end

  it 'should know when strings are integers' do
    '1'.is_int?.should == true
    '-1'.is_int?.should == true
    '0.1'.is_int?.should == false
    '1.0'.is_int?.should == false
    '-1.0'.is_int?.should == false
    '3e+08'.is_int?.should == false
    '3.1e+08'.is_int?.should == false
    'one'.is_int?.should == false
    '1.0a'.is_int?.should == false
  end

  it 'should know when strings are floats' do
    '1'.is_float?.should == false
    '-1'.is_float?.should == false
    '0.1'.is_float?.should == true
    '1.0'.is_float?.should == true
    '-1.0'.is_float?.should == true
    '3e+08'.is_float?.should == true
    '3.1e+08'.is_float?.should == true
    'one'.is_float?.should == false
    '1.0a'.is_float?.should == false
  end

end
