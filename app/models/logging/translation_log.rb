class Logging::TranslationLog < LoggingModel
  def self.inc(which)
    if $ENABLE_TRANSLATION_LOGS
      self.connection.execute(
        "INSERT INTO translation_logs (`key`, count) VALUES ('#{which}', 1) ON DUPLICATE KEY UPDATE count = count+1"
      )
    end
  end
end

# TEMP!  I'm testing things. Delete this.
class TranslationLog
end
