require File.dirname(__FILE__) + '/../spec_helper'
describe EolStatistic do
  before(:all) do
    EolStatistic.gen
  end
  it 'should select overall stats' do
    stats = EolStatistic.overall
    EolStatistic.report_attributes['overall'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
  end
   it 'should select content_partner stats' do
     stats = EolStatistic.content_partners
     EolStatistic.report_attributes['content_partners'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select page_richness stats' do
     stats = EolStatistic.page_richness
     EolStatistic.report_attributes['page_richness'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select curator stats' do
     stats = EolStatistic.curators
     EolStatistic.report_attributes['curators'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select lifedesk stats' do
     stats = EolStatistic.lifedesks
     EolStatistic.report_attributes['lifedesks'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select marine stats' do
     stats = EolStatistic.marine
     EolStatistic.report_attributes['marine'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select users data objects stats' do
     stats = EolStatistic.users_data_objects
     EolStatistic.report_attributes['users_data_objects'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
   it 'should select data objects stats' do
     stats = EolStatistic.data_objects
     EolStatistic.report_attributes['data_objects'].map{|attribute| stats[0].has_attribute?(attribute).should be_true}
   end
end
