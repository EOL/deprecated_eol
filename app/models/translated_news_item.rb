class TranslatedNewsItem < ActiveRecord::Base
  belongs_to :news_item
  belongs_to :language
  validates_presence_of :title, :if => Proc.new {|m| m.body.blank? }; validates_presence_of :body,  :if => Proc.new {|m| m.title.blank? }
end
