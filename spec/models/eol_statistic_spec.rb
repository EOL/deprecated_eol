require File.dirname(__FILE__) + '/../spec_helper'
describe EolStatistic do
  before(:all) do
    @first = EolStatistic.gen(created_at: Time.now - 1.month)
    @second = EolStatistic.gen(created_at: Time.now - 1.month + 1.day)
    @latest = EolStatistic.gen(created_at: Time.now)
  end

  describe "#scopes" do
    it 'should select overall stats' do
      stats = EolStatistic.overall
      EolStatistic.sorted_report_attributes(:overall).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select content_partner stats' do
      stats = EolStatistic.content_partners
      EolStatistic.sorted_report_attributes(:content_partners).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select page_richness stats' do
      stats = EolStatistic.page_richness
      EolStatistic.sorted_report_attributes(:page_richness).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select curator stats' do
      stats = EolStatistic.curators
      EolStatistic.sorted_report_attributes(:curators).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select lifedesk stats' do
      stats = EolStatistic.lifedesks
      EolStatistic.sorted_report_attributes(:lifedesks).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select marine stats' do
      stats = EolStatistic.marine
      EolStatistic.sorted_report_attributes(:marine).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select users data objects stats' do
      stats = EolStatistic.users_data_objects
      EolStatistic.sorted_report_attributes(:users_data_objects).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select data objects stats' do
      stats = EolStatistic.data_objects
      EolStatistic.sorted_report_attributes(:data_objects).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select data stats' do
      stats = EolStatistic.data
      EolStatistic.sorted_report_attributes(:data).map{|attribute| stats[0].has_attribute?(attribute).should be_true}
    end
    it 'should select something from a week ago' do
      stats = EolStatistic.at_least_one_week_ago(1).first
      EolStatistic.sorted_report_attributes(:overall).map{|attribute| stats.has_attribute?(attribute).should be_true}
      stats.should == @second
    end
    it 'should select latest' do
      stats = EolStatistic.latest(1).first
      EolStatistic.sorted_report_attributes(:overall).map{|attribute| stats.has_attribute?(attribute).should be_true}
      stats.should == @latest
    end
  end

  it 'should create rich_hotlist_pages_percentage' do
    @first.rich_hotlist_pages.class.should == Fixnum
    @first.hotlist_pages.class.should == Fixnum
    @first.rich_hotlist_pages_percentage.class.should == Float
  end

  it 'should create rich_redhotlist_pages_percentage' do
    @first.rich_redhotlist_pages.class.should == Fixnum
    @first.redhotlist_pages.class.should == Fixnum
    @first.rich_redhotlist_pages_percentage.class.should == Float
  end

  it 'should create prepare greatest values for rich_hotlist_pages_percentage' do
    stat1 = EolStatistic.gen()
    stat2 = EolStatistic.gen()
    stat1.greatest.should be_nil
    stat2.greatest.should be_nil

    attribute_names = stat1.attribute_names + [ 'rich_hotlist_pages_percentage', 'rich_redhotlist_pages_percentage' ] - [ 'id', 'created_at' ]
    EolStatistic.compare_and_set_greatest(stat1, stat2)
    [ stat1, stat2 ].each do |stat|
      stat.greatest.class.should == Hash
      attribute_names.each do |att|
        stat.greatest[att.to_sym].should == (stat.send(att) == [ stat1.send(att), stat2.send(att) ].max)
      end
    end
  end

end
