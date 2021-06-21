<?xml version="1.0" encoding="UTF-8"?>
<!--
	Author: Ethan Gruber
	Date: June 2021
	Function: Read the type of response, whether a nomisma ID, coin type URI, symbol URI, or symbol letter and type series in order to determine
	the structure of the SPARQL query to submit to the endpoint in order to get hoards
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
							<xsl:when test="tokenize(/request/request-url, '/')[last() - 1] = 'id'">id</xsl:when>
							<xsl:when test="tokenize(/request/request-url, '/')[last() - 1] = 'symbol'">symbol</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="/request/parameters/parameter[name='id']/value">id</xsl:when>
									<xsl:when test="/request/parameters/parameter[name='coinType']/value">coinType</xsl:when>
									<xsl:when test="/request/parameters/parameter[name='symbol']/value">symbol</xsl:when>
									<xsl:when test="/request/parameters/parameter[name='letter']">letter</xsl:when>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</type>
				</xsl:template>

			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="concept-type"/>
	</p:processor>
	
	<p:processor name="oxf:url-generator">
		<p:input name="config">
			<config>
				<url>oxf:/apps/nomisma/ui/sparql/getHoards.sparql</url>
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

						<xsl:variable name="hasFindspots" as="item()*">
							<classes>
								<class>nmo:Denomination</class>
								<class>rdac:Family</class>
								<class>nmo:Ethnic</class>
								<class>foaf:Group</class>
								<class>nmo:Manufacture</class>
								<class>nmo:Material</class>
								<class>nmo:Mint</class>
								<class>nmo:ObjectType</class>
								<class>foaf:Organization</class>
								<class>foaf:Person</class>
								<class>nmo:Region</class>
							</classes>
						</xsl:variable>

						<xsl:variable name="type" select="/rdf:RDF/*[1]/name()"/>

						<xsl:template match="/">
							<type>
								<xsl:attribute name="hasFindspots">
									<xsl:choose>
										<xsl:when test="$hasFindspots//class[text()=$type]">true</xsl:when>
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
				<!-- if the ID is itself a hoard, then render from RDF -->
				<p:when test="type = 'nmo:Hoard'">
					<p:processor name="oxf:identity">
						<p:input name="data" href="#rdf"/>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<!-- suppress any class of object for which we do not want to render a map -->
				<p:when test="type/@hasFindspots = 'false'">
					<p:processor name="oxf:identity">
						<p:input name="data">
							<null/>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<!-- generate the SPARQL query -->
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="request" href="#request"/>
						<p:input name="data" href="#type"/>
						<p:input name="config-xml" href=" ../../../config.xml"/>
						<p:input name="query" href="#sparql-query-document"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
								xmlns:nomisma="http://nomisma.org/" exclude-result-prefixes="#all">
								<xsl:include href="../../../ui/xslt/controllers/metamodel-templates.xsl"/>
								<xsl:include href="../../../ui/xslt/controllers/sparql-metamodel.xsl"/>

								<xsl:param name="id">
									<xsl:choose>
										<xsl:when test="doc('input:request')/request/parameters/parameter[name='id']/value">
											<xsl:value-of select="doc('input:request')/request/parameters/parameter[name='id']/value"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="replace(tokenize(doc('input:request')/request/request-url, '/')[last()], '.geojson', '')"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:param>
								<xsl:variable name="sparql_endpoint" select="doc('input:config-xml')/config/sparql_query"/>
								<xsl:variable name="type" select="/type"/>

								<xsl:variable name="query" select="doc('input:query')"/>

								<xsl:variable name="statements" as="element()*">
									<xsl:call-template name="nomisma:getFindspotsStatements">
										<xsl:with-param name="api">getHoards</xsl:with-param>
										<xsl:with-param name="type" select="$type"/>
										<xsl:with-param name="id" select="$id"/>
										<xsl:with-param name="letters"/>
									</xsl:call-template>
								</xsl:variable>

								<xsl:variable name="statementsSPARQL">
									<xsl:apply-templates select="$statements/*"/>
								</xsl:variable>

								<xsl:variable name="service"
									select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%STATEMENTS%', $statementsSPARQL)), '&amp;output=xml')"/>

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
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:when test="/type = 'coinType' or /type = 'symbol' or /type = 'letter'">
			<!-- execute SPARQL queries for findspots and hoards for coin types, symbols, and constituent letters of monograms -->

			<!-- generate the SPARQL query -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="request" href="#request"/>
				<p:input name="query" href="#sparql-query-document"/>
				<p:input name="type" href="#concept-type"/>
				<p:input name="data" href=" ../../../config.xml"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
						xmlns:nomisma="http://nomisma.org/" exclude-result-prefixes="#all">
						<xsl:include href="../../../ui/xslt/controllers/metamodel-templates.xsl"/>
						<xsl:include href="../../../ui/xslt/controllers/sparql-metamodel.xsl"/>

						<xsl:variable name="type" select="doc('input:type')/type"/>

						<!-- config, SPARQL query variables -->
						<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
						<xsl:variable name="query" select="doc('input:query')"/>

						<!-- evaluate the concept type and formulate the specific variables in order to construct the SPARQL query -->
						<xsl:variable name="statements" as="element()*">
							<xsl:choose>
								<xsl:when test="$type = 'coinType'">
									<xsl:variable name="coinType" select="doc('input:request')/request/parameters/parameter[name='coinType']/value"/>

									<xsl:call-template name="nomisma:getFindspotsStatements">
										<xsl:with-param name="api">getHoards</xsl:with-param>
										<xsl:with-param name="type">nmo:TypeSeriesItem</xsl:with-param>
										<xsl:with-param name="id" select="$coinType"/>
										<xsl:with-param name="letters"/>
										<xsl:with-param name="typeSeries"/>
									</xsl:call-template>
								</xsl:when>
								<xsl:when test="$type = 'symbol'">
									<xsl:variable name="uri" select="doc('input:request')/request/parameters/parameter[name='symbol']/value"/>

									<xsl:call-template name="nomisma:getFindspotsStatements">
										<xsl:with-param name="api">getHoards</xsl:with-param>
										<xsl:with-param name="type">nmo:Monogram</xsl:with-param>
										<xsl:with-param name="id" select="$uri"/>
										<xsl:with-param name="letters"/>
										<xsl:with-param name="typeSeries"/>
									</xsl:call-template>
								</xsl:when>
								
								<xsl:when test="$type = 'letter'">
									<xsl:variable name="letters" select="doc('input:request')/request/parameters/parameter[name='letter']"/>
									<xsl:variable name="typeSeries" select="doc('input:request')/request/parameters/parameter[name='typeSeries']"/>
																		
									<xsl:call-template name="nomisma:getFindspotsStatements">
										<xsl:with-param name="api">getHoards</xsl:with-param>
										<xsl:with-param name="type">letter</xsl:with-param>
										<xsl:with-param name="id"/>
										<xsl:with-param name="letters" select="$letters"/>
										<xsl:with-param name="typeSeries" select="$typeSeries"/>
									</xsl:call-template>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>

						<xsl:variable name="statementsSPARQL">
							<xsl:apply-templates select="$statements/*"/>
						</xsl:variable>

						<xsl:variable name="service"
							select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%STATEMENTS%', $statementsSPARQL)), '&amp;output=xml')"/>

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
