require 'csv'
class Admins::ContentPartnersController < AdminsController

  # GET /admin/content_partners
  def index

    @page_title = I18n.t(:admin_content_partners_page_title)

    @name = params[:name] || ''
    @resource_status_id = params[:resource_status_id]
    @partner_status_id = params[:content_partner_status_id]
    @vetted = params[:vetted]
    @published = params[:published].blank? ? '' : params[:published].to_i
    @sort_by = params[:sort_by] || 'partner'

    order = case @sort_by
    when 'newest'
      'content_partners.created_at DESC'
    else
      'content_partners.full_name'
    end
    include = [ { :resources => [ :resource_status, :hierarchy, :dwc_hierarchy ] },
                :content_partner_status, :content_partner_contacts ]
    conditions = []
    conditions_replacements = {}
    unless @name.blank?
      conditions << "content_partners.full_name LIKE :name"
      conditions_replacements[:name] = "%#{@name}%"
    end
    unless @partner_status_id.blank?
      conditions << "content_partners.content_partner_status_id = :partner_status_id"
      conditions_replacements[:partner_status_id] = @partner_status_id
    end
    unless @resource_status_id.blank?
      conditions << "resources.resource_status_id = :resource_status_id"
      conditions_replacements[:resource_status_id] = @resource_status_id
    end
    unless @vetted.blank?
      conditions << "resources.vetted = :vetted"
      conditions_replacements[:vetted] = @vetted
      @vetted = @vetted.to_i
    end
    resource_ids = case @published
    when 0 # never been harvested
      HarvestEvent.all(:select => 'resource_id').collect{|e| e.resource_id}.uniq
    when 1 # never been published
      HarvestEvent.all(:select => 'resource_id', :conditions => 'published_at IS NOT null').collect{|e| e.resource_id}.uniq
    when 2 # latest harvest not published
      HarvestEvent.find(HarvestEvent.latest_ids).collect{|e| e.resource_id if e.published_at.nil?}.compact
    when 3 # latest harvest pending publish
      HarvestEvent.find(HarvestEvent.latest_ids).collect{|e| e.resource_id if e.published_at.nil? && e.publish == true}.compact
    when 4 # latest harvest published
      HarvestEvent.find(HarvestEvent.latest_ids).collect{|e| e.resource_id if ! e.published_at.nil?}.compact
    else
      nil
    end
    unless resource_ids.nil?
      if @published == 0 || @published == 1 # not harvested or not harvested but not published
        # resource_ids contain resources that have been harvested or harvested and published
        conditions << "(resources.id NOT IN (:resource_ids) OR resources.id IS NULL)"
      else
        conditions << "resources.id IN (:resource_ids)"
      end
      conditions_replacements[:resource_ids] = resource_ids
    end
    if @published == 5
      conditions << "resources.id IS NULL"
    end
    @partners = ContentPartner.paginate(
                  :page => params[:page],
                  :per_page => 40,
                  :include => include,
                  :conditions => [ conditions.join(' AND '), conditions_replacements],
                  :order => order)
    set_filter_options
    set_sort_options
    set_resource_edit_options
  end

  # GET /admins/content_partners/notifications
  # POST /admins/content_partners/notifications
  def notifications
    @page_title = I18n.t(:admin_content_partners_notifications_page_title)
    if request.post? && params[:notification] == 'content_partner_statistics_reminder'
      last_month = Date.today - 1.month
      # TODO: The following select is ignored. This appears to occur if conditions are added. Find a solution.
      @content_partners = ContentPartner.find(:all,
                            :include => [ :content_partner_contacts, { :user => :google_analytics_partner_summaries } ],
                            :select => 'content_partners.id, content_partners.full_name, content_partners.user_id,
                                        content_partner_contacts.full_name, content_partner_contacts.email',
                            :conditions => [ 'google_analytics_partner_summaries.year = :year
                                              AND google_analytics_partner_summaries.month = :month
                                              AND content_partner_contacts.email IS NOT NULL',
                                             { :year => last_month.year, :month => last_month.month } ] )
      @content_partners.each do |content_partner|
        content_partner.content_partner_contacts.each do |contact|
          Notifier.deliver_content_partner_statistics_reminder(content_partner, contact,
            Date::MONTHNAMES[last_month.month], last_month.year)
        end
      end
    end
  end

  # GET /admins/content_partners/statistics
  def statistics
    # Note: currently just one statistic is being shown (first published by date) if more stats are needed this
    # may deserve its own controller.
    @page_title = I18n.t(:admin_content_partners_statistics_page_title)

    @date_from = Time.mktime(params[:from][:year], params[:from][:month], params[:from][:day]) rescue nil
    @date_to = Time.mktime(params[:to][:year], params[:to][:month], params[:to][:day]) rescue nil

    @date_from = Time.now.beginning_of_month - 1.month if @date_from.blank?
    @date_to = Time.now.beginning_of_month - 1.second if @date_to.blank?

    @harvest_events = HarvestEvent.find(:all, :select => 'id, MIN(published_at), resource_id, published_at',
                           :group => :resource_id,
                           :conditions => ['published_at BETWEEN :from AND :to AND completed_at IS NOT NULL',
                                           { :from => @date_from.mysql_timestamp,
                                             :to => @date_to.mysql_timestamp}])
    @resources = Resource.find_all_by_id(@harvest_events.collect{|he| he.resource_id}.compact,
                                         :select => 'id, title, content_partner_id').compact
    @content_partners = ContentPartner.find_all_by_id(@resources.collect{|r| r.content_partner_id}.compact,
                                                      :select => 'id, full_name, created_at').compact

    if params[:commit_download_csv_first_published]
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |row|
        row << ['Partner ID','Partner Full Name', 'Registered Date', 'Resource ID', 'Resource', 'Harvest ID', 'First Published']
        @harvest_events.each do |harvest_event|
          r = []
          resource = @resources.select{|r| r.id == harvest_event.resource_id}.first rescue nil
          if resource.blank?
            r = [ nil, nil, nil, nil, nil ]
          else
            content_partner = @content_partners.select{|cp| cp.id == resource.content_partner_id}.first rescue nil
            if content_partner.blank?
              r = [ nil, nil, nil]
            else
              r = [content_partner.id, content_partner.full_name, content_partner.created_at]
            end
            r << resource.id
            r << resource.title
          end
          r << harvest_event.id
          r << harvest_event.published_at
          row << r
        end
      end
      report.rewind
      send_data(report.read, :type => 'text/csv; charset=iso-8859-1; header=present',
                :filename => "EOLContentPartnersFirstPublished_#{@date_from.strftime('%Y-%m-%d')}_#{@date_to.strftime('%Y-%m-%d')}.csv",
                :disposition => 'attachment', :encoding => 'utf8')
      return false
    end
  end

