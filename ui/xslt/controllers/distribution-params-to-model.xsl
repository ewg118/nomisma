<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all">
	<xsl:include href="sparql-metamodel.xsl"/>
	
	<!-- request parameters -->
	<xsl:param name="filter" select="doc('input:filter')/query"/>
	<xsl:param name="dist" select="doc('input:request')/request/parameters/parameter[name='dist']/value"/>
	<xsl:param name="format" select="doc('input:request')/request/parameters/parameter[name='format']/value"/>
	
	<!-- config variables -->
	<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
	<xsl:variable name="query" select="doc('input:query')"/>
	
	<!-- parse query statements into a data object -->
	<xsl:variable name="statements" as="element()*">
		<statements>
			<!-- parse filters -->
			<xsl:for-each select="tokenize($filter, ';')">
				<xsl:variable name="property" select="substring-before(normalize-space(.), ' ')"/>
				<xsl:variable name="object" select="substring-after(normalize-space(.), ' ')"/>
				
				<xsl:choose>
					<xsl:when test="$property = 'portrait' or $property='deity'">
						<union>
							<triple s="?coinType" p="nmo:hasObverse/nmo:hasPortrait" o="{$object}"/>
							<triple s="?coinType" p="nmo:hasReverse/nmo:hasPortrait" o="{$object}"/>
						</union>
					</xsl:when>
					<xsl:when test="$property = 'authPerson'">
						<triple s="?coinType" p="nmo:hasAuthority" o="{$object}"/>
					</xsl:when>
					<xsl:when test="$property = 'authCorp'">
						<union>
							<group>
								<triple s="?coinType" p="nmo:hasAuthority" o="{$object}"/>
							</group>
							<group>
								<triple s="?coinType" p="nmo:hasAuthority" o="?authority"/>
								<triple s="?authority" p="org:hasMembership/org:organization" o="{$object}"/>
							</group>
						</union>
					</xsl:when>
					<xsl:when test="$property = 'from'">
						<xsl:if test="$object castable as xs:integer">
							<xsl:variable name="gYear" select="format-number(number($object), '0000')"/>
							
							<triple s="?coinType" p="nmo:hasStartDate" o="?startDate">
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
							
							<triple s="?coinType" p="nmo:hasEndDate" o="?endDate">
								<xsl:attribute name="filter">
									<xsl:text>(?endDate &lt;= "</xsl:text>
									<xsl:value-of select="$gYear"/>
									<xsl:text>"^^xsd:gYear)</xsl:text>
								</xsl:attribute>
							</triple>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<triple s="?coinType" p="{$property}" o="{$object}"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			
			<!-- parse dist -->
			<xsl:choose>
				<xsl:when test="$dist='portrait' or $dist='deity'">
					<xsl:variable name="distClass" select="if ($dist='portrait') then 'foaf:Person' else 'wordnet:Deity'"/>
					<union>
						<triple s="?coinType" p="nmo:hasObverse/nmo:hasPortrait" o="?dist"/>
						<triple s="?coinType" p="nmo:hasReverse/nmo:hasPortrait" o="?dist"/>
					</union>
					<triple s="?dist" p="a" o="{$distClass}"/>
				</xsl:when>
				<xsl:when test="$dist='authPerson'">
					<triple s="?coinType" p="nmo:hasAuthority" o="?dist"/>
					<triple s="?dist" p="a" o="foaf:Person"/>
				</xsl:when>
				<xsl:when test="$dist='authCorp'">
					<union>
						<group>
							<triple s="?coinType" p="nmo:hasAuthority" o="?dist"/>
						</group>
						<group>
							<triple s="?coinType" p="nmo:hasAuthority" o="?authority"/>
							<triple s="?authority" p="org:hasMembership/org:organization" o="?dist"/>
						</group>
					</union>
					<triple s="?dist" p="a" o="foaf:Organization"/>
				</xsl:when>
				<xsl:otherwise>
					<triple s="?coinType" p="{$dist}" o="?dist"/>
					<!-- if the dist is mint, then include lat and long, but only for CSV -->
					<xsl:if test="$dist='nmo:hasMint' and $format='csv'">
						<optional>
							<triple s="?dist" p="geo:location" o="?loc"/>
							<triple s="?loc" p="geo:lat" o="?lat"/>
							<triple s="?loc" p="geo:long" o="?long"/>
						</optional>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</statements>
	</xsl:variable>
	
	<xsl:variable name="statementsSPARQL">
		<xsl:apply-templates select="$statements/*"/>
	</xsl:variable>
	
	<xsl:variable name="service">
		<xsl:value-of
			select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%STATEMENTS%', $statementsSPARQL)), '&amp;output=xml')"
		/>
	</xsl:variable>
	
	<xsl:template match="/">
		<config>
			<url>
				<xsl:value-of select="$service"/>
			</url>
			<content-type>application/xml</content-type>
			<encoding>utf-8</encoding>
		</config>
	</xsl:template>
	
	<!-- construct triple for coins -->
	<xsl:template match="group" mode="coin">	
		<group>
			<xsl:for-each select="triple">
				<triple s="?coin" p="{@p}" o="{@o}">
					<xsl:if test="@filter">
						<xsl:attribute name="filter" select="@filter"/>
					</xsl:if>
				</triple>
			</xsl:for-each>
		</group>						
	</xsl:template>
	
	<!-- construct triples for coin types -->
	<xsl:template match="group" mode="coinType">
		<group>
			<xsl:for-each select="triple">
				<triple s="?coinType" p="{@p}" o="{@o}">
					<xsl:if test="@filter">
						<xsl:attribute name="filter" select="@filter"/>
					</xsl:if>
				</triple>								
			</xsl:for-each>
			<triple s="?coin" p="nmo:hasTypeSeriesItem" o="?coinType"/>
		</group>						
	</xsl:template>
</xsl:stylesheet>
