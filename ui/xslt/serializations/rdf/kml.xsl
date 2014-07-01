<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:nm="http://nomisma.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" exclude-result-prefixes="#all"
	version="2.0">

	<xsl:variable name="id" select="substring-after(//*[not(name()='geo:spatialThing')]/@rdf:about, 'id/')"/>
	<xsl:variable name="uri">
		<xsl:text>http://nomisma.org/id/</xsl:text>
		<xsl:value-of select="$id"/>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:apply-templates select="/content/rdf:RDF"/>
	</xsl:template>

	<xsl:template match="rdf:RDF">
		<kml xmlns="http://earth.google.com/kml/2.0">
			<Document>
				<Style id="mint">
					<IconStyle>
						<scale>1</scale>
						<hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
						<Icon>
							<href>http://maps.google.com/intl/en_us/mapfiles/ms/micons/blue-dot.png</href>
						</Icon>
					</IconStyle>
				</Style>
				<Style id="findspot">
					<IconStyle>
						<scale>1</scale>
						<hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
						<Icon>
							<href>http://maps.google.com/intl/en_us/mapfiles/ms/micons/red-dot.png</href>
						</Icon>
					</IconStyle>
				</Style>

				<xsl:apply-templates select="nm:mint|nm:region|nm:hoard">
					<xsl:with-param name="lat">
						<xsl:value-of select="geo:spatialThing/geo:lat"/>
					</xsl:with-param>
					<xsl:with-param name="long">
						<xsl:value-of select="geo:spatialThing/geo:long"/>
					</xsl:with-param>
				</xsl:apply-templates>
			</Document>
		</kml>
	</xsl:template>

	<xsl:template match="nm:hoard|nm:mint|nm:region">
		<xsl:param name="lat"/>
		<xsl:param name="long"/>
		<xsl:variable name="type" select="name()"/>

		<xsl:choose>
			<xsl:when test="$type='nm:mint'">
				<Placemark xmlns="http://earth.google.com/kml/2.0">
					<name>
						<xsl:value-of select="skos:prefLabel[@xml:lang='en']"/>
					</name>
					<styleUrl>#mint</styleUrl>
					<xsl:if test="string($lat) and string($long)">
						<description>
							<![CDATA[
								<dl class="dl-horizontal"><dt>Latitude</dt><dd>]]><xsl:value-of select="$lat"/><![CDATA[</dd>
								<dt>Longitude</dt><dd>]]><xsl:value-of select="$long"/><![CDATA[</dd>
								<![CDATA[</dl>]]>
						</description>

						<!-- add placemark -->
						<Point>
							<coordinates>
								<xsl:value-of select="concat($long, ',', $lat)"/>
							</coordinates>
						</Point>
					</xsl:if>
				</Placemark>
				<xsl:variable name="service" select="concat(/content/config/url, 'apis/getKml?uri=', $uri, '&amp;curie=', $type)"/>
				<xsl:copy-of select="document($service)//*[local-name()='Placemark']"/>
			</xsl:when>
			<xsl:when test="$type='nm:hoard'">
				<Placemark xmlns="http://earth.google.com/kml/2.0">
					<name>
						<xsl:value-of select="skos:prefLabel[@xml:lang='en']"/>
					</name>
					<styleUrl>#findspot</styleUrl>
					<xsl:if test="string($lat) and string($long)">
						<description>
							<![CDATA[
								<dl class="dl-horizontal"><dt>Latitude</dt><dd>]]><xsl:value-of select="$lat"/><![CDATA[</dd>
								<dt>Longitude</dt><dd>]]><xsl:value-of select="$long"/><![CDATA[</dd>
								<![CDATA[</dl>]]>
						</description>

						<!-- add placemark -->
						<Point>
							<coordinates>
								<xsl:value-of select="concat($long, ',', $lat)"/>
							</coordinates>
						</Point>
					</xsl:if>
				</Placemark>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
