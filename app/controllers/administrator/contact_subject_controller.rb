class Administrator::ContactSubjectController < AdminController

  access_control :DEFAULT => 'Administrator - Site CMS'
  
 def index
   
   @page_title = 'Contact Us Topics'
   @contact_subjects=ContactSubject.find(:all,:order=>'title')
   
 end
 
 def edit
 
   @page_title = 'Edit Contact Us Topic'
   @contact_subject=ContactSubject.find(params[:id])
   
 end
 
 def new
     
   @page_title = 'New Contact Us Topic'
   @contact_subject=ContactSubject.new
     
 end
 
 def create
  
   @contact_subject=ContactSubject.new(params[:contact_subject])
   if @contact_subject.save
     flash[:notice]="The new topic was created."
     redirect_to :action=>'index'
   else
     render :action=>'new'
   end
   
 end
 
 def update
   
   @contact_subject=ContactSubject.find(params[:id])
   if @contact_subject.update_attributes(params[:contact_subject])
      flash[:notice]="The topic was updated."     
      redirect_to :action=>'index' 
   else
      render :action=>'edit'
  end
  
 end

end
