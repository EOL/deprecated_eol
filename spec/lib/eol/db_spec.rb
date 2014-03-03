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

    let(:sql_file_name) { 'something.sql' }
    let(:yml_file_name) { 'something.yml' }
    let(:txt_file_name) { 'something.txt' }
    let(:non_yml_file_name) { 'yml.foo' }

    subject do
      allow(Dir).to receive(:new).with('tmp') { [sql_file_name, yml_file_name, txt_file_name, non_yml_file_name] }
      allow(File).to receive(:unlink) { true }
      EOL::Db.clear_temp
    end

    it 'deletes sql files from tmp' do
      expect(File).to receive(:unlink).with("tmp/#{sql_file_name}")
      subject
    end

    it 'deletes yml files from tmp' do
      expect(File).to receive(:unlink).with("tmp/#{yml_file_name}")
      subject
    end

    it 'does NOT delete txt files' do
      expect(File).to_not receive(:unlink).with("tmp/#{txt_file_name}")
      expect(File).to_not receive(:unlink).with(txt_file_name)
      subject
    end

    it 'does NOT delete "yml.foo"' do
      expect(File).to_not receive(:unlink).with("tmp/#{non_yml_file_name}")
      expect(File).to_not receive(:unlink).with(non_yml_file_name)
      subject
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
    allow(EOL::Db).to receive(:drop) { true }
    allow(EOL::Db).to receive(:create) { true }
    allow(EOL::Db).to receive(:clear_temp) { true }
    allow(Rake::Task['db:migrate']).to receive(:invoke) { true }
    EOL::Db.recreate
    expect(EOL::Db).to have_received(:drop)
    expect(EOL::Db).to have_received(:create)
    expect(EOL::Db).to have_received(:clear_temp)
    expect(Rake::Task['db:migrate']).to have_received(:invoke)
  end

  it '.rebuild calls a bunch of other methods' do
    allow(EOL::Db).to receive(:recreate) { true }
    allow(EOL::Db).to receive(:clear_temp) { true }
    allow(Rake::Task['solr:start']).to receive(:invoke) { true }
    allow(Rake::Task['scenarios:load']).to receive(:invoke) { true }
    allow(Rake::Task['solr:rebuild_all']).to receive(:invoke) { true }
    EOL::Db.rebuild
    expect(EOL::Db).to have_received(:recreate)
    expect(EOL::Db).to have_received(:clear_temp)
    expect(Rake::Task['solr:start']).to have_received(:invoke).at_least(:once)
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

  context 'when included' do

    let(:with_include) do
      dummy = Object.new
      dummy.extend(EOL::Db)
    end

    describe '#start_transactions' do

      after do
        Thread.current['open_transactions'] = 0
      end

      let(:connection_1) { double(Object, begin_db_transaction: true) }
      let(:connection_2) { double(Object, begin_db_transaction: true) }

      it 'begins transactions on each connection' do
        allow(EOL::Db).to receive(:all_connections) { [connection_1, connection_2] }
        with_include.start_transactions
        expect(connection_1).to have_received(:begin_db_transaction)
        expect(connection_2).to have_received(:begin_db_transaction)
      end

      it 'counts connections' do
        with_include.start_transactions
        expect(Thread.current['open_transactions']).to eq(2)
      end

    end

    describe '#rollback_transactions' do

      let(:connection_1) { double(Object, rollback_db_transaction: true) }
      let(:connection_2) { double(Object, rollback_db_transaction: true) }

      it 'begins transactions on each connection' do
        allow(EOL::Db).to receive(:all_connections) { [connection_1, connection_2] }
        with_include.rollback_transactions
        expect(connection_1).to have_received(:rollback_db_transaction)
        expect(connection_2).to have_received(:rollback_db_transaction)
      end

      it 'counts connections' do
        with_include.rollback_transactions
        expect(Thread.current['open_transactions']).to eq(0)
      end

    end

  end

end
