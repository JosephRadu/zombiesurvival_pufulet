hook.Add( 'Initialize', 'noSQL', function()
	util.AddNetworkString( "sendplayerdata" )
	
	if ( !file.IsDir("noSQL","DATA") ) then
		file.CreateDir("noSQL")
	end 
end )

function GM:PlayerUnlockItem(pl,item)
	GAMEMODE:SaveData(pl)
	GAMEMODE:SendPlayerData(pl)
end

function GM:SendPlayerData(pl)
	net.Start( "sendplayerdata" )
		net.WriteFloat(pl.XP_Commando)
		net.WriteFloat(pl.XP_Engineer)
		net.WriteFloat(pl.XP_Support)
		net.WriteFloat(pl.XP_Berserker)
		net.WriteTable(pl.Items)
		net.WriteTable(pl.Resources)
	net.Send(pl)
end

//So this shit exists, but does it for the player?
hook.Add( 'PlayerInitialSpawn', 'noSQL Read Data', function( pl )
	GAMEMODE:ReadData( pl )
end )

//Empty data here :v
function GM:GetBlankStats( pl )
	local data = {
		[ 'playername' ] = pl:Nick(),
		[ 'steamid' ] = pl:SteamID(),
		[ 'playtime' ] = 0,
		[ 'items' ] = {},
		[ 'xp' ] = 
			{
				[ 'commando' ] = 0,
				[ 'support' ] = 0,
				[ 'engineer' ] = 0,
				[ 'berserker' ] = 0
			},
		[ 'resources' ] = 
			{
				[ 'bones' ] = 0,
				[ 'ichor' ] = 0,
				[ 'undeath' ] = 0,		
				[ 'scrap' ] = 20					
			}
		
		--[ 'scrap' ] = 20
		--[ 'points' ] = 0
	}

	pl.XP_Commando = 0
	pl.XP_Support = 0
	pl.XP_Engineer = 0
	pl.XP_Berserker = 0
	pl.Resources = {
		[ 'bones' ] = 0,
		[ 'ichor' ] = 0,
		[ 'undeath' ] = 0,	
		[ 'scrap' ] = 20			
	}	

	return data
end

function GM:WriteBlank( pl )

	local path = "noSQL/player_"..string.Replace( string.sub( pl:SteamID(), 1 ), ":", "-" )..".txt"
	local data = util.TableToJSON( self:GetBlankStats( pl ) )

	file.Write( path, data )

end

function GM:ReadData( pl )
	local path = "noSQL/player_"..string.Replace( string.sub( pl:SteamID(), 1 ), ":", "-" )..".txt"
	if ( !file.Exists( path , "DATA") ) then
		GAMEMODE:WriteBlank( pl )
		for _, v in pairs( player.GetAll() ) do 
			if IsValid( v ) then
				v:ChatPrint( "Welcome "..pl:Nick().." as they have joined for the first time!" )
			end
		end
	end
	fileData = util.JSONToTable( file.Read( path ) )
	pl.DataTable = table.Copy( fileData )
	pl.Resources = {}
	for k, v in pairs( pl.DataTable ) do
		if( k == 'items' ) then
			pl.Items = v
		end
		if ( k == 'playtime' ) then
			pl.PlayTime = v
		end
		if ( k == 'xp' ) then
			for p, j in pairs( v ) do
				if( p == 'commando' ) then
					pl.XP_Commando = j
				end
				if ( p == 'support' ) then
					pl.XP_Support = j
				end
				if ( p == 'engineer' ) then
					pl.XP_Engineer = j
				end
				if ( p == 'berserker' ) then
					pl.XP_Berserker = j
				end
			end
		end
		if ( k == 'resources' ) then
			for p, j in pairs( v ) do
				if( p == 'bones' ) then
					pl.Resources[ 'bones' ] = j
				end		
				if( p == 'ichor' ) then
					pl.Resources[ 'ichor' ] = j
				end
				if( p == 'undeath' ) then
					pl.Resources[ 'undeath' ] = j
				end		
				if( p == 'scrap' ) then
					pl.Resources[ 'scrap' ] = j
				end					
			end
		end
		--if ( k == 'points' ) then
		--	pl:SetPoints(v)
		--end		
	end
	
	GAMEMODE:SendPlayerData(pl)
	
end

