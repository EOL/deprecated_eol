package org.apache.jsp.admin;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import org.apache.solr.core.SolrInfoMBean;
import org.apache.solr.core.SolrInfoRegistry;
import org.apache.solr.common.util.NamedList;
import java.util.Date;
import java.util.Map;
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

public final class stats_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static final JspFactory _jspxFactory = JspFactory.getDefaultFactory();

  private static java.util.Vector _jspx_dependants;

  static {
    _jspx_dependants = new java.util.Vector(1);
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
      response.setContentType("text/xml; charset=utf-8");
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
      out.write("\n");
      out.write("\n");
      out.write("<?xml-stylesheet type=\"text/xsl\" href=\"stats.xsl\"?>\n");
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
      out.write("\n");
      out.write("\n");
      out.write("<solr>\n");
      out.write("  ");
  
  if (core.getName() != null) { 
      out.write(" \n");
      out.write("\t  <core>");
      out.print(core.getName());
      out.write("</core> \n");
      out.write("  ");
 } 
      out.write("\n");
      out.write("  <schema>");
      out.print( collectionName );
      out.write("</schema>\n");
      out.write("  <host>");
      out.print( hostname );
      out.write("</host>\n");
      out.write("  <now>");
      out.print( new Date().toString() );
      out.write("</now>\n");
      out.write("  <start>");
      out.print( new Date(core.getStartTime()) );
      out.write("</start>\n");
      out.write("  <solr-info>\n");

for (SolrInfoMBean.Category cat : SolrInfoMBean.Category.values()) {

      out.write("\n");
      out.write("    <");
      out.print( cat.toString() );
      out.write('>');
      out.write('\n');

 Map<String,SolrInfoMBean> reg = core.getInfoRegistry();
 synchronized(reg) {
  for (Map.Entry<String,SolrInfoMBean> entry : reg.entrySet()) {
    String key = entry.getKey();
    SolrInfoMBean m = entry.getValue();

    if (m.getCategory() != cat) continue;

    NamedList nl = m.getStatistics();
    if ((nl != null) && (nl.size() != 0)) {
      String na     = "None Provided";
      String name   = (m.getName()!=null ? m.getName() : na);
      String vers   = (m.getVersion()!=null ? m.getVersion() : na);
      String desc   = (m.getDescription()!=null ? m.getDescription() : na);

      out.write("\n");
      out.write("    <entry>\n");
      out.write("      <name>\n");
      out.write("        ");
      out.print( key );
      out.write("\n");
      out.write("      </name>\n");
      out.write("      <class>\n");
      out.write("        ");
      out.print( name );
      out.write("\n");
      out.write("      </class>\n");
      out.write("      <version>\n");
      out.write("        ");
      out.print( vers );
      out.write("\n");
      out.write("      </version>\n");
      out.write("      <description>\n");
      out.write("        ");
      out.print( desc );
      out.write("\n");
      out.write("      </description>\n");
      out.write("      <stats>\n");

      for (int i = 0; i < nl.size() ; i++) {

      out.write("\n");
      out.write("        <stat name=\"");
      out.print( nl.getName(i) );
      out.write("\" >\n");
      out.write("          ");
      out.print( nl.getVal(i).toString() );
      out.write("\n");
      out.write("        </stat>\n");

      }

      out.write("\n");
      out.write("      </stats>\n");
      out.write("    </entry>\n");

    }

      out.write('\n');

  }
 }

      out.write("\n");
      out.write("    </");
      out.print( cat.toString() );
      out.write('>');
      out.write('\n');

}

      out.write("\n");
      out.write("  </solr-info>\n");
      out.write("</solr>\n");
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
