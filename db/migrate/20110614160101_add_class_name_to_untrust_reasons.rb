class AddClassNameToUntrustReasons < ActiveRecord::Migration
  def self.up
    add_column :untrust_reasons, :class_name, :string, :limit => 32
    TranslatedUntrustReason.all.each do |tur|
      ur = tur.untrust_reason
      ur.class_name = tur.label.downcase
      ur.save!
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
