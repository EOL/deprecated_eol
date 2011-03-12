class AddVettedForCommonNames <  EOL::DataMigration
  def self.up
    begin
      add_column :synonyms, :vetted_id, :integer, :default => 0
    rescue => e
      puts "** WARNING (non-fatal):"
      puts e.message
    end
    begin
      add_column :taxon_concept_names, :vetted_id, :integer, :default => 0
    rescue => e
      puts "** WARNING (non-fatal):"
      puts e.message
    end
    trusted = Vetted.find_by_label('trusted') || 1 # Because in, day, RAILS_ENV=test, there won't be one...  :\
    users_db = User.connection.config[:database]
    # Yup, this is a cross-database join.  But it's only one, so it's mostly harmless, and I want to be *absolutely* sure
    # that the agents have users (meaning: they are curators) in these cases.
    Synonym.connection.execute(
      %Q{
        UPDATE synonyms s
        SET s.vetted_id = #{trusted.id}
        WHERE s.id IN (
          SELECT synonym_id
          FROM agents_synonyms
            JOIN agents ON (agents_synonyms.agent_id = agents.id)
            JOIN #{users_db}.users ON (agents.id = #{users_db}.users.agent_id)
          WHERE #{users_db}.users.agent_id IS NOT null
            AND #{users_db}.users.curator_approved = 1
        )
      }
    );
    ChangeableObjectType.create(:ch_object_type => 'synonym')
    ChangeableObjectType.create(:ch_object_type => 'taxon_concept_name')
    ActionWithObject.create(:action_code => 'unreviewed')
  end

  def self.down
    remove_column :taxon_concept_names, :vetted_id
    remove_column :synonyms, :vetted_id
    ChangeableObjectType.find_by_ch_object_type('synonym').destroy
    ChangeableObjectType.find_by_ch_object_type('taxon_concept_name').destroy
    ActionWithObject.find_by_action_code('unreviewed').destroy
  end
end
