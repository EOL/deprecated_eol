require 'ruby-debug'
require 'haml'


desc 'Tasks useful for i18n updates'
namespace :i18n_update do
  lang_dir = Rails.root.join("config", "locales")
  gibberish_lang_dir = Rails.root.join("lang")
  en_file = "translation_template.yml"
  tmp_file = File.join([lang_dir, "tmp.yml"])
  en_yml = File.join([lang_dir, "en.yml"])
  trans_tmp = File.join([lang_dir, "translation_template.yml"])

  
  desc 'task to clean up strings that have a colon at the end of them to have _colon at the end of the key (in both the yml file and in the source code).'
  task :clean_colon_strings do

    def load_yml_file(file_path)
      read_file = open(file_path)
      file_content = ''
      read_file.read.each do |line|
        if line.match(/^\s\s([\w_?]*):\s/)
          file_content << line.strip
          file_content << "\n"
        end

      end
      read_file.close
      return YAML.load(file_content)
    end   

    def get_all_files_in_app
      Dir.chdir(Rails.root.join("app"))
      return Dir.glob(File.join("**", "*.{rb,haml,erb}"))
    end

    def update_keys_at_file(file_content, keys_array)

      temp_keys = file_content.split(/I18n.t(ranslate)*/)

      if (temp_keys.size==1)
        # no I18n keys in this file, return the same file_content
        return file_content
      else
        # ignore the first item in the array, from the second item, each will start with the key
        for i in (1..temp_keys.size-1)
          key = ""
          if temp_keys[i].match (/^(\s*\()/) # matchs I18n.t(xxxx)
            if temp_keys[i].strip != '(' # to avoid error from nested I18n.t
              temp_str = temp_keys[i].strip.gsub('(','').strip.split(")")[0].split(",")[0]
              if (temp_str.index("\"") or temp_str.index("'") or temp_str.index(":"))
                key = temp_str.strip.gsub("\"", "").gsub(":","").gsub("'","")
              end
            end
          elsif temp_keys[i].match(/^\s(\')/) # matchs I18n.t 'xxx'
            temp_str = temp_keys[i].strip[1..-1].split("'")[0] # trim then remove the first ' then split on the next ' and get the key
            key = temp_str.strip
          elsif temp_keys[i].match(/^\s(\")/) # matchs I18n.t "xxx"
            temp_str = temp_keys[i].strip[1..-1].split('"')[0] # trim then remove the first " then split on the next " and get the key
            key = temp_str.strip
          elsif temp_keys[i].match(/^\s(\:)/) # matchs I18n.t :xxx
            temp_str = temp_keys[i].strip[1..-1].split(/(,|\s|$|\Z)/)[0] # trim then remove the first : then split on the next comma, space, or a new line, end of line, or end of string
            key = temp_str.strip
          end
          
          if (key != "")            
            new_key = get_sub_key_name(key, keys_array)
            if (key != new_key)
              puts "  Replacing \"" + key + "\" with \"" + new_key + "\""
              temp_keys[i] = temp_keys[i].gsub(":" + key, ":" + new_key)
              temp_keys[i] = temp_keys[i].gsub("\"" + key + "\"", "\"" + new_key + "\"")
              temp_keys[i] = temp_keys[i].gsub("\'" + key + "\'", "\'" + new_key + "\'")
            end
          end       
        end
        
        new_file_content = temp_keys[0]
        for i in (1..temp_keys.size-1)
          new_file_content = new_file_content + "I18n.t" + temp_keys[i]
        end
        return new_file_content
        
      end          
      
    end 

    def get_sub_key_name(old_key, keys_array)
      new_key = old_key
      keys_array.each do |key|        
        if (old_key==key.split(":")[0])
          new_key = key.split(":")[1]
          return new_key
        end
      end
      return old_key
    end

    def get_keys_with_colon(en_yml_keys)
      colon_keys = Array.new
      en_yml_keys.each do |key, value|
        if (value.to_s.end_with? ":" or value.to_s.end_with? "." or value.to_s.end_with? ",") and key.to_s.end_with? "_"
          colon_keys << key
        end
      end
      return colon_keys
    end

    def generate_key(string_value)
      string_array = string_value.split('')
      return_string = ''
      for i in (0..string_array.length-1)
        if (i==string_array.length-1 and string_array[i]==".")
          #puts 'escaping last . in the line'
        else
          if (string_array[i].match(/[a-zA-Z0-9]/))
            return_string << string_array[i].downcase
          else
            if (string_array[i]!='#' and string_array[i]!='{' and string_array[i]!='}' and string_array[i]!='%')
              case string_array[i]
                when ':'
                  return_string << '_colon'
                when '.'
                  return_string << '_dot'
                when ','
                  return_string << '_comma'
                else
                  return_string << '_'
              end
            end
          end
        end
      end
      if (return_string.length>30)
        return_string = return_string[0,30]
      end
      return return_string
    end

    def update_yml_file_with_new_keys(en_yml, updated_keys)
      file_open = open(en_yml, "r")
      file_content = file_open.read
      file_open.close
      
      updated_keys.each do |key|
        file_content = file_content.gsub("  " + key.split(":")[0] + ":", "  " + key.split(":")[1] + ":")
      end
      
      file_open = open(en_yml, "w")
      file_open.write file_content
      file_open.close
    end

    def check_for_duplicate_key(en_keys, key)
      if (en_keys[key])
        return check_for_duplicate_key(en_keys, key + "_copy")   
      else
        return key
      end
    end

  
    en_yml_keys = load_yml_file(en_yml)
    
    #getting keys to be updated
    colon_keys = get_keys_with_colon(en_yml_keys)
    #generating new keys
    updated_keys = Array.new

    colon_keys.each do |key|      
      new_key = generate_key(en_yml_keys[key])
      check_for_duplicate_key(en_yml_keys, new_key)
      if (key != new_key) # key is too large and it's been cut, so colon will not matter
        updated_keys << key + ":" + new_key
      end      
      
    end

    #Scanning files for updated keys
    all_files = get_all_files_in_app

    all_files.each do |file|
      puts "checking: " + file
      file_open = open(file, "r")
      file_content = file_open.read
      file_open.close

      file_content = update_keys_at_file(file_content, updated_keys)

      file_open = open(file, "w")
      file_open.write(file_content)
      file_open.close
      
    end

    puts "updating en.yml file"
    update_yml_file_with_new_keys(en_yml, updated_keys)

  end

end
