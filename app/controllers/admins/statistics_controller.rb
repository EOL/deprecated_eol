require 'csv'
class Admins::StatisticsController < AdminsController

  def index
    @page_title = I18n.t(:admin_statistics_overall_stat_page_title)
    stats = EolStatistic.overall
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 10)
    csv_write(params, stats)
  end

  def content_partner
    @page_title = I18n.t(:admin_statistics_content_partner_page_title)
    stats = EolStatistic.content_partners
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end
  
  def data_object
    @page_title = I18n.t(:admin_statistics_data_object_page_title)
    stats = EolStatistic.data_objects
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def marine_stat
    @page_title = I18n.t(:admin_statistics_marine_page_title)
    stats = EolStatistic.marine_stats
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def curator
    @page_title = I18n.t(:admin_statistics_curator_page_title)
    stats = EolStatistic.curators
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def rich_page
    @page_title = I18n.t(:admin_statistics_rich_page_page_title)
    stats = EolStatistic.rich_pages
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def user_added_text
    @page_title = I18n.t(:admin_statistics_user_added_text_page_title)
    stats = EolStatistic.user_added_texts
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end

  def lifedesk
    @page_title = I18n.t(:admin_statistics_lifedesk_page_title)
    stats = EolStatistic.lifedesks
    @stats = stats.paginate(:page => params[:page] ||= 1, :per_page => 30)
    csv_write(params, stats)
  end
  
  private
  def csv_write(params, stats)
    if params[:commit_download_csv]
      if params[:all_records].nil?
        stats = @stats
      end
      report = StringIO.new
      CSV::Writer.generate(report, ',') do |row|
        if params[:report] == 'overall_stats'
          row << ['Created',
                  I18n.t('activerecord.attributes.eol_statistic.members_count'),
                  I18n.t('activerecord.attributes.eol_statistic.communities_count'),
                  I18n.t('activerecord.attributes.eol_statistic.collections_count'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_count'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_content'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_text'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_image'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_map'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_video'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_sound'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_without_text'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_without_image'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_image_no_text'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_text_no_image'),
                  I18n.t('activerecord.attributes.eol_statistic.base_pages'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_at_least_a_trusted_object'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_at_least_a_curatorial_action'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_BHL_links'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_BHL_links_no_text'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_with_BHL_links_only')]
        elsif params[:report] == 'content_partners'
          row << ['Created',
                  I18n.t('activerecord.attributes.eol_statistic.content_partners'), 
                  I18n.t('activerecord.attributes.eol_statistic.content_partners_with_published_resources'), 
                  I18n.t('activerecord.attributes.eol_statistic.content_partners_with_published_trusted_resources'), 
                  I18n.t('activerecord.attributes.eol_statistic.published_resources'), 
                  I18n.t('activerecord.attributes.eol_statistic.published_trusted_resources'), 
                  I18n.t('activerecord.attributes.eol_statistic.published_unreviewed_resources'), 
                  I18n.t('activerecord.attributes.eol_statistic.newly_published_resources_in_the_last_30_days')]
        elsif params[:report] == 'data_objects'
          row << ['Created',
                  I18n.t('activerecord.attributes.eol_statistic.data_objects'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_texts'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_images'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_videos'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_sounds'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_maps'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_trusted'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_unreviewed'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_untrusted'),
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_trusted_or_unreviewed_but_hidden')]
        elsif params[:report] == 'marine_stats'
          row << ['Created',
                  I18n.t('activerecord.attributes.eol_statistic.marine_pages'),
                  I18n.t('activerecord.attributes.eol_statistic.marine_pages_in_col'),
                  I18n.t('activerecord.attributes.eol_statistic.marine_pages_with_objects'),
                  I18n.t('activerecord.attributes.eol_statistic.marine_pages_with_objects_vetted')]
        elsif params[:report] == 'curators'
          row << ['Created',
                  I18n.t('activerecord.attributes.eol_statistic.curators'),
                  I18n.t('activerecord.attributes.eol_statistic.curators_assistant'),
                  I18n.t('activerecord.attributes.eol_statistic.curators_full'),
                  I18n.t('activerecord.attributes.eol_statistic.curators_master'),
                  I18n.t('activerecord.attributes.eol_statistic.active_curators'),
                  I18n.t('activerecord.attributes.eol_statistic.pages_curated_by_active_curators'),
                  I18n.t('activerecord.attributes.eol_statistic.objects_curated_in_the_last_30_days'),
                  I18n.t('activerecord.attributes.eol_statistic.curator_actions_in_the_last_30_days')]
        elsif params[:report] == 'rich_page'
          row << ['Created',
                 I18n.t('activerecord.attributes.eol_statistic.rich_pages'),
                 I18n.t('activerecord.attributes.eol_statistic.hotlist_pages'),
                 I18n.t('activerecord.attributes.eol_statistic.rich_hotlist_pages'),
                 I18n.t('activerecord.attributes.eol_statistic.redhotlist_pages'),
                 I18n.t('activerecord.attributes.eol_statistic.rich_redhotlist_pages'),
                 I18n.t('activerecord.attributes.eol_statistic.pages_with_score_10_to_39'),
                 I18n.t('activerecord.attributes.eol_statistic.pages_with_score_less_than_10')]
        elsif params[:report] == 'user_added_texts'
          row << ['Created',
                  I18n.t('activerecord.attributes.eol_statistic.data_objects_texts'),
                  I18n.t('activerecord.attributes.eol_statistic.udo_published'),
                  I18n.t('activerecord.attributes.eol_statistic.udo_published_by_curators'),
                  I18n.t('activerecord.attributes.eol_statistic.udo_published_by_non_curators')]
        elsif params[:report] == 'lifedesks'
          row << ['Created',
                  I18n.t('activerecord.attributes.eol_statistic.lifedesk_taxa'),
                  I18n.t('activerecord.attributes.eol_statistic.lifedesk_data_objects'),]
        end
        stats.each do |s|
          if params[:report] == 'overall_stats'
            r = [s.created_at.strftime('%Y-%m-%d'),s.members_count,s.communities_count,s.collections_count,s.pages_count,s.pages_with_content,s.pages_with_text,s.pages_with_image,s.pages_with_map,s.pages_with_video,s.pages_with_sound,s.pages_without_text,s.pages_without_image,s.pages_with_image_no_text,s.pages_with_text_no_image,s.base_pages,s.pages_with_at_least_a_trusted_object,s.pages_with_at_least_a_curatorial_action,s.pages_with_BHL_links,s.pages_with_BHL_links_no_text,s.pages_with_BHL_links_only]
          elsif params[:report] == 'content_partners'
            r = [s.created_at.strftime('%Y-%m-%d'),s.content_partners, s.content_partners_with_published_resources, s.content_partners_with_published_trusted_resources, s.published_resources, s.published_trusted_resources, s.published_unreviewed_resources, s.newly_published_resources_in_the_last_30_days]
          elsif params[:report] == 'data_objects'
            r = [s.created_at.strftime('%Y-%m-%d'),s.data_objects,s.data_objects_texts,s.data_objects_images,s.data_objects_videos,s.data_objects_sounds,s.data_objects_maps,s.data_objects_trusted,s.data_objects_unreviewed,s.data_objects_untrusted,s.data_objects_trusted_or_unreviewed_but_hidden]
          elsif params[:report] == 'marine_stats'
            r = [s.created_at.strftime('%Y-%m-%d'),s.marine_pages,s.marine_pages_in_col,s.marine_pages_with_objects,s.marine_pages_with_objects_vetted]
          elsif params[:report] == 'curators'
            r = [s.created_at.strftime('%Y-%m-%d'),s.curators, s.curators_assistant, s.curators_full, s.curators_master, s.active_curators, s.pages_curated_by_active_curators, s.objects_curated_in_the_last_30_days, s.curator_actions_in_the_last_30_days]
          elsif params[:report] == 'rich_page'
            r = [s.created_at.strftime('%Y-%m-%d'),s.rich_pages,s.hotlist_pages,s.rich_hotlist_pages,s.redhotlist_pages,s.rich_redhotlist_pages,s.pages_with_score_10_to_39,s.pages_with_score_less_than_10]
          elsif params[:report] == 'user_added_texts'
            r = [s.created_at.strftime('%Y-%m-%d'),s.data_objects_texts,s.udo_published,s.udo_published_by_curators,s.udo_published_by_non_curators]
          elsif params[:report] == 'lifedesks'
            r = [s.created_at.strftime('%Y-%m-%d'),s.lifedesk_taxa,s.lifedesk_data_objects]
          end
          row << r
        end
      end
      report.rewind
      send_data(report.read, :type => 'text/csv; charset=iso-8859-1; header=present', :filename => params[:report] + "_#{Date.today.strftime('%Y-%m-%d')}.csv", :disposition => 'attachment', :encoding => 'utf8')
      return false
    end
  end

end