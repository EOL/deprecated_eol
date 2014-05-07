module Models
  module StdoutHelpers

    def capture_stdout(&blk)
      old = $stdout
      $stdout = fake = StringIO.new
      blk.call
      fake.string
    ensure
      $stdout = old
    end

  end
end
