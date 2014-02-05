#!/usr/bin/env ruby

h_s = Hierarchy.all
puts "Building #{h_s.size} hierarchy nested sets."
h_s.each do |h|
  EOL.Data.make_nested_set(h)
end
