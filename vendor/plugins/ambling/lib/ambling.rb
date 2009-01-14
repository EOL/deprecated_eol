module Ambling #:nodoc
end

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'ambling/base'
require 'ambling/column'
require 'ambling/pie'
require 'ambling/line'
require 'ambling/xy'
require 'ambling/data'