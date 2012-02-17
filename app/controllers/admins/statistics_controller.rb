require 'csv'
class Admins::StatisticsController < AdminsController

  def index
    params[:report] = 'overall'
    stats = EolStatistic.overall
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 10)
    csv_write(params, stats)
  end

  def content_partner
    stats = EolStatistic.content_partners
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def data_object
    stats = EolStatistic.data_objects
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def marine
    stats = EolStatistic.marine
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def curator
    stats = EolStatistic.curators
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def page_richness
    stats = EolStatistic.page_richness
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def user_added_data
    stats = EolStatistic.user_added_data
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def lifedesk
    stats = EolStatistic.lifedesks
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end
  
  private
  def report_attributes
    @report_attributes ||= EolStatistic.report_attributes[params[:report] || params[:action]]
  end
  helper_method :report_attributes

  def csv_write(params, stats)
    if params[:commit_download_csv]
      if params[:all_records].nil?
        stats = @stats
      end
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |row|
        row << report_attributes.map {|attribute| I18n.t("activerecord.attributes.eol_statistic.#{attribute}")}
        stats.each do |s|
          r = report_attributes.map {|attribute| s.send(attribute)}
          row << r
        end
      end
      report.rewind
      send_data(report.read, :type => 'text/csv; charset=iso-8859-1; header=present', :filename => params[:action] + "_#{Date.today.strftime('%Y-%m-%d')}.csv", :disposition => 'attachment', :encoding => 'utf8')
      return false
    end
  end

end