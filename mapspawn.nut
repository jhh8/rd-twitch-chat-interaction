StringToFile( "chat_messages", "" );
::nMessageCount <- 0;
::ChatMessages_t <- "";

::COLOR_WHITE <- TextColor( 232, 232, 232 );
::COLOR_TWITCH <- TextColor( 169, 112, 255 );
::COLOR_TWITCH2 <- TextColor( 137, 79, 247 );

SendToServerConsole( "rd_lock_onslaught 1" );

hWorld <- Entities.FindByClassname( null, "worldspawn" );
hWorld.ValidateScriptScope();
hWorld.GetScriptScope()._Think <- function()
{
	Convars.SetValue( "asw_wanderer_override", 1 );
	Convars.SetValue( "asw_horde_override", 1 );
	Convars.SetValue( "asw_queen_has_damage_resistances", 0 );
	
	local hQueen = null;
	while ( hQueen = Entities.FindByClassname( hQueen, "asw_queen" ) )
		if ( hQueen.GetHealth() <= 0 )
			EntFireByHandle( hQueen, "Kill", "", 3.0, null, null );
	
	local strMessages = FileToString( "chat_messages" );
	if ( strMessages.len() == 0 )
		return 1.0;
		
	ChatMessages_t <- split( strMessages, "\n" );
	local nMessageCountReal = ChatMessages_t.len();
	
	if ( nMessageCountReal - nMessageCount == 0 )
		return 1.0;
	
	ParseMessages( nMessageCountReal - nMessageCount );
	
	nMessageCount <- nMessageCountReal;
	
	// file size limit 16KB :/
	if ( strMessages.len() > 15000 )
	{
		StringToFile( "chat_messages", "" );
		nMessageCount <- 0;
		ChatMessages_t <- "";
	}
	
	return 1.0;
}
hWorld.GetScriptScope().ParseMessages <- function( nAmount )
{
	for ( local i = nAmount; i > 0; i-- )
	{
		local strCallerName = split( ChatMessages_t[ ChatMessages_t.len() - i ], "" )[0];
		local strMessage = split( ChatMessages_t[ ChatMessages_t.len() - i ], "" )[1];

		local nMessageLen = strMessage.len();
		if ( nMessageLen >= 5 &&
			 strMessage[ nMessageLen - 1 ] == -128 &&
			 strMessage[ nMessageLen - 2 ] == -128 &&
			 strMessage[ nMessageLen - 3 ] == -96 && 
			 strMessage[ nMessageLen - 4 ] == -13 &&
			 strMessage[ nMessageLen - 5 ] == 32 )
		{
			// bitch symbol detected! twitch adds space + these 4 bytes to end of messages which are repeated for some reason
			strMessage = strMessage.slice( 0, nMessageLen - 5 );
		}
		
		strMessage = rstrip( strMessage );
		
		// uncomment at your own caution
		//EntFireByHandle( self, "RunScriptCode", "try{" + strMessage + "}catch(err){}", 0.0, null, null );
		
		if ( nMessageLen > 127 )
			strMessage = strMessage.slice( 0, 127 );
			
		if ( strMessage in ChatCommands_t )
			ChatCommands_t[ strMessage ]( strCallerName );
		else
			ClientPrint( null, 3, "%s2[%s1TWITCH%s2] %s1%s3%s2: %s4", COLOR_TWITCH, COLOR_WHITE, strCallerName, strMessage );
	}
}

AddThinkToEnt( hWorld, "_Think" );

function GetRandomInhabitedMarine( hExclude = null )
{
	local Marines_t = [];
	local hMarine = null;
	while ( hMarine = Entities.FindByClassname( hMarine, "asw_marine" ) )
		if ( hMarine.IsInhabited() && hMarine != hExclude )
			Marines_t.push( hMarine );
			
	if ( Marines_t.len() == 0 )
		return null;
		
	return Marines_t[ RandomInt( 0, Marines_t.len() - 1 ) ];
}

