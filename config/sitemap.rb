SitemapGenerator::Sitemap.create_index = :auto
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.default_host  = "http://eol.org"

SitemapGenerator::Sitemap.create do
  #hard-coded links
  add discover_path    , priority: 1
  add help_path        , priority: 1
  add about_path       , priority: 1      
  add news_path        , priority: 1
  add contact_path     , priority: 1
  add terms_of_use_path, priority: 1
  add citing_path      , priority: 1
  add privacy_path     , priority: 1
  add curators_path    , priority: 1
  
  #cms_page_urls
  names_which_have_routes = [ 'help', 'about', 'news', 'explore_biodiversity', 
    'contact', 'terms_of_use', 'citing', 'privacy', 'curators' ]
  content_pages =  ContentPage.select(:content_pages => [ :id, :page_name ]).where(["active = ? AND page_name NOT IN (?)", true, names_which_have_routes])
  content_pages.each do |content_page|
    page_url = cms_page_path(content_page.page_name)
    page_url.gsub!(/%20/, '_') # turn %20 into _
    page_url.gsub!(/&/, '&amp;') # turn & into &amp;
    add page_url, changefreq: 'weekly', priority: 1 
  end
  
  #community_page_urls
  communities = Community.select([:id, :updated_at]).where(published: true)
  communities.each do |community|
    add community_path(community.id), priority: 1, lastmod: community.updated_at
    add community_newsfeed_path(community.id), priority: 0.5    
  end
  
  #collection_page_urls
  collections = Collection.select([:id, :updated_at]).where(published: true)
  collections.each do |collection|
    add collection_path(collection.id), priority: 1, lastmod: collection.updated_at if collection.updated_at
    add collection_newsfeed_path(collection.id), priority:0.5
  end
  
  #content_partneer_urls
  content_partners = ContentPartner.where(is_public: 1).select([:id, :updated_at])
  content_partners.each do |content_partner|
    add content_partner_path(content_partner.id), changefreq: 'weekly', priority: 1
  end
  
  #user_urls
  users = User.select([:id, :updated_at]).where("active = ? AND (hidden = 0 OR hidden IS NULL)", true)
  users.each do |user|
    add user_path(user.id),          priority: 1, lastmod: user.updated_at if user.updated_at
    add user_newsfeed_path(user.id), priority: 0.5
    add user_activity_path(user.id), priority: 0.5
  end
  
  #taxon_page_urls
  TaxonConcept.select(:id).where(published: true, supercedure_id: 0, vetted_id: Vetted.trusted.id).find_each do |tc|
    add "/pages/#{tc.id}/overview", priority: 1, changefreq: 'weekly'
  end
end