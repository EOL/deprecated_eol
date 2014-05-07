# NOTE - This class has an unusual number of methods. I don't understand why.
# Typically, we don't "use" our translation models, we use the models to which
# the translation is attached. I'm not sure why we've made an exception, here.
# ...I'm assuming it's because we actively have users translating news items
# and need to act on the individual translations, but it would be nice to have
# that explained here.
class TranslatedNewsItem < ActiveRecord::Base
  belongs_to :news_item
  belongs_to :language

  validates_presence_of :title
  validates_presence_of :body

  validates_length_of :title, maximum: 255

  delegate :page_name, to: :news_item

  # TODO - these really shouldn't be called on a TranslatedNewsItem.
  # ...Find out where they're being called (if at all) and make
  # sure the check is on the NewsItem, not this.
  delegate :can_be_created_by?,
    :can_be_updated_by?, :can_be_deleted_by?,
    to: :news_item
  # This one actually uses different logic than the NewsItem.
  # TODO - find out why; it is not at all clear to me what this even means.
  def can_be_read_by?(user_wanting_access)
    user_wanting_access.is_admin? || active_translation?
  end

  def title_with_language
    title + " (" + self.language.iso_639_1 + ")"
  end

end