function GetRandomMarine( hExclude = null )
{
	// prioritise non-bots
	local hMarine = GetRandomInhabitedMarine( hExclude );
	if ( hMarine )
		return hMarine;
	
	local Marines_t = [];
	while ( hMarine = Entities.FindByClassname( hMarine, "asw_marine" ) )
		if ( hMarine != hExclude )
			Marines_t.push( hMarine );
			
	if ( Marines_t.len() == 0 )
		return null;
		
	return Marines_t[ RandomInt( 0, Marines_t.len() - 1 ) ];
}

function SpawnHorde( strCallerName )
{
	Director.SpawnHordeSoon();
	
	// "Soon" isnt fast enough, forced onslaught it is
	//Convars.SetValue( "asw_horde_override", 1 );
	//Director.SpawnHordeSoon();
	//EntFireByHandle( Entities.First(), "RunScriptCode", "Convars.SetValue( \"asw_horde_override\", 0 );", 0.9, null, null );
	
	if ( Convars.GetStr( "asw_wanderer_override" ) == "0" )
		ClientPrint( null, 3, COLOR_TWITCH2 + strCallerName + COLOR_TWITCH + " tried spawning a horde but onslaught is disabled!" );
	else
		ClientPrint( null, 3, COLOR_TWITCH2 + strCallerName + COLOR_TWITCH + " spawned a horde!" );
}

function ScreenFreeze( strCallerName )
{
	local hMarine = GetRandomMarine();
	if ( !hMarine )
		return;
		
	local strVictimName = hMarine.IsInhabited() ? hMarine.GetCommander().GetPlayerName() : hMarine.GetMarineName();
		
	DropFreezeGrenade( 0.0, 3.0, 512.0, hMarine.GetOrigin() + Vector( 0.0, 0.0, 128.0 ) );

	ClientPrint( null, 3, COLOR_TWITCH2 + strCallerName + COLOR_TWITCH + " screen froze " + COLOR_TWITCH2 + strVictimName + COLOR_TWITCH + "!" );
}

PARTICLE_FLAREBOMB_WARNING_NAME <- "Adanaxis_portal_noedge";
PARTICLE_FLAREBOMB_WARNING_NAME2 <- "mortar_grenade_main_trail";
PARTICLE_FLAREBOMB_EXPLOSION <- "explosion_huge_e";
PARTICLE_FLAREBOMB_EXPLOSION2 <- "smoke_breakwall_1";
SOUND_FLAREBOMB_EXPLOSION <- "swarm/gameeffects/minewarheadexplosion.wav";

Entities.First().PrecacheModel( "models/swarmprops/techdeco/rocketmesh/rocketmesh_new.mdl" );
Entities.First().PrecacheSoundScript( "ambient/fire/firebig.wav" );
Entities.First().PrecacheSoundScript( SOUND_FLAREBOMB_EXPLOSION );
PrecacheParticleSystem( PARTICLE_FLAREBOMB_WARNING_NAME );
PrecacheParticleSystem( PARTICLE_FLAREBOMB_WARNING_NAME2 );
PrecacheParticleSystem( PARTICLE_FLAREBOMB_EXPLOSION );
PrecacheParticleSystem( PARTICLE_FLAREBOMB_EXPLOSION2 );

function DropNuke( strCallerName )
{
	local hMarine = GetRandomMarine();
	if ( !hMarine )
		return;
		
	local strVictimName = hMarine.IsInhabited() ? hMarine.GetCommander().GetPlayerName() : hMarine.GetMarineName();
	
	local fBombSpeed = 1024.0;
	local fBombDropTime = 4.0;
				
// func movelinear that moves the bomb towards the ground
	local hMover = Entities.CreateByClassname( "func_movelinear" );
	hMover.__KeyValueFromInt( "spawnflags", 8 );
	hMover.Spawn();
	hMover.Activate();
	hMover.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, fBombSpeed * fBombDropTime ) );
	NetProps.SetPropFloat( hMover, "m_flSpeed", fBombSpeed );
	NetProps.SetPropVector( hMover, "m_vecPosition2", hMarine.GetOrigin() - Vector( 0.0, 0.0, 96.0 ) );
	EntFireByHandle( hMover, "Open", "", 0.0, null, null );
	EntFireByHandle( hMover, "KillHierarchy", "", fBombDropTime - 0.02, null, null );
	
