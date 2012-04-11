class UpdateCuratorVerdictAtValueForSomeCurators < ActiveRecord::Migration
  def self.up
    # Note: here we are updating curator_verdict_at for curators who were missing curator_verdict_at 
    # and curator_verdict_by_id. The value is set to '2012-03-29 00:00:00' as requested.
    execute "UPDATE users SET curator_verdict_at = '2012-03-29 00:00:00' WHERE curator_level_id > 0 AND curator_verdict_at IS NULL and curator_verdict_by_id IS NULL"
  end

  def self.down
    execute "UPDATE users SET curator_verdict_at = NULL WHERE curator_level_id > 0 AND curator_verdict_by_id IS NULL AND curator_verdict_at = '2012-03-29 00:00:00'"
  end
end
