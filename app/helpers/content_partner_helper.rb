module ContentPartnerHelper
  
  def content_partner_step_navigation(options = {})
    raise ArgumentError unless options[:page_header]  
    render :partial => 'content_partner/step_navigation', :locals => { :page_header => options[:page_header] }
  end

  def content_partner_submit_buttons(options = {})    
    raise ArgumentError unless options[:id]
    returning "" do |string|
      string << content_tag(:button, 'Back to Dashboard', :onclick => "window.location.href='#{url_for({ :action => 'index' })}'")
      string << content_tag(:button, 'Save', :onclick => "$('save_type').value='save';$('#{options[:id]}').submit();")
      string << content_tag(:button, 'Save &amp; Continue &#187;', :onclick => "$('save_type').value='next';$('#{options[:id]}').submit();")
    end
  end
  
  def content_partner_save_type_hidden_field
    %{<input id="save_type" type="hidden" name="save_type" value="next" />}
  end
  
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
