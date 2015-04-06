class ContentCuration < ActiveRecord::Base
  belongs_to :content, inverse_of: :content_curations
  belongs_to :user, inverse_of: :content_curations
  
  has_many :items, through: :content
end
