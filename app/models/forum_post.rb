class ForumPost < ActiveRecord::Base

  belongs_to :forum_topic
  belongs_to :user

  scope :visible, where(deleted_at: nil)

  validates_presence_of :text
  validate :text_should_be_more_than_whitespace
  validate :subject_must_exist_if_first_post

  after_create :update_topic
  after_create :update_forum
  after_create :update_user_posts_count
  after_update :update_topic
  after_update :update_forum
  after_update :update_user_posts_count
  before_update :increment_edit_count
  after_update :update_topic_title

  def can_be_deleted_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin? || forum_topic.first_post.user == user_wanting_access
  end
  def can_be_updated_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin? || forum_topic.first_post.user == user_wanting_access
  end

  def reply_to_subject
    if subject.strip =~ /^re:/i
      return subject.strip
    end
    return "Re: " + subject
  end

  def display_subject
    return I18n.t('forums.posts.deleted_subject') if deleted?
    return subject unless subject.blank?
    I18n.t('forums.posts.no_subject')
  end

  def text_should_be_more_than_whitespace
    test_text = (text.nil?) ? '' : text.dup
    test_text.gsub!(/(<p>|<\/p>|&nbsp;)/im, '')
    test_text.gsub!(/[\n\r\t ]/im, '')
    errors.add('text', I18n.t('errors.messages.blank')) if errors.blank? && test_text.strip == ''
  end

  def subject_must_exist_if_first_post
    if forum_topic_id.nil? || forum_topic.forum_posts.minimum(:id) == id
      errors.add('subject', I18n.t('errors.messages.blank')) if subject.blank? || subject.strip.blank?
    end
  end

  def topic_starter?
    self == forum_topic.first_post
  end

  def page_in_topic
    ((forum_topic.forum_posts.select(:id).index(self)) / ForumTopic::POSTS_PER_PAGE) + 1
  end

  def deleted?
    deleted_at != nil
  end

  private

  def update_topic
    forum_topic.set_first_post
    forum_topic.set_last_post
    forum_topic.set_post_count
  end

  def update_forum
    forum_topic.forum.update_last_post_and_count
  end

  def update_topic_title
    if topic_starter?
      forum_topic.update_attributes(title: subject)
    end
  end

  def increment_edit_count
    if self.edit_count.nil?
      self.edit_count = 1
    else
     self.edit_count += 1
    end
  end

  def update_user_posts_count
    user.update_column(:number_of_forum_posts, user.forum_posts.visible.count)
    user.expire_primary_index
  end
end
