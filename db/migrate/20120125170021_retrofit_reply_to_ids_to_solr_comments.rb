class RetrofitReplyToIdsToSolrComments < ActiveRecord::Migration
  def self.up
    # We released the reply-to functionality this year.  I'm going back a little further just to be safe (though I
    # did actually check it and there isn't really a need; it doesn't hurt):
    # (NOTE - as of this writing, there were all of 36 comments on staging (at least) to apply this to, so I'm not
    # worried about performance.  OBVIOSULY, Solr needs to be restarted before this migration can run.)
    solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
    Comment.find_by_sql("SELECT * FROM comments WHERE reply_to_id IS NOT NULL AND created_at > 2011-12-1").each do |c|
      solr_connection.delete_by_query("activity_log_unique_key:Comment_#{c.id}")
      c.log_activity_in_solr
    end
  end

  def self.down
    puts "** WARNING: You asked to 'down' the RetrofitReplyToIdsToSolrComments migration, but there is nothing to do."
  end
end
