#!/usr/bin/env ruby
#require File.dirname(__FILE__) + '/../config/boot'



h_s = Hierarchy.find(:all)
puts "Building #{h_s.size} hierarchy nested sets."
h_s.each do |h|
  make_nested_set(h)
end
