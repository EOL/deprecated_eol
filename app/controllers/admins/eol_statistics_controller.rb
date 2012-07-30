require 'csv'
class Admins::EolStatisticsController < AdminsController

  def index
    @stats = get_stats(:overall)
    csv_write(params, @stats)
  end

  def content_partners
    @stats = get_stats(action_name)
    csv_write(params, @stats)
  end

  def data_objects
    @stats = get_stats(action_name)
    csv_write(params, @stats)
  end

  def marine
    @stats = get_stats(action_name)
    csv_write(params, @stats)
  end

  def curators
    @stats = get_stats(action_name)
    csv_write(params, @stats)
  end

  def page_richness
    @stats = get_stats(action_name)
    csv_write(params, @stats)
  end

  def user_ata_objects
    @stats = get_stats(action_name)
    csv_write(params, @stats)
  end

  def lifedesks
    @stats = get_stats(action_name)
    csv_write(params, @stats)
  end

  private
  def get_stats(report)
    EolStatistic.send(report) # FIXME: .paginate(:page => params[:page] ||= 1, :per_page => 30)
  end

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
