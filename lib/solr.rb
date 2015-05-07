class Solr
  def self.start
    if RUBY_PLATFORM =~ /w(in)?32$/
      raise("This command does not work on Windows. Please use rake solr:run " \
            "to run Solr in the foreground.")
    end
    # TODO - move these GLOBALS to Rails.configuration:
    port = $SOLR_SERVER.gsub(/^.*:(\d+).*$/, "\\1")
    FileUtils.cd(File.join($SOLR_DIR)) do
      command = [Rails.root.join("bin", "solr"), "start", "--", "-p", port]
      command << "-r" if $SOLR_SERVER_RAM
      command << "-s" << $SOLR_DIR if $SOLR_DIR
      system("java -version")
      if $?.exitstatus != 0
        puts "ERROR: Java is not installed on machine!!"
        return false
      end
      system(Escape.shell_command(command.map { |p| p.to_s }))
      return true
    end
  end

  # TODO - remove duplication with .start:
  def self.run
    if RUBY_PLATFORM =~ /w(in)?32$/
      abort("This command does not work on Windows.")
    end
    # data_path = Sunspot::Rails.configuration.data_path
    # FileUtils.mkdir_p(data_path)
    port = $SOLR_SERVER
    port.gsub!(/^.*:(\d+).*$/, "\\1")
    command = [Rails.root.join("bin", "solr"), "run", "--", "-p", port.to_s]
    command << "-r" if $SOLR_SERVER_RAM
    command << "-s" << $SOLR_DIR if $SOLR_DIR
    exec(command.join(" "))
  end

  def self.stop
    FileUtils.cd($SOLR_DIR) do
      exec([Rails.root.join("bin", "solr"), "stop"].join(" "))
    end
    File.delete(Rails.root.join("solr", "solr", "eol-solr.pid"))
  end
end
