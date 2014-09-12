require "spec_helper"

# Needed for mocking later, if it's not available
unless defined?(Rake)

  module Rake
  end

  unless defined?(Rake::Task)
    module Rake
      class Task
        def self.[](name)
        end
      end
    end
  end

end

describe EOL::Db do

  before(:all) { @rake_task_hash = {} }

  before do
    allow(Rake::Task).to receive(:[]) do |name|
      # For stubbing
      @rake_task_hash[name] ||= Object.new
    end
  end

  describe '.all_connections' do

    it 'gets connections from ActiveRecord::Base and LoggingModel' do
      expect(EOL::Db.all_connections).to include(ActiveRecord::Base.connection)
      expect(EOL::Db.all_connections).to include(LoggingModel.connection)
    end

  end

  describe '.clear_temp' do

    # TODO - ensure it does NOT delete files that don't include "_test_"
    before do
      @sql_file_name = 'file_created_by_specs_test_whatever.sql'
      @yml_file_name = 'file_created_by_specs_test_whatever.yml'
      @txt_file_name = 'file_created_by_specs_test_whatever.txt'
      @non_yml_file_name = 'file_created_by_specs_yml.foo'
      @all_files = [@sql_file_name, @yml_file_name, @txt_file_name,
        @non_yml_file_name]

      @all_files.each do |file|
        FileUtils.touch(Rails.root.join("tmp", file))
      end
    end

    after do
      @all_files.each do |file|
        file = Rails.root.join("tmp", file)
        File.unlink(file) if File.exist?(file)
      end
    end

    subject do
      EOL::Db.clear_temp
    end

    it 'deletes sql files from tmp' do
      subject
      expect(File.exist?(Rails.root.join("tmp", @sql_file_name))).
        to be false
    end

    it 'deletes yml files from tmp' do
      subject
      expect(File.exist?(Rails.root.join("tmp", @yml_file_name))).
        to be false
    end

    it 'does NOT delete txt files' do
      subject
      expect(File.exist?(Rails.root.join("tmp", @txt_file_name))).
        to be true
    end

    it 'does NOT delete "yml.foo"' do
      subject
      expect(File.exist?(Rails.root.join("tmp", @non_yml_file_name))).
        to be true
    end

  end

  describe '.create' do

    before do
      allow(ActiveRecord::Base).to receive(:establish_connection) { true }
      allow(LoggingModel).to receive(:establish_connection) { true }
      allow(ActiveRecord::Base.connection).to receive(:create_database) { true }
      allow(LoggingModel.connection).to receive(:create_database) { true }
    end

    it 'creates the ActiveRecord::Base database' do
      EOL::Db.create
      expect(ActiveRecord::Base.connection).to have_received(:create_database)
    end

    it 'creates the LoggingModel database' do
      EOL::Db.create
      expect(LoggingModel.connection).to have_received(:create_database)
    end

  end

  describe '.drop' do

    let(:connection_1) { double(Object, drop_database: true, current_database: 'this') }
    let(:connection_2) { double(Object, drop_database: true, current_database: 'that') }

    before do
      allow(EOL::Db).to receive(:all_connections).and_return([connection_1, connection_2])
    end

    it 'does not run in production!' do
      # Assumes this only runs in test env...
      allow(Rails.env).to receive(:test?) { false }
      expect { EOL::Db.drop }.to raise_error
    end

    it 'drops all databases' do
      EOL::Db.drop
      expect(connection_1).to have_received(:drop_database)
      expect(connection_2).to have_received(:drop_database)
    end

  end

  it '.recreate calls a bunch of other methods' do
    allow(EOL::Db).to receive(:drop)
    allow(EOL::Db).to receive(:create)
    allow(EOL::Db).to receive(:clear_temp)
    allow(Rails.cache).to receive(:clear)
    # TODO - catch and test solr clearing code (but it needs to be moved, so
    # do that first.)
    allow(Rake::Task["solr:start"]).to receive(:invoke)
    allow(Rake::Task["db:migrate"]).to receive(:invoke)
    EOL::Db.recreate
    expect(EOL::Db).to have_received(:drop)
    expect(EOL::Db).to have_received(:create)
    expect(EOL::Db).to have_received(:clear_temp)
    expect(Rails.cache).to have_received(:clear)
    expect(Rake::Task["solr:start"]).to have_received(:invoke)
    expect(Rake::Task["db:migrate"]).to have_received(:invoke)
  end

  it '.rebuild calls a bunch of other methods' do
    allow(EOL::Db).to receive(:recreate) { true }
    allow(Rake::Task['scenarios:load']).to receive(:invoke) { true }
    allow(Rake::Task['solr:rebuild_all']).to receive(:invoke) { true }
    EOL::Db.rebuild
    expect(EOL::Db).to have_received(:recreate)
    expect(Rake::Task['scenarios:load']).to have_received(:invoke).once
    expect(Rake::Task['solr:rebuild_all']).to have_received(:invoke).once
    # This was the scenario that should have been run; "needs" to be stored in ENV:
    expect(ENV['NAME']).to eq('bootstrap')
  end

  it '.populate calls a bunch of other methods' do
    allow(EOL::Db).to receive(:clear_temp) { true }
    allow(Rake::Task['solr:start']).to receive(:invoke) { true }
    allow(Rake::Task['truncate']).to receive(:invoke) { true }
    allow(Rake::Task['scenarios:load']).to receive(:invoke) { true }
    allow(Rake::Task['solr:rebuild_all']).to receive(:invoke) { true }
    EOL::Db.populate
    expect(EOL::Db).to have_received(:clear_temp).once
    expect(Rake::Task['solr:start']).to have_received(:invoke).at_least(:once)
    expect(Rake::Task['truncate']).to have_received(:invoke).once
    expect(Rake::Task['scenarios:load']).to have_received(:invoke).once
    expect(Rake::Task['solr:rebuild_all']).to have_received(:invoke).once
    # This was the scenario that should have been run; "needs" to be stored in ENV:
    expect(ENV['NAME']).to eq('bootstrap')
  end

end
