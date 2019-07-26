<head>
	<title>Scott's EhCache Manager</title>
</head>
<cfscript>
function EpochTimeToLocalDate( epoch ) {
  return dateTimeFormat( DateAdd( "s",epoch,DateConvert( "utc2Local", "January 1 1970 00:00" ) ) );
}

cacheManager = createObject( "java", "net.sf.ehcache.CacheManager" ).getInstance();

if( structKeyExists( url, "purgeQueryCache" ) ){
	cfobjectcache( action="clear" );
}
if( structKeyExists( url, "purge" ) ){
	cacheManager.getCache( url.region ).remove( url.key );
	structDelete( url, "purge" );
}
if( structKeyExists( url, "purgeRegion" ) ){
	cacheManager.getCache( url.region ).removeAll();
	structDelete( url, "purgeRegion" );
}
if( structKeyExists( url, "killRegion" ) ){
	cacheManager.removeCache( url.region );
	structDelete( url, "killRegion" );
	structDelete( url, "region" );
}
if( structKeyExists( url, "region" ) ){
	regionData = cacheManager.getCache( url.region ).getKeys(  );
}
if( structKeyExists( url, "key" ) ){
	cacheKey = cacheManager.getCache( url.region ).get( url.key );
	if(  isDefined( "cacheKey" )  ){
		keyData['data'] = isDefined( "cacheKey" ) ? cacheKey.getvalue(  ) : javacast( "null", "" );
		keydata['Created'] = EpochTimeToLocalDate( cacheKey.getCreationTime(  ) / 1000 );
		keyData['TTL'] = cacheKey.getTimeToLive();
		keyData['TTI'] = cacheKey.getTimeToIdle();
		keyData['Hitcount'] = cacheKey.getHitCount();
	}
}
regions = cacheManager.getCacheNames(  );
</cfscript>
<cfoutput>
	<h2>Cache Regions</h2>
	<ul>
		<cfloop array="#regions#" index="i">
			<li><a href="?region=#i#">#i#</a></li>
		</cfloop>
	</ul>
	<cfif isdefined( "regionData" ) and not isDefined( "keyData" )>
		<h2>Cache entries in #url.region# (sizes are relative)</h2>
		<a href="manageCache.cfm?purgeRegion&region=#url.region#">Purge this Region</a>
		<a href="manageCache.cfm?killRegion&region=#url.region#">Kill this Region</a>
		<cfif right( url.region, 5) eq "QUERY">
			<button onclick="window.location.href='manageCache.cfm?purgeQueryCache'">Purge Query Cache</button>
		</cfif>
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
			<ul>
			</ul>
		<cfelse>
			<ul>
				<cfloop index="r" array="#regionData#">
					<cfset object = cacheManager.getCache( url.region ).get( r )/>
					<cfif not isNull( object )>
						<cfset size = object.getSerializedSize()/>
						<li><a href="?region=#url.region#&key=#r#">#r# ( #numberFormat(size, "9,999,999")# )</a></li>
					</cfif>
				</cfloop>
			</ul>
		</cfif>
	</cfif>
	<cfif isDefined( "keyData" )>
		<h2>Cache entries for #url.key# in #url.region# (Serialized Size: #cacheKey.getSerializedSize()# )- <a href="?purge&region=#url.region#&key=#url.key#">Purge</a></h2>
		<cfloop collection="#keydata#" item="key">
			<cfif key neq "data">
				<p>#key#: #keyData[key]#</p>
			</cfif>
		</cfloop>
		<cfdump var="#keydata.data#"/>
	</cfif>
</cfoutput>
