require 'ruby-debug'
desc 'Tasks useful for internatiolization'

namespace :i18n do
  lang_dir = File.join([RAILS_ROOT, "lang"])
  en_file = "translation_template.yml"
  tmp_file = File.join([lang_dir, "tmp.yml"])
  
  desc 'syncronizes files used for internationalization of EOL interface'
  task :sync do
    en = open(File.join([lang_dir, en_file]))
    en_data = YAML.load(en)
    en.close
    Dir.glob(File.join([lang_dir, "*"])).each do |file|
      file_name = File.split(file)[-1]
      if file_name != en_file && file != tmp_file
        en = open(File.join([lang_dir, en_file]))
        tmp = open(tmp_file, 'w')
        lang = open(file)
        data = YAML.load(lang)
        lang.close
        if data
          en.read.each do |line|
            key = line.match(/^([\w_?]*):\s/)
            if key
              key = key[1] if key
              value = data[key]
              if en_value = en_data[key]
                no_translation = value ? false : true
                value = no_translation ? en_value : value
                new_line = no_translation ? "#TODO #{key}:" : "#{key}: \"#{value.gsub('"', '\"')}\""
                tmp.write(new_line + "\n")
              else
                puts "#{file} has data which are not in the english template: #{key[1]}"
              end
            else
              tmp.write line
            end
          end
        else
          puts "no data generated for #{file}"
        end
        tmp.close
        en.close
        begin
          tmp = open(tmp_file)
          data = YAML.load(tmp)
          tmp.close
          File.rename(tmp_file, file)
        rescue ArgumentError
          puts "could not create valid YAML for #{file_name}"
          File.delete tmp_file
        end
      end
    end
  end
  
  desc "find strings which are not in template yet"
  task :update_template do
    tmp = open(tmp_file, 'w')
    data = YAML.load(open(File.join(lang_dir, en_file)))
    new_keys = {}
    named_keys = []
    Dir.glob(File.join([RAILS_ROOT, "app", "views", "**", "*"])).each do |file|
      if file.match(/(erb|haml)$/)
        open(file).read.each_with_index do |line, count|
          if key = line.match(/=\s*\#?\{?\s*"([^<>="]*?)"\[\]/)
            value = key[1]
            key =  key[1].gsub(/[^\w\d\s]/, '').strip.downcase.gsub(/\s+/, "_")
            if !data.key?(key) && !new_keys.key?(key)
              new_keys[key] = value
              tmp.write "##{file}:#{count+1}\n"
              tmp.write"%s: \"%s\"\n" % [key, value.gsub('"', "\"")]
            end
          end
          if key = line.match(/"\[\s*:([\w_]*)\b/)
            key = key[1]
            if !data.key?(key) && !new_keys.key?(key)
              new_keys[key] = ''
              named_keys << "##{file}:#{count+1}\n"
              named_keys << "%s: \"\"\n" % [key]
            end
          end
        end
      end
    end
    named_keys.each do |line|
      tmp.write(line)
    end
    puts "\nPotential key/value pairs are added to #{tmp_file}\nEdit this file and append it to template file.\n\nPlease delete #{tmp_file} when you are done.\n\n"
  end
end

