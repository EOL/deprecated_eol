function object_eol_nav(myXML)
{
   document.write('<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,45,0" width="270" height="360" id="eol_nav" align="middle">\n');
   document.write('<param name="allowScriptAccess" value="always" />\n');
   document.write('<param name="movie" value="/eol_subnav.swf?myfilename=');
   document.write(myXML);
   document.write('"/>\n');
   document.write('<param name="quality" value="high" />\n');
	 document.write('<param name="wmode" value="transparent" />\n');
	 document.write('<param name="bgcolor" value="#ffffff" />\n');
   document.write('<embed src="/eol_subnav.swf?myfilename=');
   document.write(myXML);
   document.write('" quality="high" wmode="transparent" bgcolor="#c7e2ff" width="270" height="360"" name="eol_nav" align="middle" allowScriptAccess="always" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />\n');
   document.write('</object>\n');
}
function object_eol_nav2(myHTMLPath, myXMLpath, myXML)
{
   document.write('<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,45,0" width="270" height="360" id="eol_nav" align="middle">\n');
   document.write('<param name="allowScriptAccess" value="always" />\n');
   document.write('<param name="movie" value="/eol_subnav.swf?htmlpath=');
   document.write(myHTMLPath);
   document.write('&myxmlpath=');
   document.write(myXMLpath);
   document.write('&myfilename=');
   document.write(myXML);
   document.write('"/>\n');
   document.write('<param name="quality" value="high" />\n');
	 document.write('<param name="wmode" value="transparent" />\n');
	 document.write('<param name="bgcolor" value="#ffffff" />\n');
   document.write('<embed src="/eol_subnav.swf?htmlpath=');
   document.write(myHTMLPath);
   document.write('&myxmlpath=');
   document.write(myXMLpath);
   document.write('&myfilename=');
   document.write(myXML);
   document.write('" quality="high" wmode="transparent" bgcolor="#c7e2ff" width="270" height="360" name="eol_nav" align="middle" allowScriptAccess="always" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />\n');
   document.write('</object>\n');
}
