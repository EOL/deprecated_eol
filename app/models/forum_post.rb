class ForumPost < ActiveRecord::Base

  belongs_to :forum_topic
  belongs_to :user

  validates_presence_of :text
  validate :text_should_be_more_than_whitespace
  validate :subject_must_exist_if_first_post

  after_create :update_topic
  after_create :update_forum
  before_update :increment_edit_count

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
    return subject unless subject.blank?
    "(no subject)"
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

  private

  def update_topic
    if forum_topic.first_post.nil?
      forum_topic.update_attributes(:first_post_id => id)
    end
    forum_topic.update_attributes(:number_of_posts => forum_topic.number_of_posts + 1, :last_post_id => id)
  end

  def update_forum
    forum_topic.forum.update_attributes(:number_of_posts => forum_topic.forum.number_of_posts + 1, :last_post_id => id)
  end

  def increment_edit_count
    if self.edit_count.nil?
      self.edit_count = 1
    else
     self.edit_count += 1
    end
  end

end
