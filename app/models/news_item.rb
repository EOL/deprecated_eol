class NewsItem < ActiveRecord::Base
  belongs_to :language
  
  validates_presence_of :title
  validates_presence_of :abstract
  
  def visible?
    self.activated_on <= Time.now && self.active
  end

  
end
