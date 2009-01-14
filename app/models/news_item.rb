class NewsItem < ActiveRecord::Base
  
  belongs_to :user
  
  validates_presence_of :body
  
  def visible?
    self.activated_on <= Time.now && self.active
  end
  
  # title or body (max 250 chars), stripped of HTML
  def summary
    if self.title.blank?
      result=self.body.length < 250 ? self.body : self.body[0..250] + "..."
    else
      result=self.title
    end
    result.gsub(/<\/?[^>]*>/, "")
  end

  def value
    self.title.blank? ? self.body : self.title
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: news_items
#
#  id           :integer(4)      not null, primary key
#  user_id      :integer(4)
#  active       :boolean(1)      default(TRUE)
#  body         :string(1500)    not null
#  display_date :datetime
#  title        :string(255)     default("")
#  activated_on :datetime
#  created_at   :datetime
#  updated_at   :datetime

