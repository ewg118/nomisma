<?xml version="1.0" encoding="UTF-8"?>
<!--
	Author: Ethan Gruber
	Date: August 2019
	Function: Serialize RDF for the data dumps into VoID. Include a count of coins associated with Pleiades URIs.
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
	xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>
	
	<!-- get total count of coins -->
	<p:processor name="oxf:unsafe-xslt">		
		<p:input name="data" href="../../../../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
				<xsl:variable name="query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:	<http://purl.org/dc/terms/>
PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
PREFIX nm:	<http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX void: <http://rdfs.org/ns/void#>
PREFIX skos:	<http://www.w3.org/2004/02/skos/core#>

SELECT (count(DISTINCT ?coin) as ?count) WHERE {
?coin a nmo:NumismaticObject ;
	nmo:hasTypeSeriesItem ?type ;
	void:inDataset ?dataset . FILTER (?dataset != <http://numismatics.org/search/> && ?dataset != <http://coins.lib.virginia.edu/> && ?dataset != <https://finds.org.uk/>) .
	?type nmo:hasMint ?mint .
	?mint skos:closeMatch|skos:exactMatch ?match FILTER strStarts(str(?match), "https://pleiades")
}]]></xsl:variable>
				
				<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri($query), '&amp;output=xml')"/>
				
				<xsl:template match="/">
					<config>
						<url>
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
		<p:output name="data" id="count"/>
	</p:processor>	
	
	<p:processor name="oxf:unsafe-xslt">		
		<p:input name="data" href="aggregate('content', #data, #count, ../../../../config.xml)"/>		
		<p:input name="config" href="../../../../ui/xslt/serializations/sparql/pelagios-objects.void.xsl"/>
		<p:output name="data" id="model"/>
	</p:processor>

	<p:processor name="oxf:xml-serializer">
		<p:input name="data" href="#model"/>
		<p:input name="config">
			<config>
				<content-type>application/rdf+xml</content-type>
				<indent>true</indent>
				<indent-amount>4</indent-amount>
			</config>
		</p:input>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
