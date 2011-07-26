$(document).ready(function()
{
  $('a.editx').die();
  $('a.editx').live('click', function()
  {
    id = $(this).attr('data_object_id');
    $("#div_" + id).text("...PLEASE WAIT...");
    path_url = $(this).attr('path_url');
    $.ajax({  type: 'GET', url: path_url, async: true, dataType: "html",
              success:function(response)
              {
                $("#div_" + id).html(response);
              },
              error:function (xhr, ajaxOptions, thrownError){ $("#div_" + id).text("--SORRY AN ERROR HAS OCCURRED--"); }
           });
   });

   $('a.addx').die();
   $('a.addx').live('click', function()
   {
      //Cannot open 2 add-record forms
      if ( $('#div_new_user_submitted_text_id').length ){ alert("Cannot open multiple add-forms."); return; }

      id = $(this).attr('data_object_id');
      if ( !$('#' + id).length ){ id = "new_user_submitted_text_id"; }
      
      $("#div_" + id).text("...PLEASE WAIT...");
      path_url = $(this).attr('path_url');
      $.ajax({ type:'GET',
               url:path_url,
               async: true,
               dataType: "html",
               success:function(response)
               {
                  $("#div_" + id).html(response);
                  $("#div_" + id).attr("id", "div_new_user_submitted_text_id");
               },
               error:function (xhr, ajaxOptions, thrownError){ $("#div_" + id).text("--SORRY AN ERROR HAS OCCURRED--"); }
             });
   });

});
