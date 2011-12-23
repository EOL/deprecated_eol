class RestoreAddRemoveAssociationCuratorActivityLogs < ActiveRecord::Migration
  def self.up
    cal_entries = []
    cdohe_entries = []
    duplicate_entries = []

    # get list of the curator activity logs where activity is 'add assocition' and the hierarchy entry is nil
    cal_entries = CuratorActivityLog.find_all_by_activity_id_and_hierarchy_entry_id(Activity.add_association.id, nil)

    # get the cdohe entries in cdohe_entries for each of the entries in cal_entries respectively
    cal_entries.each_index do |key|
      # use of 'read_attribute(:object_id)' is compulsory required here
      cdohes = CuratedDataObjectsHierarchyEntry.find_all_by_data_object_id_and_user_id(cal_entries[key].read_attribute(:object_id), cal_entries[key].user_id)
      unless cdohes.blank?
        cdohes.each do |cdohe|
          unless cdohe_entries.include?(cdohe)
            cdohe_entries[key] = cdohe if (cal_entries[key].created_at >= cdohe.created_at && cal_entries[key].created_at <= cdohe.created_at+15)
            break unless cdohe_entries[key].nil?
          end
        end
      else
        cdohe_entries[key] << nil
      end
    end

    # check if there are duplicate cdohe entries in the cdohe_entries
    if cdohe_entries.count != cdohe_entries.uniq.count
      cdohe_entries.each { |each| duplicate_entries << each if cdohe_entries.count(each) > 1 }
    end
    # get the unique cdohe duplicate entries
    duplicate_entries.uniq! unless duplicate_entries.blank?

    # save respective hierarchy_entries from cdohe to cal_entries
    cal_entries.each_index do |key|
      if duplicate_entries.count > 1
        skip_this_rec = 0
        duplicate_entries.each do |dupl|
          if cdohe_entries[key] == dupl
            skip_this_rec = 1
          end
        end
        unless cdohe_entries[key].nil?
          cal_entries[key].hierarchy_entry_id = cdohe_entries[key].hierarchy_entry_id unless skip_this_rec == 1
        end
      elsif duplicate_entries.count == 1
        unless cdohe_entries[key].nil?
          cal_entries[key].hierarchy_entry_id = cdohe_entries[key].hierarchy_entry_id unless cdohe_entries[key] == duplicate_entries[0]
        end
      else
        unless cdohe_entries[key].nil?
          cal_entries[key].hierarchy_entry_id = cdohe_entries[key].hierarchy_entry_id
        end
      end
      cal_entries[key].changeable_object_type_id = ChangeableObjectType.curated_data_objects_hierarchy_entry.id
      cal_entries[key].save
    end
    
  end

  def self.down
    # Nothing worth doing.
  end
end