// the bomb prop
	local hBombProp = Entities.CreateByClassname( "prop_dynamic" );
	hBombProp.__KeyValueFromString( "model", "models/swarmprops/techdeco/rocketmesh/rocketmesh_new.mdl" );
	hBombProp.__KeyValueFromInt( "solid", 0 );
	hBombProp.SetOrigin( hMover.GetOrigin() );
	hBombProp.SetAngles( 0, 0, 90 );
	hBombProp.SetParent( hMover );
	hBombProp.Spawn();
	hBombProp.Activate();
	
// particles that warn about bomb incoming
	local hParticlesWarning = Entities.CreateByClassname( "info_particle_system" );
	hParticlesWarning.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, 32.0 ) );
	hParticlesWarning.__KeyValueFromInt( "start_active", 1 );
	hParticlesWarning.__KeyValueFromString( "effect_name", PARTICLE_FLAREBOMB_WARNING_NAME );
	hParticlesWarning.Spawn();
	hParticlesWarning.Activate();
	EntFireByHandle( hParticlesWarning, "Kill", "", fBombDropTime, null, null );

	local hParticlesWarning2 = Entities.CreateByClassname( "info_particle_system" );
	hParticlesWarning2.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, 64.0 ) );
	hParticlesWarning2.__KeyValueFromInt( "start_active", 1 );
	hParticlesWarning2.__KeyValueFromString( "effect_name", PARTICLE_FLAREBOMB_WARNING_NAME2 );
	hParticlesWarning2.Spawn();
	hParticlesWarning2.Activate();
	EntFireByHandle( hParticlesWarning2, "Kill", "", fBombDropTime, null, null );
	
// particles of the explosion itself
	local hParticlesExp = Entities.CreateByClassname( "info_particle_system" );
	hParticlesExp.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, 64.0 ) );
	hParticlesExp.__KeyValueFromInt( "start_active", 0 );
	hParticlesExp.__KeyValueFromString( "effect_name", PARTICLE_FLAREBOMB_EXPLOSION );
	hParticlesExp.Spawn();
	hParticlesExp.Activate();
	EntFireByHandle( hParticlesExp, "Start", "", fBombDropTime, null, null );
	EntFireByHandle( hParticlesExp, "Kill", "", fBombDropTime + 1.0, null, null );
	
	local hParticlesExp2 = Entities.CreateByClassname( "info_particle_system" );
	hParticlesExp2.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, 64.0 ) );
	hParticlesExp2.__KeyValueFromInt( "start_active", 0 );
	hParticlesExp2.__KeyValueFromString( "effect_name", PARTICLE_FLAREBOMB_EXPLOSION2 );
	hParticlesExp2.Spawn();
	hParticlesExp2.Activate();
	EntFireByHandle( hParticlesExp2, "Start", "", fBombDropTime, null, null );
	EntFireByHandle( hParticlesExp2, "Kill", "", fBombDropTime + 1.0, null, null );
	
// sound of the explosion
	local hSound = Entities.CreateByClassname( "asw_ambient_generic" );
	hSound.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, 256.0 ) );
	hSound.__KeyValueFromInt( "health", 50 );
	hSound.__KeyValueFromInt( "pitch", 100 );
	hSound.__KeyValueFromInt( "pitchstart", 100 );
	hSound.__KeyValueFromInt( "radius", 25000 );
	hSound.__KeyValueFromInt( "spawnflags", 48 );
	hSound.__KeyValueFromString( "message", SOUND_FLAREBOMB_EXPLOSION );
	hSound.Spawn();
	hSound.Activate();
	EntFireByHandle( hSound, "PlaySound", "", 0, null, null );
	EntFireByHandle( hSound, "Kill", "", fBombDropTime + 1.0, null, null );

