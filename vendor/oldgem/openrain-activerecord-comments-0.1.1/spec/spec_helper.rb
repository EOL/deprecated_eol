require 'rubygems'
require 'spec'
require 'yaml'
begin
  require 'activerecord'
rescue LoadError
  raise "dependency ActiveRecord not found.  try: $ sudo gem install activerecord"
end

require File.dirname(__FILE__) + '/../lib/activerecord-comments'

# right now, we run all tests against MySQL (I would also do sqlite but I don't think it supports comments!)
database_hash = YAML::load File.read(File.dirname(__FILE__) + '/spec_database.yml')
ActiveRecord::Base.establish_connection database_hash

begin
  # touch the connection to see if it's OK
  ActiveRecord::Base.connection
rescue Mysql::Error => ex
  if ex.to_s =~ /unknown database/i
    db = database_hash['database']
    raise "\n\nMySQL database not found: #{db}.\ntry: $ mysqladmin create #{db}\n\n"
  else
    raise ex
  end
end
