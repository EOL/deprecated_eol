require 'csv'
class Admins::EolStatisticsController < AdminsController

  def index
    stats
    csv_write
  end

  def content_partners
    stats
    csv_write
  end

  def data_objects
    stats
    csv_write
  end

  def marine
    stats
    csv_write
  end

  def curators
    stats
    csv_write
  end

  def page_richness
    stats
    csv_write
  end

  def users_data_objects
    stats
    csv_write
  end

  def lifedesks
    stats
    csv_write
  end

  private
  def stats
    @stats ||= if params[:commit_download_csv] && params[:all_records]
                 EolStatistic.send(report)
               else
                 # FIXME: WEB-3879 pagination broken on namedscopes.
                 # This should be EolStatistic.send(report).paginate(:page => params[:page] ||= 1, :per_page => 30)
                 # but we can't chain paginate on named scope at the moment, so we throw in a dup to break
                 # the chain, loading all stats and then paginating.
                 EolStatistic.send(report).dup.paginate(:page => params[:page] ||= 1, :per_page => 30)
               end
  end

  def report
    @report ||= case action_name
                when 'index'
                  :overall
                else
                  action_name
                end
  end

  def report_attributes
    @report_attributes ||= EolStatistic.sorted_report_attributes(report)
  end
  helper_method :report_attributes

  def csv_write
    if params[:commit_download_csv]
      data = StringIO.new
      CSV::Writer.generate(data, ',') do |row|
        row << report_attributes.map {|attribute| I18n.t("activerecord.attributes.eol_statistic.#{attribute}")}
        @stats.each do |s|
          r = report_attributes.map {|attribute| s.send(attribute)}
          row << r
        end
      end
      data.rewind
      send_data(data.read, :type => 'text/csv; charset=iso-8859-1; header=present', :filename => params[:action] + "_#{Date.today.strftime('%Y-%m-%d')}.csv", :disposition => 'attachment', :encoding => 'utf8')
      return false
    end
  end

end
