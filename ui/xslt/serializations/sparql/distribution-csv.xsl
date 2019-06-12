<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:nomisma="http://nomisma.org/" exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../../functions.xsl"/>

	<!-- URL parameters -->
	<xsl:param name="api" select="tokenize(doc('input:request')/request/request-uri, '/')[last()]"/>
	<!-- distribution params -->
	<xsl:param name="dist" select="doc('input:request')/request/parameters/parameter[name = 'dist']/value"/>
	<xsl:param name="type" select="doc('input:request')/request/parameters/parameter[name = 'type']/value"/>
	<!-- query params -->
	<xsl:param name="compare" select="doc('input:request')/request/parameters/parameter[name = 'compare']/value"/>
	<xsl:param name="filter" select="doc('input:request')/request/parameters/parameter[name = 'filter']/value"/>
	<!-- metrical analysis params -->
	<xsl:param name="measurement" select="doc('input:request')/request/parameters/parameter[name = 'measurement']/value"/>
	<xsl:param name="analysisType" select="doc('input:request')/request/parameters/parameter[name = 'analysisType']/value"/>
	<xsl:param name="from" select="doc('input:request')/request/parameters/parameter[name = 'from']/value"/>
	<xsl:param name="to" select="doc('input:request')/request/parameters/parameter[name = 'to']/value"/>
	<xsl:param name="interval" select="doc('input:request')/request/parameters/parameter[name = 'interval']/value"/>

	<xsl:variable name="queries" as="element()*">
		<queries>
			<xsl:if test="string($filter)">
				<query>
					<xsl:attribute name="label" select="nomisma:parseFilter(normalize-space($filter))"/>
					<xsl:value-of select="normalize-space($filter)"/>
				</query>
			</xsl:if>
			<xsl:for-each select="$compare">
				<query>
					<xsl:attribute name="label" select="nomisma:parseFilter(normalize-space(.))"/>
					<xsl:value-of select="."/>
				</query>
			</xsl:for-each>
		</queries>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$api = 'getDistribution'">
				<xsl:text>"group","value","uri",</xsl:text>
				<xsl:if test="$dist = 'nmo:hasMint'">
					<xsl:text>"lat","long",</xsl:text>
				</xsl:if>
				<xsl:text>"</xsl:text>
				<xsl:value-of select="
						if ($type = 'count') then
							'count'
						else
							'percentage'"/>
				<xsl:text>"&#x0A;</xsl:text>
				<xsl:apply-templates select="descendant::res:sparql" mode="getDistribution"/>
			</xsl:when>
			<xsl:when test="$api = 'getMetrical'">
				<xsl:variable name="value-heading" select="concat($analysisType, ' ', lower-case(substring-after($measurement, 'has')), ' (g)')"/>
				<xsl:choose>
					<!-- apply templates on the group element if a date range query -->
					<xsl:when test="number($from) and number($to) and number($interval)">	
						<xsl:text>"group","dateRange","startDate","</xsl:text>
						<xsl:value-of select="$value-heading"/>
						<xsl:text>"&#x0A;</xsl:text>
						<xsl:apply-templates select="descendant::group" mode="getMetrical"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>"label","</xsl:text>
						<xsl:value-of select="$value-heading"/>
						<xsl:text>"&#x0A;</xsl:text>
						<xsl:for-each select="descendant::res:result[res:binding[@name = 'average']/res:literal]">
							<xsl:variable name="position" select="position()"/>
							<xsl:variable name="value" select="$queries/query[$position]/@label"/>

							<xsl:apply-templates select="self::node()" mode="getMetrical">
								<xsl:with-param name="value" select="$value"/>
								<xsl:with-param name="subset"/>
								<xsl:with-param name="label"/>
							</xsl:apply-templates>
							<xsl:if test="not(position() = last())">
								<xsl:text>&#x0A;</xsl:text>
							</xsl:if>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- templates for distribution analysis -->
	<xsl:template match="res:sparql" mode="getDistribution">
		<xsl:variable name="position" select="position()"/>
		<xsl:variable name="query" select="$queries/query[$position]"/>


		<xsl:variable name="total" select="sum(descendant::res:binding[@name = 'count']/res:literal)"/>

		<xsl:apply-templates select="descendant::res:result[res:binding[@name = 'label']/res:literal]" mode="getDistribution">
			<xsl:with-param name="query" select="$query"/>
			<xsl:with-param name="total" select="$total"/>
		</xsl:apply-templates>

		<xsl:if test="not(position() = last())">
			<xsl:text>&#x0A;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="res:result" mode="getDistribution">
		<xsl:param name="query"/>
		<xsl:param name="total"/>

		<xsl:variable name="object" as="element()*">
			<row>
				<xsl:element name="subset">
					<xsl:value-of select="nomisma:parseFilter($query)"/>
				</xsl:element>
				<xsl:element name="{if (starts-with($dist, 'nmo:')) then lower-case(substring-after($dist, 'has')) else $dist}">
					<xsl:value-of select="res:binding[@name = 'label']/res:literal"/>
				</xsl:element>
				<xsl:element name="uri">
					<xsl:value-of select="res:binding[@name = 'dist']/res:uri"/>
				</xsl:element>
				<xsl:if test="$dist = 'nmo:hasMint'">
					<xsl:element name="lat">
						<xsl:value-of select="res:binding[@name = 'lat']/res:literal"/>
					</xsl:element>
					<xsl:element name="long">
						<xsl:value-of select="res:binding[@name = 'long']/res:literal"/>
					</xsl:element>
				</xsl:if>
				<xsl:element name="{if ($type='count') then 'count' else 'percentage'}">
					<xsl:choose>
						<xsl:when test="$type = 'count'">
							<xsl:value-of select="res:binding[@name = 'count']/res:literal"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="format-number((res:binding[@name = 'count']/res:literal div $total) * 100, '0.0')"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:element>
			</row>
		</xsl:variable>

		<xsl:for-each select="$object/*">
			<xsl:choose>
				<xsl:when test=". castable as xs:integer or . castable as xs:decimal">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:when test="string-length(.) = 0"/>
				<xsl:otherwise>
					<xsl:value-of select="concat('&#x022;', replace(., '&#x022;', '&#x022;&#x022;'), '&#x022;')"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="not(position() = last())">
				<xsl:text>,</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="not(position() = last())">
			<xsl:text>&#x0A;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- templates for the getMetrical API -->
	<xsl:template match="group" mode="getMetrical">
		<xsl:variable name="position" select="position()"/>
		<xsl:variable name="subset" select="$queries/query[$position]/@label"/>
		
		<xsl:for-each select="descendant::res:result[res:binding[@name = 'average']/res:literal]">
			<xsl:variable name="value" select="ancestor::value/query/@year"/>
			<xsl:variable name="label" select="ancestor::value/query/@range"/>
			<xsl:apply-templates select="self::node()" mode="getMetrical">
				<xsl:with-param name="label" select="$label"/>
				<xsl:with-param name="subset" select="$subset"/>
				<xsl:with-param name="value" select="$value"/>
			</xsl:apply-templates>
			<xsl:if test="not(position() = last())">
				<xsl:text>&#x0A;</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="not(position() = last())">
			<xsl:text>&#x0A;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="res:result" mode="getMetrical">
		<xsl:param name="label"/>
		<xsl:param name="subset"/>
		<xsl:param name="value"/>
		
		<xsl:variable name="object" as="element()*">
			<row>
				<xsl:if test="string($subset)">
					<xsl:element name="subset">
						<xsl:value-of select="$subset"/>
					</xsl:element>
				</xsl:if>				
				<xsl:if test="string($label)">
					<xsl:element name="label">
						<xsl:value-of select="$label"/>
					</xsl:element>
				</xsl:if>
				<xsl:element name="value">
					<xsl:value-of select="$value"/>
				</xsl:element>				
				<xsl:element name="average">
					<!--<xsl:value-of select="format-number(number(res:binding[@name = 'average']/res:literal), '0.00')"/>-->
					
					<xsl:choose>
						<xsl:when test="number(res:binding[@name = 'average']/res:literal) &gt; 0">
							<xsl:value-of select="format-number(number(res:binding[@name = 'average']/res:literal), '0.00')"/>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>					
				</xsl:element>
			</row>
		</xsl:variable>
		
		<xsl:for-each select="$object/*">
			<xsl:choose>
				<xsl:when test=". = 'null'">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:when test=". castable as xs:gYear">
					<xsl:value-of select="concat('&#x022;', ., '&#x022;')"/>
				</xsl:when>
				<xsl:when test=". castable as xs:integer or . castable as xs:decimal">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('&#x022;', replace(., '&#x022;', '&#x022;&#x022;'), '&#x022;')"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="not(position() = last())">
				<xsl:text>,</xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
