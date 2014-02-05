class EolStatisticsController < ApplicationController

  layout 'basic'

  # GET /statistics
  def index
    get_stats(:overall)
  end

  # GET /statistics/content_partners
  def content_partners
    get_stats(action_name)
  end

  # GET /statistics/curators
  def curators
    get_stats(action_name)
  end

  # GET /statistics/data_objects
  def data_objects
    get_stats(action_name)
  end

  # GET /statistics/lifedesks
  def lifedesks
    get_stats(action_name)
  end

  # GET /statistics/marine
  def marine
    get_stats(action_name)
  end

  # GET /statistics/page_richness
  def page_richness
    get_stats(action_name)
  end

  # GET /statistics/users_data_objects
  def users_data_objects
    get_stats(action_name)
  end

  # GET /statistics/data
  def data
    get_stats(action_name)
  end

  private

  def get_stats(report)
    dates = Hash[[:date_one, :date_two].collect do |key|
      unless params[key].nil?
        [key, Date.new(params[key][:year].to_i, params[key][:month].to_i, params[key][:day].to_i)]
      end
    end]

    unless dates.empty?
      stats = EolStatistic.send(report).on_dates(dates.values)
      @stats_one = stats.select{|s| s.created_at.to_date == dates[:date_one]}.first
      @stats_two = stats.select{|s| s.created_at.to_date == dates[:date_two]}.first
      flash.now[:warning] = t('eol_statistics.warnings.stats_unavailable_for_date',
        date: dates[:date_one].strftime('%b %d, %Y')) if @stats_one.nil?
      flash.now[:warning] = t('eol_statistics.warnings.stats_unavailable_for_date',
        date: dates[:date_two].strftime('%b %d, %Y')) if @stats_two.nil?
    end
    @stats_two ||= EolStatistic.send(report).on_dates([Date.parse(params[:date_two_set])]).first if params[:date_two_set] # Fallback to the previously selected date if a newly selected date has no stats
    @stats_two ||= EolStatistic.send(report).latest(1).first # Default to latest stats
    @stats_one ||= EolStatistic.send(report).on_dates([Date.parse(params[:date_one_set])]).first if params[:date_one_set] # Fallback to the previously selected date if a newly selected date has no stats
    @stats_one ||= EolStatistic.send(report).on_dates([(@stats_two.created_at.to_date - 1.week)]).first unless @stats_two.nil? # Try to default to 1 week prior to second stats
    @stats_one ||= EolStatistic.send(report).at_least_one_week_ago(1).first # Otherwise default to something from a week ago
    EolStatistic.compare_and_set_greatest(@stats_one, @stats_two)
  end

end
