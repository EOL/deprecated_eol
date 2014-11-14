desc 'Move images to S3'
task :images_to_s3 => :environment do
  page = 1
  count = 1
  stop = 4
  s3 = AWS::S3.new
  suffixes = [
    '_130_130.jpg',
    '_260_190.jpg',
    '_580_360.jpg',
    '_88_88.jpg',
    '_98_68.jpg',
    '_orig.jpg',
    '.jpg'
  ]
  bucket = s3.buckets['eol.org.media']
  while count > 0 do
    search = EOL::Solr::SiteSearch.search_with_pagination(
      '*', page: 1, per_page: 100, type: ['Image']
    )
    count = search[:results].count
    # TODO: stop hard-coding these limits on the cache url.
    # NOTE: I wish we could use Solr to search on those values, but we cannot.
    # Thus, this takes a LONG time to run. ...Like, a REALLY long time. Sorry.
    search[:results].map { |r| r["instance"] }.
      select { |i| i.object_cache_url >= 201406000000000 and
                   i.object_cache_url < 201409000000000 }.each do |image|
      path = "/var/www/content" +
        ContentServer.cache_url_to_path(image.object_cache_url)
      suffixes.each do |suffix|
        bucket.objects["images"].write(file: path + suffix)
      end
    end
  end
end
