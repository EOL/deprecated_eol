desc 'Tasks useful for internatiolization'

namespace :i18n do
  desc 'syncronizes files used for internationalization of EOL interface'
  task :sync do
    lang_dir = File.join([RAILS_ROOT, "lang"])
    en_file = "translation_template.yml"
    en_data = YAML.load(File.join([lang_dir, en_file]))
    en = open(File.join([lang_dir, en_file])).read
    Dir.glob(File.join([lang_dir, "*"])).each do |file|
      file_name = File.split(file)[-1]
      if file_name != en_file
         
      end
    end
  end
end