function GM:SaveData( pl )
	local path = "noSQL/player_"..string.Replace( string.sub( pl:SteamID(), 1 ), ":", "-" )..".txt"
		local data = {
			[ 'playername' ] = pl:Nick(),
			[ 'steamid' ] = pl:SteamID(),
			[ 'playtime' ] = 0,
			[ 'items' ] = pl:GetItems(),
			[ 'xp' ] = 
				{
					[ 'commando' ] = pl:GetXPCommando(),
					[ 'support' ] = pl:GetXPSupport(),
					[ 'engineer' ] = pl:GetXPEngineer(),
					[ 'berserker' ] = pl:GetXPBerserker()
				},
			[ 'resources' ] = 
				{
					[ 'bones' ] = pl:GetResource('bones'),
					[ 'ichor' ] = pl:GetResource('ichor'),
					[ 'undeath' ] = pl:GetResource('undeath'),				
					[ 'scrap' ] = pl:GetResource('scrap')						
				},	
			[ 'points' ] = pl:GetPoints()			
		}
	local newData =  util.TableToJSON( data )
	file.Write( path, newData )
end

function GM:GetTableLength( dbTable )
	local count = 0
		for k, v in pairs( dbTable ) do
			count = count + 1
		end
	if ( count > 1 ) then
		return true
	end
	return false
end

concommand.Add( 'testDB', function( pl, cmd, args )
	for k, v in pairs( player.GetAll() ) do
		if ( !IsValid( v ) ) then continue end
		if ( v:Nick() == args[ 1 ] ) then
			local path = "noSQL/player_"..string.Replace( string.sub( pl:SteamID(), 1 ), ":", "-" )..".txt"
				PrintTable( util.JSONToTable( file.Read( path ) ) )
			break;
		end
	end

end )

concommand.Add( "unlockitem", function( pl, cmd, args )
	
	if string.match(args[1],"commando") then
		if tonumber(args[2]) > pl:GetXPCommando() then
			return
		else
			pl:GiveXP(tonumber(args[2]) * -1, "Skirmisher")
		end
	elseif string.match(args[1],"support") then
		if tonumber(args[2]) > pl:GetXPSupport() then
			return
		else
			pl:GiveXP(tonumber(args[2]) * -1, "Carpenter")
		end
	elseif string.match(args[1],"berserker") then
		if tonumber(args[2]) > pl:GetXPBerserker() then
			return
		else
			pl:GiveXP(tonumber(args[2]) * -1, "Berserker")
		end
	elseif string.match(args[1],"rogue") then
		if tonumber(args[2]) > pl:GetXPEngineer() then
			return
		else
			pl:GiveXP(tonumber(args[2]) * -1, "Rogue")
		end		
	end

	pl:UnlockItem(args[ 1 ])
	GAMEMODE:SaveData(pl)
end )

concommand.Add( "unlockresourceitem", function( pl, cmd, args )
	local item
	for i, tab in pairs(GAMEMODE.ClassItems) do
		if tab.Signature == args[1] then
			item = tab
			PrintTable(tab)
			
			break
		end
	end

	for k, v in pairs (item.Resources) do
		if (v > pl:GetResource(k)) then
			return
		end
	end
	
	for k, v in pairs (item.Resources) do
		pl:GiveResource(k, (v * -1))
	end	

	pl:UnlockItem(args[ 1 ])
	GAMEMODE:SaveData(pl)
	return true
end )

concommand.Add( "givexp", function( pl, cmd, args )
	if( args[ 1 ] && IsValid( pl ) ) then
		pl:GiveXP( tonumber( args[ 1 ] ) )
	end
end )

concommand.Add( "readfile", function( pl )
	GAMEMODE:ReadData( pl )
end )

concommand.Add( "saveData", function( pl )
	GAMEMODE:SaveData( pl )
end )

concommand.Add( "setClass", function( pl, cmd, args )
	for k,v in pairs(GAMEMODE.Classes) do	
		if string.lower(v) == args[1] or tonumber(k) == tonumber(args[1]) then
			pl:SetClass(GAMEMODE.Classes[k])
			print("YOUR CLASS IS: " .. (pl:GetClass()))
			break;
		end
	end
end )

concommand.Add( "givescrap", function( pl, cmd, args )
	if( args[ 1 ] && IsValid( pl ) ) then
		pl:GiveScrap( tonumber( args[ 1 ] ) )
	end
end )

concommand.Add("giveresource", function(pl, cmd, args )
	if (args[2] != nil) then
		pl:GiveResource(args[1],args[2])
	else
		pl:GiveResource(args[1])
	end
end )

concommand.Add( "getclassxp", function( pl )
	pl:GetClassXP()
end )

concommand.Add( "cashout", function( pl )
	pl:GiveXP(math.floor(pl:GetPoints() / 20))
	pl:TakePoints(pl:GetPoints())
end )

