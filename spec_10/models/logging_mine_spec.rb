require File.dirname(__FILE__) + '/../spec_helper'
require 'eol_logging'

# this barely tests Logging::Mine anymore ... all Logging::Mine methods
# have been moved onto the models, themselves
#
# this might as well be be state_log_daily_spec ... this spec will likely be renamed and refactored a bit 
# and maybe combined with log_daily_spec
describe Logging::Mine, 'with fixtures' do
  fixtures :users, :data_objects, :data_types

  include Logging::Mine

  before(:each) do
    [ DataObjectLog, IpAddress, StateLogDaily, CountryLogDaily ].each do |model|
      model.delete_all
    end
  end

  it 'should create dailies for states' do
    ['AZ','AZ','CA','NC','NC','NC','CT'].each do |state|
      create_data_object_log :state => state
    end
    DataObjectLog.count.should == 7 # just incase ...

    StateLogDaily.count.should == 0
    StateLogDaily.mine
    StateLogDaily.count.should == 4 # there are 4 different states

    StateLogDaily.find_by_state_code('AZ').total.should == 2
    StateLogDaily.find_by_state_code('CA').total.should == 1
    StateLogDaily.find_by_state_code('NC').total.should == 3
    StateLogDaily.find_by_state_code('CT').total.should == 1

    # move grand_total stuff to its own spec
    totals = StateLogDaily.grand_totals
    totals.length.should == 4
    totals.inject(0){|total,daily| total += daily.total }.should == 7 # total of all totals, combined
    # ^ need to test that grand totals works with different dates and whatnot ...
  end

  # move to a spec for StateLogDaily or LogDaily ... it's already implemented but needs hardcore refactoring
  it '#grand_totals should accept a range'

  it 'should be able to mine certain date ranges (for states)' do
    [ '01/01', '01/01', '01/05', '01/06', '01/06', '01/06', '01/07' ].each do |date|
      create_data_object_log :state => 'AZ', :date => date
    end

    StateLogDaily.count.should == 0
    StateLogDaily.find_all_for_range( D['01/01']..D['12/31'] ).should be_empty

    # just mine a few of the days ...
    StateLogDaily.mine D['01/05']..D['01/06']
    StateLogDaily.count.should == 2
    StateLogDaily.find_by_day(D['01/06']).total.should == 3
    StateLogDaily.find_by_day(D['01/05']).total.should == 1
    StateLogDaily.find_by_day(D['01/01']).should be_nil
    StateLogDaily.find_all_for_range( D['01/01']..D['01/05'] ).length.should == 1

    # now mine everything ...
    StateLogDaily.mine
    StateLogDaily.count.should == 4
    StateLogDaily.find_all_for_range( D['01/01']..D['01/05'] ).length.should == 2
    StateLogDaily.find_all_for_range( D['01/07']..D['12/31'] ).length.should == 1
    StateLogDaily.find_by_day(D['01/01']).total.should == 2
  end

  it 'should create dailies for countries' do
    ['US','US','US','AU','CA','CA','BM'].each do |country|
      create_data_object_log :country => country
    end

    CountryLogDaily.count.should == 0
    CountryLogDaily.mine
    CountryLogDaily.count.should == 4 # there are 4 different countries

    CountryLogDaily.find_by_country_code('US').total.should == 3
    CountryLogDaily.find_by_country_code('AU').total.should == 1
    CountryLogDaily.find_by_country_code('CA').total.should == 2
    CountryLogDaily.find_by_country_code('BM').total.should == 1
  end

  it 'should create dailies for users' # and various other things ... we'll make more mining classes as needed
  it 'should create dailies for popular sources'
  it 'should create dailies for popular species'
  it 'should report popular data objects, by type'

end
