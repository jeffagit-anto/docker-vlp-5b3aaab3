<?xml version="1.0" encoding="UTF-8"?>

<!--
  Stylesheet for the XML-essays of the VLP.
  (c) First Version 2008 by Hartmut Kern 
  (c) 2008 by Robert Casties
-->


<xsl:stylesheet	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:fo="http://www.w3.org/1999/XSL/Format"
				version="1.0">

  <xsl:output encoding="UTF-8" method="xml" version="1.0" indent="yes"/>

  <!--********************************************************-->
  <!-- A callable template which generates the page masters.  -->
  <!--********************************************************-->
  <xsl:template name="doPageMasters">
    <fo:layout-master-set>
      
      <fo:simple-page-master master-name="main"  margin-left="72pt" margin-right="72pt" margin="18pt">
	<fo:region-body	margin-top="36pt" margin-bottom="36pt"/>
	<fo:region-before region-name="before" extent="36pt" />
	<fo:region-after region-name="after" extent="36pt" />
      </fo:simple-page-master>
      
    </fo:layout-master-set>
  </xsl:template>


<!--********************************************************-->
<!-- Some simple, html type styling tags.                   -->
<!--********************************************************-->
	<xsl:template match="h3">
		<fo:block font-size="18pt" space-before="8pt" space-end="-3pt" font-family="sans-serif">
			<xsl:apply-templates />
		</fo:block>
	</xsl:template>

	<xsl:template match="h2">
		<fo:block font-size="14pt" space-before="6pt" space-end="-3pt">
			<xsl:apply-templates />
		</fo:block>
	</xsl:template>

	<xsl:template match="b">
		<fo:inline font-weight="bold">
			<xsl:apply-templates />
		</fo:inline>
	</xsl:template>

	<xsl:template match="i">
		<fo:inline font-style="italic">
			<xsl:apply-templates />
		</fo:inline>
	</xsl:template>


	<xsl:template match="p">
          <xsl:if test="not(.//link[@class='essayBacklink'])">
		<fo:block space-before="6pt">
			<xsl:apply-templates />
		</fo:block>
          </xsl:if>
	</xsl:template>
	
	<xsl:template match="img">
	<fo:block border="1pt solid black" space-after="14pt" space-before="14pt">
		<fo:external-graphic content-height="100%" content-width="100%">
		 <xsl:attribute name="src">
				<xsl:value-of select="@src" />
		 </xsl:attribute>
		</fo:external-graphic>
	</fo:block>
	</xsl:template>

	<xsl:template match="li">
		<fo:block space-before="6pt">
			<xsl:apply-templates />
		</fo:block>
	</xsl:template>

	<xsl:template match="table">
	<fo:table table-layout="auto" width="100%">
	  <fo:table-column column-number="1" column-width="100%"/>
	   <!-- <fo:table-column column-number="2" column-width="135mm"/> -->
	  <!-- <fo:table-column column-number="3" column-width="25mm"/> -->
	  <fo:table-body>

	 <fo:table-row text-align="center">
	      <fo:table-cell text-align="center" display-align="center">
	        <fo:block>
			<xsl:apply-templates />
	        </fo:block>
	      </fo:table-cell>
	    </fo:table-row>
	  </fo:table-body>
	</fo:table>
	</xsl:template>


	<xsl:template match="div">
	        <fo:block text-align="center" display-align="center">
			<xsl:apply-templates />
	        </fo:block>
	</xsl:template>

        <!-- link element -->
        <xsl:template match="link">
          <xsl:choose>
          <xsl:when test="not(./img)">
          <fo:inline>
            <fo:basic-link>
              <xsl:attribute name="external-destination">
                http://vlp.mpiwg-berlin.mpg.de/references?id=<xsl:value-of select="@ref"/>
              </xsl:attribute>
              <xsl:value-of select="."/>
            </fo:basic-link>
          </fo:inline>
          </xsl:when>
          <xsl:when test="./img">
          <fo:block>
            <fo:basic-link>
              <xsl:attribute name="external-destination">
                http://vlp.mpiwg-berlin.mpg.de/references?id=<xsl:value-of select="@ref"/>
              </xsl:attribute>
              <xsl:apply-templates/>
            </fo:basic-link>
          </fo:block>
          </xsl:when>
          </xsl:choose>
        </xsl:template>

        <!-- ordinary "a" link -->
        <xsl:template match="a">
          <fo:inline>
            <fo:basic-link>
              <xsl:if test="@href">
                <xsl:attribute name="external-destination">
                  <xsl:value-of select="@href"/>
        	    </xsl:attribute>
        	  </xsl:if>
        	  <xsl:if test="not(@href)">
                <xsl:attribute name="external-destination">#</xsl:attribute>
        	  </xsl:if>
              <xsl:value-of select="."/>
            </fo:basic-link>
          </fo:inline>
        </xsl:template>

<!--********************************************************-->
<!-- Process a Chapter/page.                                     -->
<!--********************************************************-->
	<xsl:template match="page">
		<fo:block break-before="page" space-before="6pt" space-after="4pt">
			<fo:marker marker-class-name="ChapTitle"><xsl:value-of select="@title" /></fo:marker>
			<xsl:apply-templates />
		</fo:block>
	</xsl:template>


<!--********************************************************-->
<!-- Process all of the chapters in the document.           -->
<!--********************************************************-->
	<xsl:template name="doChapters">
		<fo:page-sequence master-reference="main">

			<!-- Page Heading -->
			<fo:static-content flow-name="before">
				<fo:block text-align-last="justify" space-after="6pt" font-size="10pt">
					<fo:wrapper>
						<fo:retrieve-marker retrieve-class-name="ChapTitle"/>
					</fo:wrapper>
					<fo:leader />
					Page <fo:page-number/> of <fo:page-number-citation ref-id="lastPageId" />
				</fo:block>

				<fo:block line-height="2pt" text-align-last="justify">
					<fo:leader leader-pattern="rule" />
				</fo:block>

			</fo:static-content>


			<!-- Page Footer -->
			<fo:static-content flow-name="after">
				<fo:block text-align-last="justify" >
					<fo:leader leader-pattern="rule" alignment-adjust="central" />
					<fo:page-number space-start="8pt" space-end="8pt"/>
					<fo:leader leader-pattern="rule" alignment-adjust="central" />
				</fo:block>

			</fo:static-content>



			<!-- The main flow... -->
			<fo:flow flow-name="xsl-region-body" font-family="serif">

				<!-- Process the Chapters... -->
				<xsl:apply-templates />

				<!-- identify the 'last' page. -->
				<fo:block id="lastPageId" line-height="0" />

			</fo:flow>
		</fo:page-sequence>

	</xsl:template>


<!--********************************************************-->
<!-- Start at the root of the Document.                     -->
<!--********************************************************-->
	<xsl:template match = "document">
		<fo:root	xmlns:fo="http://www.w3.org/1999/XSL/Format">
			<xsl:call-template name="doPageMasters" />
			<xsl:call-template name="doChapters" />
		</fo:root>
	</xsl:template>



</xsl:stylesheet>
