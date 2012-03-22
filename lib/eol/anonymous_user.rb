module EOL
  class AnonymousUser

    # Anonymous users are LANGUAGE-SPECIFIC.
    def initialize(lang)
      @lang = lang
    end

    # This ensures that a whole bunch of method calls will "just work" on anonymous users:
    def method_missing(method, *args, &block)
      known = defaults
      known.has_key?(method.to_sym) ? known[method.to_sym] : raise("Anonymous Users cannot #{method}")
    end

    # If this isn't defined, you end up with lots of "Object#id deprecated" errors.
    def id
      0
    end

    # This actually does require a little logic, so can't be a default:
    # NOTE - returns self for convenience; objects can call things like #is_admin? on this object, but not on nil.
    def can_read?(object)
      object.respond_to?(:can_be_read_by?) ? object.can_be_read_by?(self) : false
    end

    def defaults
      Language
      @defaults ||=
        $CACHE.fetch("anonymous/#{@lang}") do
          {:agent => nil,
          :agreed_with_terms => false,
          :all_collections => [],
          :blank? => true,
          :can_create? => false,
          :can_delete? => false,
          :can_edit_collection? => false,
          :can_manage_community? => false,
          :can_update? => false,
          :content_page_cache_str => 'anonymous',
          :default_hierarchy_id => nil,
          :email => '',
          :filter_content_by_hierarchy => nil,
          :full_name => I18n.t(:anonymous_user_full_name),
          :given_name => I18n.t(:anonymous_user_given_name),
          :ignored_data_object? => false,
          :is_admin? => false,
          :is_curator? => false,
          :language => Language.default,
          :log_activity => nil,
          :logo_url => nil,
          :member_of => false,
          :members => [],
          :min_curator_level? => false,
          :nil? => true,
          :rating_for_object_guids => nil,
          :save => false,
          :selected_default_hierarchy => Hierarchy.default,
          :short_name => I18n.t(:anonymous_user_given_name),
          :tag_line => I18n.t(:anonymous_user_tag_line),
          :username => I18n.t(:anonymous_user_given_name),
          :vetted => false,
          :watch_collection => nil}
        end
    end

  end
end
