require 'csv'
class Administrator::ContactController < AdminController

  access_control :DEFAULT => 'Administrator - Contact Us Submissions'

  def index
   
   @subjects=ContactSubject.find(:all,:order=>'title')
   @contact_subject_id=params[:id]
   @comment_search_string=params[:comment_search_string] || ''
   search_string_parameter='%' + @comment_search_string + '%'
   @all_contacts_count=Contact.count(:conditions=>['comments like ?',search_string_parameter])
   if @contact_subject_id.nil? == false && @contact_subject_id != '*'
     @subject=ContactSubject.find(@contact_subject_id).title
     @contacts=Contact.paginate_by_contact_subject_id(@contact_subject_id,:conditions=>['comments like ?',search_string_parameter],:order=>'created_at desc',:page => params[:page])
     @contacts_count=Contact.count(:conditions=>['contact_subject_id=? and comments like ?',@contact_subject_id,search_string_parameter])
   elsif @contact_subject_id == '*'
     @subject="all topics" 
     @contacts=Contact.paginate(:conditions=>['comments like ?',search_string_parameter],:order=>'created_at desc,contact_subject_id asc',:page => params[:page])
     @contacts_count=@all_contacts_count
   end
   
 end
 
 def export
   
     @contacts=Contact.find(:all,:include=>:contact_subject)
     report = StringIO.new
     CSV::Writer.generate(report, ',') do |title|
         title << ['Id', 'Topic', 'Name', 'Email', 'Comments','Taxon Group','Date','Referred Page','User ID']
         @contacts.each do |c|
           title << [c.id,c.contact_subject.title,c.name,c.email,c.comments,c.taxon_group,c.created_at.strftime("%m/%d/%y - %I:%M %p %Z"),c.referred_page,c.user_id]       
         end
      end
      report.rewind
      send_data(report.read,:type=>'text/csv; charset=iso-8859-1; header=present',:filename => 'EOL_contact_us_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv', :disposition =>'attachment', :encoding => 'utf8')
  
 end

end
