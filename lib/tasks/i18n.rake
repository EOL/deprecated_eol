require 'haml'


desc 'Tasks useful for internatiolization'
namespace :i18n do
  lang_dir = Rails.root.join("config", "locales")
  lang_dir = Rails.root.join("config", "translations") if Rails.env.development? || Rails.env.test_dev?
  gibberish_lang_dir = Rails.root.join("lang")
  en_file = "translation_template.yml"
  tmp_file = File.join([lang_dir, "tmp.yml"])
  en_yml = File.join([lang_dir, "en.yml"])
  trans_tmp = File.join([lang_dir, "translation_template.yml"])
  excluded_tables = ["translated_mime_types", "translated_news_items", "translated_privileges",
    "translated_info_items", "translated_content_pages", "translated_content_page_archives", "translated_languages"]
  db_field_delim = '-' # Double-underscore does not work with TW.

  desc "Load all translations into redis."
  task :to_redis do
    Dir.entries(lang_dir).grep(/yml$/).each do |file|
      translations = YAML.load_file(File.join(lang_dir, file))
      locale = translations.keys.first # There's only one.
      puts "  ++ #{locale} -> #{file} (#{translations[locale].keys.count} keys)"
      I18n.backend.store_translations(locale, translations[locale], escape: false)
      I18n.backend.store.set(file)
    end
  end

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
        if line.match(/^\s\s(\s*)([\w_?]*):\s/)
          en_content << line + "\n"
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
    Dir.glob(Rails.root.join("app", "**", "*")).each do |file|
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
      if line.match(/^\s\s(\s*)([\w_?]*):\s/)
        en_content << line
        en_content << "\n"
      end
    end
    en.close
    en_data = YAML.load(en_content)

    Dir.glob(File.join([lang_dir, "*"])).each do |file|
      file_name = File.split(file)[-1]
      if file_name != en_file && file != tmp_file && file_name != File.split(en_yml)[-1]
        puts "loading file: " + file_name
        en = open(en_yml)
        lang = open(file)

        lang_content = ''
        lang.read.each do |line|
          if line.match(/^\s\s(\s*)([\w_?]*):\s/)
            lang_content << line
            lang_content << "\n"
          end
        end
        data = YAML.load(lang_content)
        lang.close

        if data
          to_be_translated_content = ''
          en.read.each do |line|
            key = line.match(/^\s\s(\s*)([\w_?]*):\s/)
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
  task :generate_key do |t, args|
    def check_if_string_exists(string, en_yml)
      en = open(en_yml)
      en_content = ''
      en.read.each do |line|
        if line.match(/^\s\s(\s*)([\w_?]*):\s/)
          en_content << line
          en_content << "\n"
        end
      end
      en.close
      en_data = YAML.load(en_content)
      en_data.each do |key, value|
        if value==string
          return key
          exit
        end
      end
      return ''
    end

    def check_for_duplicated_key(key, en_yml)
      en = open(en_yml)
      en_content = ''
      en.read.each do |line|
        if line.match(/^\s\s(\s*)([\w_?]*):\s/)
          en_content << line
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

    if (ENV['string'])
      puts "Key: " + process_string(ENV['string'], en_yml)
    else
      puts "Error: please use rake i18n:generate_key string=\"hello world\" to generate the i18n key."
    end
  end

  desc 'task to make sure all keys in en.yml file are used somewhere in the code'
  task :check_en_yml_not_used_keys do

    def load_yml_file(file_path)
      read_file = open(file_path)
      file_content = ''
      read_file.read.each do |line|
        if line.match(/^\s\s(\s*)([\w_?]*):\s/)
          file_content << line
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

    def get_keys(file_content)
      # returns array of keys in the file if any
      keys = Array.new

      temp_keys = file_content.split(/I18n.t(ranslate)*/)

      if (temp_keys.size==1)
        # no I18n keys in this file, return an empty array
        return keys
      else
        # ignore the first item in the array, from the second item, each will start with the key
        keys_count = 0
        for i in (1..temp_keys.size-1)
          if temp_keys[i].match (/^(\s*\()/) # matchs I18n.t(xxxx)
            if temp_keys[i].strip != '(' # to avoid error from nested I18n.t
              temp_str = temp_keys[i].strip.gsub('(','').strip.split(")")[0].split(",")[0]
              if (temp_str.index("\"") or temp_str.index("'") or temp_str.index(":"))
                keys[keys_count] = temp_str.strip.gsub("\"", "").gsub(":","").gsub("'","")
                keys_count = keys_count + 1
              end
            end
          elsif temp_keys[i].match(/^\s(\')/) # matchs I18n.t 'xxx'
            temp_str = temp_keys[i].strip[1..-1].split("'")[0] # trim then remove the first ' then split on the next ' and get the key
            keys[keys_count] = temp_str.strip
            keys_count = keys_count + 1
          elsif temp_keys[i].match(/^\s(\")/) # matchs I18n.t "xxx"
            temp_str = temp_keys[i].strip[1..-1].split('"')[0] # trim then remove the first " then split on the next " and get the key
            keys[keys_count] = temp_str.strip
            keys_count = keys_count + 1
          elsif temp_keys[i].match(/^\s(\:)/) # matchs I18n.t :xxx
            temp_str = temp_keys[i].strip[1..-1].split(/(,|\s|$|\Z)/)[0] # trim then remove the first : then split on the next comma, space, or a new line, end of line, or end of string
            keys[keys_count] = temp_str.strip
            keys_count = keys_count + 1
          end
        end

        return keys
      end

    end

    def drop_keys_from_yml_file(yml_container, keys)
      keys.each do |key|
        if (yml_container[key])
         yml_container.delete(key)
        end
      end

      return yml_container
    end

    en_yml_keys = load_yml_file(en_yml)

    all_files = get_all_files_in_app

    all_files.each do |file|
      file_open = open(file, "r")
      file_content = file_open.read
      file_open.close

      file_used_keys = get_keys(file_content)
      if file_used_keys.size > 0
        en_yml_keys = drop_keys_from_yml_file(en_yml_keys, file_used_keys)
      end
    end

    not_used_keys = ''

    en_yml_keys.each do |key, value|
      not_used_keys << "\n" if not_used_keys != ''
      not_used_keys << key.to_s
    end

    if (not_used_keys != '')
      puts not_used_keys.split("\n").count.to_s + ' keys are not used'
      not_used_keys.each do |key|
        puts key
      end
    else
      puts 'All keys in en.yml file are used'
    end

  end

  desc 'list db strings for translation by twiki'
  task :list_db_strings => :environment do
    en_strings = "en-db:\n"
    en_id = Language.english.id

    # TODO - this doesn't look for models in the nested directories (ie: logging)
    all_models = Dir.foreach(Rails.root.join('app', 'models')).map do |model_path|
      if m = model_path.match(/translate/) && model_path.match(/^(([a-z]+_)*[a-z]+)\.rb$/)
        m[1].camelcase.constantize
      else
        nil
      end
    end.compact
    all_tables = {}
    all_models.each do |model|
      begin
        if excluded_tables.include?(model.table_name)
          puts "Excluding: " + model.full_table_name
        else
          cols = model.column_names.dup
          all_tables[model.full_table_name] = {}
          cols.delete("id")
          cols.delete("language_id")
          all_tables[model.full_table_name][:associations] = cols.grep(/_id$/)
          cols.delete_if {|c| c =~ /_id$/ }
          cols.delete_if {|c| c =~ /^phonetic_/ }
          all_tables[model.full_table_name][:translatable] = cols
        end
      rescue ActiveRecord::StatementInvalid => e
        puts "** You seem to have a missing table:"
        puts e.message
      end
    end
    all_tables.keys.each do |table_name|
      foreign_key = all_tables[table_name][:associations].to_s # Note this COULD be an array, but we can't handle that
      translatable = ""
      all_tables[table_name][:translatable].each do |field|
        translatable << ", " if translatable != ""
        translatable << field
      end
      puts "select #{foreign_key}, #{translatable} from #{table_name} where language_id=#{en_id}"
      results = ActiveRecord::Base.connection.execute("SELECT #{foreign_key}, #{translatable} FROM #{table_name} WHERE language_id=#{en_id}")
      results.each_hash do |row|
        all_tables[table_name][:translatable].each do |field|

          # if we are in the Ranks table, ignore any rows not in our translation whitelist
          if table_name =~ /translated_ranks$/ && field == 'label'
            lookup_rank_label = row[field].downcase.gsub(/\.$/, '')  # remove trailing periods
            next unless Rank.english_rank_labels_to_translate.include?(lookup_rank_label)
          end

          # Some fields should never get translated for obvious reasons:
          next if field == 'updated_at'
          next if field == 'created_at'
          next if field == 'active_translation'
          next unless row[field]

          value = row[field].gsub("\"", "\\\"").gsub("\n", "\\n")

          # Skip empty values:
          next if value == ''

          # If we are in the Activities table, ignore any keys with underscores:
          next if table_name =~ /translated_activities$/ && value =~ /_/

          en_strings << "  #{table_name.sub(/^.*\./, '')}#{db_field_delim}#{field}#{db_field_delim}#{foreign_key}#{db_field_delim}#{row[foreign_key]}: \"#{value}\"\n"
        end
      end
    end

    puts "Writing to en-db.yml"
    en_file = Rails.root.join("config", "locales" , "en-db.yml")
    en_data = open(en_file, 'w')
    en_data.write en_strings
    en_data.close
  end

  desc 'Task to import db translations in db'
  task :import_db_translations => :environment do
    def load_language_keys(lang_abbr)
      filename = Rails.root.join("config", "locales", lang_abbr + "-db.yml")
      return nil unless File.exists?(filename)
      temp_yml = YAML.load_file(Rails.root.join("config", "locales", lang_abbr + "-db.yml"))
      return temp_yml[lang_abbr] || temp_yml.values.last # this || fixes a bug with Arabic.  Not sure why.
    end

    def get_languages
      # returns array of language abbriviations for those a pattern of *-dt.yml
      Dir.chdir(Rails.root.join("config", "locales"))
      files = Dir.glob(File.join("**", "*-db.yml"))

      return_lang = Array.new
      files.each do |file|
        lang_abbr = File.split(file)[-1].gsub("-db.yml", "")
        return_lang << lang_abbr if lang_abbr != 'en'
      end

      return return_lang
    end

    def get_lang_id_by_lang_abbr(lang_abbr)
      results = ActiveRecord::Base.connection.execute("select id from languages where iso_639_1='" + lang_abbr + "'")
      if (results.nil? || results.size == 0)
        return 0
      else
        return results.first.first
      end
    end

    def clean_basic_injection(value)
      return value.gsub(/\\/, '\&\&').gsub(/'/, "''").gsub('--', '- -')
    end

    def escape_new_line(value)
      return value.gsub("\n", "\\n");
    end

    def insert_or_update_db_value(table_name, column_name, identity_column_name, lang_id, field_id, column_value)
      results = begin
                  LoggingModel.connection.execute("
                    SELECT * FROM #{table_name}
                    WHERE #{identity_column_name}=#{field_id} and language_id=#{lang_id}
                  ")
                rescue => e
                  begin
                    ActiveRecord::Base.connection.execute("
                      SELECT * FROM #{table_name}
                      WHERE #{identity_column_name}=#{field_id} and language_id=#{lang_id}
                    ")
                  rescue => e
                    puts "**\n** MISSING #{table_name}.#{identity_column_name}##{field_id} SKIPPING #{column_name} = \"#{column_value}\"\n**"
                    return
                  end
                end
      query = ""
      if (results.nil? || results.size == 0)
        # new record
        query = "insert into #{table_name} (#{identity_column_name}, language_id, #{column_name}) values (#{field_id}, #{lang_id}, '" + escape_new_line(clean_basic_injection(column_value)) + "')"
      else
        query = "update #{table_name} set #{column_name}='" + escape_new_line(clean_basic_injection(column_value)) + "'
                  where #{identity_column_name} = #{field_id}
                  and language_id=#{lang_id};"

      end

      begin
        LoggingModel.connection.execute(query)
      rescue
        begin
          ActiveRecord::Base.connection.execute(query)
        rescue => e
          puts "** ERROR: Could not execute #{query}: #{e.class.name}, #{e.message}"
        end
      end
    end

    en_keys = load_language_keys('en')

    translated_languages = ENV['LANGUAGE'] ? Array(ENV['LANGUAGE'].split(',')) : get_languages

    translated_languages.each do |lang|
      lang_id = get_lang_id_by_lang_abbr(lang)
      if (lang_id != 0)
        print "processing " + lang + " file"
        lang_keys = load_language_keys(lang)
        if lang_keys.nil?
          puts " (none)"
        else
          puts " (#{lang_keys.keys.count})"
          next if lang_keys.blank?
          lang_keys.each do |pair|
            (key, val) = pair
            (table_name, column_name, identity_column_name, field_id) = key.split(db_field_delim)
            insert_or_update_db_value(table_name, column_name, identity_column_name, lang_id, field_id, val)
          end
        end
      end
    end

  end
end
