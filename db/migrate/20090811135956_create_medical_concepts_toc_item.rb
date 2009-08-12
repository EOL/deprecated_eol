class CreateMedicalConceptsTocItem < ActiveRecord::Migration
  def self.up
    references = TocItem.find_by_label('References and More Information')
    if references 
      children   = TocItem.find_all_by_parent_id(references.id)
      found_specialist_projects = false # Yes, I c/ use new_view_order instead, but found that confusing.
      new_view_order = 0
      # Re-order the children
      children.each do |child|
        if found_specialist_projects
          # The children after SP need their view order bumped up by one:
          new_view_order += 1
          child.view_order = new_view_order
          child.save!
        else
          if child.label == 'Specialist Projects'
            new_view_order = child.view_order + 1
            found_specialist_projects = true
            TocItem.create(:parent_id => references.id, :label => 'Medical Concepts', :view_order => new_view_order)
          end
        end
      end
      unless found_specialist_projects
        puts "** WARNING: I couldn't find the 'Specialist Projects' TocItem."
        puts "** I am assuming you are NOT running this in PRODUCTION (or staging or the like)."
        puts "** If you ARE IN PRODUCTION, this is a big problem.  Contact a developer for information."
      end
    else
      puts "** WARNING: I couldn't find a 'References and More Information' TocItem."
      puts "** I am assuming you are NOT running this in PRODUCTION (or staging or the like)."
      puts "** If you ARE IN PRODUCTION, this is a big problem.  Contact a developer for information."
    end

  end

  def self.down
  end
end
