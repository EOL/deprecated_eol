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
    unless hosted_file_exists?
      write_file
      response = upload_file(id, local_file_path, local_file_url)
      if response[:error].blank?
        # The user may delete the download before it has finished (if it's hung,
        # the workers are busy or its just taking a very long time). If so,
        # we should not email them when the process has finished
        if hosted_file_exists? && instance_still_exists?
          send_completion_email
        end
        update_attributes(completed_at: Time.now.utc)
      else
        # something goes wrong with uploading file
        update_attributes(failed_at: Time.now.utc, error: response[:error])
      end
    end
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

  def from_as_data_point
    DataPointUri.new(object: from, unit_of_measure_known_uri_id: unit_known_uri ? unit_known_uri.id : nil)
  end

  def to_as_data_point
    DataPointUri.new(object: to, unit_of_measure_known_uri_id: unit_known_uri ? unit_known_uri.id : nil)
  end

  private

  def local_file_path
    Rails.configuration.data_search_file_full_path.sub(/:id/, id.to_s)
  end

  def get_data(options = {})
    # TODO - we should also check to see if the job has been canceled.
    rows = []
    page = 1
    search = { querystring: q, attribute: uri, min_value: from, max_value: to,
        sort: sort, page: page, per_page: 1000, clade: taxon_concept_id,
        unit: unit_uri }
    results = SearchTraits.new(search)
    total = results.traits.total_entries
    count = results.traits.count
    while count <= total and results.traits.count > 0
      EOL.log("DSF: page #{page}, count #{count}, total #{total}", prefix: ".")
      break unless DataSearchFile.exists?(self) # Someone canceled the job.
      results.traits.each do |trait|
        if trait.point.hidden?
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

  # TODO - we /might/ want to add the utf-8 BOM here to ease opening the file for users of Excel. q.v.:
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
