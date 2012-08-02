require 'ruby-debug'
require 'haml'
require 'i18n'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'cgi'

namespace :i18n do

  lang_dir = Rails.root.join("config", "locales"])
  en_yml = File.join([lang_dir, "en.yml"])

  desc 'sending text to google for translation'
  task :google_translate, [:to_language] do |t, args|

    def translate_key(to_language, key_value)
      if !key_value
        return ""
        exit
      end
      variable_array = Array.new
      temp_array = key_value.split("%{")
      if (temp_array.length > 1)
        for i in (1..temp_array.length-1)
          variable_array[i] = temp_array[i].split("}")[0]
          key_value = key_value.gsub("%{"+variable_array[i]+"}", "_r_var_"+i.to_s)
        end
      end

      ############
      # if proxy #
      ############
      # uri = URI.parse('https://www.googleapis.com')
      # proxy = Net::HTTP::Proxy('proxy', port, 'user.name', 'password')
      # http_session = proxy.new(uri.host, uri.port)
      # http_session.use_ssl = true
      # http_session.verify_mode = OpenSSL::SSL::VERIFY_NONE
      # http_session.start {|http|
      #  http_result = http.get('/language/translate/v2?key=AIzaSyBF8nY7sHUN1Mzmb9Sr5q033oGbnWU7X08&pp=1&source=en&format=html&target='+to_language+'&q='+ CGI.escape(key_value)).body
      #  json = JSON.parse(http_result)
      #  http_to_yaml = YAML.dump(json)
      #  translated_string = json["data"]["translations"].to_s.gsub("translatedText", "")
      #  for i in (1..variable_array.length-1)
      #    translated_string = translated_string.gsub("_r_var_"+i.to_s, "%{" + variable_array[i] + "}")
      #  end
      #
      #  return CGI.unescape(translated_string)
      #
      # }

      ###############
      #if proxy end #
      ###############


      ###############
      # if No proxy #
      ###############

      string = 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBF8nY7sHUN1Mzmb9Sr5q033oGbnWU7X08&pp=1&source=en&format=html&target='+to_language+'&q='+ CGI.escape(key_value)
      url = URI.parse(string)

      req = Net::HTTP::Get.new(url.path)

      # proxy = Net::HTTP
      proxy = Net::HTTP::Proxy('192.168.1.5', 8080)

      http_result = proxy.start(url.host, url.port) { |h| h.request(req) }.body

      json = JSON.parse(http_result)
      http_to_yaml = YAML.dump(json)
      translated_string = json["data"]["translations"].to_s.gsub("translatedText", "")
      for i in (1..variable_array.length-1)
        translated_string = translated_string.gsub("_r_var_"+i.to_s, "%{" + variable_array[i] + "}")
      end

      return CGI.unescape(translated_string)

      ##################
      #if no proxy end #
      ##################
    end

    def load_language_haml(lang_yml)
      lang = open(lang_yml)
      lang_content = ''
      lang.read.each do |line|
        if line.match(/^\s\s([\w_?]*):\s/)
          lang_content << line.strip
          lang_content << "\n"
        end
      end
      lang.close
      lang_data = YAML.load(lang_content)

      return lang_data
    end

    def write_file(content, to_lang, lang_dir)
      lang = open(File.join([lang_dir, to_lang + ".yml"]), 'w')
      lang.write content
      lang.close
    end

    def add_key(key, key_value, to_lang, lang_dir)
      lang = open(File.join([lang_dir, to_lang + ".yml"]), 'a')
      lang.write "  " + key + ": \"" + key_value.gsub("\n", "\\n").gsub("\\", "\\\\").gsub("\"", "\\\"")  + "\"\n"
      lang.close
    end

    if (!args.to_language)
      puts "Error: please use rake i18n:google_translate[\"fr\"] to translate the fr.yml file."
      exit
    end

    #puts translate_key(args.to_language, "Please fill in the full name of the project or web site from which the information will come as you want it to be visible in the Encyclopedia of Life.  THIS INFORMATION WILL BE VISIBLE ON THE WEB SITE")
    #exit

    en_haml = load_language_haml(en_yml)
    lang_haml = load_language_haml(File.join([lang_dir, args.to_language + ".yml"]))

    lang_haml_content = args.to_language + ":\n"
    puts args.to_language

    open(en_yml).read.each do |line|
      key = line.match(/^\s\s([\w_?]*):\s/)
      if key
        key = key[1] if key
        if !lang_haml[key]  and lang_haml[key] != ''
          lang_haml_content << "  " + key + ": \"" + translate_key(args.to_language, en_haml[key]).gsub("\n", "\\n").gsub("\"", "\\\"") + "\"\n"
          puts "  " + key + ": \"" + translate_key(args.to_language, en_haml[key]).gsub("\n", "\\n").gsub("\"", "\\\"") + "\""
        else
          lang_haml_content << "  " + key + ": \"" + lang_haml[key].gsub("\n", "\\n").gsub("\"", "\\\"") + "\"\n" + "\""
          puts "  " + key + ": \"" + lang_haml[key].gsub("\n", "\\n").gsub("\"", "\\\"") + "\""
        end
      end
    end
    write_file lang_haml_content, args.to_language, lang_dir
  end

end

