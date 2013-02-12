require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonDetails do

  # obnoxious but true: we need a set of articles in various languages.
  before(:all) do
    load_foundation_cache
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @native_entry = HierarchyEntry.gen(:taxon_concept => @taxon_concept)
    @entry = HierarchyEntry.gen
    @user = User.gen
  end

  before(:each) do # NOTE - we want these 'pristine' for each test, because values get cached.
    @details = TaxonDetails.new(@taxon_concept, @user)
    @details_with_entry = TaxonDetails.new(@taxon_concept, @user, @entry)
  end

  it 'should know when it does NOT have articles in other languages' do
    @details.should_receive(:count_by_language).and_return({})
    @details.articles_in_other_languages?.should_not be_true
  end

  it 'should know when it has articles in other languages' do
    @details.should_receive(:count_by_language).and_return({:whatever => 1})
    @details.articles_in_other_languages?.should be_true
  end

  # This looks more complicated than it is. It's actually pretty simple, if you read through it.
  it 'should have a count by language of approved languages (only)' do
    english_article = DataObject.gen(:language => Language.first)
    english_article.stub!(:approved_language?).and_return(true)
    bad_article = DataObject.gen(:language => Language.last)
    bad_article.stub!(:approved_language?).and_return(false)
    articles = [english_article, bad_article]
    @taxon_concept.should_receive(:text_for_user).and_return([english_article])
    DataObject.should_receive(:preload_associations).with([english_article], :language).and_return([english_article])
    @details.count_by_language.has_key?(Language.first).should be_true
    @details.count_by_language[Language.first].should == 1
    @details.count_by_language.has_key?(Language.last).should_not be_true
  end

  it 'should think there is a thumbnail if there is an image with a 260_190 version' do
    img = DataObject.gen
    img.should_receive(:thumb_or_object).with('260_190').and_return('yup')
    @details.should_receive(:image).at_least(1).times.and_return(img)
    @details.thumb?.should be_true
  end

  it 'should think there is NO thumbnail if there is an image WITHOUT a 260_190 version' do
    img = DataObject.gen
    img.should_receive(:thumb_or_object).with('260_190').and_return(nil)
    @details.should_receive(:image).at_least(1).times.and_return(img)
    @details.thumb?.should_not be_true
  end

  it 'should return the 260x190 thumbnail' do
    img = DataObject.gen
    img.should_receive(:thumb_or_object).with('260_190').and_return('howdy')
    @details.should_receive(:image).at_least(1).times.and_return(img)
    @details.thumb.should == 'howdy'
  end

  it 'should know if there are any toc_items if there are toc_roots' do
    @details.should_receive(toc_roots).and_return('sure')
    @details.toc_item?.should be_true
  end

  it 'should know there are not any toc_items when there are no toc_roots' do
    @details.should_receive(toc_roots).and_return(nil)
    @details.toc_item?.should_not be_true
  end

  # NOTE - I'm not testing all the args. There's just too many to bother.
  it '#details should get text from taxon_concept, preload it, and sort it' do
    texts = [DataObject.gen]
    @taxon_concept.should_receive(:text_for_user).and_return(texts)
    DataObject.should_receive(:preload_associations).and_return(texts)
    DataObject.should_receive(:sort_by_rating).with(texts, @taxon_concept).and_return('done')
    @details.details.should == 'done'
  end

  it '#details should be able to filter by toc_item'

end
