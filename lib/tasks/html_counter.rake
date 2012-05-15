def count_html_tags(string, opened, closed)
  s = string.dup

  close_re = /<\s*\/\s*(\w+)[^>]*>/
  while(s =~ close_re) do
    tag = $1
    closed[tag] ||= 0
    closed[tag] += 1
    s.sub!(close_re, '')
  end

  open_re = /<\s*(\w+)[^>]*>/
  while(s =~ open_re) do
    tag = $1
    opened[tag] ||= 0
    opened[tag] += 1
    s.sub!(open_re, '')
  end
end

def report_on_tags(opened, closed)
  puts "Open tags:"
  opened.keys.sort.each do |k|
    print "  #{k}:#{opened[k]}"
    if closed.has_key?(k)
      if closed[k] < opened[k]
        puts " (#{opened[k] - closed[k]} unclosed)"
      else
        print "\n"
      end
    else
      puts " (NONE closed)"
    end
  end
end

desc 'Count the HTML tags in a field in the DB'
task :html_counter => :environment do
  opened = {}
  closed = {}
  puts "Counting Comments:"
  counter = 0
  Comment.all(:select => 'id, body').each do |c|
    if counter % 100 == 0 
      print "."
    end
    count_html_tags(c.body, opened, closed)
    counter += 1
  end
  print "\n"
  report_on_tags(opened, closed)
end
