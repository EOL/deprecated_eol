class AddUniqueKeyToTranslationLogs < EOL::LoggingMigration
  def self.up
    TranslationLog.connection.execute("ALTER TABLE translation_logs ADD UNIQUE KEY `key` (`key`)")
  end

  def self.down
    TranslationLog.connection.execute("ALTER TABLE translation_logs DROP KEY `key`")
  end
end
