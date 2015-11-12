class WikipediaQueue < ActiveRecord::Base

  self.table_name = "wikipedia_queue"

  belongs_to :user
  counter_culture :user
  attr_accessor :revision_url

  validates_presence_of :revision_id
  validates_presence_of :user_id

  def can_be_created_by?(user_wanting_access)
    user_wanting_access.is_admin? || user_wanting_access.is_curator?
  end

end

