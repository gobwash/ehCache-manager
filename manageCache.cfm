<cfscript>
	function EpochTimeToLocalDate( epoch ) {
	  return dateTimeFormat( DateAdd( "s",epoch,DateConvert( "utc2Local", "January 1 1970 00:00" ) ) );
	}
	showKeyData = false;
	showRegionData = false;
	cfparam( name="url.action", default="" );
	cacheManager = createObject( "java", "net.sf.ehcache.CacheManager" ).getInstance();

	switch( url.action ){
		case "purge":
			cacheManager.getCache( url.region ).remove( url.key );
		break;
		case "purgeRegion":
			cacheManager.getCache( url.region ).removeAll();
		break;
		case "purgeQueryCache":
			cfobjectcache( action="clear" );
		break;
		case "killRegion":
			cacheManager.removeCache( url.region );
			structDelete( url, "region" );
		break;
	}
	structDelete( url, "action" );
	
	if( structKeyExists( url, "region" ) ){
		regionData = cacheManager.getCache( url.region ).getKeys();
		showRegionData = isDefined( "regionData" );
	}
	if( structKeyExists( url, "key" ) ){
		cacheKey = cacheManager.getCache( url.region ).get( url.key );
		showKeyData = isDefined( "cacheKey" );
	}

	regions = cacheManager.getCacheNames();
</cfscript>

<head>
	<title>Scott's EhCache Manager</title>
	<style>
		td{padding: .5em 0 .5em 0;}
		tr:nth-child(even) {background-color: #f2f2f2;}
	</style>
</head>
<cfoutput>
	<h2>Cache Regions</h2>
	<ul>
		<cfloop array="#regions#" index="i">
			<li style="list-style-type: square"><a href="?region=#i#">#i#</a></li>
		</cfloop>
	</ul>
	
	<cfif showKeyData>
		<h2>Cache entries for #url.key# in #url.region# (Serialized Size: #cacheKey.getSerializedSize()# )</h2>
		<p><button onclick="window.location.href='manageCache.cfm?action=purge&region=#url.region#&key=#url.key#'">Purge</button></p>
		<p>Created: #EpochTimeToLocalDate( cacheKey.getCreationTime() / 1000 )#</p>
		<p>Time To Live: #cacheKey.getTimeToLive()#</p>
		<p>Time To Idle: #cacheKey.getTimeToIdle()#</p>
		<p>Hit Count: #cacheKey.getHitCount()#</p>
		Data:
		<cfdump var="#cacheKey.getvalue()#"/>
	<cfelseif showRegionData>
		<h2>#arrayLen(regionData)# Cache entries in #url.region# (sizes are relative)</h2>
		<cfset queryPurgeURL = right( url.region, 5) eq "QUERY" ? "purgeQueryCache" : "purgeRegion&region=" & url.region/>
		<span style="margin: 0 2em 0 0">
			<button onclick="window.location.href='manageCache.cfm?action=#queryPurgeURL#'">Purge #url.region#</button>
		</span>
		<span style="margin: 0 2em 0 0"><button onclick="window.location.href='manageCache.cfm?action=killRegion&region=#url.region#'">Kill #url.region#</button></span>
		<cfif isArray(regionData) and arrayLen(regionData) and isObject( regionData[1] )>
			<table cellpadding="5">
				<thead>
					<th width="50%">SQL</th>
					<th width="40%">Params</th>
					<th>UserName</th>
				</thead>
				<tbody>
					<cfloop index="r" array="#regionData#">
						<tr>
							<td>#r.getSQL()#</td>
							<td>
								<cfif isNull(r.getParamList())>
									&nbsp;
								<cfelse>
									#replace(r.getParamList().getWhere(), "] ,", "<br>", "all")#
								</cfif>
							</td>
							<td>#r.getUsername()#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		<cfelse>
			<table cellpadding="5">
				<thead>
					<th width="90%" style="text-align:left">Key</th>
					<th width="10%">Serialized Size</th>
				</thead>
				<tbody>
					<cfloop index="r" array="#regionData#">
						<cfset object = cacheManager.getCache( url.region ).get( r )/>
						<cfif not isNull( object )>
							<tr>
								<td><a href="?region=#url.region#&key=#r#">#r#</a></td>
								<td>#object.getSerializedSize()#</td>
							</tr>
						</cfif>
					</cfloop>
				</tbody>
			</table>
		</cfif>
	</cfif>
</cfoutput>
