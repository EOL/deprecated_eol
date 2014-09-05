namespace :content_partners do
  desc 'Agreement-embedded ERB'
  task :agreement_erb => :environment do
    ContentPartner.find(:all, :include => :content_partner_agreements).each do |cp|
      cp.content_partner_agreements.each do |a|
        matches = a.template.scan(/<%=(.*?)%>/)
        unless matches.blank?
          matches.each{ |m| puts m}
        end
      end
    end
    true
  end
end
