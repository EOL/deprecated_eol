puts "zh-Hans:"
current_parts = []
last_part = ''
# TODO - accept a command-line arg for the filename:
File.open(ARGV[0]).each do |line|
  line.chomp!
  next if line =~ /^#/
  next if line =~ /^"/
  next if line =~ /msgstr ""/ && current_parts.empty?
  next unless line =~ /\w/
  next if line =~ /^msgid/
  if line =~ /msgctxt "website-([^"]+)"\s*$/
    key = $1
    parts = key.split(".")
    last_part = parts.pop
    parts.each_with_index do |part, i|
      unless current_parts[i] == part
        puts "  " + ("  " * i) + part + ":"
        current_parts = [] # No more should be checked after one diff is found!
      end
    end
    current_parts = parts
    if last_part =~ /^\d+$/
      last_part = '- ' if last_part =~ /^\d+$/
    else
      last_part += ": "
    end
    print "  " + ("  " * parts.length) + last_part
  else
    if line =~ /msgctxt "database/
      # TODO
      break
    end
    line.sub!(/msgstr\s+"/, '')
    line.sub!(/"\s*$/, '')
    line.gsub!(/\\?"/, '\\"')
    if line =~ /^\{\{PLURAL\|(.*)\}\}$/
      translation = $1
      print "\n"
      puts "  " + ("  " * current_parts.length) + "  one: \"#{translation}\""
      puts "  " + ("  " * current_parts.length) + "  other: \"#{translation}\""
    else
      if line =~ /\S/
        if line =~ /^\d+$/
          if line == '1' && last_part =~ /significant/
            puts 'true'
          else
            puts line
          end
        else
          puts "\"#{line}\""
        end
      else
        if last_part =~ /significant/
          puts "false"
        elsif current_parts.include?('date')
          puts '~'
        else
          puts '""'
        end
      end
    end
  end
end

