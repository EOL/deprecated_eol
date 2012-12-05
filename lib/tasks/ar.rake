require 'haml'


desc 'Tasks for ar.yml file updates'
namespace :ar do
  lang_dir = Rails.root.join("config", "locales")
  gibberish_lang_dir = Rails.root.join("lang")
  en_file = "translation_template.yml"
  tmp_file = File.join([lang_dir, "tmp.yml"])
  en_yml = File.join([lang_dir, "en.yml"])
  trans_tmp = File.join([lang_dir, "translation_template.yml"])
  excluded_tables = ["translated_mime_types"]
  
  desc 'convert old yml language files from Gibberish format to support i18n '
  task :compare_with_twiki  do
    
    def load_yml_file(yml_path, lang_abbr)
      temp_yml = YAML.load_file(yml_path)
      return temp_yml[lang_abbr]
    end
    
    init_ar_yml = load_yml_file(Rails.root.join("config", "locales", "ar.yml"), "ar")
    twiki_ar_yml = load_yml_file(Rails.root.join("config", "locales", "initial", "ar.yml"), "ar")
    init_en_yml = load_yml_file(Rails.root.join("config", "locales", "en.yml"), "en")
    translated_ar_yml = load_yml_file(Rails.root.join("config", "locales", "translated_ar.yml"), "ar")
    
    
    init_en_yml.each do |key, value|
      if init_ar_yml[key].nil? and translated_ar_yml[key].nil?
        # key doesn't exist in the initials folder
        if !twiki_ar_yml[key].nil?
          if twiki_ar_yml[key] == init_en_yml[key]
            puts key + " : " + init_en_yml[key].to_s
          end
        else  
          puts key + " : " + init_en_yml[key].to_s
        end
      end
    end
    
    
  end







end
