class SiteConfigurationOption < ActiveRecord::Base

  after_create :clear_caches
  after_update :clear_caches
  validates_uniqueness_of :parameter
  
  def self.reference_parsing_enabled
    cached_find(:parameter, 'reference_parsing_enabled')
  end
  
  def self.reference_parser_endpoint
    cached_find(:parameter, 'reference_parser_endpoint')
  end
  
  def self.reference_parser_pid
    cached_find(:parameter, 'reference_parser_pid')
  end

  def self.method_missing(name, *args, &block)
    # The regex here keeps us from going into a wild loop, because cached_find called find_by_[param], which is found
    # via method_missing in the rails code!
    if name !~ /^find/ && SiteConfigurationOption.exists?(:parameter => name)
      if param = cached_find(:parameter, name)
        param.value
      else
        super
      end
    else
      super
    end
  end

  def clear_caches
    Rails.cache.fetch("application/#{self.parameter}") if self.parameter
  end

end
