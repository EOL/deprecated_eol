# TODO what if we could basically just give each LogDaily a SQL string which we use?
#      these are too specific to DataObjectLog
#
# A nugget of information derived from the master log (DataObjectLog), intended to be optimized 
# for data reporting purposes and not necessarily normalized for performance reasons.
#
# There are a number of pieces of data that we track for each LogDaily.
# These are subject to change.  For now, we include them all here.
#
# For performance reasons (or if these defaults conflict with other LogDailies we
# wish to create), we will likely remove some of these associations / validations.
#
# All LogDaily classes should implement a few common class methods.
#
# LogDaily#mine RANGE
#   go and mine data for a range and save the log objects
#
# LogDaily#mine
#   go and mine ALL data (no range given) and save the log objects
#
# LogDaily#mine_data RANGE
#   returns objects to save (fetches the data used by #mine)
#
# LogDaily#mine_data
#   returns objects to save (fetches the data used by #mine_all)
#   
# LogDaily#grand_totals
#   returns the sum of the LogDaily#total for all records
#
# LogDaily#grand_totals RANGE
#   returns the sum of the LogDaily#total for a given range of records
#
# LogDaily#unique_data
#   returns the value of the LogDaily#unique_data_column ... LogDails objects all have a 
#   column with some kindof unique data that we're logging
#
#   IMPORTANT: this currently assumes that we only have 1 column of unique data
#              which we're logging and we'll display.  this should be refactored 
#              to handle any arbitrary number of columns and any arbitrary number 
#              of views of this data.  Needs to be simpler but also more flexible.
#
# LogDaily#create_table
#   intended to be called within the context of an ActiveRecord::Migration, this should 
#   properly create a LogDaily table with the default columns.  it should take a block
#   with the usual |t| parameter for defining any additional columns
#
# Primary Maintainers
# - Preston Lee <preston.lee@openrain.com>
# - Remi Taylor <remi.taylor@openrain.com>
class LogDaily < LoggingModel

  # default :per_page argument for pagination
  DEFAULT_PER_PAGE = 10 unless defined? DEFAULT_PER_PAGE

  self.abstract_class = true

  named_scope :find_all_for_range, lambda {|range|{ :conditions => ["day >= ? AND day <= ?", range.first, range.last] }}

  # Every fact always corresponds to a single DataType.
  belongs_to :data_type  
  validates_presence_of :data_type

  # We cache the Agent that every LogDaily is associated with
  belongs_to :agent
  validates_presence_of :agent

  # We store the count of some aggregation of data (#total) 
  # per *day* for every LogDaily
  validates_presence_of :day  

  # we don't have the unique column when the class is declared, so we actually 
  # set this validation in #set_unique_data_column
  # validates_uniqueness_of :day, :scope => [:agent_id, :data_type_id, self.unique_data_column.to_sym]

  # Every fact represents a count of some aggregation of data.
  validates_presence_of :total
  validates_numericality_of :total

  # if grand_totals is called with :include_percentage => true, grand_totals will set 
  # this column on all returned objects using using #total / the #total of all objects (ungrouped)
  attr_accessor :percentage

  class_inheritable_accessor :unique_data_column, :unique_data_column_info, :mine_data_options, :uniqueness_scope

  class << self
    def set_unique_data_column type, name, options = { :null => false }
      self.unique_data_column = name.to_s
      self.unique_data_column_info = { :type => type, :name => name, :options => options }

      # we validate the uniqueness of LogDaily objects per a given day, a unique data_type, 
      # a unique agent, AND the custom bit of unique_data
      #
      # we stick the scope we're using within a class attribute: uniqueness_scope so 
      # we can reuse it elsewhere, if desired
      #
      # actually, i thought i was going to reuse this, but i'm not currently reusing it anywhere, so ...
      # TODO remove uniqueness_scope ?
      self.uniqueness_scope = [ :agent_id, :data_type_id ]
      self.uniqueness_scope << self.unique_data_column.to_sym unless self.uniqueness_scope.include? unique_data_column.to_sym

      self.validates_uniqueness_of :day, :scope => self.uniqueness_scope
    end
    def set_mine_data_options options
      self.mine_data_options = options
    end
  end

  # returns the value of this daily's unique data column (eg. state_code or user_id)
  #
  # TODO i want to change this to return a Hash like { :description => 'blah', :data_table => 'xxx' }
  #      and then i can use the keys as table column headers and whatnot ... this also means changing 
  #      set_unique_data_column to set_unique_data_columns ... 
  #      if i wanna be really hardcore i might allow a lambda (or something that responds to #call) 
  #      as the value for the key, so it'll eval ONLY if you #call the value (IF the value responds to #call)
  #      ... it might help optimize so we're lazily loading some things.  then again, we might want to 
  #      eagerly load things to optimize as well
  def unique_data
    self.attributes[ self.unique_data_column ]
  end

  # whereas there is currently only 1 fact (#unique_data) that each LogDaily class 
  # tracks (within the scope of 1 day and 1 agent), each LogDaily class might have 
  # different unique data that makes up how the fact should be displayed.
  #
  # for example, if we track Agents, AgentLogDaily tracks the IDs of Agents.
  #
  # we might use #display_data to, instead, display some information about 
  # the particular Agent, eg. the Agent ID and the Agent name
  #
  # as this is merely data and not UI-specific (it's not specific to XML or HTML or CSV, etc),
  # I believe it's okay to have this on the model class, itself
  #
  # Usage:
  #
  #   class AgentLogDaily < LogDaily
  #     set_unique_data_column :agent_id
  #     display_data :agent_name => lambda {}
  #   end
  #def self.display_data
    # ...
  #end
  # ... i'm not yet sure how i actually wanna do this.  to be optimized, i wanna have the SQL updated
  #     for additional data we want to display, but i also wanna support 'virtual attribute' type data,
  #     which is calculated by a method in on the model ... i'll play with this when I create the 
  #     TopSpeciesLogDaily report

  # override this if you want to return something custom (and pretty) when #unique_data
  # is printed out (we call unique_data_to_s from views which defaults to unique_data.to_s)
  #
  # this will be deprecated when #unique_data becomes a hash
  def unique_data_to_s
    unique_data.to_s
  end

  # this will be deprecated when we change the way #unique_data works and make it more flexible
  #
  # for now, this merely allow us to give a unique name to our unique data.  essentially:
  #
  #   unique_data_name:  the name of the daily log's data
  #   unique_data:       the value is unique_data
  #   unique_data_to_s:  the value to display is unique_data_to_s
  #   
  # override this in your LogDaily class to return something different
  def self.unique_data_name
    self.report_name.singularize
  end

  # a pretty URL path that this class is associated with ... eg. StateLogDaily.path => 'states'
  def self.path
    self.name.sub(/LogDaily$/,'').underscore.pluralize
  end

  # returns the *LogDaily classes
  #
  # this is currently updated *MANUALLY*
  def self.report_classes
    # self.subclasses
    [ StateLogDaily, CountryLogDaily, UserLogDaily, AgentLogDaily, DataObjectLogDaily ]
  end

  # a pretty title / name for the report that this class is associated with (when we fetch grand_totals)
  # eg. StateLogDaily.report_name => 'States'
  #
  # TODO make this overridable in classes, set_report_name 'Blah'
  def self.report_name
    self.path.camelize.pluralize
  end

  ### Helpers for migrations for creating new LogDaily models ###

  def self.create_table(migration)
    migration.create_table self.table_name.to_sym, :force => true do |t|
      t.integer :data_type_id, :null => false
      t.integer :total, :null => false
      t.integer :agent_id, :null => false
      t.date    :day, :null => false

      unless [ :data_type_id, :total, :agent_id, :day ].include? self.unique_data_column.to_sym
        t.column self.unique_data_column_info[:name], self.unique_data_column_info[:type], self.unique_data_column_info[:options]
      end

      yield(t) if block_given?
    end
  end

  def self.drop_table(migration)
    migration.drop_table self.table_name.to_sym
  end

  # will run a #find or a #paginate call depending on whether pagination options are
  # included in the options passed.  it'll also set :per_page to a default if it's unset 
  # (and if :page is set) so you don't have to always pass :per_page in
  #
  # if :page => :all or :page => 'all', pagination will NOT be used
  #
  # TODO move this onto ActiveRecord::Base so all models get it?
  def self.find_or_paginate first_argument, options = {}
    if options.has_key? :page and not options[:page].to_s.downcase == 'all'
      options[:per_page] = DEFAULT_PER_PAGE unless options.has_key? :per_page
      paginate first_argument, options
    else
      options.delete :page
      options.delete :per_page
      find first_argument, options
    end
  end

  ### DEFAULT METHOD IMPLEMENTATIONS ###

  # mine a date range
  #
  # returns [(total number of items found),(number successfully mined),(number skipped)]
  def self.mine date_range = nil, additional_options = {}
    data = mine_data(date_range, additional_options)
    skipped = 0
    created = 0
    data.each do |log|
      begin
        object = create log.attributes # ActiveRecord validation errors are silenced
        (object.new_record?) ? (skipped += 1) : (created += 1)
      rescue ActiveRecord::StatementInvalid # Mysql::Error exceptions caught here, wrapped in StatementInvalid
        skipped += 1
      end
    end
    return data.length, created, skipped
  end

  # NOTE currently assumes logging from DataObjectLog!
  def self.mine_data date_range = nil, additional_options = {}
    options = { :select => "count(*) AS total, agent_id, data_type_id, DATE(data_object_logs.created_at) AS day, #{ self.unique_data_column }", 
      :group => "agent_id, data_type_id, #{ self.unique_data_column }, DATE(data_object_logs.created_at)" }
    options[:conditions] = ["DATE(data_object_logs.created_at) >= ? AND DATE(data_object_logs.created_at) <= ?", date_range.first, date_range.last] if date_range
    options.merge! self.mine_data_options if self.mine_data_options
    options.merge! additional_options     if additional_options
    DataObjectLog.find :all, options
  end

  # Usage: 
  #   grand_totals :options => value
  #   grand_totals <Date>..<Date>, :options => value
  #
  # see log_daily_spec for usage.
  #
  # you can pass in options and they will override the options passed to #find,
  # except for :conditions (you need to pass :override_conditions for that)
  #
  # please pass your :conditions in as ["sql string with :keys", {:keys => 'value'}]
  # or they will explode  :P
  #
  # there are a few 'special' options:
  # 
  #   :agent => 5               # filter the results to just those for Agent with id 5
  #   :agent => Agent.find(5)   # filter the results to just those for Agent with id 5
  #
  #   :include_percentage => true   # will add a .percentage to each item for the percentage its .total
  #                                 # represents out of ALL of the .total's for the query
  #
  #   :override_conditions => true  # the :conditions passed will override all other :conditions
  #
  # TODO test (spec) that :conditions work as expected, with and without :override_conditions
  #
  def self.grand_totals date_range = nil, additional_options = {}
    if date_range.is_a?Hash
      additional_options = date_range
      date_range         = nil
    end
    
    agent_id            = additional_options.delete :agent
    include_percentage  = additional_options.delete :include_percentage
    override_conditions = additional_options.delete :override_conditions

    conditions_sql      = []
    conditions_values   = {}

    # create the default #find options
    options = { 
      :select => "count(*) as count, sum(total) as total, agent_id, #{ self.unique_data_column }", 
      :group => "#{ self.unique_data_column }",
      :order => "sum(total) DESC, #{ self.unique_data_column }"
    }

    # filter by date, if a date_range was passed in
    if date_range
      conditions_sql += ["day >= :start_date", "day <= :end_date"]
      conditions_values.merge!({ :start_date => date_range.first, :end_date => date_range.last })
    end

    # filter by agent, if an agent was passed in
    if agent_id
      agent_id = agent_id.id if agent_id.is_a? Agent # we allow a Fixnum (id) or an Agent object
      conditions_sql << "agent_id = :agent_id"
      conditions_values.merge!({ :agent_id => agent_id })
    end

    # if :conditions were passed in and we're not overriding all of the conditions, add the conditions ( assuming ["",{}] format )
    if additional_options[:conditions] and not override_conditions
      conditions = additional_options.delete :conditions
      conditions_sql << conditions.first       unless conditions.first.empty?
      conditions_values.merge! conditions.last unless conditions.last.empty?
    end

    # build final :conditions to pass to #find
    unless additional_options[:conditions] and override_conditions
      options[:conditions] = [ conditions_sql.join(' AND '), conditions_values ] unless conditions_sql.empty?
    end

    # merge in the rest of the options
    options.merge! additional_options unless additional_options.empty?

    results = find_or_paginate :all, options

    if include_percentage == true
      # tweak options to get the total
      options.delete :group
      options.delete :page
      options.delete :per_page
      options[:select] = 'sum(total) as total'

      # get the total
      total = find( :all, options ).first.total.to_f

      results.each do |result|
        result.percentage = ( result.total.to_f / total ) * 100
      end
    end

    results
  end

end
