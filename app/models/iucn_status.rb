module IucnStatus
  def from_uri(uri)
    status = uri.split('/').last.underscore
    case status
    when "extinct"
      "Extinct (EX)"
    when "extinct_in_the_wild"
      "Extinct in the Wild (EW)"
    when "extinctinthe_wild"
      "Extinct in the Wild (EW)"
    when "critically_endangered"
      "Critically Endangered (CR)"
    when "endangered"
      "Endangered (EN)"
    when "vulnerable"
      "Vulnerable (VU)"
    when "near_threatened"
      "Near Threatened (NT)"
    when "least_concern"
      "Least Concern (LC)"
    when "data_deficient"
      "Data Deficient (DD)"
    else
      status.humanize.split.map(&:capitalize).join(' ')
    end
  end
end
