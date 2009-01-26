require File.dirname(__FILE__) + '/../spec_helper'

describe ContentSection, 'with fixtures' do

  fixtures :content_sections, :content_pages

  it 'should have a home page section with one content page' do
    @home_page = ContentSection.find_by_name('Home Page', :include => :content_pages)
    @home_page.should_not be_nil
    @home_page.content_pages.length.should == 1
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: content_sections
#
#  id           :integer(4)      not null, primary key
#  language_key :string(255)     not null, default("")
#  name         :string(255)     not null, default("")
#  created_at   :datetime
#  updated_at   :datetime

