<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Ethan Gruber
    Date: June 2019
    Function: XSLT templates that construct the XML metamodel used in various contexts for SPARQL queries. 
    The sparql-metamodel.xsl stylesheet converts this XML model into text for the SPARQL endpoint
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nomisma="http://nomisma.org/"
    exclude-result-prefixes="#all" version="2.0">

    <!-- default properties associated with the various classes of RDF for Nomisma concepts -->
    <xsl:variable name="classes" as="item()*">
        <classes>
            <class prop="nmo:hasCollection">nmo:Collection</class>
            <class prop="nmo:hasDenomination">nmo:Denomination</class>
            <class prop="nmo:hasAuthority">nmo:Ethnic</class>
            <class prop="nmo:hasAuthority">rdac:Family</class>
            <class prop="nmo:hasAuthority">foaf:Group</class>
            <class prop="dcterms:isPartOf">nmo:Hoard</class>
            <class prop="nmo:hasManufacture">nmo:Manufacture</class>
            <class prop="nmo:hasMaterial">nmo:Material</class>
            <class prop="nmo:hasMint">nmo:Mint</class>
            <class prop="nmo:hasAuthority">foaf:Organization</class>
            <class prop="nmo:representsObjectType">nmo:ObjectType</class>
            <class prop="?prop">foaf:Person</class>
            <class prop="nmo:hasRegion">nmo:Region</class>
            <class prop="dcterms:source">nmo:TypeSeries</class>
        </classes>
    </xsl:variable>

    <!-- convert the $filter params (simple, semi-colon separated fragments) for the metrical and distribution analysis interfaces 
    into an XML meta-model that reflects complex SPARQL queries-->
    <xsl:template name="nomisma:filterToMetamodel">
        <xsl:param name="subject"/>
        <xsl:param name="filter"/>

        <xsl:for-each select="tokenize($filter, ';')">
            <xsl:variable name="property" select="substring-before(normalize-space(.), ' ')"/>
            <xsl:variable name="object" select="substring-after(normalize-space(.), ' ')"/>
            <xsl:choose>
                <xsl:when test="$property = 'portrait' or $property = 'deity'">
                    <union>
                        <triple s="{$subject}" p="nmo:hasObverse/nmo:hasPortrait" o="{$object}"/>
                        <triple s="{$subject}" p="nmo:hasReverse/nmo:hasPortrait" o="{$object}"/>
                    </union>
                </xsl:when>
                <xsl:when test="$property = 'authPerson'">
                    <triple s="{$subject}" p="nmo:hasAuthority" o="{$object}"/>
                </xsl:when>
                <xsl:when test="$property = 'authCorp'">
                    <union>
                        <group>
                            <triple s="{$subject}" p="nmo:hasAuthority" o="{$object}"/>
                        </group>
                        <group>
                            <triple s="{$subject}" p="nmo:hasAuthority" o="?authority"/>
                            <triple s="?authority" p="org:hasMembership/org:organization" o="{$object}"/>
                        </group>
                    </union>
                </xsl:when>
                <xsl:when test="$property = 'dynasty'">
                    <union>
                        <group>
                            <triple s="{$subject}" p="nmo:hasAuthority" o="{$object}"/>
                        </group>
                        <group>
                            <triple s="{$subject}" p="nmo:hasAuthority" o="?person"/>
                            <triple s="?person" p="org:memberOf" o="{$object}"/>                            
                        </group>
                    </union>
                    <triple s="{$object}" p="a" o="rdac:Family"/>
                </xsl:when>
                <xsl:when test="$property = '?prop'">
                    <union>
                        <triple s="{$subject}" p="?prop" o="{$object}"/>
                        <triple s="{$subject}" p="nmo:hasObverse/nmo:hasPortrait" o="{$object}"/>
                        <triple s="{$subject}" p="nmo:hasReverse/nmo:hasPortrait" o="{$object}"/>
                    </union>
                    <triple s="{$object}" p="a" o="foaf:Person"/>
                </xsl:when>
                <xsl:when test="$property = 'from'">
                    <xsl:if test="$object castable as xs:integer">
                        <xsl:variable name="gYear" select="format-number(number($object), '0000')"/>

                        <triple s="{$subject}" p="nmo:hasStartDate" o="?startDate">
                            <xsl:attribute name="filter">
                                <xsl:text>(?startDate >= "</xsl:text>
                                <xsl:value-of select="$gYear"/>
                                <xsl:text>"^^xsd:gYear)</xsl:text>
                            </xsl:attribute>
                        </triple>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$property = 'to'">
                    <xsl:if test="$object castable as xs:integer">
                        <xsl:variable name="gYear" select="format-number(number($object), '0000')"/>

                        <triple s="{$subject}" p="nmo:hasEndDate" o="?endDate">
                            <xsl:attribute name="filter">
                                <xsl:text>(?endDate &lt;= "</xsl:text>
                                <xsl:value-of select="$gYear"/>
                                <xsl:text>"^^xsd:gYear)</xsl:text>
                            </xsl:attribute>
                        </triple>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$property = 'range'">
                    <xsl:if test="matches($object, '-?\d+\|-?\d+')">
                        <xsl:variable name="range" select="tokenize($object, '\|')"/>

                        <xsl:variable name="s">
                            <xsl:choose>
                                <xsl:when test="contains($filter, 'nmo:hasTypeSeriesItem')">
                                    <xsl:analyze-string select="$filter" regex="nmo:hasTypeSeriesItem\s(&lt;.*&gt;)">
                                        <xsl:matching-substring>
                                            <xsl:value-of select="regex-group(1)"/>
                                        </xsl:matching-substring>
                                    </xsl:analyze-string>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$subject"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>

                        <xsl:choose>
                            <!-- if the interval is 1, then the from and to are the same -->
                            <xsl:when test="number($range[1]) = number($range[2])">
                                <triple s="{$s}" p="nmo:hasStartDate" o="?startDate">
                                    <xsl:attribute name="filter">
                                        <xsl:text>(?startDate &lt;= "</xsl:text>
                                        <xsl:value-of select="format-number(number($range[1]), '0000')"/>
                                        <xsl:text>"^^xsd:gYear)</xsl:text>
                                    </xsl:attribute>
                                </triple>
                                <triple s="{$s}" p="nmo:hasEndDate" o="?endDate">
                                    <xsl:attribute name="filter">
                                        <xsl:text>(?endDate &gt;= "</xsl:text>
                                        <xsl:value-of select="format-number(number($range[1]), '0000')"/>
                                        <xsl:text>"^^xsd:gYear)</xsl:text>
                                    </xsl:attribute>
                                </triple>
                            </xsl:when>
                            <xsl:otherwise>
                                <triple s="{$s}" p="nmo:hasEndDate" o="?endDate">
                                    <xsl:attribute name="filter">
                                        <xsl:text>(?endDate &gt;= "</xsl:text>
                                        <xsl:value-of select="format-number(number($range[1]), '0000')"/>
                                        <xsl:text>"^^xsd:gYear &amp;&amp; ?endDate &lt;= "</xsl:text>
                                        <xsl:value-of select="format-number(number($range[2]), '0000')"/>
                                        <xsl:text>"^^xsd:gYear)</xsl:text>
                                    </xsl:attribute>
                                </triple>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$property = 'nmo:hasTypeSeriesItem'">
                    <!-- get the measurements for all coins connected with a given type or any of its subtypes -->
                    <union>
                        <group>
                            <triple s="{$subject}" p="{$property}" o="{$object}"/>
                        </group>
                        <group>
                            <triple s="?broader" p="skos:broader+" o="{$object}"/>
                            <triple s="{$subject}" p="{$property}" o="?broader"/>
                        </group>
                    </union>
                </xsl:when>
                <xsl:otherwise>
                    <triple s="{$subject}" p="{$property}" o="{$object}"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- extract the $dist for distribution queries or the $facet for the SPARQL-based facet drop down menu. The prefLabel portion of the query is embedded in the SPARQL -->
    <xsl:template name="nomisma:distToMetamodel">
        <xsl:param name="object"/>
        <xsl:param name="dist"/>

        <xsl:choose>
            <xsl:when test="$dist = '?prop'">
                <union>
                    <triple s="?coinType" p="?prop" o="{$object}"/>
                    <triple s="?coinType" p="nmo:hasObverse/nmo:hasPortrait" o="{$object}"/>
                    <triple s="?coinType" p="nmo:hasReverse/nmo:hasPortrait" o="{$object}"/>
                </union>
                <triple s="{$object}" p="a" o="foaf:Person"/>
            </xsl:when>
            <xsl:when test="$dist = 'authPerson'">
                <triple s="?coinType" p="nmo:hasAuthority" o="{$object}"/>
                <triple s="{$object}" p="a" o="foaf:Person"/>
            </xsl:when>
            <xsl:when test="$dist = 'authCorp'">
                <union>
                    <group>
                        <triple s="?coinType" p="nmo:hasAuthority" o="{$object}"/>
                    </group>
                    <group>
                        <triple s="?coinType" p="nmo:hasAuthority" o="?authority"/>
                        <triple s="?authority" p="org:hasMembership/org:organization" o="{$object}"/>
                    </group>
                </union>
                <triple s="{$object}" p="a" o="foaf:Organization"/>
            </xsl:when>
            <xsl:when test="$dist = 'dynasty'">
                <union>
                    <group>
                        <triple s="?coinType" p="nmo:hasAuthority" o="{$object}"/>
                        <triple s="{$object}" p="a" o="rdac:Family"/>
                    </group>
                    <group>
                        <triple s="?coinType" p="nmo:hasAuthority" o="?person"/>
                        <triple s="?person" p="org:memberOf" o="{$object}"/>
                        <triple s="{$object}" p="a" o="rdac:Family"/>
                    </group>
                </union>
            </xsl:when>
            <xsl:when test="$dist = 'portrait' or $dist = 'deity'">
                <xsl:variable name="distClass"
                    select="
                        if ($dist = 'portrait') then
                            'foaf:Person'
                        else
                            'wordnet:Deity'"/>
                <union>
                    <triple s="?coinType" p="nmo:hasObverse/nmo:hasPortrait" o="{$object}"/>
                    <triple s="?coinType" p="nmo:hasReverse/nmo:hasPortrait" o="{$object}"/>
                </union>
                <triple s="{$object}" p="a" o="{$distClass}"/>
            </xsl:when>
            
            <xsl:when test="$dist = 'region'">
                <union>
                    <group>
                        <triple s="?coinType" p="nmo:hasRegion" o="{$object}"/>
                    </group>
                    <group>
                        <triple s="?coinType" p="nmo:hasMint" o="?mint"/>
                        <triple s="?mint" p="skos:broader+" o="{$object}"/>
                    </group>
                </union>
            </xsl:when>
            <xsl:otherwise>
                <triple s="?coinType" p="{$dist}" o="{$object}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="nomisma:getMintsStatements">
        <xsl:param name="type"/>
        <xsl:param name="id"/>
        <xsl:param name="letters"/>
        
        <statements>
            <xsl:choose>
                <xsl:when test="$type = 'nmo:Mint'">
                    <triple s="nm:{$id}" p="geo:location" o="?loc"/>
                </xsl:when>
                <xsl:when test="$type = 'nmo:Region'">
                    <union>
                        <group>
                            <triple s="nm:{$id}" p="geo:location" o="?loc"/>
                        </group>
                        <group>
                            <triple s="?mint" p="skos:broader+" o="nm:{$id}"/>
                            <triple s="?mint" p="geo:location" o="?loc"/>
                        </group>
                    </union>
                </xsl:when>
                <xsl:when test="$type = 'nmo:Hoard'">
                    <triple s="?coin" p="dcterms:isPartOf" o="nm:{$id}"/>
                    <triple s="?coin" p="a" o="nmo:NumismaticObject"/>
                    <union>
                        <group>
                            <triple s="?coin" p="nmo:hasTypeSeriesItem" o="?coinType"/>
                            <triple s="?coinType" p="nmo:hasMint" o="?place"/>
                        </group>
                        <group>
                            <triple s="?coin" p="nmo:hasMint" o="?place"/>
                        </group>
                    </union>
                    <triple s="?place" p="geo:location" o="?loc"/>
                </xsl:when>
                <xsl:when test="$type = 'nmo:Collection'">
                    <triple s="?coin" p="nmo:hasCollection" o="nm:{$id}"/>
                    <union>
                        <group>
                            <triple s="?coin" p="nmo:hasTypeSeriesItem" o="?coinType"/>
                            <triple s="?coinType" p="nmo:hasMint" o="?place"/>
                        </group>
                        <group>
                            <triple s="?coin" p="nmo:hasMint" o="?place"/>
                        </group>
                    </union>
                    <triple s="?place" p="geo:location" o="?loc"/>
                </xsl:when>
                <xsl:when test="$type = 'foaf:Person'">
                    <union>
                        <group>
                            <triple s="?coinType" p="?prop" o="nm:{$id}"/>                            
                        </group>
                        <group>
                            <triple s="?obv" p="?prop" o="nm:{$id}"/>
                            <triple s="?coinType" p="nmo:hasObverse" o="?obv"/>
                        </group>
                        <group>
                            <triple s="?rev" p="?prop" o="nm:{$id}"/>
                            <triple s="?coinType" p="nmo:hasReverse" o="?rev"/>
                        </group>
                        <group>
                            <triple s="nm:{$id}" p="org:hasMembership/org:organization" o="?place"/>
                        </group>
                    </union>
                    <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
                    <triple s="?coinType" p="nmo:hasMint" o="?place"/>
                    <minus>
                        <triple s="?coinType" p="dcterms:isReplacedBy" o="?replaced"/>
                    </minus>
                    <triple s="?place" p="geo:location" o="?loc"/>
                </xsl:when>
                <xsl:when test="$type = 'rdac:Family'">
                    <union>
                        <group>
                            <triple s="?coinType" p="nmo:hasAuthority" o="nm:{$id}"/>
                        </group>
                        <group>
                            <triple s="?coinType" p="nmo:hasAuthority" o="?person"/>
                            <triple s="?person" p="a" o="foaf:Person"/>
                            <triple s="?person" p="org:memberOf" o="nm:{$id}"/>
                        </group>
                    </union>
                    <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
                    <triple s="?coinType" p="nmo:hasMint" o="?place"/>
                    <minus>
                        <triple s="?coinType" p="dcterms:isReplacedBy" o="?replaced"/>
                    </minus>
                    <triple s="?place" p="geo:location" o="?loc"/>
                </xsl:when>
                <xsl:when test="$type = 'foaf:Organization' or $type = 'foaf:Group'">
                    <union>
                        <group>
                            <triple s="?coinType" p="nmo:hasAuthority" o="nm:{$id}"/>
                        </group>
                        <group>
                            <triple s="?coinType" p="nmo:hasAuthority" o="?person"/>
                            <triple s="?person" p="a" o="foaf:Person"/>
                            <triple s="?person" p="org:hasMembership/org:organization" o="nm:{$id}"/>
                        </group>
                    </union>                    
                    <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
                    <triple s="?coinType" p="nmo:hasMint" o="?place"/>
                    <minus>
                        <triple s="?coinType" p="dcterms:isReplacedBy" o="?replaced"/>
                    </minus>
                    <triple s="?place" p="geo:location" o="?loc"/>
                </xsl:when>
                <!-- when the query type is for constituent letters from a monogram, then construct a different sort of query than typical ID queries -->
                <xsl:when test="$type = 'letter'">
                    <!-- evaluate the $letters and construct the proper object query for 1+ literals -->
                    <xsl:variable name="letter-query">
                        <xsl:for-each select="$letters//value">
                            <xsl:value-of select="concat('&#x022;', ., '&#x022;')"/>
                            <xsl:if test="not(position() = last())">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <triple s="?monogram" p="crm:P106_is_composed_of" o="{$letter-query}"/>
                    <triple s="?side" p="nmo:hasControlmark" o="?monogram"/>
                    <triple s="?coinType" p="nmo:hasObverse|nmo:hasReverse" o="?side"/>
                    <triple s="?coinType" p="rdf:type" o="?TypeSeriesItem"/>
                    <triple s="?coinType" p="nmo:hasMint|nmo:hasMint/rdf:value" o="?place"/>                    
                    <triple s="?place" p="geo:location" o="?loc"/>
                </xsl:when>
                <xsl:otherwise>
                    <triple s="?coinType" p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                    <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
                    <triple s="?coinType" p="nmo:hasMint" o="?place"/>
                    <minus>
                        <triple s="?coinType" p="dcterms:isReplacedBy" o="?replaced"/>
                    </minus>
                    <triple s="?place" p="geo:location" o="?loc"/>
                </xsl:otherwise>
            </xsl:choose>
        </statements>
    </xsl:template>
    
    <xsl:template name="nomisma:getFindspotsStatements">
        <xsl:param name="api"/>
        <xsl:param name="type"/>
        <xsl:param name="id"/>
        <xsl:param name="letters"/>
        
        <statements>
            <xsl:choose>
                <xsl:when test="$type = 'foaf:Person'">
                    
                    <xsl:choose>
                        <xsl:when test="$api = 'getHoards' or $api = 'heatmap'">
                            <union>
                                <group>
                                    <xsl:call-template name="person-findspots">
                                        <xsl:with-param name="id" select="$id"/>
                                    </xsl:call-template>
                                    <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                    <xsl:if test="$api = 'heatmap'">
                                        <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </xsl:if>
                                </group>
                                <xsl:if test="$api = 'heatmap'">
                                    <group>
                                        <xsl:call-template name="person-findspots">
                                            <xsl:with-param name="id" select="$id"/>
                                        </xsl:call-template>
                                        <triple s="?object" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </group>
                                </xsl:if>
                               <group>
                                   <xsl:call-template name="hoard-content-query">
                                       <xsl:with-param name="api" select="$api"/>
                                       <xsl:with-param name="id" select="$id"/>
                                       <xsl:with-param name="type" select="$type"/>
                                   </xsl:call-template>
                               </group>
                            </union>                           
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="person-findspots">
                                <xsl:with-param name="id" select="$id"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$type = 'rdac:Family'">
                    <xsl:choose>
                        <xsl:when test="$api = 'getHoards' or $api = 'heatmap'">
                            <union>
                                <group>
                                    <xsl:call-template name="dynasty-findspots">
                                        <xsl:with-param name="id" select="$id"/>
                                    </xsl:call-template>
                                    <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                    <xsl:if test="$api = 'heatmap'">
                                        <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </xsl:if>
                                </group>
                                <xsl:if test="$api = 'heatmap'">
                                    <group>
                                        <xsl:call-template name="dynasty-findspots">
                                            <xsl:with-param name="id" select="$id"/>
                                        </xsl:call-template>
                                        <triple s="?object" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </group>
                                </xsl:if>
                                <group>
                                    <xsl:call-template name="hoard-content-query">
                                        <xsl:with-param name="api" select="$api"/>
                                        <xsl:with-param name="id" select="$id"/>
                                        <xsl:with-param name="type" select="$type"/>
                                    </xsl:call-template>
                                </group>
                            </union>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="dynasty-findspots">
                                <xsl:with-param name="id" select="$id"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>                    
                </xsl:when>
                <xsl:when test="$type = 'foaf:Organization' or $type = 'foaf:Group'">
                    
                    <xsl:choose>
                        <xsl:when test="$api = 'getHoards' or $api = 'heatmap'">
                            <union>
                                <group>
                                    <xsl:call-template name="org-findspots">
                                        <xsl:with-param name="id" select="$id"/>
                                    </xsl:call-template>
                                    <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                    <xsl:if test="$api = 'heatmap'">
                                        <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </xsl:if>
                                </group>
                                <xsl:if test="$api = 'heatmap'">
                                    <group>
                                        <xsl:call-template name="org-findspots">
                                            <xsl:with-param name="id" select="$id"/>
                                        </xsl:call-template>
                                        <triple s="?object" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </group>
                                </xsl:if>
                                <group>
                                    <xsl:call-template name="hoard-content-query">
                                        <xsl:with-param name="api" select="$api"/>
                                        <xsl:with-param name="id" select="$id"/>
                                        <xsl:with-param name="type" select="$type"/>
                                    </xsl:call-template>
                                </group>
                            </union>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="org-findspots">
                                <xsl:with-param name="id" select="$id"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$type = 'nmo:TypeSeriesItem'">    
                    <xsl:choose>
                        <xsl:when test="$api = 'getHoards' or $api = 'heatmap'">
                            <union>                                
                                <group>
                                    <triple s="?object" p="nmo:hasTypeSeriesItem" o="&lt;{$id}&gt;"/>
                                    <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                                    <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                    <xsl:if test="$api = 'heatmap'">
                                        <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </xsl:if>
                                </group>
                                <xsl:if test="$api = 'heatmap'">
                                    <group>
                                        <triple s="?object" p="nmo:hasTypeSeriesItem" o="&lt;{$id}&gt;"/>
                                        <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                                        <triple s="?object" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </group>
                                </xsl:if>
                                <group>
                                    <triple s="?contents"  p="nmo:hasTypeSeriesItem" o="&lt;{$id}&gt;"/>
                                    <triple s="?contents" p="rdf:type" o="dcmitype:Collection"/>
                                    <triple s="?hoard" p="dcterms:tableOfContents" o="?contents"/>
                                    <xsl:if test="$api = 'heatmap'">
                                        <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </xsl:if>
                                </group>
                            </union>                            
                        </xsl:when>
                        <xsl:otherwise>
                            <triple s="?object" p="nmo:hasTypeSeriesItem" o="&lt;{$id}&gt;"/>
                            <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$type = 'nmo:Monogram' or $type = 'crm:E37_Mark' or $type = 'letter'">  
                    
                    <xsl:choose>
                        <!-- Monograms and other E37_Marks utilize a sub-select query to get all coin type sides
                            connected to the URI or and children concepts of the URI -->
                        <xsl:when test="$type = 'nmo:Monogram' or $type = 'crm:E37_Mark'">
                            <select variables="?side">
                                <union>
                                    <group>
                                        <triple s="?side" p="nmo:hasControlmark" o="&lt;{$id}&gt;"/>
                                    </group>
                                    <group>
                                        <triple s="?children" p="skos:broader+" o="&lt;{$id}&gt;"/>
                                        <triple s="?side" p="nmo:hasControlmark" o="?children"/>
                                    </group>
                                </union>                        
                            </select>
                        </xsl:when>
                        <!-- when querying for 1 or more letters that are constituent parts of a monogram, then form the query -->
                        <xsl:when test="$type = 'letter'">
                            <!-- evaluate the $letters and construct the proper object query for 1+ literals -->
                            <xsl:variable name="letter-query">
                                <xsl:for-each select="$letters//value">
                                    <xsl:value-of select="concat('&#x022;', ., '&#x022;')"/>
                                    <xsl:if test="not(position() = last())">
                                        <xsl:text>,</xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:variable>
                            
                            <triple s="?monogram" p="crm:P106_is_composed_of" o="{$letter-query}"/>
                            <triple s="?side" p="nmo:hasControlmark" o="?monogram"/>
                        </xsl:when>
                    </xsl:choose>
                    
                    
                    <!-- remaining hoard union queries apply -->
                    <xsl:choose>
                        <xsl:when test="$api = 'getHoards' or $api = 'heatmap'">
                            <union>
                                <group>
                                    <triple s="?coinType" p="nmo:hasObverse|nmo:hasReverse" o="?side"/>
                                    <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>
                                    <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                                    <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                    <xsl:if test="$api = 'heatmap'">
                                        <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </xsl:if>
                                </group>
                                <xsl:if test="$api = 'heatmap'">
                                    <group>
                                        <triple s="?coinType" p="nmo:hasObverse|nmo:hasReverse" o="?side"/>
                                        <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>
                                        <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                                        <triple s="?object" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </group>
                                </xsl:if>
                                <group>
                                    <triple s="?coinType" p="nmo:hasObverse|nmo:hasReverse" o="?side"/>
                                    <triple s="?contents"  p="nmo:hasTypeSeriesItem" o="?coinType"/>
                                    <triple s="?contents" p="rdf:type" o="dcmitype:Collection"/>
                                    <triple s="?hoard" p="dcterms:tableOfContents" o="?contents"/>
                                    <xsl:if test="$api = 'heatmap'">
                                        <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                    </xsl:if>
                                </group>
                            </union>
                        </xsl:when>
                        <xsl:otherwise>
                            <triple s="?coinType" p="nmo:hasObverse|nmo:hasReverse" o="?side"/>
                            <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>
                            <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <!-- for letters, be sure to include a possible UNION query of type series -->
                    
                </xsl:when>
                <xsl:otherwise>
                    <union>
                        <!-- get coin types related to the concept -->
                        <group>
                            <triple s="?coinType" p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                            <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
                            <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>  
                            <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                            
                            <xsl:choose>
                                <xsl:when test="$api = 'getHoards'">
                                    <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                </xsl:when>
                                <xsl:when test="$api = 'heatmap'">
                                    <triple s="?object" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                </xsl:when>
                            </xsl:choose>
                        </group>
                        <!-- get physical coins connected to the concept -->
                        <group>
                            <triple s="?object" p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                            <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                            
                            <xsl:choose>
                                <xsl:when test="$api = 'getHoards'">
                                    <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                </xsl:when>
                                <xsl:when test="$api = 'heatmap'">
                                    <triple s="?object" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                                </xsl:when>
                            </xsl:choose>
                        </group>
                        
                        <xsl:if test="$api = 'heatmap'">
                            <!-- in the heatmap API, combine the query for both hoards and findspots related to the concept -->
                            <group>
                                <triple s="?coinType" p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                                <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
                                <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>  
                                <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                                <triple s="?object" p="dcterms:isPartOf" o="?hoard"/> 
                                <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                            </group>
                            <!-- get physical coins connected to the concept -->
                            <group>
                                <triple s="?object" p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                                <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
                                <triple s="?object" p="dcterms:isPartOf" o="?hoard"/>
                                <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                            </group>
                        </xsl:if>
                        
                        <xsl:if test="$api = 'getHoards' or $api = 'heatmap'">
                            <xsl:call-template name="hoard-content-query">
                                <xsl:with-param name="api" select="$api"/>
                                <xsl:with-param name="id" select="$id"/>
                                <xsl:with-param name="type" select="$type"/>
                            </xsl:call-template>
                        </xsl:if>
                    </union>
                </xsl:otherwise>
            </xsl:choose>
            
            <!-- evaluate whether the coin has a findspot for the getFindspots API or whether the coin/type is part of a hoard -->
            <xsl:choose>
                <xsl:when test="$api = 'getHoards'">
                    <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                </xsl:when>
                <xsl:when test="$api = 'getFindspots'">
                    <triple s="?object" p="nmo:hasFindspot" o="?place"/>
                </xsl:when>
            </xsl:choose>
            
        </statements>        
    </xsl:template>
    
    <!-- reusable templates for specific entities -->
    <xsl:template name="person-findspots">
        <xsl:param name="id"/>
        
        <union>
            <group>
                <triple s="?coinType" p="?prop" o="nm:{$id}"/>                            
            </group>
            <group>
                <triple s="?obv" p="?prop" o="nm:{$id}"/>
                <triple s="?coinType" p="nmo:hasObverse" o="?obv"/>
            </group>
            <group>
                <triple s="?rev" p="?prop" o="nm:{$id}"/>
                <triple s="?coinType" p="nmo:hasReverse" o="?rev"/>
            </group>                        
        </union>
        <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
        <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>
        <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
    </xsl:template>
    
    <xsl:template name="dynasty-findspots">
        <xsl:param name="id"/>
        
        <union>
            <group>
                <triple s="?coinType" p="?prop" o="nm:{$id}"/>
            </group>
            <group>
                <triple s="?person" p="org:memberOf" o="nm:{$id}"/>
                <triple s="?person" p="a" o="foaf:Person"/>                
                <triple s="?coinType" p="?prop" o="?person"/>               
            </group>
        </union>
        <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
        <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>
        <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
    </xsl:template>
    
    <xsl:template name="org-findspots">
        <xsl:param name="id"/>
        
        <union>
            <group>
                <triple s="?coinType" p="nmo:hasAuthority" o="nm:{$id}"/>
            </group>
            <group>
                <triple s="?person" p="org:hasMembership/org:organization" o="nm:{$id}"/>
                <triple s="?person" p="a" o="foaf:Person"/>
                <triple s="?coinType" p="nmo:hasAuthority" o="?person"/>                                
            </group>
        </union>                    
        <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>  
        <triple s="?object" p="nmo:hasTypeSeriesItem" o="?coinType"/>
        <triple s="?object" p="rdf:type" o="nmo:NumismaticObject"/>
    </xsl:template>
    
    <xsl:template name="hoard-content-query">
        <xsl:param name="api"/>
        <xsl:param name="id"/>
        <xsl:param name="type"/>
          
        <group>
            <group>
                <triple s="?coinType" p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
                <triple s="?contents" p="nmo:hasTypeSeriesItem" o="?coinType"/>
                <triple s="?contents" p="rdf:type" o="dcmitype:Collection"/>
                <triple s="?hoard" p="dcterms:tableOfContents" o="?contents"/>
                <xsl:if test="$api = 'heatmap'">
                    <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                </xsl:if>
            </group>
            <group>
                <triple s="?contents"  p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                <triple s="?contents" p="rdf:type" o="dcmitype:Collection"/>
                <triple s="?hoard" p="dcterms:tableOfContents" o="?contents"/>
                <xsl:if test="$api = 'heatmap'">
                    <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                </xsl:if>
            </group>
            <!-- look for people related to orgs and dynasties only in the hoard contents -->
            <xsl:choose>
                <xsl:when test="$type = 'foaf:Group' or 'foaf:Organization'">
                    <group>
                        <triple s="?person" p="org:hasMembership/org:organization" o="nm:{$id}"/>
                        <triple s="?person" p="rdf:type" o="foaf:Person"/>
                        <triple s="?contents"  p="nmo:hasAuthority" o="?person"/>
                        <triple s="?contents" p="rdf:type" o="dcmitype:Collection"/>
                        <triple s="?hoard" p="dcterms:tableOfContents" o="?contents"/>
                        <xsl:if test="$api = 'heatmap'">
                            <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                        </xsl:if>
                    </group>
                </xsl:when>
                <xsl:when test="$type = 'rdac:Family'">
                    <group>
                        <triple s="?person" p="org:memberOf" o="nm:{$id}"/>
                        <triple s="?person" p="rdf:type" o="foaf:Person"/>
                        <triple s="?contents"  p="nmo:hasAuthority" o="?person"/>
                        <triple s="?contents" p="rdf:type" o="dcmitype:Collection"/>
                        <triple s="?hoard" p="dcterms:tableOfContents" o="?contents"/>
                        <xsl:if test="$api = 'heatmap'">
                            <triple s="?hoard" p="nmo:hasFindspot/crm:P7_took_place_at/crm:P89_falls_within" o="?place"/>
                        </xsl:if>
                    </group>
                </xsl:when>
            </xsl:choose>
        </group>
    </xsl:template>

    <xsl:template name="nomisma:listTypesStatements">
        <xsl:param name="type"/>
        <xsl:param name="id"/>
        
        <statements>
            <xsl:choose>
                <xsl:when test="$type = 'foaf:Person'">
                    <union>
                        <triple s="?coinType" p="?prop" o="nm:{$id}"/>
                        <triple s="?coinType" p="nmo:hasObverse/nmo:hasPortrait" o="nm:{$id}"/>
                        <triple s="?coinType" p="nmo:hasReverse/nmo:hasPortrait" o="nm:{$id}"/>
                    </union>
                </xsl:when>
                <xsl:when test="$type = 'rdac:Family'">
                    <union>
                        <group>
                            <triple s="?coinType" p="nmo:hasAuthority" o="nm:{$id}"/>
                        </group>
                        <group>
                            <triple s="?coinType" p="nmo:hasAuthority" o="?person"/>
                            <triple s="?person" p="a" o="foaf:Person"/>
                            <triple s="?person" p="org:memberOf" o="nm:{$id}"/>
                        </group>
                    </union>
                </xsl:when>
                <xsl:when test="$type = 'foaf:Organization' or $type = 'foaf:Group' or $type = 'nmo:Ethnic'">
                    <union>
                        <group>
                            <triple s="?coinType" p="nmo:hasAuthority" o="nm:{$id}"/>
                        </group>
                        <group>
                            <triple s="?coinType" p="?prop" o="?person"/>
                            <triple s="?person" p="a" o="foaf:Person"/>
                            <triple s="?person" p="org:hasMembership/org:organization" o="nm:{$id}"/>
                        </group>
                    </union>
                </xsl:when>
                <xsl:when test="$type = 'nmo:Region'">
                    <union>
                        <group>
                            <triple s="?coinType" p="nmo:hasRegion" o="nm:{$id}"/>
                        </group>
                        <group>
                            <triple s="?coinType" p="nmo:hasMint" o="?mint"/>
                            <triple s="?mint" p="skos:broader+" o="nm:{$id}"/>
                        </group>
                    </union>
                </xsl:when>
                <xsl:otherwise>
                    <triple s="?coinType" p="{$classes//class[text()=$type]/@prop}" o="nm:{$id}"/>
                </xsl:otherwise>
            </xsl:choose>
            <triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
        </statements>
    </xsl:template>

</xsl:stylesheet>
