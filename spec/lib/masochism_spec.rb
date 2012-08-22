require File.dirname(__FILE__) + '/../spec_helper'


describe 'Masochism' do

  # # all of the abstract models which have master connections we need to test. Also includes
  # # the name of a table that we can INSERT INTO table (id) VALUES (NULL) for testing
  # # this is not in the before all because we loop through this array to CREATE tests
  # connections_to_test = [
  #   { :abstract_model => ActiveRecord::Base, :database_suffix => '', :test_model => Comment},
  #   { :abstract_model => LoggingModel, :database_suffix => 'logging', :test_model => Activity}]
  # 
  # describe ': test_master setup' do
  #   it 'should have a test_master environment' do
  #     ActiveRecord::Base.configurations['test_master'].class.should == Hash
  #     ActiveRecord::Base.configurations['test_master_logging'].class.should == Hash
  #     unless ActiveRecord::Base.configurations['test_master'] &&
  #         ActiveRecord::Base.configurations['test_master_logging']
  #       puts "** WARNING: YOU NEED TO CREATE A test_master DATABASE.YML ENTRY"
  #     end
  #   end
  # end
  # 
  # describe ': with master/slave' do
  #   before :all do
  #     truncate_all_tables
  # 
  #     # close existing mysql connections as we'll reconnect below.
  #     # trying to avoid a MySQL max_user_connections error
  #     ActiveRecord::Base.connection.disconnect!
  #     LoggingModel.connection.disconnect!
  # 
  #     # set up the proper master database
  #     ActiveReload::ConnectionProxy.setup_for ActiveReload::MasterDatabase, ActiveRecord::Base
  #     ActiveReload::ConnectionProxy.setup_for LoggingWriter, LoggingModel
  #   end
  # 
  #   after :all do
  #     # this will truncate the _master tables
  #     truncate_all_tables
  # 
  #     # close master connections to avoid a MySQL max_user_connections error
  #     ActiveRecord::Base.with_master { ActiveRecord::Base.connection.disconnect! }
  #     LoggingModel.with_master { LoggingModel.connection.disconnect! }
  # 
  #     # revert back to proper slave databases
  #     ActiveReload::ConnectionProxy.setup_for ActiveRecord::Base, ActiveRecord::Base
  #     ActiveReload::ConnectionProxy.setup_for LoggingModel, LoggingModel
  #   end
  # 
  #   connections_to_test.each do |test_data|
  #     it 'should have a migrated test_master environment' do
  #       number_of_tables = 0;
  #       test_data[:abstract_model].with_master do
  #         number_of_tables = test_data[:abstract_model].connection.select_values('SHOW TABLES').length
  #         number_of_tables.should > 6
  #       end
  #     end
  # 
  #     it 'should properly use the master' do
  #       test_connection = test_data[:abstract_model].connection
  #       test_table_name = test_data[:test_model].table_name
  #       slave_database_name = test_data[:database_suffix].blank? ? "test" : "test_" + test_data[:database_suffix]
  #       master_database_name = test_data[:database_suffix].blank? ? "test_master" : "test_master_" + test_data[:database_suffix]
  # 
  #       # add a row - this should go into the master connection
  #       test_connection.execute("INSERT INTO #{test_table_name} (id) VALUES (12345678)")
  # 
  #       # try to find the row - this should fail as this should use the slave and the row isnt on the slave
  #       test_connection.select_values("SELECT * FROM #{test_table_name} WHERE id=1234567").length.should == 0
  # 
  #       # make sure we're using the slave DB
  #       current_db_name = test_connection.select_values('SELECT DATABASE()')[0]
  #       current_db_name.should == test_data[:abstract_model].configurations[slave_database_name]['database']
  # 
  #       # now switch to the master
  #       test_data[:abstract_model].with_master do
  #         # make sure we're using the master DB
  #         current_db_name = test_connection.select_values('SELECT DATABASE()')[0]
  #         current_db_name.should == test_data[:abstract_model].configurations[master_database_name]['database']
  # 
  #         # try to find the row again - this time it passes as this searches the master
  #         test_connection.select_values("SELECT * FROM #{test_table_name} WHERE id=12345678").length.should == 1
  #       end
  #     end
  #   end
  # end
  # 
  # describe ': without master/slave' do
  #   # this is not in the before all because we loop through this array to CREATE tests
  # 
  #   connections_to_test.each do |test_data|
  #     it 'should write to the slave when master === slave' do
  #       test_connection = test_data[:abstract_model].connection
  #       test_table_name = test_data[:test_model].table_name
  #       slave_database_name = test_data[:database_suffix].blank? ? "test" : "test_" + test_data[:database_suffix]
  # 
  #       # add a row - this should go into the slave connection
  #       test_connection.execute("INSERT INTO #{test_table_name} (id) VALUES (87654321)")
  #       test_connection.select_values("SELECT * FROM #{test_table_name} WHERE id=87654321").length.should == 1
  # 
  #       # make sure we're using the slave DB
  #       current_db_name = test_connection.select_values('SELECT DATABASE()')[0]
  #       current_db_name.should == test_data[:abstract_model].configurations[slave_database_name]['database']
  # 
  #       # now call the with_master block which should have no effect
  #       test_data[:abstract_model].with_master do
  #         # make sure we're STILL using the slave DB
  #         current_db_name = test_connection.select_values('SELECT DATABASE()')[0]
  #         current_db_name.should == test_data[:abstract_model].configurations[slave_database_name]['database']
  # 
  #         # make sure the row we just added above to the slave is still found
  #         test_connection.select_values("SELECT * FROM #{test_table_name} WHERE id=87654321").length.should == 1
  #       end
  #     end
  #   end
  # end
end
