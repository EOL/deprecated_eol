require File.dirname(__FILE__) + '/../spec_helper'
describe EolStatistic do
  before(:all) do
    EolStatistic.gen
  end
  it 'should select overall stats' do
    stats = EolStatistic.overall()
    EolStatistic.report_attributes['overall'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
  end
   it 'should select content_partner stats' do
     stats = EolStatistic.content_partners()
     EolStatistic.report_attributes['content_partner'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select page_richness stats' do
     stats = EolStatistic.page_richness()
     EolStatistic.report_attributes['page_richness'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select curator stats' do
     stats = EolStatistic.curators()
     EolStatistic.report_attributes['curator'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select lifedesk stats' do
     stats = EolStatistic.lifedesks()
     EolStatistic.report_attributes['lifedesk'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select marine stats' do
     stats = EolStatistic.marine()
     EolStatistic.report_attributes['marine'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select user_added_data stats' do
     stats = EolStatistic.user_added_data()
     EolStatistic.report_attributes['user_added_data'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select data_object stats' do
     stats = EolStatistic.data_objects()
     EolStatistic.report_attributes['data_object'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should not select data_object stats' do
     stats = EolStatistic.lifedesks()
     EolStatistic.report_attributes['data_object'].select{|attribute| attribute != :created_at}.map{|attribute| stats[0].has_attribute?(attribute).should be_false}
   end
end
