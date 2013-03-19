#!/usr/bin/env ruby

require 'yaml'

keys = YAML::load(File.read('config/locales/zh-Hans.yml')).keys.count
puts "Ostensibly looks fine." if keys == 1
