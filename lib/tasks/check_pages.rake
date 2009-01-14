namespace :eol do
  desc 'Check all content-level 4 pages (and a handfull of others), to ensure they are actually working.'
  task (:check_pages => :environment)  do

    require 'hpricot'
    require 'open-uri'

    set = TaxonConceptContent.find_all_by_content_level(4).map {|c| c.id}
    set += TaxonConceptContent.find_all_by_content_level(3, :limit => 20).map {|c| c.id}
    set += TaxonConceptContent.find_all_by_content_level(2, :limit => 20).map {|c| c.id}
    set += TaxonConceptContent.find_all_by_content_level(1, :limit => 20).map {|c| c.id}
    start = Time.now
    length = set.length
    counter_size = 100000
    counter_size = 10000 if length < 1000000
    counter_size = 1000  if length < 100000 
    counter_size = 100   if length < 10000  
    counter_size = 10    if length < 1000   
    counter_size = 1     if length < 100    

    puts "+++ Starting.  Will test #{length} pages."

    set.each_with_index do |page, i|
      percent_complete = sprintf("%3.3f", i.to_f/length.to_f*100) + '% complete'
      print percent_complete
      begin
        doc = Hpricot(open("http://integration.eol.org/pages/#{page}"))
      rescue OpenURI::HTTPError => e
        puts "\n*** BROKEN: Page #{page} returned #{e.message}."
        next
      end
      title = doc.at("#page-title h1").inner_text
      if title =~ /Sorry,/
        puts "\n*** BROKEN: Page #{page} appears to be broken ('Sorry' message)"
      else
       if i % (length / counter_size) == 0
         time_taken = Time.now - start
         minutes = ((time_taken / (i + 1)) * (length - (i + 1))) / 60
         puts "\n--- Estimated time to completion: #{minutes.to_i} minutes"
         puts "    (That's #{minutes / 60} hours.)" if minutes > 120
         puts "    (And that's #{minutes / (60 * 24)} days!)" if minutes > (24 * 60)
         puts "    Seconds passed: #{time_taken} "
         puts "    Pages checked: #{i + 1}"
         puts "    Current page: #{title}"
       else
         print "\x08" * percent_complete.length
       end
      end
    end
    print "\n"

  end
end
