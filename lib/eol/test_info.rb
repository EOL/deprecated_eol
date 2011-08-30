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

      if data.is_a? Hash # ...and it should be...
        data.keys.each do |k|
          begin
            data[k].to_yaml
          rescue => e
            puts "+" * 200
            puts "++ ATTEMPT TO WRITE AN INVALID VALUE TO SCENARIO FILE!\n++ Key: #{k}\n++ Value: #{data[k]}"
            raise e
          end
        end
      end

      File.open(file_for(name), "w") do |f|
        test_info_yaml = data.deep_stringify_keys.to_yaml
        # this will remove any Proc statements from the YAML file. Procs were being used in validations
        # for models using the Paperclip plugin to attach icons
        test_info_yaml.gsub!(/^\s*- \!ruby\/object:Proc \{\}\n/, '')
        f.write(test_info_yaml)
      end

    end

    def self.load(name)
      hash = YAML::load_file(file_for(name))
    end

    def self.file_for(name)
      File.join(RAILS_ROOT, 'tmp', "#{name}_test_info.yml")
    end

  end
end
