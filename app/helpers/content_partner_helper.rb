module ContentPartnerHelper
  def content_partner_check_box_image(checked, params = {})
    image_tag(checked ? "/images/checked.png" : "/images/not-checked.png", { :style => "vertical-align: bottom" }.merge(params))
  end
  
  def content_partner_completed_step(agent, method, title)
    unless agent.content_partner.nil? 
       completed = agent.content_partner.send("#{method}?") 
       completed_date = agent.content_partner.send("#{method}")
    else
       completed=false
    end
    returning "" do |string|
        string << content_partner_check_box_image(completed)
        if completed
          string << " #{title} <strong>#{completed_date.strftime("%m.%d.%y")}</strong>"
        else
          string << " #{title}"
        end
        
        string << "<br />"
     end
  end
  
  def content_partner_date(date)
    date.respond_to?(:strftime) ? date.strftime("%m.%d.%y") : nil
  end
end
