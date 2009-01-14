UseDb
by David Stevenson
ds@elctech.com
=====
USAGE

This plugin allows you to use multiple databases in your rails application.  
You can switch the database for a model in the following manner:

class MyModel < ActiveRecord::Base
	use_db :prefix => "secdb_", :suffix => "_cool"
end

"use_db" takes a prefix and a suffix (only 1 of which is required) which are prepended and appended onto the current RAILS_ENV.  
In the above example, I would have to make the following database entries to my database.yml:

secdb_development_cool:
  adapter: mysql
  database: secdb_dev_db
  ...

secdb_test_cool:
  adapater: mysql
  database: secdb_test_db
  ...

It's often useful to create a single abstract model which all models using a different database extend from:

class SecdbBase < ActiveRecord::Base
	use_db :prefix => "secdb_"
	self.abstract_class = true
end

class MyModel < SecdbBase
  # this model will use a different database automatically now
end

==========
MIGRATIONS

To write a migration which executes on a different database, add the following method to your
migration:

class MyMigration < ActiveRecord::Migration
  def self.database_model
    return "SecdbBase"
  end

  def self.up
    ...
  end

  ...
end

The "self.database_model" call must return a string which is the name of the model whose connection
you want to borrow when performing the migration.  If this method is undefined, the default ActiveRecord::Base
connection is used.

=======
TESTING

In order to test multiple databases, you must invoke a task which clones the development database
structure and copies it into the test database, clearing out the existing test data.  There is a single
helper method which executes this task and you invoke it as follows:

UseDbTest.prepare_test_db(:prefix => "secdb_")

Even though it might not be the best place for it, I often place a call to this in my test helper.
You don't want it to execute for every test, so put the following guards around it:

unless defined?(CLONED_SEC_DB_FOR_TEST)
  UseDbTest.prepare_test_db(:prefix => "secdb_")
  CLONED_SEC_DB_FOR_TEST = true
end

========
FIXTURES

Fixtures will automatically be loaded into the correct database as long as the fixture name corresponds
to the name of a model.  For example, if I have a model called SecdbUser who uses a different database and
I create a fixture file called secdb_users.yml, the fixture loader will use whatever database connection
belongs to hte SecdbUser model.

There is currently no other way to force a fixture to use a specific database (sorry, no join tables yet),
like there is for migrations.