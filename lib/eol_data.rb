class EOL
  module DB
    module Create
      def all
        ActiveRecord::Base.configurations.keys.find_all {|c| c =~ /#{RAILS_ENV}/ }.each do |config_name|
          config = ActiveRecord::Base.configurations[config_name]
          begin
            ActiveRecord::Base.establish_connection(config)
            ActiveRecord::Base.connection
          rescue
            @charset   = ENV['CHARSET']   || 'utf8'
            @collation = ENV['COLLATION'] || 'utf8_general_ci'
            begin
              ActiveRecord::Base.establish_connection(config.merge('database' => nil))
              ActiveRecord::Base.connection.create_database(config['database'], :charset => (config['charset'] || @charset), :collation => (config['collation'] || @collation))
              ActiveRecord::Base.establish_connection(config)
            rescue
              $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{config['charset'] || @charset}, collation: #{config['collation'] || @collation} (if you set the charset manually, make sure you have a matching collation)"
            end
          else
            $stderr.puts "#{config['database']} already exists"
          end
        end
      end
    end
    module Drop
      def all
        ActiveRecord::Base.configurations.keys.find_all {|c| c =~ /#{RAILS_ENV}/ }.each do |config_name|
          begin
            ActiveRecord::Base.connection.drop_database ActiveRecord::Base.configurations[config_name]['database']
          rescue
            $stderr.puts "#{ActiveRecord::Base.configurations[config_name]['database']} doesn't exist"
          end
        end
      end
    end

    def start_transactions
      [ User, CuratorActivity, Name ].each do |model|
        conn = model.connection
        Thread.current['open_transactions'] ||= 0
        Thread.current['open_transactions'] += 1
        conn.begin_db_transaction
        # puts "BEGIN transaction"
      end
    end

    def commit_transactions
      [ User, CuratorActivity, Name ].each do |model|
        conn = model.connection
        conn.commit_db_transaction
        Thread.current['open_transactions'] = 0
      end
    end

    def rollback_transactions
      [ User, CuratorActivity, Name ].each do |model|
        conn = model.connection
        conn.rollback_db_transaction
        Thread.current['open_transactions'] = 0
        # puts "ROLLBACK"
        # TODO after rolling back, this might be a good place to reset the auto_increment on tables
      end
    end

  end
    
  module Data

    # for each Hierarchy, make the nested sets for that Hierarchy via #make_nested_set
    def make_all_nested_sets
      Hierarchy.find(:all).each do |hierarchy|
        make_nested_set hierarchy
      end
    end
    
    # grabs the top-level HierarchyEntry nodes of a given Hierarchy and assigns proper 
    # lft/rgt IDs to them and their children via #assign_id
    def make_nested_set hierarchy
      next_range_id = 1
      hierarchy.hierarchy_entries.select {|entry| entry.parent_id == 0 }.each do |entry|
        next_range_id = assign_id entry, next_range_id
      end
    end

    # recurses through the childred of a HierarchyEntry and, given the current 'next_range_id',
    # assigns their lft/rgt IDs properly via #assign_id
    def make_nested_set_recursion entry, next_range_id
      entry.children.each do |child|
        next_range_id = assign_id child, next_range_id
      end
      return next_range_id
    end

    # assigns the proper lft/right IDs to a HierarchyEntry given the current 'next_range_id' 
    # and calls #make_nested_set_recursion to assign_id for the entry's children
    def assign_id entry, next_range_id
      entry.lft = next_range_id
      next_range_id += 1
      next_range_id = make_nested_set_recursion entry, next_range_id
      entry.rgt = next_range_id
      next_range_id += 1
      entry.save!
      return next_range_id
    end
    
    
    
    
    def rebuild_collection_type_nested_set
      CollectionType.find(:all).each do |ct|
        ct.lft = ct.rgt = 0
        ct.save!
      end
      nested_set_value = 0
      CollectionType.find_all_by_parent_id(0).each do |ct|
        nested_set_value = rebuild_collection_type_nested_set_assign(ct, nested_set_value)
      end
    end
    
    def rebuild_collection_type_nested_set_assign(ct, nested_set_value)
      ct.lft = nested_set_value
      ct.save!
      nested_set_value += 1
      
      CollectionType.find_all_by_parent_id(ct.id).each do |child_ct|
        nested_set_value = rebuild_collection_type_nested_set_assign(child_ct, nested_set_value)
      end
      
      ct.rgt = nested_set_value
      ct.save!
      nested_set_value += 1
      
      return nested_set_value
    end
    
  end

  module Print
    
    # prints out HierarchyEntry notes for a given Hierarchy ID, displaying depths, eg:
    #
    #  $ ./script/console 
    #  Loading development environment (Rails 2.1.1)
    #  >> require 'eol_data'
    #  => ["EOL"]
    #  >> include EOL::Print
    #  => Object
    #  >> print_hierarchy_entries
    #  [16097869] Animals [1 -> 126]
    #    [99953] giant eaque [106 -> 107]
    #    [99954] least excepturi [108 -> 109]
    #    [888001] Karenteen seabream [124 -> 125]
    #  [16098238] Plants [127 -> 128]
    #  [16098245] Bacteria [129 -> 130]
    #  [16101659] Chromista [131 -> 146]
    #    [16101973] <i>Sagenista</i> [132 -> 145]
    #      [16101974] Bicosoecids [133 -> 144]
    #        [16101975] <i>Bicosoecales</i> [134 -> 143]
    #          [16101978] <i>Cafeteriaceae</i> [135 -> 142]
    #            [16109089] <i>Cafeteria</i> [136 -> 139]
    #              [16222828] <i>Cafeteria roenbergensis</i> [137 -> 138]
    #            [16222829] <i>Spicy Food</i> [140 -> 141]
    #  [16101981] Fungi [147 -> 148]
    #
    def print_hierarchy_entries hierarchy_id = 106
      Hierarchy.find(hierarchy_id).hierarchy_entries.select {|he| he.parent_id == 0 }.each {|he| print_he he }
    end

    def print_he(he)
      puts "#{ "\t" * he.depth }[#{he.id}] #{he.name} [#{he.lft} -> #{he.rgt}]"
      he.children.each {|child| print_he(child) }
    end
    
  end
end