private

  def set_filter_options
    @resource_statuses = @partners.collect{|p| p.resources.collect{|r| r.resource_status}}.flatten.uniq.compact
    @partner_statuses  = @partners.collect{|p| p.content_partner_status}.flatten.uniq.compact
    @vetted_options    = [ [I18n.t(:option_please_select), ""],
                           [I18n.t(:content_partner_filter_option_vetted_yes), 1],
                           [I18n.t(:content_partner_filter_option_vetted_no), 0]]
    @published_options = [ [I18n.t(:option_please_select), ""],
                           [I18n.t(:content_partner_filter_option_published_never_harvested), 0],
                           [I18n.t(:content_partner_filter_option_published_never_published), 1],
                           [I18n.t(:content_partner_filter_option_published_latest_harvest_not_published), 2],
                           [I18n.t(:content_partner_filter_option_published_latest_harvest_pending_publish), 3],
                           [I18n.t(:content_partner_filter_option_published_latest_harvest_published), 4],
                           [I18n.t(:content_partner_filter_option_published_no_resources), 5] ]
  end

  def set_sort_options
    @sort_by_options   = [[I18n.t(:content_partner_column_header_partner), 'partner'],
                          [I18n.t(:sort_by_newest_option), 'newest'],
                          [I18n.t(:sort_by_oldest_option), 'oldest']]
  end

  def set_resource_edit_options
    @import_frequencies = [ [ I18n.t(:import_once), 0 ],
                            [ I18n.t(:weekly), 7 * 24 ],
                            [ I18n.t(:monthly), 30 * 24 ],
                            [ I18n.t(:bi_monthly), 60 * 24 ],
                            [ I18n.t(:quarterly), 91 * 24 ] ]
  end
end
