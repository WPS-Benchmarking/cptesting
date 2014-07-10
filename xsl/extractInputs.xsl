<?xml version="1.0"  encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:ows="http://www.opengis.net/ows/1.1"
		xmlns:wps="http://www.opengis.net/wps/1.0.0"
		xmlns:xlink="http://www.w3.org/1999/xlink">

  <xsl:output method="text"/>

  <xsl:template match="wps:ProcessDescriptions">
    <xsl:for-each select="./*/DataInputs/*">
      <xsl:if test="./ComplexData/Default/Format/MimeType">
	<xsl:for-each select="./ows:Identifier">
	  <xsl:value-of select="text()" /><xsl:text> </xsl:text>
	</xsl:for-each>
<xsl:text>
</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template> 

</xsl:stylesheet>
