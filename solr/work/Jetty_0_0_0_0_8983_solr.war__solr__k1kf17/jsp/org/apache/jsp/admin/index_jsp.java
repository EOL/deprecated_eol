package org.apache.jsp.admin;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import java.util.Date;
import java.util.List;
import java.util.Collection;
import org.apache.solr.core.SolrConfig;
import org.apache.solr.core.SolrCore;
import org.apache.solr.schema.IndexSchema;
import java.io.File;
import java.net.InetAddress;
import java.io.StringWriter;
import org.apache.solr.core.Config;
import org.apache.solr.common.util.XML;
import org.apache.solr.common.SolrException;
import org.apache.lucene.LucenePackage;
import java.net.UnknownHostException;

public final class index_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static final JspFactory _jspxFactory = JspFactory.getDefaultFactory();

  private static java.util.Vector _jspx_dependants;

  static {
    _jspx_dependants = new java.util.Vector(2);
    _jspx_dependants.add("/admin/header.jsp");
    _jspx_dependants.add("/admin/_info.jsp");
  }

  private org.apache.jasper.runtime.ResourceInjector _jspx_resourceInjector;

  public Object getDependants() {
    return _jspx_dependants;
  }

  public void _jspService(HttpServletRequest request, HttpServletResponse response)
        throws java.io.IOException, ServletException {

    PageContext pageContext = null;
    HttpSession session = null;
    ServletContext application = null;
    ServletConfig config = null;
    JspWriter out = null;
    Object page = this;
    JspWriter _jspx_out = null;
    PageContext _jspx_page_context = null;


    try {
      response.setContentType("text/html; charset=utf-8");
      pageContext = _jspxFactory.getPageContext(this, request, response,
      			null, true, 8192, true);
      _jspx_page_context = pageContext;
      application = pageContext.getServletContext();
      config = pageContext.getServletConfig();
      session = pageContext.getSession();
      out = pageContext.getOut();
      _jspx_out = out;
      _jspx_resourceInjector = (org.apache.jasper.runtime.ResourceInjector) application.getAttribute("com.sun.appserv.jsp.resource.injector");

      out.write('\n');
      out.write('\n');
      out.write('\n');
      out.write('\n');
      out.write('\n');
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write('\n');
      out.write('\n');
      out.write('\n');
      out.write("\n");
      out.write("<html>\n");
      out.write("<head>\n");

request.setCharacterEncoding("UTF-8");

      out.write('\n');
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");

  // 
  SolrCore  core = (SolrCore) request.getAttribute("org.apache.solr.SolrCore");
  if (core == null) {
    response.sendError( 404, "missing core name in path" );
    return;
  }
    
  SolrConfig solrConfig = core.getSolrConfig();
  int port = request.getServerPort();
  IndexSchema schema = core.getSchema();

  // enabled/disabled is purely from the point of a load-balancer
  // and has no effect on local server function.  If there is no healthcheck
  // configured, don't put any status on the admin pages.
  String enabledStatus = null;
  String enabledFile = solrConfig.get("admin/healthcheck/text()",null);
  boolean isEnabled = false;
  if (enabledFile!=null) {
    isEnabled = new File(enabledFile).exists();
  }

  String collectionName = schema!=null ? schema.getName():"unknown";
  InetAddress addr = null;
  String hostname = "unknown";
  try {
    addr = InetAddress.getLocalHost();
    hostname = addr.getCanonicalHostName();
  } catch (UnknownHostException e) {
    //default to unknown
  }

  String defaultSearch = "";
  { 
    StringWriter tmp = new StringWriter();
    XML.escapeCharData
      (solrConfig.get("admin/defaultQuery/text()", null), tmp);
    defaultSearch = tmp.toString();
  }

  String solrImplVersion = "";
  String solrSpecVersion = "";
  String luceneImplVersion = "";
  String luceneSpecVersion = "";

  { 
    Package p;
    StringWriter tmp;

    p = SolrCore.class.getPackage();

    tmp = new StringWriter();
    solrImplVersion = p.getImplementationVersion();
    if (null != solrImplVersion) {
      XML.escapeCharData(solrImplVersion, tmp);
      solrImplVersion = tmp.toString();
    }
    tmp = new StringWriter();
    solrSpecVersion = p.getSpecificationVersion() ;
    if (null != solrSpecVersion) {
      XML.escapeCharData(solrSpecVersion, tmp);
      solrSpecVersion = tmp.toString();
    }
  
    p = LucenePackage.class.getPackage();

    tmp = new StringWriter();
    luceneImplVersion = p.getImplementationVersion();
    if (null != luceneImplVersion) {
      XML.escapeCharData(luceneImplVersion, tmp);
      luceneImplVersion = tmp.toString();
    }
    tmp = new StringWriter();
    luceneSpecVersion = p.getSpecificationVersion() ;
    if (null != luceneSpecVersion) {
      XML.escapeCharData(luceneSpecVersion, tmp);
      luceneSpecVersion = tmp.toString();
    }
  }
  
  String cwd=System.getProperty("user.dir");
  String solrHome= solrConfig.getInstanceDir();

      out.write("\n");
      out.write("<script>\n");
      out.write("var host_name=\"");
      out.print( hostname );
      out.write("\"\n");
      out.write("</script>\n");
      out.write("\n");
      out.write("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n");
      out.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"solr-admin.css\">\n");
      out.write("<link rel=\"icon\" href=\"favicon.ico\" type=\"image/ico\"></link>\n");
      out.write("<link rel=\"shortcut icon\" href=\"favicon.ico\" type=\"image/ico\"></link>\n");
      out.write("<title>Solr admin page</title>\n");
      out.write("</head>\n");
      out.write("\n");
      out.write("<body>\n");
      out.write("<a href=\".\"><img border=\"0\" align=\"right\" height=\"61\" width=\"142\" src=\"solr-head.gif\" alt=\"Solr\"></a>\n");
      out.write("<h1>Solr Admin (");
      out.print( collectionName );
      out.write(')');
      out.write('\n');
      out.print( enabledStatus==null ? "" : (isEnabled ? " - Enabled" : " - Disabled") );
      out.write(" </h1>\n");
      out.write("\n");
      out.print( hostname );
      out.write(':');
      out.print( port );
      out.write("<br/>\n");
      out.write("cwd=");
      out.print( cwd );
      out.write("  SolrHome=");
      out.print( solrHome );
      out.write('\n');
      out.write("\n");
      out.write("\n");
      out.write("<br clear=\"all\">\n");
      out.write("<table>\n");
      out.write("\n");
      out.write("<tr>\n");
      out.write("  <td>\n");
      out.write("\t<h3>Solr</h3>\n");
      out.write("  </td>\n");
      out.write("  <td>\n");
      out.write("    ");
 if (null != core.getSchemaResource()) { 
      out.write("\n");
      out.write("    [<a href=\"file/?file=");
      out.print(core.getSchemaResource());
      out.write("\">Schema</a>]\n");
      out.write("    ");
 }
       if (null != core.getConfigResource()) { 
      out.write("\n");
      out.write("    [<a href=\"file/?file=");
      out.print(core.getConfigResource());
      out.write("\">Config</a>]\n");
      out.write("    ");
 } 
      out.write("\n");
      out.write("    [<a href=\"analysis.jsp?highlight=on\">Analysis</a>]\n");
      out.write("    [<a href=\"schema.jsp\">Schema Browser</a>]\n");
      out.write("    <br>\n");
      out.write("    [<a href=\"stats.jsp\">Statistics</a>]\n");
      out.write("    [<a href=\"registry.jsp\">Info</a>]\n");
      out.write("    [<a href=\"distributiondump.jsp\">Distribution</a>]\n");
      out.write("    [<a href=\"ping\">Ping</a>]\n");
      out.write("    [<a href=\"logging\">Logging</a>]\n");
      out.write("  </td>\n");
      out.write("</tr>\n");
      out.write("\n");
      out.write('\n');
 org.apache.solr.core.CoreContainer cores = (org.apache.solr.core.CoreContainer)request.getAttribute("org.apache.solr.CoreContainer");
  if (cores!=null) {
    Collection<String> names = cores.getCoreNames();
    if (names.size() > 1) {
      out.write("<tr><td><strong>Cores:</strong><br></td><td>");

    for (String name : names) {
    
      out.write("[<a href=\"../../");
      out.print(name);
      out.write("/admin/\">");
      out.print(name);
      out.write("</a>]");
         
  }
      out.write("</td></tr>");

}}
      out.write("\n");
      out.write("\n");
      out.write("<tr>\n");
      out.write("  <td>\n");
      out.write("    <strong>App server:</strong><br>\n");
      out.write("  </td>\n");
      out.write("  <td>\n");
      out.write("    [<a href=\"get-properties.jsp\">Java Properties</a>]\n");
      out.write("    [<a href=\"threaddump.jsp\">Thread Dump</a>]\n");
      out.write("  ");

    if (enabledFile!=null)
    if (isEnabled) {
  
      out.write("\n");
      out.write("  [<a href=\"action.jsp?action=Disable\">Disable</a>]\n");
      out.write("  ");

    } else {
  
      out.write("\n");
      out.write("  [<a href=\"action.jsp?action=Enable\">Enable</a>]\n");
      out.write("  ");

    }
  
      out.write("\n");
      out.write("  </td>\n");
      out.write("</tr>\n");
      out.write("\n");
      out.write("\n");

 // a quick hack to get rid of get-file.jsp -- note this still spits out invalid HTML
 out.write( org.apache.solr.handler.admin.ShowFileRequestHandler.getFileContents( "admin-extra.html" ) );

      out.write("\n");
      out.write("\n");
      out.write("</table><P>\n");
      out.write("\n");
      out.write("\n");
      out.write("<table>\n");
      out.write("<tr>\n");
      out.write("  <td>\n");
      out.write("\t<h3>Make a Query</h3>\n");
      out.write("  </td>\n");
      out.write("  <td>\n");
      out.write("[<a href=\"form.jsp\">Full Interface</a>]\n");
      out.write("  </td>\n");
      out.write("  \n");
      out.write("</tr>\n");
      out.write("<tr>\n");
      out.write("  <td>\n");
      out.write("  Query String:\n");
      out.write("  </td>\n");
      out.write("  <td colspan=2>\n");
      out.write("\t<form name=queryForm method=\"GET\" action=\"../select/\" accept-charset=\"UTF-8\">\n");
      out.write("        <textarea class=\"std\" rows=\"4\" cols=\"40\" name=\"q\">");
      out.print( defaultSearch );
      out.write("</textarea>\n");
      out.write("        <input name=\"version\" type=\"hidden\" value=\"2.2\">\n");
      out.write("\t<input name=\"start\" type=\"hidden\" value=\"0\">\n");
      out.write("\t<input name=\"rows\" type=\"hidden\" value=\"10\">\n");
      out.write("\t<input name=\"indent\" type=\"hidden\" value=\"on\">\n");
      out.write("        <br><input class=\"stdbutton\" type=\"submit\" value=\"search\" \n");
      out.write("        \tonclick=\"if (queryForm.q.value.length==0) { alert('no empty queries, please'); return false; } else { queryForm.submit(); } \">\n");
      out.write("\t</form>\n");
      out.write("  </td>\n");
      out.write("</tr>\n");
      out.write("</table><p>\n");
      out.write("\n");
      out.write("<table>\n");
      out.write("<tr>\n");
      out.write("  <td>\n");
      out.write("\t<h3>Assistance</h3>\n");
      out.write("  </td>\n");
      out.write("  <td>\n");
      out.write("\t[<a href=\"http://lucene.apache.org/solr/\">Documentation</a>]\n");
      out.write("\t[<a href=\"http://issues.apache.org/jira/browse/SOLR\">Issue Tracker</a>]\n");
      out.write("\t[<a href=\"mailto:solr-user@lucene.apache.org\">Send Email</a>]\n");
      out.write("\t<br>\n");
      out.write("        [<a href=\"http://wiki.apache.org/solr/SolrQuerySyntax\">Solr Query Syntax</a>]\n");
      out.write("  </td>\n");
      out.write("</tr>\n");
      out.write("<tr>\n");
      out.write("  <td>\n");
      out.write("  </td>\n");
      out.write("  <td>\n");
      out.write("  Current Time: ");
      out.print( new Date() );
      out.write("\n");
      out.write("  </td>\n");
      out.write("</tr>\n");
      out.write("<tr>\n");
      out.write("  <td>\n");
      out.write("  </td>\n");
      out.write("  <td>\n");
      out.write("  Server Start At: ");
      out.print( new Date(core.getStartTime()) );
      out.write("\n");
      out.write("  </td>\n");
      out.write("</tr>\n");
      out.write("</table>\n");
      out.write("</body>\n");
      out.write("</html>\n");
    } catch (Throwable t) {
      if (!(t instanceof SkipPageException)){
        out = _jspx_out;
        if (out != null && out.getBufferSize() != 0)
          out.clearBuffer();
        if (_jspx_page_context != null) _jspx_page_context.handlePageException(t);
      }
    } finally {
      _jspxFactory.releasePageContext(_jspx_page_context);
    }
  }
}
