class ForumTopic < ActiveRecord::Base

  belongs_to :forum
  belongs_to :user
  belongs_to :first_post, :class_name => 'ForumPost', :foreign_key => :first_post_id
  belongs_to :last_post, :class_name => 'ForumPost', :foreign_key => :last_post_id
  has_many :forum_posts

  accepts_nested_attributes_for :forum_posts

  after_create :increment_forum_count

  private

  def increment_forum_count
    forum.update_attributes(:number_of_topics => forum.number_of_topics + 1)
  end

end