// fire after drop
	local hAfterFire = Entities.CreateByClassname( "env_fire" );
	hAfterFire.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, 4.0 ) );
	NetProps.SetPropFloat( hAfterFire, "m_flHeatLevel", 1000.0 );
	hAfterFire.__KeyValueFromInt( "firesize", 112 );
	hAfterFire.__KeyValueFromInt( "StartDisabled", 1 );
	hAfterFire.__KeyValueFromInt( "spawnflags", 521 );
	hAfterFire.Spawn();
	hAfterFire.Activate();
	EntFireByHandle( hAfterFire, "Enable", "", fBombDropTime, null, null );
	EntFireByHandle( hAfterFire, "StartFire", "", fBombDropTime, null, null );
	
	// this took me so long to figure out, WTF!
	EntFireByHandle( hAfterFire, "RunScriptCode", "self.ClearParent()", fBombDropTime + 5.0, null, null );

// explosion damage
	local hExplosionDamage = Entities.CreateByClassname( "env_physexplosion" );
	hExplosionDamage.SetOrigin( hMarine.GetOrigin() + Vector( 0.0, 0.0, 32.0 ) );
	hExplosionDamage.__KeyValueFromInt( "magnitude", 160 );
	hExplosionDamage.SetName( "flarebomb_damage" );
	hExplosionDamage.Spawn();
	hExplosionDamage.Activate;
	EntFireByHandle( hExplosionDamage, "Explode", "", fBombDropTime, null, null );
	EntFireByHandle( hExplosionDamage, "Kill", "", fBombDropTime + 1.0, null, null );
	
	ClientPrint( null, 3, COLOR_TWITCH2 + strCallerName + COLOR_TWITCH + " dropped a nuke on " + COLOR_TWITCH2 + strVictimName + COLOR_TWITCH + "!" );
}

// first element in array is weight (chance to be picked), 
// second is how many to spawn, 
// third is name used in spawn chat message, 
// fourth is size of the alien (for finding valid spawn point)
RandomAliens_t <- 
{
	asw_drone = [ 20, 5, "drones", 24.0 ],
	asw_boomer = [ 10, 2, "boomers", 32.0 ],
	asw_shieldbug = [ 10, 2, "shieldbugs", 48.0 ],
	asw_buzzer = [ 10, 5, "buzzers", 6.0 ],
	asw_ranger = [ 10, 3, "rangers", 24.0 ],
	asw_mortarbug = [ 10, 2, "mortarbugs", 40.0 ],
	asw_queen = [ 2, 1, "QUEEN", 80.0 ]
}

function SpawnRandomAlien( strCallerName )
{
	local nTotalWeight = 0;
	foreach( key, value in RandomAliens_t )
		nTotalWeight += value[0];
		
	local nRand = RandomInt( 0, nTotalWeight );
	
	local strAlien = "";
	local strAlienOfficialName = "";
	local nCount = 0;
	local fHullSize = 1.0;
	foreach( key, value in RandomAliens_t )
	{
		if ( nRand > value[0] )
		{
			nRand -= value[0];
			continue;
		}
		
		strAlien = key;
		nCount = value[1];
		strAlienOfficialName = value[2];
		fHullSize = value[3];
		
		break;
	}
	
	// spawn alien auto sucks and boofs :( ;)
	//for ( local i = 0; i < nCount; i++ )
	//	Director.SpawnAlienAuto( strAlien );
	
	local hMarine = GetRandomMarine();
	if ( !hMarine )
		return;
	
	local NodesSpawnCandidate_t = [];
	local Nodes_t = {};
	InfoNodes.GetAllNodes( Nodes_t );
	foreach ( key, value in Nodes_t )
	{
		local nNodeID = key.slice(4).tointeger();
		if ( strAlien != "asw_buzzer" && InfoNodes.GetNodeType( nNodeID ) != NODE_GROUND )
			continue;
		
		local hNearestMarine = Entities.FindByClassnameNearest( "asw_marine", value.GetOrigin(), 1200.0 );
		local fDist = hNearestMarine ? sqrt( ( hNearestMarine.GetOrigin() - value.GetOrigin() ).LengthSqr() ) : 10000.0;
		if ( fDist >= 256.0 && fDist <= 1200.0 )
			NodesSpawnCandidate_t.push( value );
	}
	
	if ( NodesSpawnCandidate_t.len() == 0 )
		return;
	
	local nSpawned = 0;
	for ( local i = 0; i < nCount; i++ )
	{
		if ( NodesSpawnCandidate_t.len() == 0 )
			break;
		
		local nRand = RandomInt( 0, NodesSpawnCandidate_t.len() - 1 );
		local hNode = NodesSpawnCandidate_t.remove( nRand );
		local hSpawn = null;
		if ( Director.ValidSpawnPoint( hNode.GetOrigin(), Vector( -fHullSize, -fHullSize, 0.0 ), Vector( fHullSize, fHullSize, fHullSize ) ) )
		{
			hSpawn = Director.SpawnAlienAt( strAlien, hNode.GetOrigin(), Vector( 0, RandomInt( 0, 359 ), 0 ) )
			if ( hSpawn.GetClassname() == "asw_queen" )
				EntFireByHandle( hSpawn, "AddOutput", "modelscale 0.65", 0.0, null, null );
			
			nSpawned += 1;
		}
		else
		{
			i--;
		}
	}
		
	ClientPrint( null, 3, COLOR_TWITCH2 + strCallerName + COLOR_TWITCH + " spawned " + COLOR_TWITCH2 + nSpawned.tostring() + " " + strAlienOfficialName + COLOR_TWITCH + "!" );
}

