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

    # They have never rated anything!
    def rating_for_guid(*args)
      0
    end

    # They have never rated anything!
    def ratings_for_guids(*args)
      {}
    end

    # This can actually be dynamic:
    def language
      @lang_object ||= @lang.is_a?(Language) ? @lang : Language.find_by_iso_639_1(@lang)
    end
    def language_id
      language.id
    end
    def language_abbr
      language.iso_639_1
    end

    # This actually does require a little logic, so can't be a default:
    # NOTE - returns self for convenience; objects can call things like #is_admin? on this object, but not on nil.
    def can_read?(object)
      object.respond_to?(:can_be_read_by?) ? object.can_be_read_by?(self) : false
    end

    def can_see_data?
      EolConfig.data?
    end

    def defaults
      @defaults ||=
        Rails.cache.fetch("anonymous/#{@lang}") do
          {:active => true,
          :active? => true,
          :agent => nil,
          :agreed_with_terms => true, # Because we don't want to redirect them
          :all_collections => [],
          :assistant_curator? => false,
          :blank? => true,
          :can? => false,
          :can_create? => false,
          :can_delete? => false,
          :can_edit_collection? => false,
          :can_manage_community? => false,
          :can_update? => false,
          :content_page_cache_str => 'anonymous',
          :credentials => '',
          :curator_scope => '',
          :default_language? => true,
          :email => '',
          :full_name => I18n.t(:anonymous_user_full_name),
          :given_name => I18n.t(:anonymous_user_given_name),
          :ignored_data_object? => false,
          :is_admin? => false,
          :is_curator? => false,
          :log_activity => nil,
          :logo_url => nil,
          :member_of => false,
          :members => [],
          :min_curator_level? => false,
          :nil? => true,
          :save => false,
          :short_name => I18n.t(:anonymous_user_given_name),
          :tag_line => I18n.t(:anonymous_user_tag_line),
          :username => I18n.t(:anonymous_user_given_name),
          :vetted => false,
          :visibility_types => ['visible'],
          :vetted_types => ['trusted', 'unreviewed'],
          :news_in_preferred_language => false,
          :watch_collection => nil}
        end
    end

  end
end
