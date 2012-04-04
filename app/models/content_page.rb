# The top nav bar of the site is geared to handle ContentSection (q.v.) sections, each of which has one or more ContentPage
# objects associated with it.  These pages are static content *or* links to external resources, and can be edited by
# administrators.
class ContentPage < $PARENT_CLASS_MUST_USE_MASTER
  uses_translations

  belongs_to :parent, :class_name => ContentPage.to_s, :foreign_key => 'parent_content_page_id'
  has_many :children, :class_name => ContentPage.to_s, :foreign_key => 'parent_content_page_id', :order => 'sort_order'

  #has_many :content_page_archives, :order => 'created_at DESC', :limit => 15
  belongs_to :user, :foreign_key => 'last_update_user_id'

  accepts_nested_attributes_for :children
  accepts_nested_attributes_for :translations, :allow_destroy => true

  before_destroy :give_children_new_parent
  before_destroy :archive_self
  before_destroy :destroy_translations # TODO: can we have :dependent => :destroy on translations rather than this custom callback?


  validates_presence_of :page_name
  validates_length_of :page_name, :maximum => 255
  validates_uniqueness_of :page_name, :scope => :id
  # TODO: add unique index of page_name in db ?
  # TODO: Validate format of page name alphanumeric and underscores only - when we move to machine names

  index_with_solr :keywords => [:title, :main_content]

  def can_be_read_by?(user_wanting_access)
    user_wanting_access.is_admin? || active?
  end
  def can_be_created_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end
  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end
  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end

  def self.get_navigation_tree(page_id)
    if (page_id)
      content_page = ContentPage.find(page_id)
      if content_page.parent_content_page_id
        return get_navigation_tree(content_page.parent_content_page_id) + " > " + content_page.page_name
      else
        return content_page.page_name
      end
    end
  end

  def self.get_navigation_tree_with_links(page_id)
    if (page_id)
      content_page = ContentPage.find(page_id)
      if content_page.parent_content_page_id
        parent_content_page = self.find(content_page.parent_content_page_id)
        return get_navigation_tree_with_links(content_page.parent_content_page_id) + "<a href='/content/page/#{parent_content_page.id}'>" + parent_content_page.page_name + "</a> > "
      else
        return ''#content_page.page_name
      end
    end
  end

  def self.find_top_level
    # get pages where parent is null
    ContentPage.find_all_by_parent_content_page_id(nil, :order => 'sort_order', :include => [ :translations, :children ])
  end

  def self.max_view_order_by_parent_id(parent_id)
    condition = parent_id.blank? ? " IS NULL" : " = #{parent_id}"
    self.connection.select_values("SELECT max(id) FROM content_pages WHERE parent_content_page_id #{condition}")[0].to_i
  end


  def not_available_in_languages(force_exist_language)
    if self.id
      languages = []
      languages << force_exist_language if force_exist_language
      languages += Language.find_by_sql("SELECT l.* FROM languages l
          LEFT JOIN translated_content_pages tcp ON (l.id=tcp.language_id AND tcp.content_page_id=#{self.id})
          WHERE tcp.id IS NULL AND l.activated_on <= '#{Time.now.to_s(:db)}' order by sort_order ASC")
    else
      return Language.find_active
    end
  end

  def self.update_sort_order_based_on_deleting_page(parent_content_page_id, sort_order)
    condition = parent_content_page_id.blank? ? " IS NULL" : " = #{parent_content_page_id}"
    self.connection.execute("UPDATE content_pages
      SET sort_order = sort_order - 1
      WHERE parent_content_page_id #{condition}
      AND sort_order > #{sort_order}")
  end

  def page_url
    all_pages_with_this_name = ContentPage.find_all_by_page_name(page_name)
    if all_pages_with_this_name.count > 1 && all_pages_with_this_name.first != self
      return self.id
    else
      return self.page_name.gsub(' ', '_').downcase
    end
  end

  def alternate_page_url
    all_pages_with_this_name = ContentPage.find_all_by_page_name(page_name)
    if all_pages_with_this_name.count == 1
      return self.id
    end
  end

  def logo_url(size = 'large', specified_content_host = nil)
    return "v2/logos/cms_pages.png"
  end

private

  def give_children_new_parent
    # TODO: Use nested attributes if we can get it to work properly
    children.map{|c| c.parent_content_page_id = parent_content_page_id}
    save
  end

  def archive_self
    ContentPageArchive.backup(self)
  end

  def destroy_translations
    translations.each do |translated_content_page|
      translated_content_page.destroy
    end
  end

end

