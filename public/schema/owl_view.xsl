<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:owl="http://www.w3.org/2002/07/owl#" version="1.0">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>
  <xsl:template match="rdf:RDF">
    <html>
      <body>
        <xsl:apply-templates select="owl:Ontology"/>
        <xsl:apply-templates select="owl:Class"/>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="owl:Ontology">
    <h2>Ontology: <xsl:value-of select="rdfs:label"/></h2>
    <xsl:if test="dc:title">
      title: <xsl:value-of select="dc:title"/><br/>
    </xsl:if>
    <xsl:if test="rdfs:comment">
      Comment: <xsl:value-of select="rdfs:comment"/><br/>
    </xsl:if>
    <br/><br/>
  </xsl:template>
  <xsl:template match="owl:Class">
    <xsl:variable name="currentClass">
      <xsl:value-of select="concat('http://www.eol.org/schema/transfer#', @rdf:ID)"/>
    </xsl:variable>
    <a>
      <xsl:attribute name="name">
        <xsl:value-of select="@rdf:ID"/>
      </xsl:attribute>
    </a>
    <h3>Class: <xsl:value-of select="@rdf:ID"/></h3>
    <xsl:if test="count(//rdf:RDF/owl:*[rdfs:domain/@rdf:resource = $currentClass]) &gt; 0">
      <blockquote>
        <xsl:apply-templates select="//rdf:RDF/owl:*[rdfs:domain/@rdf:resource = $currentClass]"/>
      </blockquote>
    </xsl:if>
    <xsl:if test="dc:description">
      Description: <xsl:value-of select="dc:description"/><br/>
    </xsl:if>
    <hr/>
  </xsl:template>
  <xsl:template match="owl:ObjectProperty">
    <a>
      <xsl:attribute name="name">
        <xsl:value-of select="@rdf:ID"/>
      </xsl:attribute>
    </a>
    <b>Property: <xsl:value-of select="@rdf:ID"/></b><br/>
    <xsl:if test="rdfs:range/@rdf:resource">
      Range: <xsl:value-of select="rdfs:range/@rdf:resource"/><br/>
    </xsl:if>
    <xsl:if test="rdfs:comment">
      Comment: <xsl:value-of select="rdfs:comment"/><br/>
    </xsl:if>
    <xsl:if test="owl:equivalentProperty/@rdf:resource">
      Equivalent To: <xsl:value-of select="owl:equivalentProperty/@rdf:resource"/><br/>
    </xsl:if>
    <xsl:if test="rdfs:subPropertyOf/@rdf:resource">
      Sub-Property Of: <xsl:value-of select="rdfs:subPropertyOf/@rdf:resource"/><br/>
    </xsl:if>
    <hr/>
  </xsl:template>
</xsl:stylesheet>
