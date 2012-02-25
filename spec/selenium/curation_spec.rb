require File.dirname(__FILE__) + '/../spec_helper'

def create_curator_for_taxon_concept(tc)
 curator = build_curator(tc)
 return curator
end

describe 'Curation' do

  before(:all) do
    Capybara.reset_sessions!
  end

  after(:all) do
    truncate_all_tables
  end

  before(:each) do
    ActiveRecord::Base.connection.execute('set AUTOCOMMIT=1')
  end

  after(:each) do
    visit('/logout')
  end

  it 'should only run this with selenium tests' do
    puts "I am here"
    false.should be_true
  end

end
