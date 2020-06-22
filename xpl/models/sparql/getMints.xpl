<?xml version="1.0" encoding="UTF-8"?>
<!--
	Author: Ethan Gruber
	Date: June 2020
	Function: Read the type of response, whether a nomisma ID, a symbol URI, or symbol letter and type series in order to determine
	the structure of the SPARQL query to submit to the endpoint in order to get mints pertaining to that query.
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

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

	<!-- determine whether the query is for a coin type or for a Nomisma ID -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
				xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
				<xsl:template match="/">
					<type>
						<xsl:choose>
							<xsl:when test="/request/parameters/parameter[name='id']/value">id</xsl:when>
							<xsl:when test="/request/parameters/parameter[name='symbol']/value">symbol</xsl:when>
							<xsl:when test="/request/parameters/parameter[name='letter']">letter</xsl:when>
						</xsl:choose>
					</type>
				</xsl:template>

			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="concept-type"/>
	</p:processor>

	<p:choose href="#concept-type">
		<!-- execute specific SPARQL queries for getting associated geo locations for Nomisma ID Concepts -->
		<p:when test="/type = 'id'">
			<p:processor name="oxf:pipeline">
				<p:input name="config" href="../rdf/get-id.xpl"/>
				<p:output name="data" id="rdf"/>
			</p:processor>

			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="#rdf"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
						xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

						<xsl:variable name="hasMints" as="item()*">
							<classes>
								<class>nmo:Collection</class>
								<class>nmo:Denomination</class>
								<class>rdac:Family</class>
								<class>nmo:Ethnic</class>
								<class>foaf:Group</class>
								<class>nmo:Hoard</class>
								<class>nmo:Manufacture</class>
								<class>nmo:Material</class>
								<class>nmo:Mint</class>
								<class>nmo:ObjectType</class>
								<class>foaf:Organization</class>
								<class>foaf:Person</class>
								<class>nmo:Region</class>
								<class>nmo:TypeSeries</class>
							</classes>
						</xsl:variable>

						<xsl:variable name="type" select="/rdf:RDF/*[1]/name()"/>

						<xsl:template match="/">
							<type>
								<xsl:attribute name="hasMints">
									<xsl:choose>
										<xsl:when test="$hasMints//class[text()=$type]">true</xsl:when>
										<xsl:otherwise>false</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>

								<xsl:value-of select="$type"/>
							</type>
						</xsl:template>

					</xsl:stylesheet>
				</p:input>
				<p:output name="data" id="type"/>
			</p:processor>

			<p:choose href="#type">
				<!-- check to see whether the ID is a mint or region, if so, process the coordinates or geoJSON polygon in the RDF into geoJSON -->
				<p:when test="type = 'nmo:Mint'">
					<p:processor name="oxf:identity">
						<p:input name="data" href="#rdf"/>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<!-- when the ID is a region, include the region RDF to display a polygon, if applicable as well as execute a SPARQL query for all mints in the region -->
				<p:when test="type = 'nmo:Region'">
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="request" href="#request"/>
						<p:input name="data" href="#type"/>
						<p:input name="config-xml" href=" ../../../config.xml"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
								xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
								<xsl:param name="id" select="doc('input:request')/request/parameters/parameter[name='id']/value"/>
								<xsl:variable name="sparql_endpoint" select="doc('input:config-xml')/config/sparql_query"/>

								<xsl:variable name="query"><![CDATA[PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:  <http://purl.org/dc/terms/>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX nm:       <http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX skos:      <http://www.w3.org/2004/02/skos/core#>
PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
PREFIX osgeo:	<http://data.ordnancesurvey.co.uk/ontology/geometry/>
PREFIX org: <http://www.w3.org/ns/org#>
SELECT ?place ?label ?lat ?long WHERE {
  ?place skos:broader+ nm:ID ;
        geo:location ?loc ;
        skos:prefLabel ?label FILTER langMatches(lang(?label), "en") .
  ?loc geo:lat ?lat ;
       geo:long ?long
}]]></xsl:variable>
								<xsl:template match="/">
									<xsl:variable name="service"
										select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace($query, 'ID', $id))), '&amp;output=xml')"/>

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

					<p:processor name="oxf:url-generator">
						<p:input name="config" href="#url-generator-config"/>
						<p:output name="data" id="sparql-results"/>
					</p:processor>

					<p:processor name="oxf:identity">
						<p:input name="data" href="aggregate('content', #rdf, #sparql-results)"/>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<!-- suppress any class of object for which we do not want to render a map -->
				<p:when test="type/@hasMints = 'false'">
					<p:processor name="oxf:identity">
						<p:input name="data">
							<null/>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<!-- apply alternate SPARQL query to get mints associated with a Hoard -->
				<p:otherwise>

					<!-- get query from a text file on disk -->
					<p:processor name="oxf:url-generator">
						<p:input name="config">
							<config>
								<url>oxf:/apps/nomisma/ui/sparql/getMints.sparql</url>
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

					<p:processor name="oxf:unsafe-xslt">
						<p:input name="request" href="#request"/>
						<p:input name="query" href="#query-document"/>
						<p:input name="data" href="#type"/>
						<p:input name="config-xml" href=" ../../../config.xml"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
								xmlns:nomisma="http://nomisma.org/" exclude-result-prefixes="#all">
								<xsl:include href="../../../ui/xslt/controllers/metamodel-templates.xsl"/>
								<xsl:include href="../../../ui/xslt/controllers/sparql-metamodel.xsl"/>

								<xsl:variable name="sparql_endpoint" select="doc('input:config-xml')/config/sparql_query"/>
								<xsl:param name="id" select="doc('input:request')/request/parameters/parameter[name='id']/value"/>
								<xsl:variable name="type" select="/type"/>

								<xsl:variable name="query" select="doc('input:query')"/>

								<xsl:variable name="statements" as="element()*">
									<xsl:call-template name="nomisma:getMintsStatements">
										<xsl:with-param name="type" select="$type"/>
										<xsl:with-param name="id" select="$id"/>
										<xsl:with-param name="letters"/>
										<xsl:with-param name="typeSeries"/>
									</xsl:call-template>
								</xsl:variable>

								<xsl:variable name="statementsSPARQL">
									<xsl:apply-templates select="$statements/*"/>
								</xsl:variable>

								<xsl:variable name="service"
									select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%STATEMENTS%', $statementsSPARQL)), '&amp;output=xml')"> </xsl:variable>

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

					<p:processor name="oxf:url-generator">
						<p:input name="config" href="#url-generator-config"/>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:when test="/type = 'symbol'">
			<p:processor name="oxf:url-generator">
				<p:input name="config">
					<config>
						<url>oxf:/apps/nomisma/ui/sparql/getMints_symbol.sparql</url>
						<content-type>text/plain</content-type>
						<encoding>utf-8</encoding>
					</config>
				</p:input>
				<p:output name="data" id="sparql-query"/>
			</p:processor>

			<!-- convert text into an XML document for use in XSLT -->
			<p:processor name="oxf:text-converter">
				<p:input name="data" href="#sparql-query"/>
				<p:input name="config">
					<config/>
				</p:input>
				<p:output name="data" id="sparql-query-document"/>
			</p:processor>

			<!-- generate the SPARQL query -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="request" href="#request"/>
				<p:input name="query" href="#sparql-query-document"/>
				<p:input name="data" href=" ../../../config.xml"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
						xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
						<!-- request params -->
						<xsl:param name="uri" select="doc('input:request')/request/parameters/parameter[name='symbol']/value"/>

						<!-- config, SPARQL query variables -->
						<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
						<xsl:variable name="query" select="doc('input:query')"/>

						<xsl:template match="/">
							<xsl:variable name="service"
								select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace($query, '%URI%', $uri))), '&amp;output=xml')"/>

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

			<!-- execute SPARQL query -->
			<p:processor name="oxf:url-generator">
				<p:input name="config" href="#url-generator-config"/>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:when test="/type = 'letter'">
			<p:processor name="oxf:url-generator">
				<p:input name="config">
					<config>
						<url>oxf:/apps/nomisma/ui/sparql/getMints.sparql</url>
						<content-type>text/plain</content-type>
						<encoding>utf-8</encoding>
					</config>
				</p:input>
				<p:output name="data" id="sparql-query"/>
			</p:processor>
			
			<!-- convert text into an XML document for use in XSLT -->
			<p:processor name="oxf:text-converter">
				<p:input name="data" href="#sparql-query"/>
				<p:input name="config">
					<config/>
				</p:input>
				<p:output name="data" id="sparql-query-document"/>
			</p:processor>
			
			<!-- generate the SPARQL query -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="request" href="#request"/>
				<p:input name="query" href="#sparql-query-document"/>
				<p:input name="data" href=" ../../../config.xml"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
						xmlns:nomisma="http://nomisma.org/" exclude-result-prefixes="#all">
						<xsl:include href="../../../ui/xslt/controllers/metamodel-templates.xsl"/>
						<xsl:include href="../../../ui/xslt/controllers/sparql-metamodel.xsl"/>
						
						<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
						<xsl:variable name="letters" select="doc('input:request')/request/parameters/parameter[name='letter']"/>						
						<xsl:variable name="typeSeries" select="doc('input:request')/request/parameters/parameter[name='typeSeries']"/>
						
						<xsl:variable name="query" select="doc('input:query')"/>
						
						<xsl:variable name="statements" as="element()*">
							<xsl:call-template name="nomisma:getMintsStatements">
								<xsl:with-param name="type">letter</xsl:with-param>
								<xsl:with-param name="id"/>
								<xsl:with-param name="letters" select="$letters"/>
								<xsl:with-param name="typeSeries" select="$typeSeries"/>
							</xsl:call-template>
						</xsl:variable>
						
						<xsl:variable name="statementsSPARQL">
							<xsl:apply-templates select="$statements/*"/>
						</xsl:variable>
						
						<xsl:variable name="service"
							select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%STATEMENTS%', $statementsSPARQL)), '&amp;output=xml')"> </xsl:variable>
						
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
			
			<!-- execute SPARQL query -->
			<p:processor name="oxf:url-generator">
				<p:input name="config" href="#url-generator-config"/>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
	</p:choose>
</p:config>
