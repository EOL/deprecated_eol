# If you use a _slightly_ later version of MySQL 5.6, you will get an odd error.
# This should resolve it.
class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  NATIVE_DATABASE_TYPES[:primary_key] =
    "int(11) auto_increment PRIMARY KEY"
end
