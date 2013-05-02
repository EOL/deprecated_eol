class DataObjectCaching

  attr_accessor :data_object

  DEFAULT_EXPIRATION = 12.hours
  PRELOAD_ARRAYS = {
    CuratedDataObjectsHierarchyEntry =>
      [:vetted, :visibility, :data_object, :user, {:hierarchy_entry => [:name, :taxon_concept]}],
    DataObjectsHierarchyEntry =>
      [:vetted, :visibility, :data_object, {:hierarchy_entry => [:name, :taxon_concept]}],
    UsersDataObject =>
      [:vetted, :visibility, :data_object, :user, :taxon_concept]
  }

  class << self

    def clear(data_object)
      DataObjectCaching.new(data_object).clear
    end

    def title(data_object, language)
      DataObjectCaching.new(data_object).title(language)
    end

    def associations(data_object, filter = nil)
      DataObjectCaching.new(data_object).associations(filter)
    end

  end

  def initialize(dato)
    @data_object = dato
  end

  def clear
    reg = registered[data_object.id]
    if reg
      registered[data_object.id].each do |name|
        Rails.cache.delete(name)
      end
    end
  end

  def title(language)
    store_value("title_#{data_object.id}_#{language.id}") do
      data_object.best_title
    end
  end

  # The only filter allowed right now is :published.
  # Some association lists are just too big, so we have to store a hash of the classes and ids used to build them.
  def associations(filter = nil)
    name = "associations_#{data_object.id}_#{filter}"
    assocs = []
    if exists?(name)
      assoc_hash = read(name) # Read the hash,
      assoc_hash.each do |key, values|
        # DataObjectsHierarchyEntry has CPK, so it's handled differently (and somewhat less efficiently):
        objects = key == DataObjectsHierarchyEntry ?
          DataObjectsHierarchyEntry.find_all(values) :
          key.send(:find, values)
        key.send(:preload_associations, objects, PRELOAD_ARRAYS[key])
        Array(objects).each do |this|
          assocs << DataObjectTaxon.new(this) # Rebuild the associations
        end
      end
    else
      store_value("associations_#{data_object.id}_#{filter}") do
        hash = {}
        assocs = data_object.uncached_data_object_taxa(filter)
        assocs.group_by { |el| el.source.class }.each do |k,v|
          hash[k] = v.map(&:source).map(&:id)
        end
        hash # Store the hash,
      end
    end
    assocs # Return the associations.
  end

  private

  def exists?(name)
    Rails.cache.exist?(DataObject.cached_name_for(name))
  end

  def read(name)
    Rails.cache.read(DataObject.cached_name_for(name))
  end

  def store_value(name, &block)
    cache_name = DataObject.cached_name_for(name)
    value = yield
    value.dup if value.frozen?
    Rails.cache.fetch(cache_name, expires_in: DEFAULT_EXPIRATION) { value }
    register(cache_name)
    value
  end

  def register(what)
    reg = registered.dup
    reg[data_object.id] ||= []
    unless reg[data_object.id].include?(what)
      reg[data_object.id] << what
      Rails.cache.write(DataObject.cached_name_for('register'), reg)
    end
  end

  def registered
    reg = Rails.cache.read(DataObject.cached_name_for('register'))
    return reg if reg
    clear_register
    return {}
  end

  def clear_register
    Rails.cache.write(DataObject.cached_name_for('register'), {})
  end

end
