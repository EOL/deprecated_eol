# Methods to assist in the truncation of tables for specs, scenarios, and other administrative tasks. Probably not
# wise to use this in production.
#
# Note this is a module that should be INCLUDED. These aren't class methods.
module TruncateHelpers

  # call truncate_all_tables but make sure it only happens once in the Process
  # TODO - why?  Any spec that needs truncated tables should probably truncate tables. (Most do.) Smells of a hack.
  def truncate_all_tables_once
    unless $truncated_all_tables_once
      $truncated_all_tables_once = true
      print "truncating tables ... "
      EOL::Db.truncate_all_tables
      puts "done"
    end
  end

  # truncates all tables in all databases
  def truncate_all_tables(options = {})
    EOL::Db.truncate_all_tables(options)
  end

end
