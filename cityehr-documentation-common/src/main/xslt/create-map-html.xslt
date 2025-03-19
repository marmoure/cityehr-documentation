<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:hcom="http://cityehr/html/common"
  xmlns:com="http://cityehr/common"
  exclude-result-prefixes="xs hcom com"
  version="2.0">
  
  <!--
    Generates a simple HTML website from an LwDITA 'map'.
    Author: Adam Retter
  -->
  
  <xsl:import href="common.xslt"/>
  <xsl:import href="common-html.xslt"/>
  <xsl:import href="create-topic-html.xslt"/>
  
  <xsl:output method="html" version="5.0" encoding="UTF-8" indent="yes"/>

  <!-- PARAMETER - the version number of the generated document -->
  <xsl:param name="version" required="yes" as="xs:string"/>

  <!-- PARAMETER - the revision date and time of the generated document -->
  <xsl:param name="revision" required="no" as="xs:dateTime" select="current-dateTime()"/>
  
  <!-- PARAMETER - the path to the folder where you want to output the Topic HTML files -->
  <xsl:param name="output-folder" as="xs:string" select="com:parent-path(com:document-uri(/map))"/>
  
  <!-- PARAMETER - specifying a PDF file version of this to present a download link for -->
  <xsl:param name="download-pdf-filename" as="xs:string?"/>
  
  <xsl:variable name="authors" as="xs:string+" select="('John Chelsom', 'Stephanie Cabrera', 'Catriona Hopper', 'Jennifer Ramirez')"/>

  <!-- NOTE(AR) used for building the top-nav and bottom-nav -->
  <xsl:variable name="map-uri" as="xs:string" select="com:document-uri(/map)"/>
  <xsl:variable name="topicrefs" as="element(topicref)+" select="doc($map-uri)/map/topicref"/>

  <xsl:template match="map">
    <html xmlns:cc="http://creativecommons.org/ns#" xmlns:dct="http://purl.org/dc/terms/">
      <head>
        <xsl:call-template name="hcom:meta">
          <xsl:with-param name="authors" select="$authors"/>
          <xsl:with-param name="version" select="$version"/>
          <xsl:with-param name="created-dateTime" select="$revision"/>
          <xsl:with-param name="modified-dateTime" select="$revision"/>
        </xsl:call-template>
        <xsl:call-template name="hcom:style"/>
        <style>
          .toc-entry-level-1 {
            margin-top: 1em;
          }
        </style>
      </head>
      <body about="">
        <div id="cover-page">
          <div id="cover-page-logo">
            <img src="images/cityehr-logo.png"/>
          </div>
          <xsl:apply-templates select="topicmeta" mode="cover-page"/>
        </div>
        <article typeof="cc:Work">
          <time datetime="{$revision}" pubdate="pubdate"></time>
          <xsl:apply-templates select="topicmeta" mode="body"/>
          <xsl:if test="exists($download-pdf-filename)">
            <div id="download-pdf-version"><a href="{$download-pdf-filename}">Download PDF version</a></div>
          </xsl:if>
          <xsl:apply-templates select="." mode="toc"/>
        </article>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="topicmeta" mode="metadata body">
    <xsl:apply-templates select="navtitle" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="topicmeta" mode="cover-page">
    <div id="version" style="font-size: 9pt;">
      <p><b>Version:</b> <xsl:value-of select="$version"/></p>
      <p><b>Revision:</b> <xsl:value-of select="hcom:simple-date-utc-from-dateTime($revision)"/></p>
    </div>
    <div id="license" style="display: flex; align-items: center; justify-content: left">
      <div id="license-image" style="max-width: 100%; max-height:100%;">
        <a rel="license" href="{othermeta[@name eq 'dcterms:license'][2]/@content}"><img src="images/by-nc-sa.png" width="30%"/></a>
      </div>
      <div id="license-text" style="padding-left: 8pt; font-size: 8pt;">
        <p><a property="cc:attributionName" rel="cc:attributionURL" href="{othermeta[@name eq 'dcterms:rightsHolder']/@content}"><xsl:value-of select="othermeta[@name eq 'dcterms:rights']/@content"/></a></p>
        <p><a rel="license" href="{othermeta[@name eq 'dcterms:license'][2]/@content}"><xsl:value-of select="othermeta[@name eq 'dcterms:license'][1]/@content"/></a></p>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="navtitle" mode="metadata">
    <title><xsl:value-of select="."/></title>
  </xsl:template>
  
  <xsl:template match="navtitle" mode="body">
    <h1 property="dct:title"><xsl:value-of select="."/></h1>
  </xsl:template>
  
  <!-- Create a new HTML file for each topic that is referenced -->
  <xsl:template match="topicref" mode="create-topic-html">
    <xsl:result-document href="file://{$output-folder}/{hcom:dita-filename-to-html(@href)}">
      <xsl:apply-templates select="doc(com:abs-uri(., @href))/topic"/>
    </xsl:result-document>
  </xsl:template>
  
  <!-- TOC (Table of Contents) -->
  <xsl:template match="map" mode="toc">
    <section>
      <h2>Table of Contents</h2>
      <xsl:apply-templates select="topicref" mode="create-topic-html"/>
      <xsl:call-template name="hcom:toc">
        <xsl:with-param name="sections" select="topicref"/>
      </xsl:call-template>
    </section>
  </xsl:template>

  <!-- OVERRIDE this template from create-topic-html.xsd so that we can add previous and following links -->
  <xsl:template match="topic" mode="top-nav bottom-nav">
    <xsl:variable name="this-topicref-href" as="xs:string" select="com:filename(com:document-uri(.))"/>
    <xsl:variable name="this-topicref" as="element(topicref)?" select="$topicrefs[@href eq $this-topicref-href]"/>
    <xsl:variable name="preceding-topicref" as="element(topicref)?" select="$this-topicref/preceding-sibling::topicref[1]"/>
    <xsl:variable name="following-topicref" as="element(topicref)?" select="$this-topicref/following-sibling::topicref[1]"/>
    <div id="contents-link"><b>[ </b><xsl:if test="exists($preceding-topicref)"><i>&lt;&lt; </i><a href="{hcom:dita-filename-to-html($preceding-topicref/@href)}"><xsl:value-of select="com:get-topic-title(., $preceding-topicref)"/></a><b> | </b></xsl:if><a href="index.html">Contents</a><xsl:if test="exists($following-topicref)"><b> | </b><a href="{hcom:dita-filename-to-html($following-topicref/@href)}"><xsl:value-of select="com:get-topic-title(., $following-topicref)"/></a><i> &gt;&gt; </i></xsl:if><b> ]</b></div>
  </xsl:template>
  
</xsl:stylesheet>