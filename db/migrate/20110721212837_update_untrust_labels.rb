class UpdateUntrustLabels < ActiveRecord::Migration
  def self.up
    execute("update translated_untrust_reasons set label='misidentified' where label='Misidentified'")
    execute("update translated_untrust_reasons set label='incorrect/misleading' where label='Incorrect/misleading information'")
    execute("update translated_untrust_reasons set label='low quality' where label='Poor writing/image/sound quality'")
    execute("update translated_untrust_reasons set label='duplicate' where label='Redundant/duplicate'")
  end

  def self.down
    execute("update translated_untrust_reasons set label='Misidentified' where label='misidentified'")
    execute("update translated_untrust_reasons set label='Incorrect/misleading information' where label='incorrect/misleading'")
    execute("update translated_untrust_reasons set label='Poor writing/image/sound quality' where label='low quality'")
    execute("update translated_untrust_reasons set label='Redundant/duplicate' where label='duplicate'")
  end
end
