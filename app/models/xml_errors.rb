class XmlErrors
  def initialize(errors)
    @errors = errors
  end

  def to_xml(options = {})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.errors {
      @errors.each do |error|
        xml.error error
      end
    }
  end
end