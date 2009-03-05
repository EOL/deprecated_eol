require 'rubygems'
require 'sinatra'
 
Sinatra::Application.default_options.merge!(
  :run => false,
  :env => :production
)
 
require 'sinatra_app'
use Rack::Session::Cookie
run Sinatra.application
