module EOL
  module Solr
    class BHLCoreRebuilder
      attr_reader :solr_api
      attr_reader :objects_to_send
      attr_reader :title_item_publication_title_details

      def initialize()
        @solr_api = SolrAPI.new($SOLR_SERVER, $SOLR_BHL_CORE)
        @objects_to_send = []
      end

      def obliterate
        delete_all
      end
      
      def delete_all
        @solr_api.delete_all_documents
      end

      def begin_rebuild(optimize = true, options={})
        delete_all
        lookup_and_cache_publication_titles
        start_to_index_bhl
        SolrLog.log_transaction(options.merge(:core => $SOLR_BHL_CORE, :action => 'rebuild'))
        @solr_api.optimize if optimize
      end

      def start_to_index_bhl
        start = ItemPage.minimum('id')
        max_id = ItemPage.maximum('id')
        return if start.nil? || max_id.nil?
        limit = 50000
        i = start
        while i <= max_id
          @objects_to_send = {}
          lookup_item_pages(i, limit);
          lookup_page_names(i, limit);
          @objects_to_send.delete_if do |k, o|
            o['name_id'].blank?
          end
          @solr_api.send_attributes(@objects_to_send) unless @objects_to_send.blank?
          i += limit
        end
      end

      def lookup_item_pages(start, limit)
        max = start + limit
        ItemPage.connection.select_all("
              SELECT ip.id, ip.year, ip.volume, ip.issue, ip.number, ip.title_item_id, ip.prefix
              FROM item_pages ip
              WHERE ip.id BETWEEN #{start} AND #{max}").each do |row|
          next if @title_item_publication_title_details[row['title_item_id']].blank?
          title_details = @title_item_publication_title_details[row['title_item_id']]
          
          row['year'] = '1700' if row['year'] == '17--?'
          if row['year'] && m = row['year'].match(/^\[?([12][0-9]{3})(\?|\]|-| |$)/)
            row['year'] = m[1]
          else
            row['year'] = 0
          end
          
          fields = {
            'year' => row['year'],
            'volume' => row['volume'],
            'issue' => row['issue'],
            'number' => row['number'],
            'prefix' => row['prefix'],
            'publication_id' => SolrAPI.text_filter(title_details['id']),
            'title_item_id' => SolrAPI.text_filter(title_details['title_item_id']),
            'publication_title' => SolrAPI.text_filter(title_details['title']),
            'details' => SolrAPI.text_filter(title_details['details']),
            'volume_info' => SolrAPI.text_filter(title_details['volume_info']),
            'start_year' => title_details['start_year'],
            'end_year' => title_details['end_year']
          }
          
          # default year to start_year, so year can be the searchable column
          if fields['year'].blank? || fields['year'] == 0
            fields['year'] = fields['start_year']
          end
          # default year to 0 so we can ignore records with no year
          if fields['year'].blank? || fields['year'] == 0
            fields['year'] = 0
          end
          fields['name_id'] = []
          @objects_to_send[row['id']] = fields          
        end
      end
      
      def lookup_page_names(start, limit)
        max = start + limit
        PageName.connection.select_all("
              SELECT pn.item_page_id, pn.name_id
              FROM page_names pn
              WHERE pn.item_page_id BETWEEN #{start} AND #{max}").each do |row|
          next unless @objects_to_send[row['item_page_id']]
          @objects_to_send[row['item_page_id']]['name_id'] << row['name_id']          
        end
      end
      
      def lookup_and_cache_publication_titles
        @title_item_publication_title_details = {}
        PublicationTitle.connection.select_all('
              SELECT ti.id title_item_id, pt.id, pt.title, pt.start_year, pt.end_year, pt.details, ti.volume_info
              FROM publication_titles pt
              JOIN title_items ti ON (pt.id=ti.publication_title_id)').each do |row|
          @title_item_publication_title_details[row['title_item_id']] = {
            'id' => row['id'],
            'title' => row['title'],
            'start_year' => row['start_year'],
            'end_year' => row['end_year'],
            'details' => row['details'],
            'title_item_id' => row['title_item_id'],
            'volume_info' => row['volume_info']
          }
        end
      end
      
    end
  end
end
