namespace :content_partners do
  desc 'Redo agreements'
  task :agreements => :environment do
    class Helper
      include Singleton
      include TaxaHelper
      include ApplicationHelper
      include ActionView::Helpers::SanitizeHelper
    end
    require 'erb'
    
    ContentPartner.find(:all, :include => [ :content_partner_agreements, :content_partner_contacts ]).each do |cp|
      cp.content_partner_agreements.each do |a|
        a.template.gsub!(/@agent.project_description/, '@content_partner.description')
        a.template.gsub!(/@agent.project_name/, '@content_partner.full_name')
        a.template.gsub!(/@primary_contact/, '@content_partner.primary_contact')
        a.template.gsub!(/format_date_time/, 'Helper.instance.format_date_time')
        a.template.gsub!(/mail_to/, 'Helper.instance.mail_to')
        
        @content_partner = cp
        @agreement = a
        template = ERB.new(a.template)
        new_agreement_body = template.result(binding)
        unless new_agreement_body.blank?
          a.body = new_agreement_body
          a.save!
        end
      end
    end
    true
  end
  
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