function MarineSwap( strCallerName )
{
	local Players_t = [];
	local hPlayer = null;
	while ( hPlayer = Entities.FindByClassname( hPlayer, "player" ) )
		if ( hPlayer.GetMarine() )
			Players_t.push( hPlayer );
		
	if ( Players_t.len() == 0 )
		return;
	
	local strVictimName1 = "";
	local strVictimName2 = "";
	
	if ( Players_t.len() == 1 )
	{
		strVictimName1 = Players_t[0].GetPlayerName();
		
		local hNewMarine = GetRandomMarine( Players_t[0].GetMarine() );
		strVictimName2 = hNewMarine.GetMarineName();
		
		Players_t[0].SetNPC( hNewMarine );
	}
	else
	{
		local nRand1 = RandomInt( 0, Players_t.len() - 1 );
		local hVictim1 = Players_t.remove( nRand1 );
		strVictimName1 = hVictim1.GetPlayerName();
		
		local nRand2 = RandomInt( 0, Players_t.len() - 1 );
		local hVictim2 = Players_t.remove( nRand2 );
		strVictimName2 = hVictim2.GetPlayerName();
		
		local hVictim1MarineBefore = hVictim1.GetMarine();
		
		hVictim1.SetNPC( hVictim2.GetMarine() );
		hVictim2.SetNPC( hVictim1MarineBefore );
	}
	
	ClientPrint( null, 3, COLOR_TWITCH2 + strCallerName + COLOR_TWITCH + " swapped the marines of " + COLOR_TWITCH2 + strVictimName1 + COLOR_TWITCH + " and " + COLOR_TWITCH2 + strVictimName2 + COLOR_TWITCH + "!" );
}

::ChatCommands_t <- {};
ChatCommands_t["spawnhorde"] <- SpawnHorde;
ChatCommands_t["spawnhordes"] <- SpawnHorde;
ChatCommands_t["screenfreeze"] <- ScreenFreeze;
ChatCommands_t["dropnuke"] <- DropNuke;
ChatCommands_t["dropbomb"] <- DropNuke;
ChatCommands_t["spawnrandomalien"] <- SpawnRandomAlien;
ChatCommands_t["spawnrandomaliens"] <- SpawnRandomAlien;
ChatCommands_t["marineswap"] <- MarineSwap;

function OnTakeDamage_Alive_Any( victim, inflictor, attacker, weapon, damage, damageType, ammoName )
{
	if ( attacker && attacker.GetName() == "flarebomb_damage" )
	{
		if ( !victim )
			return damage;
			
		if ( victim.IsAlien() )
			return 10000;
			
		if ( victim.GetClassname() == "asw_marine" )
		{
			if ( damage > 60 )
			{
				victim.SetHealth( 1 );
				return 150;
			}
				
			if ( damage < 10 )
				return 0;
				
			return damage * 2;
		}
	}
	
	return damage;
}

