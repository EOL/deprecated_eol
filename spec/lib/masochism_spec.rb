require File.dirname(__FILE__) + '/../spec_helper'


describe 'Masochism' do
  
  describe ' test setup' do
    it 'should have a test_master environment' do
      ActiveRecord::Base.configurations['test_master'].class.should == Hash
      ActiveRecord::Base.configurations['test_master_data'].class.should == Hash
      ActiveRecord::Base.configurations['test_master_logging'].class.should == Hash
      unless ActiveRecord::Base.configurations['test_master'] &&
          ActiveRecord::Base.configurations['test_master_data'] &&
          ActiveRecord::Base.configurations['test_master_logging']
        puts "** WARNING: YOU NEED TO CREATE A test_master DATABASE.YML ENTRY"
      end
    end
  end
  
  describe ' with master/slave' do
  
    before :all do
      # set up the proper master database
      ActiveReload::ConnectionProxy.setup_for ActiveReload::MasterDatabase, ActiveRecord::Base
      ActiveReload::ConnectionProxy.setup_for SpeciesSchemaWriter, SpeciesSchemaModel
      ActiveReload::ConnectionProxy.setup_for LoggingWriter, LoggingModel
    end
    
    after :all do
      # this will truncate the _master tables
      truncate_all_tables
      # revert back to proper slave databases
      ActiveReload::ConnectionProxy.setup_for ActiveRecord::Base, ActiveRecord::Base
      ActiveReload::ConnectionProxy.setup_for SpeciesSchemaModel, SpeciesSchemaModel
      ActiveReload::ConnectionProxy.setup_for LoggingModel, LoggingModel
      
      # this will truncate the normal test tables
      truncate_all_tables
    end
    
    it 'should have a migrated test_master environment' do
      eol_size = eol_data_size = eol_logging_size = 0
      ActiveRecord::Base.with_master do
        eol_size = ActiveRecord::Base.connection.select_values('SHOW TABLES').length
        eol_size.should > 6
      end
      SpeciesSchemaModel.with_master do
        eol_data_size = SpeciesSchemaModel.connection.select_values('SHOW TABLES').length
        eol_data_size.should > 6
      end
      LoggingModel.with_master do
        eol_logging_size = LoggingModel.connection.select_values('SHOW TABLES').length
        eol_logging_size.should > 6
      end
      unless eol_size>6 && eol_data_size>6 && eol_logging_size>6
        puts "** WARNING: YOU MUST RUN MIGRATIONS IN test_master ENVIRONMENT"
      end
      
    end
    
    
    it 'should recognize eol master' do
      # add a row - this should go into the master connection
      ActiveRecord::Base.connection.execute("INSERT INTO comments (id) VALUES (12345678)")
      
      # try to find the row - this should fail as this should use the slave and the row isnt on the slave
      ActiveRecord::Base.connection.select_values('SELECT * FROM comments WHERE id=12345678').length.should == 0
      ActiveRecord::Base.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test']['database']
      ActiveRecord::Base.with_master do
        ActiveRecord::Base.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_master']['database']
        
        # try to find the row again - this time passes as this searches the master
        ActiveRecord::Base.connection.select_values('SELECT * FROM comments WHERE id=12345678').length.should == 1
      end
    end
    
    it 'should recognize eol_data master' do
      SpeciesSchemaModel.connection.execute("INSERT INTO taxon_concepts (id) VALUES (12345678)")
      SpeciesSchemaModel.connection.select_values('SELECT * FROM taxon_concepts WHERE id=12345678').length.should == 0
      SpeciesSchemaModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_data']['database']
      SpeciesSchemaModel.with_master do
        SpeciesSchemaModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_master_data']['database']
        SpeciesSchemaModel.connection.select_values('SELECT * FROM taxon_concepts WHERE id=12345678').length.should == 1
      end
    end
    
    it 'should recognize eol_logging master' do
      LoggingModel.connection.execute("INSERT INTO activities (id) VALUES (12345678)")
      LoggingModel.connection.select_values('SELECT * FROM activities WHERE id=12345678').length.should == 0
      LoggingModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_logging']['database']
      LoggingModel.with_master do
        LoggingModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_master_logging']['database']
        LoggingModel.connection.select_values('SELECT * FROM activities WHERE id=12345678').length.should == 1
      end
    end
  end
  
  describe ' without master/slave' do
    it 'should ignore eol with_master' do
      ActiveRecord::Base.connection.execute("INSERT INTO comments (id) VALUES (87654321)")
      ActiveRecord::Base.connection.select_values('SELECT * FROM comments WHERE id=87654321').length.should == 1
      ActiveRecord::Base.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test']['database']
      ActiveRecord::Base.with_master do
        ActiveRecord::Base.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test']['database']
        ActiveRecord::Base.connection.select_values('SELECT * FROM comments WHERE id=87654321').length.should == 1
      end
    end
    
    it 'should ignore eol_data with_master' do
      SpeciesSchemaModel.connection.execute("INSERT INTO taxon_concepts (id) VALUES (87654321)")
      SpeciesSchemaModel.connection.select_values('SELECT * FROM taxon_concepts WHERE id=87654321').length.should == 1
      SpeciesSchemaModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_data']['database']
      SpeciesSchemaModel.with_master do
        SpeciesSchemaModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_data']['database']
        SpeciesSchemaModel.connection.select_values('SELECT * FROM taxon_concepts WHERE id=87654321').length.should == 1
      end
    end
    
    it 'should ignore eol_logging with_master' do
      LoggingModel.connection.execute("INSERT INTO activities (id) VALUES (87654321)")
      LoggingModel.connection.select_values('SELECT * FROM activities WHERE id=87654321').length.should == 1
      LoggingModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_logging']['database']
      LoggingModel.with_master do
        LoggingModel.connection.select_values('SELECT DATABASE()')[0].should == ActiveRecord::Base.configurations['test_logging']['database']
        LoggingModel.connection.select_values('SELECT * FROM activities WHERE id=87654321').length.should == 1
      end
    end
  end
end