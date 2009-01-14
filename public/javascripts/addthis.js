var  addthis_url   = '';
var  addthis_title = '';

function addthis_click(obj, str){

 var aturl  = 'http://www.addthis.com/bookmark.php';
 aturl += '?v=10';
 aturl += '&pub='+addthis_pub;
 aturl += '&url='+encodeURIComponent(addthis_url);
 aturl += '&title='+encodeURIComponent(addthis_title);

 window.open(aturl,'addthis','scrollbars=yes,menubar=no,width=620,height=520,resizable=yes,toolbar=no,location=no,status=no,screenX=200,screenY=100,left=200,top=100');


 return false;
}
