# EOL tweaks / extensions related to factory-girl ... could use some cleanup
module EOL::FactoryGirlActiveRecordBaseExtensions

  attr_accessor :factory_name

  # default factory name User => :user
  def factory_name
    @factory_name ||= self.name.underscore.downcase
  end

  # User.generate :username => 'bob'
  # NOTE that we trust the generator and skip URL validations.
  def generate *args
    skip_url_validations { FactoryGirl.create(factory_name, *args) }
  end
  alias gen generate

  # Use a factory to build an object that may already be there.  This syntax sucks.
  # NOTE - skips valid URL validations for those classes that listen to $SKIP_URL_VALIDATIONS
  def gen_if_not_exists(attributes)
    found = nil
    skip_url_validations do
      begin
        searchable_attributes = {}
        searchable_translation_attributes = {}
        associated_translation = nil
        attributes.keys.each do |key|
          # Specified ids could be stored as Fixnum, not just int:
          if attributes[key].class == String or attributes[key].class == Integer or attributes[key].class == Fixnum or
            attributes[key].class == TrueClass or attributes[key].class == FalseClass
            if self.columns.map {|c| c.name.to_sym}.include? key
              searchable_attributes[key] = attributes[key]
            elsif defined?(self::USES_TRANSLATIONS) && self::USES_TRANSLATIONS
              if self::TRANSLATION_CLASS.columns.map {|c| c.name.to_sym}.include? key
                searchable_translation_attributes[key] = attributes[key]
              end
            end
          elsif attributes[key].class != Array
            key_id = "#{key}_id"
            key_id = 'toc_id' if key_id == 'toc_item_id'
            searchable_attributes[key_id] = attributes[key].id
          end
        end
        if searchable_translation_attributes.blank?
          # there are no fields which are to be translated
          found = self.find_existing_by_attributes(searchable_attributes)
          found = gen(searchable_attributes) if found.nil?
        else
          # we need to create a translation
          # sometimes the default language is not set, so we set it here
          if !searchable_translation_attributes['language_id']
            l = Language.gen_if_not_exists(:iso_639_1 => APPLICATION_DEFAULT_LANGUAGE_ISO)
            searchable_translation_attributes['language_id'] = l.id
          end
          
          # only look up the translated values if they are supposed to be unique (default)
          unless defined?(self::TRANSLATIONS_ARE_UNIQUE) && !self::TRANSLATIONS_ARE_UNIQUE
            associated_translation = self::TRANSLATION_CLASS.find_existing_by_attributes(searchable_translation_attributes)
          end
          associated_translation = self::TRANSLATION_CLASS.gen(searchable_translation_attributes) if associated_translation.nil?
          
          association_name = (factory_name == "language") ? "original_language" : factory_name
          # puts "associated_translation.#{association_name}"
          found = eval("associated_translation.#{association_name}")
          # pp found
          # pp associated_translation
          # add to the new record the attributes that don't belong in the translation
          searchable_attributes.each do |a, v|
            eval("found.#{a} = v if found.#{a} != v")
          end
          found.save
        end
      rescue ActiveRecord::RecordInvalid => e
        puts "** Invalid Record : #{e.message}"
      end
    end
    return found
  end
  
  def find_existing_by_attributes(attributes)
    begin
      # Assumes that .keys returns in same order as .values, which is appears is true:
      found = find(:first, :conditions => attributes) unless
        attributes.keys.blank?
    rescue NoMethodError
      raise "It seems there is a bad column on #{self}. One of its expected attributes seems to be missing: " +
            "#{attributes.keys.inspect}"
    end
  end

  def skip_url_validations(&block)
    old_val = $SKIP_URL_VALIDATIONS
    $SKIP_URL_VALIDATIONS = true
    begin
      yield
    ensure
      $SKIP_URL_VALIDATIONS = old_val
    end
  end

  # User.build :username => 'bob'
  #
  # calls 'new' instead of 'create'
  def build *args
    Factory.build factory_name, *args
  end
  alias spawn build

  # User.valid_attributes
  # User.generator
  # Factory.attributes_for(:user)
  #
  # gets the attributes for a new model
  def valid_attributes
    Factory.attributes_for factory_name
  end
  alias generator valid_attributes

end

# Extends all ActiveRecord::Base models with extensions 
# that integrate with factory-girl
ActiveRecord::Base.class_eval do
  extend EOL::FactoryGirlActiveRecordBaseExtensions
end
