require File.dirname(__FILE__) + '/../spec_helper'

describe String do
  describe "normalize" do
    it "should remove undesired characters" do
      ':;,.()[]!?*_\\/"\''.normalize.should == ''
    end

    it "should remove multiple spaces, tabs" do
      "a a  a   a    a".normalize.should == "a a a a a"
      "a\ta\t a\t\ta".normalize.should == "a a a a"
    end

    it "should remove tags" do
      "<i>a</i> a <>        <><>".normalize.should == "a a "
    end

    it "should covert ascii to lower case" do
      "ABCDEFG".normalize.should == "abcdefg"
    end

    it "should do all substitutions together" do
      "abc<\t        i>a</i>:; ,.(Laddnda\t   )[]!?*_\\dd  \t  dd/\"'".normalize.should == "abca laddnda dd dd"
    end
  end

  describe 'balance tags' do
    it 'should prepend tags' do
      '</div></div>'.balance_tags.should == '<div><div></div></div>'
      '<div></div></div>'.balance_tags.should == '<div><div></div></div>'
      '<div></div></div><div>'.balance_tags.should == '<div><div></div></div><div></div>'
    end

    it 'should balance tags with attributes' do
      '<div class="ok"></div></div>'.balance_tags.should == '<div><div class="ok"></div></div>'
      '<div id="23"></div></div><div alt="text">'.balance_tags.should == '<div><div id="23"></div></div><div alt="text"></div>'
    end

    it 'should balance divs before p tags' do
      '</div></p>'.balance_tags.should == '<p><div></div></p>'
      '<p></div></p>'.balance_tags.should == '<div><p></div></p>'
      '</p><p></div></p>'.balance_tags.should == '<p><div></p><p></div></p>'
    end
  end

  describe "cleanup_for_presentation" do
    it "should remove long underscore lines" do
      "____".cleanup_for_presentation.should == "____"
      "___________________________________________________".cleanup_for_presentation.should == ' '
    end
  end
  
  describe "alphabet detection" do
    before(:all) do
      @english_phrases = [
        "The Quick Brown Fox",
        "a",
        "animalia",
        "This one doesn't contain only 小灰山椒鸟 chinese",
        "This one doesn't contain only الرسمية arabic"
      ]
      @chinese_phrases = [
        "了王(琼中)",
        "灰燕鵙 叉尾太阳鸟 宾灰燕儿 小灰山椒鸟 - 褐背鹟",
        "短嘴山椒鸟 23145",
        "绿喉太阳鸟",
        "钝翅(稻田)苇莺",
        "棕尾褐鶲, 棕尾鹟",
        "十"
      ]
      @arabic_phrases = [
        "الرسمية",
        "العربية هي",
        "قاموس صموئيل جو,نسون، وهو من أوائل من وضع قاموس إنجليزي، ",
        "الأسماء","الغربية (أي الآرامية والعبرية والكنعانية) هي أقرب",
        "سنة 1462، والتي كُتبت"
      ]
    end
    
    it "should recognize chinese strings" do
      @chinese_phrases.each{ |phrase| phrase.contains_chinese?.should == true }
      @english_phrases.each{ |phrase| phrase.contains_chinese?.should == false }
      @arabic_phrases.each{ |phrase| phrase.contains_chinese?.should == false }
    end
    
    it "should recognize arabic strings" do
      @arabic_phrases.each{ |phrase| phrase.contains_arabic?.should == true }
      @english_phrases.each{ |phrase| phrase.contains_arabic?.should == false }
      @chinese_phrases.each{ |phrase| phrase.contains_arabic?.should == false }
    end
  end
end


describe Array do
  it 'should group hashes by an attribute' do
    arr = [{'id' => 2, 'value' => 'first'},
           {'id' => 1, 'value' => 'first'}]
    arr.group_hashes_by!('value')
    arr.length.should == 1
    arr[0]['id'].should == 2
  end

  it 'should group objects by an attribute' do
    truncate_all_tables
    load_scenario_with_caching(:foundation)
    obj = User.gen
    obj2 = obj.clone
    obj2.id = 99999
    arr = [obj2, obj]

    grouped_arr = arr.group_objects_by('given_name')
    grouped_arr.length.should == 1
    grouped_arr[0].id.should == obj2.id
  end
end

describe Hash do
  it 'should create a deep copy' do
    h = {:a => [:b, :c]}
    dup_h = h.dup
    h.should == dup_h
    dup_h[:a].reject!{|v| v == :b }
    # this is what I thought was a bug - I've duplicated the array but the values are still identical
    # Even though dup_h is changed, according to Rails it shoul have changes h as well. Enter deepcopy
    dup_h.should == h

    h = {:a => [:b, :c]}
    dup_h = h.clone
    h.should == dup_h
    dup_h[:a].reject!{|v| v == :b }
    # same with clone
    dup_h.should == h

    h = {:a => [:b, :c]}
    # now create a deep copy instead of clone or dup
    dup_h = h.deepcopy
    h.should == dup_h
    dup_h[:a].reject!{|v| v == :b }
    dup_h.should_not == h
    dup_h.should == {:a => [:c]}
    h.should == {:a => [:b, :c]}
  end
end

describe Float do
  it 'should round float values' do
    138.249.round_to(2).should == 138.25
  end
  it 'should round float values' do
    138.249.round_to(-1).should == 140.00
  end
  it 'should floor float values' do
    138.249.floor_to(2).should == 138.240
  end
  it 'should ceil float values' do
    138.249.ceil_to(2).should == 138.250
  end
end

describe 'Uses Translations' do
  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @en = Language.gen_if_not_exists(:iso_639_1 => 'en')
    TranslatedLanguage.gen_if_not_exists(:label => 'English', :original_language_id => @en.id)
    @fr = Language.gen_if_not_exists(:iso_639_1 => 'fr')
    TranslatedLanguage.gen_if_not_exists(:label => 'French', :original_language_id => @fr.id)
    @language = Language.gen()
    @rank = Rank.gen()
    @swahili = Language.gen(:iso_639_1 => 'sw')
    @uberkingdom = Rank.gen()
    TranslatedLanguage.gen_if_not_exists(:label => 'Swahili', :language_id => @en.id, :original_language_id => @swahili.id)
    TranslatedLanguage.gen_if_not_exists(:label => 'French Swahili', :language_id => @fr.id, :original_language_id => @swahili.id)
    # rank is only in Swahili - no English
    TranslatedRank.gen_if_not_exists(:label => 'Swahili uberkingdom', :rank_id => @uberkingdom.id, :language_id => @swahili.id)
    @hierarchy_entry = HierarchyEntry.gen()
  end

  it 'should create methods for getting translated attributes' do
    @language.public_methods.include?('label').should == true
    @language.public_methods.include?('phonetic_label').should == true
    @rank.public_methods.include?('label').should == true
    @rank.public_methods.include?('phonetic_label').should == true
    @hierarchy_entry.public_methods.include?('label').should == false
    @hierarchy_entry.public_methods.include?('phonetic_label').should == false
  end

  it 'should not have labels without translations' do
    @language.label.should == nil
    @rank.label.should == nil
  end

  it 'should default to an English translation' do
    @swahili.label.should == 'Swahili'
    @swahili.label('en').should == 'Swahili'
    @uberkingdom.label.should == nil  # this rank didn't have an English label
    @uberkingdom.label('en').should == nil
  end

  it 'should be able to return different translations' do
    @swahili.label('fr').should == 'French Swahili'
    @uberkingdom.label('sw').should == 'Swahili uberkingdom'
  end
end
