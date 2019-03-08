<?xml version="1.0" encoding="UTF-8"?>
<!--
	XPL handling SPARQL queries from Fuseki	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>
	
	<!-- get query from a text file on disk -->
	<p:processor name="oxf:url-generator">
		<p:input name="config">
			<config>
				<url>oxf:/apps/nomisma/ui/sparql/facets.sparql</url>
				<content-type>text/plain</content-type>
				<encoding>utf-8</encoding>
			</config>
		</p:input>
		<p:output name="data" id="query"/>
	</p:processor>
	
	<p:processor name="oxf:text-converter">		
		<p:input name="data" href="#query"/>
		<p:input name="config">
			<config/>
		</p:input>
		<p:output name="data" id="query-document"/>
	</p:processor>

	<!-- develop config for URL generator for the main SPARQL-based distribution query -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="query" href="#query-document"/>
		<p:input name="request" href="#request"/>
		<p:input name="data" href="../../../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:include href="../../../ui/xslt/controllers/sparql-metamodel.xsl"/>
				
				<!-- request parameters -->
				<xsl:param name="filter" select="doc('input:request')/request/parameters/parameter[name='filter']/value"/>
				<xsl:param name="facet" select="doc('input:request')/request/parameters/parameter[name='facet']/value"/>
				
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
				<xsl:variable name="query" select="doc('input:query')"/>

				<xsl:variable name="statements" as="element()*">
					<statements>
						<triple s="?coinType" p="rdf:type" o="nmo:TypeSeriesItem"/>
						
						<!-- parse filters -->
						<xsl:for-each select="tokenize($filter, ';')">
							<xsl:variable name="property" select="substring-before(normalize-space(.), ' ')"/>
							<xsl:variable name="object" select="substring-after(normalize-space(.), ' ')"/>
							
							<!-- process filters -->
							<xsl:choose>
								<xsl:when test="$property = 'portrait' or $property='deity'">
									<union>
										<triple s="?coinType" p="nmo:hasObverse/nmo:hasPortrait" o="{$object}"/>
										<triple s="?coinType" p="nmo:hasReverse/nmo:hasPortrait" o="{$object}"/>
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
						
						<!-- facet -->
						<xsl:choose>
							<xsl:when test="$facet='?prop'">
								<triple s="?coinType" p="?prop" o="?facet"></triple>
								<triple s="?facet" p="rdf:type" o="?type FILTER strStarts(str(?type), &#x022;http://xmlns.com/foaf/0.1/&#x022;)"></triple>
							</xsl:when>
							<xsl:when test="$facet='portrait' or $facet='deity'">
								<xsl:variable name="distClass" select="if ($facet='portrait') then 'foaf:Person' else 'wordnet:Deity'"/>									
								<union>
									<triple s="?coinType" p="nmo:hasObverse/nmo:hasPortrait" o="?facet"/>
									<triple s="?coinType" p="nmo:hasReverse/nmo:hasPortrait" o="?facet"/>
								</union>
								<triple s="?facet" p="a" o="{$distClass}"/>				
							</xsl:when>
							<xsl:otherwise>
								<triple s="?coinType" p="{$facet}" o="?facet"/>
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
							<!--<xsl:copy-of select="$statementsSPARQL"/>-->
							<xsl:value-of select="$service"/>
						</url>
						<content-type>application/xml</content-type>
						<encoding>utf-8</encoding>
					</config>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="url-generator-config"/>
	</p:processor>

	<!-- get the data from fuseki -->
	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#url-generator-config"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
