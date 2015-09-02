<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#" xmlns:nm="http://nomisma.org/id/"
	exclude-result-prefixes="xs res nm" version="2.0">
	<!-- config variables -->
	<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
	<!-- url params -->
	<xsl:param name="identifiers" select="doc('input:request')/request/parameters/parameter[name='identifiers']/value"/>
	<xsl:param name="constraints" select="doc('input:request')/request/parameters/parameter[name='constraints']/value"/>
	<xsl:param name="uri" select="doc('input:request')/request/parameters/parameter[name='uri']/value"/>
	<xsl:param name="curie" select="doc('input:request')/request/parameters/parameter[name='curie']/value"/>
	<xsl:param name="lang" select="doc('input:request')/request/parameters/parameter[name='lang']/value"/>
	<xsl:param name="format" select="doc('input:request')/request/parameters/parameter[name='format']/value"/>
	<xsl:param name="baseUri" select="doc('input:request')/request/parameters/parameter[name='baseUri']/value"/>

	<xsl:template name="kml">
		<xsl:variable name="query">
			<![CDATA[PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:  <http://purl.org/dc/terms/>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX nm:       <http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX skos:      <http://www.w3.org/2004/02/skos/core#>
PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
PREFIX rdfs:	<http://www.w3.org/2000/01/rdf-schema#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT DISTINCT ?findspot ?lat ?long ?name WHERE {
{ ?coinType nmo:hasMint <URI> ;
  a nmo:TypeSeriesItem . 
 ?object nmo:hasTypeSeriesItem ?coinType ;
  rdf:type nmo:NumismaticObject ;
  nmo:hasFindspot ?findspot }
UNION { ?coinType nmo:hasMint <URI> ;
  a nmo:TypeSeriesItem .
  ?object nmo:hasTypeSeriesItem ?coinType ;
  rdf:type nmo:NumismaticObject ;
  dcterms:isPartOf ?hoard .
  ?hoard nmo:hasFindspot ?findspot }
UNION { ?coinType nmo:hasMint <URI> ;
  a nmo:TypeSeriesItem .
?contents nmo:hasTypeSeriesItem ?coinType ;
                  a dcmitype:Collection .
  ?object dcterms:tableOfContents ?contents ;
    nmo:hasFindspot ?findspot }
 UNION { ?contents nmo:hasMint <URI> ;
                  a dcmitype:Collection .
  ?object dcterms:tableOfContents ?contents ;
    nmo:hasFindspot ?findspot }
?object a ?type .
?findspot geo:lat ?lat ; geo:long ?long .
OPTIONAL { ?findspot foaf:name ?name }
OPTIONAL { ?findspot rdfs:label ?name }
}]]>
		</xsl:variable>

		<xsl:if test="string($query)">
			<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace($query, 'URI', $uri))), '&amp;output=xml')"/>

			<kml xmlns="http://earth.google.com/kml/2.0">
				<Document>
					<xsl:apply-templates select="document($service)/res:sparql" mode="kml"/>
				</Document>
			</kml>
		</xsl:if>
	</xsl:template>

	<xsl:template name="heatmap">
		<xsl:variable name="query">
			<![CDATA[PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:  <http://purl.org/dc/terms/>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX nm:       <http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX skos:      <http://www.w3.org/2004/02/skos/core#>
PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
SELECT DISTINCT ?findspot ?lat ?long ?count WHERE {
{ ?coinType nmo:hasMint <URI> ;
  a nmo:TypeSeriesItem . 
 ?object nmo:hasTypeSeriesItem ?coinType ;
  rdf:type nmo:NumismaticObject ;
  nmo:hasFindspot ?findspot }
UNION { ?coinType nmo:hasMint <URI> ;
  a nmo:TypeSeriesItem .
  ?object nmo:hasTypeSeriesItem ?coinType ;
  rdf:type nmo:NumismaticObject ;
  dcterms:isPartOf ?hoard .
  ?hoard nmo:hasFindspot ?findspot }
UNION { ?coinType nmo:hasMint <URI> ;
  a nmo:TypeSeriesItem .
?contents nmo:hasTypeSeriesItem ?coinType ;
                  a dcmitype:Collection .
  ?object dcterms:tableOfContents ?contents ;
    nmo:hasFindspot ?findspot }
 UNION { ?contents nmo:hasMint <URI> ;
                  a dcmitype:Collection .
  ?object dcterms:tableOfContents ?contents ;
    nmo:hasFindspot ?findspot }
?findspot geo:lat ?lat ; geo:long ?long}]]>
		</xsl:variable>

		<xsl:if test="string($query)">
			<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace($query, 'URI', $uri))), '&amp;output=xml')"/>

			<xsl:apply-templates select="document($service)/res:sparql" mode="heatmap"/>
		</xsl:if>
	</xsl:template>

	<xsl:template name="closingDate">
		<xsl:variable name="query">
			<![CDATA[ 
			PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
			PREFIX dcterms:  <http://purl.org/dc/terms/>
			PREFIX nm:       <http://nomisma.org/id/>
			PREFIX nmo:	<http://nomisma.org/ontology#>
			PREFIX owl:      <http://www.w3.org/2002/07/owl#>
			PREFIX xsd:	<http://www.w3.org/2001/XMLSchema#>
			SELECT (MAX(xsd:int(?date)) AS ?year)
			WHERE {
			<IDENTIFIERS>
			}
			]]>
		</xsl:variable>

		<xsl:variable name="replace">
			<xsl:for-each select="tokenize($identifiers, '\|')">
				<xsl:choose>
					<xsl:when test="position() = 1">
						<xsl:text>{&lt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:text>&gt; nmo:hasClosingDate ?timeSpan .
							?timeSpan nmo:hasEndDate ?date }</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>UNION {&lt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:text>&gt; nmo:hasClosingDate ?timeSpan .
							?timeSpan nmo:hasEndDate ?date }</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace($query, '&lt;IDENTIFIERS&gt;', $replace))), '&amp;output=xml')"/>

		<!-- no need to call template, create XML-RPC response here:-->

		<xsl:choose>
			<xsl:when test="$format='json'">
				<xsl:text>{"nmo:hasClosingDate":</xsl:text>
				<xsl:value-of select="number(document($service)/descendant::res:binding[@name='year']/res:literal)"/>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<response>
					<xsl:value-of select="number(document($service)/descendant::res:binding[@name='year']/res:literal)"/>
				</response>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="avgMeasurement">
		<xsl:param name="measurement"/>
		<xsl:variable name="query">
			<![CDATA[ 
			PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
			PREFIX dcterms:  <http://purl.org/dc/terms/>
			PREFIX nm:	<http://nomisma.org/id/>
			PREFIX nmo:	<http://nomisma.org/ontology#>
			PREFIX xsd:	<http://www.w3.org/2001/XMLSchema#>
			SELECT (AVG(xsd:decimal(?MEASUREMENT)) AS ?average)
			WHERE {
			<CONSTRAINTS>
			}
			]]>
		</xsl:variable>

		<xsl:variable name="replace">
			<xsl:text>{</xsl:text>
			<xsl:for-each select="tokenize($constraints, ' AND ')">
				<xsl:text>?coin </xsl:text>
				<xsl:value-of select="."/>
				<xsl:text> .</xsl:text>
			</xsl:for-each>
			<xsl:text>?coin nmo:hasMEASUREMENT ?MEASUREMENT</xsl:text>
			<xsl:text>} UNION {</xsl:text>
			<xsl:for-each select="tokenize($constraints, ' AND ')">
				<!-- ignore collection -->
				<xsl:if test="not(contains(., 'nmo:hasCollection'))">
					<xsl:text>?type </xsl:text>
					<xsl:value-of select="."/>
					<xsl:text> .</xsl:text>
				</xsl:if>
			</xsl:for-each>
			<xsl:text>?coin nmo:hasTypeSeriesItem ?type .</xsl:text>
			<xsl:if test="contains($constraints, 'nmo:hasCollection')">
				<xsl:analyze-string select="$constraints" regex="(nmo:hasCollection\s&lt;[^&gt;]+&gt;)">
					<xsl:matching-substring>
						<xsl:value-of select="concat('?coin ', regex-group(1), '.')"/>
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:if>
			<xsl:text>?coin nmo:hasMEASUREMENT ?MEASUREMENT</xsl:text>
			<xsl:text>}</xsl:text>
		</xsl:variable>

		<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace(replace($query, '&lt;CONSTRAINTS&gt;', replace($replace, '\\\\and',
			'&amp;&amp;')), 'MEASUREMENT', concat(upper-case(substring($measurement, 1, 1)), substring($measurement, 2))))), '&amp;output=xml')"/>

		<xsl:choose>
			<xsl:when test="$format='json'">
				<xsl:text>{"</xsl:text>
				<xsl:value-of select="$measurement"/>
				<xsl:text>":</xsl:text>
				<xsl:value-of select="number(document($service)/descendant::res:binding[@name='average']/res:literal)"/>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<response>
					<xsl:value-of select="number(document($service)/descendant::res:binding[@name='average']/res:literal)"/>
				</response>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="regionHierarchy">
		<xsl:variable name="query">
			<![CDATA[PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX nm:       <http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX skos:      <http://www.w3.org/2004/02/skos/core#>						
SELECT ?uri ?en ?lang WHERE {
nm:%ID% skos:broader+ ?uri .
?uri skos:prefLabel ?en . FILTER(langMatches(lang(?en), "en"))
%lang%}]]>
		</xsl:variable>

		<xsl:variable name="lang-template">?uri skos:prefLabel ?lang . FILTER(langMatches(lang(?lang), "LANG"))</xsl:variable>

		<response>
			<xsl:for-each select="tokenize($identifiers, '\|')">
				<xsl:variable name="id" select="."/>
				<xsl:variable name="service">
					<xsl:choose>
						<xsl:when test="string($lang)">
							<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace(replace($query, '%lang%', replace($lang-template, 'LANG', $lang)), '%ID%',
								$id))), '&amp;output=xml')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace(replace($query, '%lang%', ''), '%ID%', $id))), '&amp;output=xml')"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>

				<xsl:apply-templates select="document($service)/res:sparql" mode="regionHierarchy">
					<xsl:with-param name="id" select="$id"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</response>
	</xsl:template>
	
	<xsl:template match="res:sparql" mode="regionHierarchy">
		<xsl:param name="id"/>
		
		<hierarchy uri="http://nomisma.org/id/{$id}">
			<xsl:apply-templates select="descendant::res:result" mode="regionHierarchy"/>
		</hierarchy>
	</xsl:template>
	
	<xsl:template match="res:result" mode="regionHierarchy">
		<region uri="{res:binding[@name='uri']/res:uri}">
			<xsl:choose>
				<xsl:when test="string(res:binding[@name='lang']/res:literal)">
					<xsl:value-of select="res:binding[@name='lang']/res:literal"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="res:binding[@name='en']/res:literal"/>
				</xsl:otherwise>
			</xsl:choose>
		</region>
	</xsl:template>

	<xsl:template name="getLabel">
		<xsl:variable name="query">
			<![CDATA[
			PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
			PREFIX nm:       <http://nomisma.org/id/>
			PREFIX nmo:	<http://nomisma.org/ontology#>
			PREFIX skos:      <http://www.w3.org/2004/02/skos/core#>						
			SELECT DISTINCT ?label WHERE {
			<URI> skos:prefLabel ?label
			FILTER(langMatches(lang(?label), "LANG"))} 
			ORDER BY asc(?label)
			]]>
		</xsl:variable>
		<xsl:variable name="langStr" select="if (string($lang)) then $lang else 'en'"/>
		<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace(replace($query, 'LANG', $langStr), 'URI', $uri))), '&amp;output=xml')"/>
		<xsl:choose>
			<xsl:when test="$format='json'">
				<xsl:text>{"label":"</xsl:text>
				<xsl:value-of select="document($service)/descendant::res:binding[@name='label']/res:literal"/>
				<xsl:text>"}</xsl:text>
			</xsl:when>
			<xsl:when test="$format='jsonp'">
				<xsl:text>jsonCallback ({"label":"</xsl:text>
				<xsl:value-of select="document($service)/descendant::res:binding[@name='label']/res:literal"/>
				<xsl:text>"})</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<response>
					<xsl:value-of select="document($service)/descendant::res:binding[@name='label']/res:literal"/>
				</response>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="numishareResults">
		<xsl:variable name="query">
			<![CDATA[PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX nm: <http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?object ?type ?identifier ?collection ?obvThumb ?revThumb ?obvRef ?revRef ?comThumb ?comRef ?type WHERE {
{ ?object a nmo:NumismaticObject ;
 nmo:hasTypeSeriesItem <typeUri>}
UNION { ?broader skos:broader+ <typeUri> .
?object nmo:hasTypeSeriesItem ?broader ;
  a nmo:NumismaticObject }
UNION { ?contents a dcmitype:Collection ; 
  nmo:hasTypeSeriesItem <typeUri> .
?object dcterms:tableOfContents ?contents }
?object rdf:type ?type .
OPTIONAL { ?object dcterms:identifier ?identifier }
OPTIONAL { ?object nmo:hasCollection ?colUri .
?colUri skos:prefLabel ?collection
FILTER(langMatches(lang(?collection), "EN"))}
OPTIONAL { ?object foaf:thumbnail ?comThumb }
OPTIONAL { ?object foaf:depiction ?comRef }
OPTIONAL { ?object nmo:hasObverse ?obverse .
?obverse foaf:thumbnail ?obvThumb }
OPTIONAL { ?object nmo:hasObverse ?obverse .
?obverse foaf:depiction ?obvRef }
OPTIONAL { ?object nmo:hasReverse ?reverse .
?reverse foaf:thumbnail ?revThumb }
OPTIONAL { ?object nmo:hasReverse ?reverse .
?reverse foaf:depiction ?revRef }
}]]>
		</xsl:variable>

		<!-- process identifiers, executing a SPARQL query internally for each one, restructuring data into a response to return to numishare -->
		<response>
			<xsl:choose>
				<xsl:when test="not(string($identifiers))">
					<error>identifiers are required.</error>
				</xsl:when>
				<xsl:when test="not(string($baseUri))">
					<error>baseUri parameter is required.</error>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="tokenize($identifiers, '\|')">
						<xsl:variable name="uri" select="concat($baseUri, .)"/>
						<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace($query, 'typeUri', $uri))), '&amp;output=xml')"/>
						<xsl:apply-templates select="document($service)/res:sparql" mode="numishareResults">
							<xsl:with-param name="id" select="."/>
						</xsl:apply-templates>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</response>
	</xsl:template>

	<xsl:template match="res:sparql" mode="kml">
		<xsl:apply-templates select="descendant::res:result" mode="kml"/>
	</xsl:template>

	<xsl:template match="res:result" mode="kml">
		<xsl:variable name="label">
			<xsl:choose>
				<xsl:when test="res:binding[@name='name']/res:literal">
					<xsl:value-of select="res:binding[@name='name']/res:literal"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="res:binding[@name='findspot']/res:uri"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<Placemark xmlns="http://earth.google.com/kml/2.0">
			<name>
				<xsl:value-of select="$label"/>
			</name>
			<description>
				<xsl:variable name="description">
					<![CDATA[<a href="]]><xsl:value-of select="res:binding[@name='findspot']/res:uri"/><![CDATA[">]]><xsl:value-of select="res:binding[@name='findspot']/res:uri"/><![CDATA[</a>]]>
				</xsl:variable>
				<xsl:value-of select="normalize-space($description)"/>
			</description>
			<styleUrl>#findspot</styleUrl>
			<Point>
				<coordinates>
					<xsl:value-of select="concat(res:binding[@name='long']/res:literal, ',', res:binding[@name='lat']/res:literal)"/>
				</coordinates>
			</Point>
		</Placemark>
	</xsl:template>

	<!-- results to generate JSON for leaflet heatmap -->
	<xsl:template match="res:sparql" mode="heatmap">
		<xsl:text>{"max":1</xsl:text>
		<xsl:text>,"data":[</xsl:text>
		<xsl:apply-templates select="descendant::res:result" mode="heatmap"/>
		<xsl:text>]}</xsl:text>
	</xsl:template>

	<xsl:template match="res:result" mode="heatmap">
		<xsl:value-of select="concat('{&#x022;lat&#x022;:', res:binding[@name='lat']/res:literal, ', &#x022;lng&#x022;:', res:binding[@name='long']/res:literal, ', &#x022;count&#x022;:',1, '}')"/>
		<xsl:if test="not(position()=last())">
			<xsl:text>,</xsl:text>
		</xsl:if>
	</xsl:template>

	<!-- format SPARQL results into a manageable chunk for manipulation in Numishare results pages -->
	<xsl:template match="res:sparql" mode="numishareResults">
		<xsl:param name="id"/>
		<group id="{$id}">
			<object-count>
				<xsl:value-of select="count(descendant::res:result[contains(res:binding[@name='type']/res:uri, 'NumismaticObject')])"/>
			</object-count>
			<hoard-count>
				<xsl:value-of select="count(descendant::res:result[contains(res:binding[@name='type']/res:uri, 'Hoard')])"/>
			</hoard-count>
			<objects>
				<xsl:for-each select="descendant::res:result[res:binding[contains(@name, 'rev') or contains(@name, 'obv') or contains(@name,'com')]][position() &lt;=5]">
					<object collection="{res:binding[@name='collection']/res:literal}" identifier="{res:binding[@name='identifier']/res:literal}" uri="{res:binding[@name='object']/res:uri}">
						<xsl:if test="string(res:binding[@name='obvRef']/res:uri)">
							<obvRef>
								<xsl:value-of select="res:binding[@name='obvRef']/res:uri"/>
							</obvRef>
						</xsl:if>
						<xsl:if test="string(res:binding[@name='obvThumb']/res:uri)">
							<obvThumb>
								<xsl:value-of select="res:binding[@name='obvThumb']/res:uri"/>
							</obvThumb>
						</xsl:if>
						<xsl:if test="string(res:binding[@name='revRef']/res:uri)">
							<revRef>
								<xsl:value-of select="res:binding[@name='revRef']/res:uri"/>
							</revRef>
						</xsl:if>
						<xsl:if test="string(res:binding[@name='revThumb']/res:uri)">
							<revThumb>
								<xsl:value-of select="res:binding[@name='revThumb']/res:uri"/>
							</revThumb>
						</xsl:if>
						<xsl:if test="string(res:binding[@name='comRef']/res:uri)">
							<comRef>
								<xsl:value-of select="res:binding[@name='comRef']/res:uri"/>
							</comRef>
						</xsl:if>
						<xsl:if test="string(res:binding[@name='comThumb']/res:uri)">
							<comThumb>
								<xsl:value-of select="res:binding[@name='comThumb']/res:uri"/>
							</comThumb>
						</xsl:if>
					</object>
				</xsl:for-each>
			</objects>
		</group>
	</xsl:template>

	<xsl:function name="nm:normalizeYear">
		<xsl:param name="gYear"/>

		<xsl:choose>
			<xsl:when test="number($gYear) &gt; 0">
				<xsl:if test="number($gYear) &lt; 400">
					<xsl:text>A.D. </xsl:text>
				</xsl:if>
				<xsl:value-of select="number($gYear)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="abs(number($gYear)) + 1"/>
				<xsl:text> B.C.</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
</xsl:stylesheet>
