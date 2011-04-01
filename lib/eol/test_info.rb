# Logic basically stolen from http://iain.nl/2009/05/writing-yaml-files/
class Hash
  def deep_stringify_keys
    new_hash = {}
    self.each do |key, value|
      new_hash.merge!(key.to_s => (value.is_a?(Hash) ? value.deep_stringify_keys : value))
    end
  end
end

module EOL
  class TestInfo
    def self.save(name, data)
      File.open(file_for(name), "w") do |f|
        f.write(data.deep_stringify_keys.to_yaml)
      end
    end
    def self.load(name)
      YAML::load_file(file_for(name))
    end
    def self.file_for(name)
      File.join(RAILS_ROOT, 'tmp', "#{name}_test_info.yml")
    end 
  end
end
