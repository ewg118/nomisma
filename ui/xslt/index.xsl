<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
	<xsl:include href="templates.xsl"/>
	<xsl:variable name="display_path">./</xsl:variable>

	<xsl:template match="/">
		<html lang="en">
			<head>
				<title>nomisma.org</title>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"/>
				<!-- bootstrap -->
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"/>
				<script type="text/javascript" src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"/>
				<link rel="stylesheet" href="{$display_path}ui/css/style.css"/>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="body"/>
				<xsl:call-template name="footer"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="body">
		<div class="container-fluid">
			<div class="row">
				<div class="col-md-8">
					<h1>Nomisma</h1>
					<xsl:copy-of select="//index/*"/>
				</div>
				<div class="col-md-4">
					<div>
						<h3>Data Download</h3>
						<a href="nomisma.org.xml">RDF/XML</a>
					</div>
					<div>
						<h3>Atom Feed</h3>
						<a href="feed/">
							<img src="{$display_path}ui/images/atom-large.png"/>
						</a>
					</div>
					<div>
						<h3>Contributors</h3>
						<p>The following institutions have contributed data, specialist advice and/or financial support to the Nomisma project:</p>

						<div class="media">
							<a href="http://numismatics.org" title="http://numismatics.org" rel="nofollow">
								<img src="http://www.numismatics.org/pmwiki/pub/skins/ans/ans_seal.gif" alt="http://numismatics.org"/>
							</a>
						</div>
						<div class="media">
							<a href="http://www.paris-sorbonne.fr/" title="http://www.paris-sorbonne.fr/" rel="nofollow">
								<img src="ui/images/paris-small.jpg" alt="http://www.paris-sorbonne.fr/"/>
							</a>
						</div>
						<div class="media">
							<a href="http://stanford.edu" title="http://stanford.edu" rel="nofollow">
								<img src="ui/images/stanford-small.jpg" alt="http://stanford.edu"/>
							</a>
						</div>
						<!--<a href="http://www.jisc.ac.uk" class="media" title="http://www.jisc.ac.uk" rel="nofollow">
								<img src="http://www.jisc.ac.uk/media/3/4/5/%7B345F1B7F-4AD6-4A61-B5BE-70AFA60F002F%7Djisclogojpgweb.jpg" />
								</a>-->
						<div class="media">
							<a href="http://finds.org.uk/" title="http://finds.org.uk/" rel="nofollow">
								<img src="http://finds.org.uk/images/logos/pas.gif" alt="http://finds.org.uk/"/>
							</a>
						</div>
						<div class="media">
							<a href="http://www.britishmuseum.org/" title="http://www.britishmuseum.org/" rel="nofollow">
								<img src="http://finds.org.uk/images/logos/bm_logo.png" alt="http://www.britishmuseum.org/"/>
							</a>
						</div>
						<div class="media">
							<a href="http://www.dainst.org/" title="http://www.dainst.org/" rel="nofollow">
								<img src="ui/images/GreifBlau.jpg" alt="http://www.dainst.org/"/>
							</a>
						</div>
						<div class="media">
							<a href="http://www.ahrc.ac.uk/" title="http://www.ahrc.ac.uk/" rel="nofollow">
								<img src="http://archaeologydataservice.ac.uk/images/logos/org34.png" alt="http://www.ahrc.ac.uk/"/>
							</a>
						</div>
						<div class="media">
							<a href="http://www.smb.museum/ikmk/" title="http://www.smb.museum/ikmk/" rel="nofollow">
								<img src="ui/images/SMB_MK_Black_sRGB.jpg" alt="http://www.smb.museum/ikmk/"/>
							</a>
						</div>
						<div class="media">
							<a href="http://www.acad.ro/" title="http://www.acad.ro/" rel="nofollow">
								<img src="http://upload.wikimedia.org/wikipedia/de/7/7a/Sigla_academia_romana.gif" alt="http://www.acad.ro/"/>
							</a>
						</div>
						<div class="media">
							<a href="http://www2.uni-frankfurt.de/" title="http://www2.uni-frankfurt.de/" rel="nofollow">
								<img src="ui/images/goethe.png" alt="http://www2.uni-frankfurt.de/"/>
							</a>
						</div>
					</div>
				</div>
			</div>
		</div>
	</xsl:template>
</xsl:stylesheet>
