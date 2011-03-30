require 'ruby-debug'
require 'haml'

desc 'Tasks useful for internatiolization'

namespace :i18n do
  lang_dir = File.join([RAILS_ROOT, "config", "locales"])
  gibberish_lang_dir = File.join([RAILS_ROOT, "lang"])
  en_file = "translation_template.yml"
  tmp_file = File.join([lang_dir, "tmp.yml"])
  en_yml = File.join([lang_dir, "en.yml"])
  trans_tmp = File.join([lang_dir, "translation_template.yml"])


  desc 'convert old yml language files from Gibberish format to support i18n '
  task :convert_yml do
    Dir.glob(File.join([gibberish_lang_dir,"*"])).each do |file|
      puts file
      if file.match(/\b[a-z]{2}\.yml\b/)
        lang = File.split(file)[-1][0..1]
        if lang=="en"
          puts " --No action"
        else
          cur_file = open(file)
          line = cur_file.readline
          line = line.gsub("\xEF\xBB\xBF", '')
          if(line.match(/^[a-z]{2}:/))
            converted=false
            cur_file.close
            puts " --Nothing to do, file already converted before."
          else
            tmp = open(tmp_file, 'w')
            tmp.write lang+":\n"
	    tmp.write "  "+line.gsub('{','%{')
            while (!cur_file.eof? && line = cur_file.readline)
              tmp.write "  " + line.gsub('{','%{')
            end
            tmp.close
            cur_file.close
            File.rename(tmp_file,File.join([lang_dir, lang + ".yml"]))
            puts " --Converted successfully :)"
	  end
        end
      else
        #File.delete file
        puts "  --Not a valid locale file"
      end
    end
  end

  desc 'Convert from Gibberish to i18n in all app/ files'
  task :gibberish_to_i18n do
    new_keys = {}
    named_keys = []

    #read en.yml file if already exist
    if File.exist?(en_yml)
      en = open(en_yml)
      write_type = 'a'
      en_content = ''
      en.read.each do |line|
        if line.match(/^\s\s([\w_?]*):\s/)
          en_content << line.strip + "\n"
        end
      end
      en.close
      new_keys  = YAML.load(en_content)
      puts "en.yml file exist and available contents are loaded"
    else
      write_type='w'
      named_keys << "en:\n"
      puts "New en.yml file will be created"
    end

    #loop on each file in the app folder
    Dir.glob(File.join([RAILS_ROOT, "app", "**", "*"])).each do |file|
      if file.match(/(erb|haml|rb)$/)
        tmp = open(tmp_file, 'w')
        puts "File: " + file + "\n"
        open(file).read.each_with_index do |line, count|
          begin
            found=false
            if wmatch = line.match(/\s*(("([^<>="]*?)")|('([^<>=']*?)'))\[\]/)
              value = wmatch[1][1..-2]
              key =  wmatch[1].gsub(/[^\w\d\s]/, '').strip.downcase.gsub(/\s+/, "_")
              found=true
              puts "KEY= "+key+"----VALUE="+value
            elsif wmatch = line.match(/(("([^<>="]*?)")|('([^<>=']*?)'))\[\s*:([\w\s_,.]*)\]/)
              value = wmatch[1][1..-2]
              key = wmatch[0].match(/\[\s*:[\w_]*\s*(\]|,)/).to_s.gsub(/(\[|\]|,|\s|:)+/,"")
	      if wmatch[0].match(/\[\s*:[\w_]*\s*,/)
                params= wmatch[0].split(":"+key)[-1][0..-2]
                param_keys = value.scan(/\{[\w_]*\}/)
                param_values = params.strip.split(",")
                params=""
                (0..param_keys.size-1).each do |i|
                  params+=" , :%s => %s"  % [ param_keys[i].strip[1..-2], param_values[i+1].strip ]
                end
                value = value.gsub('{','%{')
              end
              puts "KEY= "+key+"----VALUE="+value
              found=true
            end
            if found==true && key.length==0
               found=false
            end
            if found==true
              line = line.gsub(wmatch[0], " I18n.t(:%s%s) " % [key,params])
	      if(!new_keys.key?(key))
                new_keys[key] = value
                named_keys << "  %s: \"%s\"\n" % [key,value.gsub('"',"\"")]
              end
            end
          end while found==true
          tmp.write line
        end
        tmp.close
        File.rename(tmp_file,file+"")
      end
    end
    en = open(en_yml,write_type)
    named_keys.each do |line|
      en.write(line)
    end
    en.close
  end

  desc 'Synchronize english template with other language files'
  task :sync do
    puts "load english as a template"
    en = open(en_yml)
    puts "loaded"

    en_content = ''
    en.read.each do |line|
      if line.match(/^\s\s([\w_?]*):\s/)
        en_content << line.strip
        en_content << "\n"
      end
    end
    en.close
    en_data = YAML.load(en_content)

    Dir.glob(File.join([lang_dir, "*"])).each do |file|
      file_name = File.split(file)[-1]
      if file_name != en_file && file != tmp_file && file_name != File.split(en_yml)[-1] && file_name.match(/^[a-z]{2}\.yml\b/)
        puts "loading file: " + file_name
        en = open(en_yml)
        lang = open(file)

        lang_content = ''
        lang.read.each do |line|
          if line.match(/^\s\s([\w_?]*):\s/)
            lang_content << line.strip
            lang_content << "\n"
          end
        end
        data = YAML.load(lang_content)
        lang.close

        if data
          to_be_translated_content = ''
          en.read.each do |line|
            key = line.match(/^\s\s([\w_?]*):\s/)
            if key
              key = key[1] if key
              if !data[key]  and key != nil
                to_be_translated_content << "#TODO: "
                to_be_translated_content << en_data[key].gsub("\n", " ") if en_data[key]
                to_be_translated_content << "\n"
                to_be_translated_content << "  #TODO: " + key + ":\n"
              end
            end
          end
        end
        en.close
        puts "appending changes to " + file_name
        lang = open(file, 'a')
        lang.write to_be_translated_content
        lang.close

      end
    end
  end

  desc 'task to generate a key based on a based argument'
  task :generate_key, [:message] do |t, args|

    def check_if_string_exists(string, en_yml)
      en = open(en_yml)
      en.read.each do |line|
        if line.match(/^\s\s([\w_?]*):\s/)
          if (line.split(': "')[1].rstrip == string.gsub("\"", "\\\"")+'"')
            return line.split(': "')[0].strip
            exit
          end
        end
      end
      return ''
    end

    def check_for_duplicated_key(key, en_yml)
      en = open(en_yml)
      en_content = ''
      en.read.each do |line|
        if line.match(/^\s\s([\w_?]*):\s/)
          en_content << line.strip
          en_content << "\n"
        end
      end
      en.close
      en_data = YAML.load(en_content)
      while en_data[key]  do
        key << '_'
      end
      return key
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
              return_string << '_'
            end
          end
        end
      end
      if (return_string.length>30)
        return_string = return_string[0,30]
      end
      return return_string
    end

    def generate_variable(string_value)
      string_array = string_value.split('')
      return_string = 'var_'
      for i in (0..string_array.length-1)
        if (string_array[i].match(/[a-zA-Z0-9]/))
          return_string << string_array[i].downcase
        else
          return_string << '_'
        end
      end
      return return_string
    end

    def write_to_en_yml_file(en_yml, key, value)
      en_file = open(en_yml, 'a')
      en_file.write "  " + key + ": \"" + value.gsub("\"", "\\\"") + "\"\n"
      en_file.close
    end

    def process_string(string_value, en_yml)
      key_array = Array.new
      variable_array = Array.new

      output_string = string_value
      hash_count = 0
      if (string_value.include? '#{')
        temp_array = string_value.split('#{')
        for i in (1..temp_array.length-1)
          hash_count = hash_count + 1
          temp_string = temp_array[i].split('}')[0]
          variable_array[i] = temp_string
          key_array[i] = generate_variable(temp_string)
          output_string = output_string.gsub('#{'+temp_string+'}','%{'+key_array[i]+'}')
        end
      end

      string_key = check_if_string_exists(output_string, en_yml)
      if (string_key == '')
        string_key = check_for_duplicated_key(generate_key(output_string), en_yml)
        write_to_en_yml_file en_yml, string_key, output_string
      end

      output_str=""
      output_str << 'I18n.t("' + string_key + '"'
      for i in (1..hash_count)
        output_str << ', :'  + key_array[i] + ' => ' + variable_array[i]
      end

      output_str << ')'

      return output_str
    end

    if (args.message)
      puts "Key: " + process_string(args.message, en_yml)
    else
      puts "Error: please use rake i18n:generate_key[\"hello world\"] to generate the i18n key."
    end
  end

end
