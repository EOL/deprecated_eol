class DataSearchFile < ActiveRecord::Base
  include FileDownloadHelper

  # TODO: remove file_number ; not using it now.
  attr_accessible :from, :known_uri, :known_uri_id, :language, :language_id, :q,
    :sort, :to, :uri, :user, :user_id, :completed_at, :hosted_file_url,
    :row_count, :unit_uri, :taxon_concept_id, :file_number, :failed_at, :error
  attr_accessor :results

  has_many :data_search_file_equivalents

  belongs_to :user
  belongs_to :language
  belongs_to :known_uri
  belongs_to :taxon_concept

  def build_file
    if other = similar_file
      FileUtils.cp(other.local_file_path, local_file_path, preserve: true)
      mark_as_completed
    else
      write_file
    end
    response = upload_file(id, local_file_path, local_file_url)
    if response[:error].blank?
      # The user may delete the download before it has finished (if it's hung,
      # the workers are busy or its just taking a very long time). If so,
      # we should not email them when the process has finished
      if hosted_file_exists? && instance_still_exists?
        send_completion_email
      end
      mark_as_completed
    else
      # something goes wrong with uploading file
      update_attributes(failed_at: Time.now.utc, error: response[:error])
    end
  end

  def similar_file
    dsf = DataSearchFile.where(q: q, uri: uri, from: from, to: to, sort: sort,
      taxon_concept_id: taxon_concept_id, unit_uri: unit_uri).
      where(["completed_at > ?", EXPIRATION_TIME.ago]).
      where(["id != ?", id]).last
    return nil unless dsf
    File.exist?(dsf.local_file_path) && dsf.downloadable? ? dsf : nil
  end

  def mark_as_completed
    update_attributes(completed_at: Time.now.utc, failed_at: nil)
  end

  def failed?
    ! failed_at.blank?
  end

  def csv(options = {})
    rows = get_data(options)
    col_heads = get_headers(rows)
    CSV.generate do |csv|
      csv_builder(csv, col_heads, rows)
    end
  end

  def instance_still_exists?
    !! DataSearchFile.find_by_id(id)
  end

  def local_file_url
    "http://" + EOL::Server.ip_address +
      Rails.configuration.data_search_file_rel_path.sub(/:id/, id.to_s)
  end

  def unit_known_uri
    KnownUri.by_uri(unit_uri)
  end

  def local_file_path
    Rails.configuration.data_search_file_full_path.sub(/:id/, id.to_s)
  end

  private

  def get_data(options = {})
    # TODO - we should also check to see if the job has been canceled.
    rows = []
    page = 1
    search = { querystring: q, attribute: uri, min_value: from, max_value: to,
        sort: sort, page: page, per_page: 200, clade: taxon_concept_id,
        unit: unit_uri }
    results = SearchTraits.new(search)
    total = results.traits.total_entries
    count = results.traits.count
    while count <= total and results.traits.count > 0
      EOL.log("DSF: page #{page}, count #{count}, total #{total}", prefix: ".")
      break unless DataSearchFile.exists?(self) # Someone canceled the job.
      results.traits.each do |trait|
        if trait.hidden?
          # TODO - we should probably add a "hidden" column to the file and
          # allow admins/master curators to see those rows, (as long as they are
          # marked as hidden). For now, though, let's just remove the rows:
          # data_column_tc_id is used here just because it is the first cloumn
          # in the downloaded file.
          rows << { I18n.t(:data_column_tc_id) =>
            I18n.t(:data_search_row_hidden) }
        else
          rows << trait.to_hash
        end
      end
      page += 1
      results = SearchTraits.new(search.merge(page: page))
      count += results.traits.count
    end
    rows
  end

  # TODO - we /might/ want to add the utf-8 BOM here to ease opening the file
  # for users of Excel. q.v.:
  # http://stackoverflow.com/questions/9886705/how-to-write-bom-marker-to-a-file-in-ruby
  def write_file
    rows = get_data
    col_heads = get_headers(rows)
    CSV.open(local_file_path, 'wb') do |csv|
      csv_builder(csv, col_heads, rows)
    end
    update_attributes(row_count: rows.count, failed_at: nil, error: nil)
  end

  def send_completion_email
    RecentActivityMailer.data_search_file_download_ready(self).deliver
  end

end
