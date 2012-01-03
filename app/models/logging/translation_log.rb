class Logging::TranslationLog < LoggingModel
  def self.inc(which)
    if $ENABLE_TRANSLATION_LOGS
      val = Logging::TranslationLog.find_by_key(which.to_s)
      if val
        val.count += 1
        val.save
      else
        Logging::TranslationLog.create(:key => which.to_s, :count => 1)
      end
    end
  end
end
