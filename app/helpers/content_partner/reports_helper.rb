# TODO: should this be moved?  somehow, both the Administrator and DataPartner versions of
# the ReportsController views get access to these ...

module ContentPartner::ReportsHelper

  # helper method for easily constructing paths to reports (with query strings)
  #
  # Usage:
  #
  #   path_for_report
  #   path_for_report :states
  #   path_for_report :page => 2, :per_page => 10
  #   path_for_report :states, :page => 2, :per_page => 10
  #
  # If no report is given, it will default to the current +@report+ (assuming you're on a report's page)
  #
  def path_for_report report = nil, query_strings = {}
    if report.is_a?Hash
      query_strings = report
      report        = @report
    elsif report.nil?
      report        = @report
    end

    format = ''
    if query_strings.include? :format
      format = '.' + query_strings.delete(:format).to_s
    end

    report_path   = "/#{controller.controller_path}/#{ report }#{ format }"
    query_strings = request.query_parameters.merge query_strings.stringify_keys

    # create the full string.  only select the query strings where the value isn't nil.
    query_string = query_strings.select {|k,v| not v.nil? }.map {|k,v| "#{k}=#{v}"}.join('&')
    report_path + ((query_string.empty?) ? '' : "?#{ query_string }")
  end

  # helper method for easily constructing links to reports (with query strings)
  #
  # see #path_for_report
  #
  # Usage:
  #
  #   link_to_report 'Current Report'
  #   link_to_report 'States Report', :states
  #   link_to_report 'States Report', :states, :per_page => 50, :page => 5
  #
  def link_to_report text, report = nil, query_strings = {}
    %{<a href="#{ path_for_report report, query_strings }">#{ text }</a>}
  end

end
