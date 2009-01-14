class Administrator::ContactSubjectController < AdminController

  access_control :DEFAULT => 'Administrator - Site CMS'
  
 def index
   
   @contact_subjects=ContactSubject.find(:all,:order=>'title')
   
 end
 
 def edit
 
   @contact_subject=ContactSubject.find(params[:id])
   
 end
 
 def new
     
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
