#!/usr/bin/env ruby

require 'yaml'

en = YAML::load(File.read('config/locales/en.yml'))["en"]
files = Dir.glob(File.join('config', 'locales', "*"))

@nesting = []
@re = /%{([^}]+)}/

en_count = en.keys.count

def nest_into(what)
  @nesting << what
end

def unnest
  @nesting.pop
end

def nested_key(key)
  "#{@nesting.join('.')}.#{key}"
end

def check_val(hash, key, source)
  check_vars(source[key], hash[key], 'this', 'missing')
  check_vars(hash[key], source[key], 'english', 'extra')
end

def check_vars(a_orig, b, b_name, problem)
  unless a_orig.is_a?(String)
    puts "   ...Skipping #{a_orig.class.name}..."
    return
  end
  a = a_orig.dup
  while(a.sub!(@re, ''))
    var = $1
    unless b =~ /%{#{var}}/
      puts "   ** #{problem.upcase} VAR: #{var}"
      puts "      #{b_name.upcase}: #{b}"
      puts "      VS: #{a_orig}"
    end
  end
end

def check_vals(hash, source)
  hash.keys.each do |key|
    if source.has_key?(key)
      if hash[key].class != source[key].class
        puts "   ** ERROR: #{nested_key(key)} is a #{source[key].class.name} in the source, but a #{hash[key].class.name} here."
      elsif source[key].is_a?(Hash)
        nest_into(key)
        check_vals(hash[key], source[key])
        unnest
      elsif hash[key].is_a?(Array)
        puts "   ...Skipping array..."
      else
        begin
          check_val(hash, key, source)
        rescue => e
          puts "   ** ERROR: #{e.message} for #{nested_key(key)}"
        end
      end
    else
      puts "   Extra key: #{nested_key(key)}, please remove."
    end
  end
end

files.each do |file|
  next if file =~ /-db.yml$/ # Not handling DB files yet.
  next if file =~ /en.yml$/ # No need to check English, of course.
  puts "++ Checking #{file}"
  data = YAML::load(File.read(file))
  data = data[data.keys.first]
  puts "   There are #{data.keys.count} of #{en_count} keys."
  check_vals(data, en)
end

