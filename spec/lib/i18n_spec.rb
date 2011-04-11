require File.dirname(__FILE__) + '/../spec_helper'

describe 'I18n' do  
  
  lang_dir = File.join([RAILS_ROOT, "config", "locales"])
  en_yml = File.join([lang_dir, "en.yml"])
  log_file = File.join([RAILS_ROOT, "log", "i18n_missing_keys.txt"])
  
  it 'check for language yml files consistency' do

    def load_en_keys(en_yml)
      # return array of keys
      en = open(en_yml)
      en_keys = Array.new
      key_count = 0
      en.read.each do |line|
        key = line.match(/^\s\s([\w_?]*):\s/)
        if key
          key = key[1] if key
          if key
            en_keys[key_count] = key
            key_count = key_count + 1
          end
        end
      end
      en.close

      return en_keys
    end
    
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
    
    def get_missing_keys_count(file_path, en_keys, missing_keys, en_yml_keys)
      # returns number of missing keys at the langauge file comparing with the en file                        
      missing_count = 0
      lang_yml = load_yml_file(file_path)
      for i in (0..en_keys.length-1)      
        key = en_keys[i]   
        if ((!lang_yml[key]) or lang_yml[key] == '') 
          missing_count = missing_count + 1
          missing_keys << "  " + key + ": \"" + en_yml_keys[key]  + "\"\n" 
        end
      end
      return missing_count
    end
    
    en_keys = load_en_keys(en_yml)
    en_yml_keys = load_yml_file(en_yml)
    error_message = ''
    missing_keys = ''
    
    Dir.glob(File.join([lang_dir, "*"])).each do |file|
      file_name = File.split(file)[-1]
      if file_name != en_yml && file_name != File.split(en_yml)[-1] && file_name.match(/^[a-z]{2}\.yml\b/)
        missing_keys << "\n\n" if missing_keys != ''        
        missing_keys << file_name + ": \n"
                
        missing_count = get_missing_keys_count(file, en_keys, missing_keys, en_yml_keys)
        if (missing_count > 0)
          error_message = error_message + "\n" if error_message != ''
          error_message = error_message + missing_count.to_s + " missing keys in " + file_name          
        end
      end
    end
    
    # logging data in log file
    log_data = open(log_file, 'w')
    log_data.write missing_keys
    log_data.close
    
    if (error_message != '')
      error_message << "\n\nPlease check missing keys at " + log_file
      raise error_message
    end
    
  end	
end
