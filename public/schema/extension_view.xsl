<?xml version="1.0" encoding="UTF-8"?>
<!-- borrowed from rs.gbif.org/style/human.xsl -->
<xsl:stylesheet version="1.0" 
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
     xmlns:dc="http://purl.org/dc/terms/" 
     xmlns:dwc="http://purl.org/dc/terms/" 
     xmlns:ext="http://rs.gbif.org/extension/"
     xmlns:voc="http://rs.gbif.org/thesaurus/"
     xmlns="http://www.w3.org/1999/xhtml">
     
     
     <xsl:output method="html" encoding="UTF-8" indent="yes"/>
     <xsl:template match="/*">
          <xsl:variable name="defType">
               <xsl:choose>
                    <xsl:when test="/ext:extension">Extension</xsl:when>
                    <xsl:otherwise>Vocabulary</xsl:otherwise>
               </xsl:choose>
          </xsl:variable>
          <html>
               <head>
                    <title><xsl:value-of select="@dc:title"/> - <xsl:value-of select="$defType"/></title>
                    <link rel="stylesheet" type="text/css" href="extension_view.css"/>
               </head>
               <body>
                    <div class="container">
                         <div id="header" class="box">
                              <h1><xsl:value-of select="@dc:title"/></h1>
                         </div>
                         
                         <div id="content">
                              <table class="nice">
                                   <tr>
                                        <th>Title</th><td><xsl:value-of select="@dc:title"/></td>
                                   </tr>
                                   <xsl:if test="@name">
                                        <tr>
                                             <th>Name</th><td><xsl:value-of select="@name"/></td>
                                        </tr>
                                   </xsl:if>
                                   <xsl:if test="@namespace">
                                        <tr>
                                             <th>Namespace</th><td><xsl:value-of select="@namespace"/></td>
                                        </tr>
                                   </xsl:if>
                                   <xsl:if test="@dc:URI">
                                        <tr>
                                             <th>URI</th><td><xsl:value-of select="@dc:URI"/></td>
                                        </tr>
                                   </xsl:if>
                                   <xsl:if test="@rowType">
                                        <tr>
                                             <th>RowType</th><td><xsl:value-of select="@rowType"/></td>
                                        </tr>
                                   </xsl:if>
                                   <xsl:if test="@dc:description">
                                        <tr>
                                             <th>Description</th><td><xsl:value-of select="@dc:description"/></td>
                                        </tr>
                                   </xsl:if>
                                   <xsl:if test="@dc:subject">
                                        <tr>
                                             <th>Keywords</th><td><xsl:value-of select="@dc:subject"/></td>
                                        </tr>
                                   </xsl:if>
                                   <xsl:if test="@dc:relation">
                                        <tr>
                                             <th>Link</th>
                                             <td>
                                                  <a>
                                                       <xsl:attribute name="href">
                                                            <xsl:value-of select="@dc:relation"/>
                                                       </xsl:attribute>
                                                       <xsl:value-of select="@dc:relation"/>
                                                  </a>
                                             </td>
                                        </tr>
                                   </xsl:if>
                              </table>
                              <p>(This is an HTML view of the definition. Use View-Source to see the underlying XML.) </p>
                              
                              
                              <xsl:choose>
                                   <xsl:when test="/ext:extension">
                                        <h2>Properties</h2>
                                        <table class="definition">
                                             <xsl:apply-templates mode="table-row" select="//ext:extension/ext:property">
                                                  <xsl:sort select="@group"/>
                                             </xsl:apply-templates>
                                        </table>
                                   </xsl:when>
                                   <xsl:otherwise>
                                        <h2>Concepts</h2>
                                        <table class="definition">
                                             <xsl:apply-templates mode="table-row" select="//voc:thesaurus/voc:concept">
                                                  <xsl:sort select="@identifier"/>
                                             </xsl:apply-templates>
                                        </table>
                                   </xsl:otherwise>
                              </xsl:choose>
                         </div>
                    </div>
               </body>
          </html>          
     </xsl:template>
     
     <xsl:template mode="table-row" match="ext:property">
          <a>
               <xsl:attribute name="name">
                    <xsl:value-of select="@name"/>
               </xsl:attribute>
          </a>
          <tr>
               <th><xsl:value-of select="@name"/></th>
               <td>
                    <div class="description">
                         <xsl:value-of select="@dc:description"/>
                         <xsl:if test="@dc:relation != ''">
                              see also 
                              <a>
                                   <xsl:attribute name="href">
                                        <xsl:value-of select="@dc:relation"/>
                                   </xsl:attribute>
                                   <xsl:value-of select="@dc:relation"/>
                              </a>
                         </xsl:if>
                    </div>
                    <xsl:if test="@examples != ''">
                         <div class="examples">
                              <em>Examples</em>: 
                              <xsl:value-of select="@examples"/>
                         </div>
                    </xsl:if>
                    <div class="technical">
                         <table>
                              <tr><th>Qualname</th><td><xsl:value-of select="@qualName"/></td></tr>
                              <tr><th>Namespace</th><td><xsl:value-of select="@namespace"/></td></tr>
                              <tr><th>Group</th><td><xsl:value-of select="@group"/></td></tr>
                              <tr><th>Data Type</th><td>
							<xsl:choose>
                                   <xsl:when test="@thesaurus != ''">
		                              Vocabulary:
		                              <a>
		                                   <xsl:attribute name="href">
		                                        <xsl:value-of select="@thesaurus"/>
		                                   </xsl:attribute>
		                                   <xsl:value-of select="@thesaurus"/>
		                              </a>
                                   </xsl:when>
                                   <xsl:otherwise>
									<xsl:value-of select="@type"/>
                                   </xsl:otherwise>
							</xsl:choose>
							  </td></tr>
                              <tr><th>Required</th><td><xsl:value-of select="@required"/></td></tr>
                         </table>
                    </div>
               </td>
          </tr>
     </xsl:template>
     
     <xsl:template mode="table-row" match="voc:concept">
          <a>
               <xsl:attribute name="name">
                    <xsl:value-of select="@dc:identifier"/>
               </xsl:attribute>
          </a>
          <tr>
               <th><xsl:value-of select="@dc:identifier"/></th>
               <td>
                    <div class="description">
                         <xsl:value-of select="@dc:description"/>
                         <xsl:if test="@dc:relation != ''">
                              <br/>See also 
                              <a>
                                   <xsl:attribute name="href">
                                        <xsl:value-of select="@dc:relation"/>
                                   </xsl:attribute>
                                   <xsl:value-of select="@dc:relation"/>
                              </a>
                         </xsl:if>
                    </div>
                    <div class="preferred">
	                    <ul>
	                         <xsl:apply-templates select="voc:preferred/voc:term">
	                         </xsl:apply-templates>
	                    </ul>
                    </div>
                    <div class="technical">
                         <table>
                              <tr><th>Code</th><td><xsl:value-of select="@dc:identifier"/></td></tr>
                              <tr><th>URI</th><td><xsl:value-of select="@dc:URI"/></td></tr>
                              <tr><th>Issued</th><td><xsl:value-of select="@dc:issued"/></td></tr>
					          <tr>
					               <th>Alternative Terms</th>
					               <td>
					                    <ul>
					                         <xsl:apply-templates select="voc:alternative/voc:term">
					                         </xsl:apply-templates>
					                    </ul>
					               </td>
					          </tr>
                         </table>
                    </div>
               </td>
          </tr>
     </xsl:template>

     <xsl:template match="voc:term">
          <li>
               <xsl:value-of select="@dc:title"/> 
               <span class="smaller">
                    [lang=<xsl:value-of select="@xml:lang"/>, source=<xsl:value-of select="@dc:source"/>]
               </span>
          </li>
     </xsl:template>
     
</xsl:stylesheet>
