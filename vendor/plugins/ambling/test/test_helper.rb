module TestHelper
  # UGH!  test/unit/xml can't handle a newline in the file
  # I tried REXML::Document.new(source, :compress_whitespace => :all) but that didn't work either
  def read_and_strip_xml_file(filename)
    File.read(File.join(File.dirname(__FILE__), "xmls", filename)).gsub(/>\s+</,"><")
  end
end