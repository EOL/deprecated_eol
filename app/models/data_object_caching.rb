class DataObjectCaching

  attr_accessor :data_object

  DEFAULT_EXPIRATION = 12.hours

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

  def associations(filter)
    cache_name = DataObject.cached_name_for("title_#{data_object.id}_#{language.id}")
  end

  # The only filter allowed right now is :published.
  def associations(filter = nil)
    store_value("associations_#{data_object.id}_#{filter}") do
      data_object.uncached_data_object_taxa(filter)
    end
  end

  private

  def store_value(name, &block)
    cache_name = DataObject.cached_name_for(name)
    value = Rails.cache.fetch(cache_name, expires_in: DEFAULT_EXPIRATION) do
      yield
    end
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
