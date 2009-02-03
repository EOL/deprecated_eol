require File.dirname(__FILE__) + '/spec_helper'

describe ActiveRecord::Comments, 'MySQL' do

  # HELPERS
  
  def connection
    ActiveRecord::Base.connection
  end

  def drop_table
    connection.execute 'DROP TABLE IF EXISTS foxes;'
  end

  before do
    drop_table
    @foxes = Class.new(ActiveRecord::Base){ set_table_name 'foxes' }
  end

  # EXAMPLES

  describe ActiveRecord::Base, 'extensions' do

    it "should create table OK" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY );"
      @foxes.count.should == 0
    end

    it "Model#comment should return nil for a model that doesn't have a database comment" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY );"
      @foxes.comment.should be_nil
      ActiveRecord::Base.comment(:foxes).should be_nil
      ActiveRecord::Base.comment('foxes').should be_nil
    end

    it "Model#comment should return the database comment for a model that has a database comment" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ) COMMENT 'foxes Rule';"
      @foxes.comment.should == 'foxes Rule'
      ActiveRecord::Base.comment(:foxes).should == 'foxes Rule'
      ActiveRecord::Base.comment('foxes').should == 'foxes Rule'
    end

    it "Model#comment should return the database comment for a model that has a database comment in different formats" do
      pending
      #[ 'foxes Rule', 'i has Numbers123', 'i have " double " quotes', "i have ' single quotes'" ].each do
      #  connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ) COMMENT 'foxes Rule';"
      #@foxes.comment.should == 'foxes Rule'
    end

  end

  describe ActiveRecord::ConnectionAdapters::Column, 'extensions' do

    it 'Model#column_comment should return the comment for a column' do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'i am the ID column' );"
      @foxes.column_comment('id').should == 'i am the ID column'
      @foxes.column_comment(:id).should == 'i am the ID column'
      ActiveRecord::Base.column_comment(:id, :foxes).should == 'i am the ID column'
      ActiveRecord::Base.column_comment(:id, 'foxes').should == 'i am the ID column'
      ActiveRecord::Base.column_comment('id', 'foxes').should == 'i am the ID column'
    end

    it "@column#comment should return nil for a column that doesn't have a database comment" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY );"
      @foxes.columns.first.name.should == 'id'
      @foxes.columns.first.comment.should be_nil
    end

    # need to add this extension (tho it's yucky) so a column can easily find its comment (needs its table name)
    it "@column should know its #table_name" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY );"
      @foxes.columns.length.should == 1
      @foxes.columns.first.table_name.should == 'foxes'
    end

    it "@column#comment should return the database comment for a column that has a database comment" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'i am the ID column' );"
      @foxes.columns.first.name.should == 'id'
      @foxes.columns.first.comment.should == 'i am the ID column'
    end

  end

  describe 'Connection', 'extensions' do
    
    it "@connection#comment(table) should return the database comment for a table that has a database comment" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY ) COMMENT 'foxes Rule';"
      connection.comment('foxes').should == 'foxes Rule'
      connection.comment(:foxes).should == 'foxes Rule'
    end

    it "@connection.columns(table) should inject the table name to column objects" do
      pending "Not implementing this (for now?)"
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'i am the ID column' );"
      connection.columns(:foxes).length.should == 1
      connection.columns(:foxes).first.name.should == 'id'
      connection.columns(:foxes).first.comment.should == 'i am the ID column'
    end

    it "@connection#column_comment should return the database comment for a column that has a database comment" do
      connection.execute "CREATE TABLE foxes( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'i am the ID column' );"
      connection.column_comment(:id, :foxes).should == 'i am the ID column'
      connection.column_comment('id', :foxes).should == 'i am the ID column'
      connection.column_comment('id', 'foxes').should == 'i am the ID column'
    end

  end

end
