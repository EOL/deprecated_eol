class CreateSurveyResponses < ActiveRecord::Migration
  def self.up
    create_table :survey_responses do |t|
      t.column :taxon_id, :string
      t.column :user_response, :string
      t.column :user_id, :integer
      t.column :user_agent, :string, :limit=>100
      t.column :ip_address, :string
      t.timestamps 
    end
  end

  def self.down
    drop_table :survey_responses
  end
end
