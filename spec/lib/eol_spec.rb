require File.dirname(__FILE__) + '/../spec_helper'

describe 'EOL Lib' do
  describe ': Setting site configurations' do
    before :all do
      EolConfig.connection.execute('TRUNCATE TABLE site_configuration_options')
      @only_in_db = 'ONLY_IN_DB'
      @only_in_db_instance = EolConfig.gen(:parameter => @only_in_db, :value => 'anything')
      @nil_only_in_db = 'NIL_ONLY_IN_DB'
      @nil_only_in_db_instance = EolConfig.gen(:parameter => @nil_only_in_db, :value => nil)
      
      @only_in_environment = 'ONLY_IN_ENVIRONMENT'
      $ONLY_IN_ENVIRONMENT = 'some other value'
      @nil_only_in_environment = 'NIL_ONLY_IN_ENVIRONMENT'
      $NIL_ONLY_IN_ENVIRONMENT = nil
    end
    
    after :all do
      EolConfig.connection.execute('TRUNCATE TABLE site_configuration_options')
    end
    
    it 'should only accept variables with letters and underscores' do
      bad_strings = ['with space', 'HAS_A_123NUMBER', 'WITH_@SPECIAL_CHARS', '1234']
      bad_strings.each do |str|
        EolConfig.gen(:parameter => str, :value => 'anything')
        EOL.value_of_global(str).should == nil
      end
    end
    
    it 'should recognize variables defined in the database' do
      EOL.defined_in_database?(@only_in_db).should == true
      EOL.defined_in_database?(@only_in_environment).should == false
      EOL.global_defined?(@only_in_db).should == true
      EOL.value_of_global(@only_in_db).should == @only_in_db_instance.value
    end
    
    it 'should recognize variables defined in the code' do
      EOL.defined_in_environment?(@only_in_environment).should == true
      EOL.defined_in_environment?(@only_in_db).should == false
      EOL.global_defined?(@only_in_environment).should == true
      EOL.value_of_global(@only_in_environment).should == $ONLY_IN_ENVIRONMENT
    end
    
    it 'should default to using the value in the environment' do
      @in_both = 'IN_BOTH'
      @in_both_instance = EolConfig.gen(:parameter => @in_both, :value => 'db value')
      EOL.value_of_global(@in_both).should == @in_both_instance.value
      
      # environment variable takes presedence
      $IN_BOTH = 'env value'
      EOL.value_of_global(@in_both).should == $IN_BOTH
      
      $IN_BOTH = nil
      EOL.value_of_global(@in_both).should == nil
    end
    
    it 'should be able to change or unset global variables' do
      @variable_name = 'TEST_UNSETTING'
      @db_global = EolConfig.gen(:parameter => @variable_name, :value => 'some value in db')
      EOL.value_of_global(@variable_name).should == @db_global.value
      
      @db_global.value = 'a changed value'
      @db_global.save
      @db_global.value.should == 'a changed value'
      EOL.value_of_global(@variable_name).should == 'a changed value'
      
      @db_global.delete()
      EOL.value_of_global(@variable_name).should == nil
      
      $TEST_UNSETTING = 'value in environment'
      EOL.value_of_global(@variable_name).should == $TEST_UNSETTING
      
      $TEST_UNSETTING = 'changed value in environment'
      EOL.value_of_global(@variable_name).should == 'changed value in environment'
      
      # its not possible to undefine a global variable in Ruby, so the value will remain nil here
      $TEST_UNSETTING = nil
      EOL.value_of_global(@variable_name).should == nil
      @db_global = EolConfig.gen(:parameter => @variable_name, :value => 'resurrected DB value')
      EOL.value_of_global(@variable_name).should == nil
      
    end
    
  end
end
