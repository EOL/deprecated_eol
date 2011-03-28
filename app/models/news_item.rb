class NewsItem < ActiveRecord::Base
  uses_translations
  belongs_to :user
  
  
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

