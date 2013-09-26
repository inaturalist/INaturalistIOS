<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dc="http://purl.org/dc/elements/1.1/">
    
    <xsl:template match="/">
        <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                <link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css"/>
                <style type="text/css">
                    <![CDATA[
                        .images {white-space: nowrap; overflow-x:auto; overflow-y:hidden;-webkit-overflow-scrolling: touch;}
                        .images img.thumb {margin-left:1em; max-width:100%;}
                        .images img.thumb:first-child {margin-left:0;}
                        #photos img.thumb {max-height:200px; }
                        .container {padding-top: 1em;padding-bottom: 2em;}
                    ]]>
                </style>
            </head>
            <body>
                <div class="container">
                    <div id="photos" class="images">
                        <xsl:for-each select="//GuidePhoto">
                            <img src="{href[@type='local' and @size='small']}" class="thumb img-rounded" data-toggle="modal"/>
                        </xsl:for-each>
                    </div>
                    <h1>
                        <xsl:choose>
                            <xsl:when test="//displayName">
                                <xsl:value-of select="//displayName"/>
                                <xsl:if test="//GuideTaxon/name">
                                    <div><small><i><xsl:value-of select="//GuideTaxon/name"/></i></small></div>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <i><xsl:value-of select="//name"/></i>
                            </xsl:otherwise>
                        </xsl:choose>
                    </h1>
                    <div id="ranges" class="images">
                        <xsl:for-each select="//GuideRange">
                            <img src="{href[@type='local' and @size='medium']}" class="thumb img-rounded" data-toggle="modal"/>
                        </xsl:for-each>
                    </div>
                    <xsl:for-each select="//GuideSection">
                        <h2><xsl:value-of select="dc:title"/></h2>
                        <xsl:value-of select="dc:body" disable-output-escaping="yes"/>
                    </xsl:for-each>
                </div>
            </body>
        </html>
    </xsl:template>
    
</xsl:stylesheet>