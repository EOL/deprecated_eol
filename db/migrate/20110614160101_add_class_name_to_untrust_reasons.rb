class AddClassNameToUntrustReasons < ActiveRecord::Migration
  def self.up
    add_column :untrust_reasons, :class_name, :string, :limit => 32
    TranslatedUntrustReason.all.each do |tur|
      # Doing this to the DB because I was getting a frozen hash when attempting this on the test_master DB:
      UntrustReason.connection.execute("UPDATE untrust_reasons SET class_name = '#{tur.label.downcase}' WHERE id =
                                       #{tur.untrust_reason_id}")
    end
    # Technically, this only needs to go through English, but I don't mind:
    TranslatedUntrustReason.all.each do |tur|
      case tur.label
      when 'Misidentified'
        # Do nothing, fine.
      when 'Incorrect'
        tur.label = "Incorrect/misleading information"
      when 'Poor'
        tur.label = "Poor writing/image/sound quality"
      when 'Duplicate'
        tur.label = "Redundant/duplicate"
      when 'Other'
        # Do nothing, fine.
      end
      tur.save!
    end
  end

  def self.down
    remove_column :untrust_reasons, :class_name
    # Technically, this only needs to go through English, but I don't mind:
    TranslatedUntrustReason.all.each do |tur|
      case tur.label
      when 'Misidentified'
        # Do nothing, fine.
      when "Incorrect/misleading information"
        tur.label = 'Incorrect'
      when "Poor writing/image/sound quality"
        tur.label = 'Poor'
      when "Redundant/duplicate"
        tur.label = 'Duplicate'
      when 'Other'
        # Do nothing, fine.
      end
      tur.save!
    end
  end
end
