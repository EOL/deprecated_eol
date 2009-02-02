require File.dirname(__FILE__) + '/../spec_helper'

describe 'Search' do

  scenario :foundation, :before => :all

  it 'should return a helpful message if no results' do
    request('/search?q=tiger').body.should include("Your search on 'tiger' did not find any matches")
  end

  it 'should redirect to species page if only 1 possible match is found'

  it 'should show a list of possible results if more than 1 match is found'
  
end
