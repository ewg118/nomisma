<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Ethan Gruber
	Date: June 2021
	Function: Serialize SPARQL query responses and/or RDF/XML for regions and mints into GeoJSON, both for individual mint/findspot/hoard APIs and the aggregated
	.geojson response -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:osgeo="http://data.ordnancesurvey.co.uk/ontology/geometry/" xmlns:nmo="http://nomisma.org/ontology#"
	xmlns:dcterms="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:nomisma="http://nomisma.org/"
	exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../json/json-metamodel.xsl"/>
	<xsl:include href="../../functions.xsl"/>

	<xsl:param name="api" select="tokenize(doc('input:request')/request/request-url, '/')[last()]"/>	

	<xsl:template match="/">
		<xsl:variable name="model" as="element()*">
			<_object>
				<type>FeatureCollection</type>
				<features>
					<_array>
						<xsl:choose>			
							<!-- content template for nmo:Region, aggregating region RDF and SPARQL query for child mints -->
							<xsl:when test="content">
								<xsl:apply-templates select="content"/>
							</xsl:when>
							<!-- GeoJSON serialization for a concept in the .geojson URL or content negotiation -->
							<xsl:when test="ignore">
								<xsl:apply-templates select="ignore"/>
							</xsl:when>
							<!-- apply templates for RDF/XML for CONSTRUCT or DESCRIBE SPARQL queries or from the identity transform included for an API request for a mint -->
							<xsl:when test="*[namespace-uri() = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#']">
								<xsl:choose>
									<!-- create JSON from a DESCRIBE/CONSTRUCT response -->
									<xsl:when test="$api = 'query.json'">
										<xsl:if test="count(//*[geo:lat and geo:long]) &gt; 0">
											<!-- apply-templates only on those RDF objects that have coordinates -->
											<xsl:apply-templates select="//*[geo:lat and geo:long]" mode="describe"/>
										</xsl:if>
									</xsl:when>
									<!-- create JSON from a mint or region concept -->
									<xsl:otherwise>
										<xsl:choose>
											<xsl:when test="descendant::geo:SpatialThing/osgeo:asGeoJSON">
												<xsl:apply-templates select="descendant::geo:SpatialThing" mode="poly">
													<xsl:with-param name="uri" select="*[1]/@rdf:about"/>
													<xsl:with-param name="label" select="*[1]/skos:prefLabel[@xml:lang = 'en']"/>
												</xsl:apply-templates>
											</xsl:when>
											<xsl:when test="descendant::geo:SpatialThing[geo:lat and geo:long]">
												<xsl:apply-templates select="descendant::geo:SpatialThing" mode="point">
													<xsl:with-param name="uri" select="*[1]/@rdf:about"/>
													<xsl:with-param name="label" select="*[1]/skos:prefLabel[@xml:lang = 'en']"/>
												</xsl:apply-templates>
											</xsl:when>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<!-- apply templates to SPARQL response -->
							<xsl:when test="*[namespace-uri() = 'http://www.w3.org/2005/sparql-results#']">
								<!-- evaluate API and construct the attributes according to GeoJSON-T -->		
								<xsl:choose>
									<xsl:when test="$api = 'getFindspots' or $api = 'getMints' or $api = 'getHoards'">
										<xsl:variable name="type">
											<xsl:choose>
												<xsl:when test="$api = 'getMints'">mint</xsl:when>
												<xsl:when test="$api = 'getHoards'">hoard</xsl:when>
												<xsl:when test="$api = 'getFindspots'">findspot</xsl:when>
											</xsl:choose>
										</xsl:variable>
										
										<xsl:apply-templates select="res:sparql">
											<xsl:with-param name="type" select="$type"/>
										</xsl:apply-templates>
									</xsl:when>
									<xsl:when test="$api = 'query.json'">
										<xsl:variable name="query" select="doc('input:request')/request/parameters/parameter[name = 'query']/value"/>
										
										<!-- parse out the lat and long variables from the SPARQL query -->
										<xsl:variable name="latParam">
											<xsl:analyze-string select="$query" regex="geo:lat\s+\?([a-zA-Z0-9_]+)">
												<xsl:matching-substring>
													<xsl:value-of select="regex-group(1)"/>
												</xsl:matching-substring>
											</xsl:analyze-string>
										</xsl:variable>
										<xsl:variable name="longParam">
											<xsl:analyze-string select="$query" regex="geo:long\s+\?([a-zA-Z0-9_]+)">
												
												<xsl:matching-substring>
													<xsl:value-of select="regex-group(1)"/>
												</xsl:matching-substring>
											</xsl:analyze-string>
										</xsl:variable>
										
										<!-- if lat and long are available, then apply templates for results with coordinates -->
										<xsl:if test="string-length($latParam) &gt; 0 and string-length($longParam) &gt; 0">
											<xsl:apply-templates
												select="descendant::res:result[res:binding[@name = $latParam] and res:binding[@name = $longParam]]"
												mode="query">
												<xsl:with-param name="lat" select="$latParam"/>
												<xsl:with-param name="long" select="$longParam"/>
											</xsl:apply-templates>
										</xsl:if>
									</xsl:when>
								</xsl:choose>
							</xsl:when>
						</xsl:choose>
					</_array>
				</features>
			</_object>
		</xsl:variable>

		<xsl:apply-templates select="$model"/>
	</xsl:template>

	<!-- handle aggregations of models, for .geojson serialization for concepts that involve SPARQL queries -->
	<xsl:template match="content">
		<xsl:call-template name="region-features"/>
	</xsl:template>
	
	<!-- ignore the RDF in the ignore root element, apply templates only to the three docs -->
	<xsl:template match="ignore">
		<xsl:apply-templates select="doc('input:mints')/*">
			<xsl:with-param name="type">mint</xsl:with-param>
		</xsl:apply-templates>
		<xsl:apply-templates select="doc('input:hoards')/res:sparql">
			<xsl:with-param name="type">hoard</xsl:with-param>
		</xsl:apply-templates>
		<xsl:apply-templates select="doc('input:findspots')/res:sparql">
			<xsl:with-param name="type">findspot</xsl:with-param>
		</xsl:apply-templates>
	</xsl:template>

	<!-- generate GeoJSON for id/ responses -->
	<xsl:template match="geo:SpatialThing" mode="point">
		<xsl:param name="uri"/>
		<xsl:param name="label"/>

		<_object>
			<type>Feature</type>
			<label>
				<xsl:value-of select="$label"/>
			</label>
			<id>
				<xsl:value-of select="$uri"/>
			</id>
			<geometry>
				<_object>
					<type>Point</type>
					<coordinates>
						<_array>
							<_>
								<xsl:value-of select="geo:long"/>
							</_>
							<_>
								<xsl:value-of select="geo:lat"/>
							</_>
						</_array>
					</coordinates>
				</_object>
			</geometry>

			<properties>
				<_object>
					<toponym>
						<xsl:value-of select="$label"/>
					</toponym>
					<gazetteer_label>
						<xsl:value-of select="$label"/>
					</gazetteer_label>
					<type>
						<xsl:value-of select="lower-case(parent::node()/*[1]/local-name())"/>
					</type>
				</_object>
			</properties>
		</_object>
	</xsl:template>

	<xsl:template match="geo:SpatialThing" mode="poly">
		<xsl:param name="uri"/>
		<xsl:param name="label"/>

		<_object>
			<type>Feature</type>
			<label>
				<xsl:value-of select="$label"/>
			</label>
			<id>
				<xsl:value-of select="$uri"/>
			</id>
			<geometry datatype="osgeo:asGeoJSON">
				<xsl:value-of select="osgeo:asGeoJSON"/>
			</geometry>
			<properties>
				<_object>
					<toponym>
						<xsl:value-of select="$label"/>
					</toponym>
					<gazetteer_label>
						<xsl:value-of select="$label"/>
					</gazetteer_label>
					<type>
						<xsl:value-of select="lower-case(parent::node()/*[1]/local-name())"/>
					</type>
				</_object>
			</properties>
		</_object>
	</xsl:template>

	<!-- Combine region polygon and SPARQL mint results into same FeatureCollection -->
	<xsl:template name="region-features">
		<xsl:if test="descendant::geo:SpatialThing/osgeo:asGeoJSON">
			<xsl:apply-templates select="descendant::geo:SpatialThing" mode="poly">
				<xsl:with-param name="uri" select="rdf:RDF/*[1]/@rdf:about"/>
				<xsl:with-param name="label" select="rdf:RDF/*[1]/skos:prefLabel[@xml:lang = 'en']"/>
			</xsl:apply-templates>
		</xsl:if>

		<xsl:apply-templates select="res:sparql">
			<xsl:with-param name="type">mint</xsl:with-param>
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- GeoJSON result for general SELECT SPARQL query lat/long -->
	<xsl:template match="res:result" mode="query">
		<xsl:param name="lat"/>
		<xsl:param name="long"/>

		<xsl:variable name="label" select="res:binding[1]/res:*"/>

		<_object>
			<type>Feature</type>
			<label>
				<xsl:value-of select="$label"/>
			</label>
			<xsl:if test="matches($label, 'https?://')">
				<id>
					<xsl:value-of select="$label"/>
				</id>
			</xsl:if>
			<geometry>
				<_object>
					<type>Point</type>
					<coordinates>
						<_array>
							<_>
								<xsl:value-of select="res:binding[@name = $long]/res:literal"/>
							</_>
							<_>
								<xsl:value-of select="res:binding[@name = $lat]/res:literal"/>
							</_>
						</_array>
					</coordinates>
				</_object>
			</geometry>
		</_object>
	</xsl:template>

	<!-- GeoJSON result for CONSTRUCT/DESCRIBE SPARQL query response -->
	<xsl:template match="*" mode="describe">
		<xsl:variable name="uri" select="@rdf:about"/>
		<xsl:variable name="object" as="element()*">
			<rdf:RDF>
				<xsl:choose>
					<xsl:when test="//*[nmo:hasFindspot/@rdf:resource = $uri]">
						<xsl:copy-of select="//*[nmo:hasFindspot/@rdf:resource = $uri]"/>
					</xsl:when>
					<xsl:when test="//*[nmo:hasFindspot/geo:SpatialThing[@rdf:about = $uri]]">
						<xsl:copy-of select="//*[nmo:hasFindspot/geo:SpatialThing[@rdf:about = $uri]]"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="self::node()"/>
					</xsl:otherwise>
				</xsl:choose>
			</rdf:RDF>
		</xsl:variable>

		<xsl:variable name="label">
			<xsl:apply-templates select="$object/*" mode="name"/>
		</xsl:variable>

		<_object>
			<type>Feature</type>
			<label>
				<xsl:value-of select="$label"/>
			</label>
			<id>
				<xsl:value-of select="$object/*[1]/@rdf:about"/>
			</id>
			<geometry>
				<_object>
					<type>Point</type>
					<coordinates>
						<_array>
							<_>
								<xsl:value-of select="geo:long"/>
							</_>
							<_>
								<xsl:value-of select="geo:lat"/>
							</_>
						</_array>
					</coordinates>
				</_object>
			</geometry>
		</_object>
	</xsl:template>

	<xsl:template match="*" mode="name">
		<xsl:choose>
			<xsl:when test="dcterms:title">
				<xsl:value-of select="dcterms:title[1]"/>
			</xsl:when>
			<xsl:when test="skos:prefLabel">
				<xsl:choose>
					<xsl:when test="skos:prefLabel[@xml:lang = 'en']">
						<xsl:value-of select="skos:prefLabel[@xml:lang = 'en']"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="skos:prefLabel[1]"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="foaf:name">
				<xsl:value-of select="foaf:name[1]"/>
			</xsl:when>
			<xsl:when test="rdfs:label">
				<xsl:value-of select="rdfs:label[1]"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- other GeoJSON API responses -->
	<xsl:template match="res:sparql">
		<xsl:param name="type"/>
		
		<xsl:apply-templates select="descendant::res:result">
			<xsl:with-param name="type" select="$type"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="res:result">
		<xsl:param name="type"/>

		<xsl:choose>
			<xsl:when test="res:binding[@name = 'poly']">
				<_object>
					<type>Feature</type>
					<label>
						<xsl:value-of
							select="
								if (res:binding[@name = 'hoardLabel']/res:literal) then
									res:binding[@name = 'hoardLabel']/res:literal
								else
									res:binding[@name = 'label']/res:literal"
						/>
					</label>
					<xsl:if test="res:binding[@name = 'hoard']/res:uri">
						<id>
							<xsl:value-of select="res:binding[@name = 'hoard']/res:uri"/>
						</id>
					</xsl:if>
					<geometry datatype="osgeo:asGeoJSON">
						<xsl:value-of select="res:binding[@name = 'poly']/res:literal"/>
					</geometry>

					<properties>
						<_object>
							<toponym>
								<xsl:value-of select="res:binding[@name = 'label']/res:literal"/>
							</toponym>
							<gazetteer_label>
								<xsl:value-of select="res:binding[@name = 'label']/res:literal"/>
							</gazetteer_label>
							<gazetteer_uri>
								<xsl:value-of select="res:binding[@name = 'place']/res:uri"/>
							</gazetteer_uri>
							<type>
								<xsl:value-of select="$type"/>
							</type>
						</_object>
					</properties>
				</_object>
			</xsl:when>
			<xsl:otherwise>
				<_object>
					<type>Feature</type>
					<label>
						<xsl:value-of
							select="
								if (res:binding[@name = 'hoardLabel']/res:literal) then
									res:binding[@name = 'hoardLabel']/res:literal
								else
									res:binding[@name = 'label']/res:literal"
						/>
					</label>
					<xsl:if test="res:binding[@name = 'hoard']/res:uri">
						<id>
							<xsl:value-of select="res:binding[@name = 'hoard']/res:uri"/>
						</id>
					</xsl:if>
					<geometry>
						<_object>
							<type>Point</type>
							<coordinates>
								<_array>
									<_>
										<xsl:value-of select="res:binding[@name = 'long']/res:literal"/>
									</_>
									<_>
										<xsl:value-of select="res:binding[@name = 'lat']/res:literal"/>
									</_>
								</_array>
							</coordinates>
						</_object>
					</geometry>

					<xsl:if test="res:binding[@name = 'closingDate']">
						<when>
							<_object>
								<timespans>
									<_array>
										<_object>
											<start>
												<xsl:value-of select="nomisma:xsdToIso(res:binding[@name = 'closingDate']/res:literal)"/>
											</start>
											<end>
												<xsl:value-of select="nomisma:xsdToIso(res:binding[@name = 'closingDate']/res:literal)"/>
											</end>
										</_object>
									</_array>
								</timespans>
							</_object>
						</when>
					</xsl:if>

					<properties>
						<_object>
							<toponym>
								<xsl:value-of select="res:binding[@name = 'label']/res:literal"/>
							</toponym>
							<gazetteer_label>
								<xsl:value-of select="res:binding[@name = 'label']/res:literal"/>
							</gazetteer_label>
							<gazetteer_uri>
								<xsl:value-of select="res:binding[@name = 'place']/res:uri"/>
							</gazetteer_uri>
							<type>
								<xsl:value-of select="$type"/>
							</type>
							<xsl:if test="res:binding[@name = 'count']">
								<count>
									<xsl:value-of select="res:binding[@name = 'count']/res:literal"/>
								</count>
							</xsl:if>
							<xsl:if test="res:binding[@name = 'closingDate']">
								<closing_date>
									<xsl:value-of select="nomisma:normalizeDate(res:binding[@name = 'closingDate']/res:literal)"/>
								</closing_date>
							</xsl:if>
						</_object>
					</properties>
				</_object>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
