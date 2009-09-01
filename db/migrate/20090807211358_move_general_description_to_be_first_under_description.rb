class MoveGeneralDescriptionToBeFirstUnderDescription < ActiveRecord::Migration
  def self.up
    description = TocItem.find_by_label('Description')
    if description
      descriptions = TocItem.find_all_by_parent_id(description.id)
      unless descriptions.blank?
        general_description = TocItem.find_by_label('General Description')
        raise "Expected to find a 'General Description' label in the toc_items table." unless general_description
        current_child_order = 1
        general_description.view_order = current_child_order
        general_description.save!
        descriptions.sort_by{ |d| d.view_order }.each do |child|
          current_child_order += 4
          next if child.id == general_description.id # We've already set this one to the first position.
          child.view_order = current_child_order
          child.save!
        end
      else
        puts "** IMPORTANT **\n"
        puts "I didn't find any children of 'Description' in the TOC Items.\n"
        puts "...I am going to assume you are in development or testing mode and haven't run the bootstrap scenario."
        puts "IF YOU GOT THIS MESSAGE ON STAGING OR IN PRODUCTION, something went seriously wrong.  Ask JRice."
      end
    else
      puts "** IMPORTANT **\n"
      puts "I didn't find a 'Description' TOC Item.\n"
      puts "...I am going to assume you are in development or testing mode and haven't run the foundation scenario."
      puts "IF YOU GOT THIS MESSAGE ON STAGING OR IN PRODUCTION, something went seriously wrong.  Ask JRice."
    end
  end

  def self.down
    # Nothing worth doing.
  end
end
