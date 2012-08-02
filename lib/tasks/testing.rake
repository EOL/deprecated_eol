# any tasks helpful / related to testing

desc 'Truncates all tables'
task :truncate => :environment do
  if RAILS_ENV == 'test' || RAILS_ENV == 'development' || RAILS_ENV == 'test_master'
    require Rails.root.join('spec', 'eol_spec_helpers')
    include EOL::Spec::Helpers
    truncate_all_tables :verbose => true
  else
    puts "sorry, i'm not comfortable doing this in any environment but 'test' or 'development'"
  end
end

desc 'Print specdocs'
task :specdoc do
  if ENV['MATCH']
    all_specs = Dir[ Rails.root.join('spec', '**', '*_spec.rb') ]
    matchers  = ENV['MATCH'].split(',')
    specs = all_specs.inject([]) do |specs, this_spec_filename|
      matchers.each do |matcher|
        if this_spec_filename.include? matcher
          specs << this_spec_filename
          break
        end
      end
      specs
    end
    specs = specs.uniq.join(' ')
  else
    specs = 'spec/*/*_spec.rb'
  end
  cmd = "cd '#{Rails.root}' && ruby script/spec --color -f specdoc #{ specs }"
  puts cmd
  exec cmd
end

desc 'Print HTML specdocs'
task :spechtml do
  # extract this match bit out into a method - DRY up!
  if ENV['MATCH']
    all_specs = Dir[ Rails.root.join('spec', '**', '*_spec.rb') ]
    matchers  = ENV['MATCH'].split(',')
    specs = all_specs.inject([]) do |specs, this_spec_filename|
      matchers.each do |matcher|
        if this_spec_filename.include? matcher
          specs << this_spec_filename
          break
        end
      end
      specs
    end
    specs = specs.uniq.join(' ')
  else
    specs = 'spec/*/*_spec.rb'
  end
  dir = Rails.root.join('tmp', 'spec_output')
  unless File.directory?dir
    require 'fileutils'
    FileUtils::mkdir_p dir
  end
  html_filename = File.join dir, "#{ Time.now.strftime '%m%d%Y_%H%M%S' }_specdoc.html"

  cmd = "cd '#{Rails.root}' && ruby script/spec -f html #{ specs } > '#{ html_filename }'"
  puts cmd
  puts `#{ cmd }`

  cmd = (PLATFORM =~ /darwin/i) ? "open '#{ html_filename }'" : "firefox '#{ html_filename }'"
  puts cmd
  puts `#{ cmd }`
end

desc 'Run several checks on the validity of I18n tools, such as missing values, hard-coded strings, and the like.'
task :check_i18n => :environment do
  require Rails.root.join('lib', 'eol', 'check_i18n_files')
  EOL::CheckI18nFiles.new
end

