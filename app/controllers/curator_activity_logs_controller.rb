class CuratorActivityLogsController < ApplicationController

  def index
    # Do nithing, fir niw.
  end

  def last_ten_minutes
    respond_to do |format|
      format.json { render :json => {count: CuratorActivityLog.where(["created_at >= ?", 10.minutes.ago.utc]).count} }
    end
  end

end
