require( 'util/timers' )

if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
	-- For all the models to show up dynamically, they have to be precached here
	PrecacheResource( "model_folder", "models/items", context )
 	PrecacheResource( "model_folder", "models/heroes", context ) 
	PrecacheResource( "model", "models/development/invisiblebox.vmdl", context )
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CAddonTemplateGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CAddonTemplateGameMode:InitGameMode()
	-- Load KV model file
	self:_ReadModelLookup()
	
	-- Set GameRules
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	GameRules:SetTreeRegrowTime( 15.0 )
	
	-- Set GameMode
	local mode = GameRules:GetGameModeEntity()
	mode:SetCameraDistanceOverride( 1150 )
	mode:SetFixedRespawnTime( 5.0 )
	
	-- This line is very important, has to be included.
	SendToServerConsole( "dota_combine_models 0" )
	
	-- Listen to Game Event
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CAddonTemplateGameMode, "OnUnitSpawned" ), self )
	
	-- Custom command
	Convars:RegisterCommand( "fow_enable", function( cmd, p )						-- Set fog of war
			local option = tonumber( p )
			if option == 0 then
				GameRules:GetGameModeEntity():SetFogOfWarDisabled( true )
			elseif option == 1 then
				GameRules:GetGameModeEntity():SetFogOfWarDisabled( false )
			else
				print( "Custom Command - fow_enable: Input can only be 0 or 1." )
			end
		end, "Enable or disable fog of war", 0
	)
	Convars:RegisterCommand( "zoom", function( cmd, d )								-- Set camera distance
			local distance = tonumber( d )
			if distance < 750 then
				print( "Custom Command - zoom: Distance cannot be lowered than 750." )
				distance = 750
			end
			GameRules:GetGameModeEntity():SetCameraDistanceOverride( distance )
		end, "Set camera distance", 0
	)
	Convars:RegisterCommand( "swap_cosmetic", function( cmd, toReplace, toSwap )	-- Swap the cosmetic
			if toReplace and toSwap then
				return self:SwapCosmetic( Convars:GetCommandClient(), toReplace, toSwap )
			end
		end, "Swap cosmetic", 0
	)
	Convars:RegisterCommand( "list_cosmetic", function( ... )						-- List all cosmetics this unit current equipped
			return self:ListCosmetics( Convars:GetCommandClient() )
		end, "List cosmetics", 0
	)
	Convars:RegisterCommand( "list_available_cosmetic", function( ... )				-- List all available cosmetics for this unit
			return self:ListAvailableCosmetics( Convars:GetCommandClient() )
		end, "List available cosmetics", 0
	)
	Convars:RegisterCommand( "cosmetic_default", function( ... )					-- Revert to default cosmetics
			return self:DefaultCosmetics( Convars:GetCommandClient() )
		end, "Revert all cosmetics to default", 0
	)
	Convars:RegisterCommand( "set_animation", function( cmd, p )
			return self:SetAnimation( Convars:GetCommandClient(), p )
		end, "Force animation onto unit", 0
	)
end

-- Evaluate the state of the game
function CAddonTemplateGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end

-- Read all model from lookup file
function CAddonTemplateGameMode:_ReadModelLookup()
	local kv = LoadKeyValues( "scripts/maps/model_lookup.txt" )
	self.model_lookup = kv or {}
end

-- List all available cosmetics for this hero
function CAddonTemplateGameMode:ListAvailableCosmetics( cmdPlayer )
	local hero = cmdPlayer:GetAssignedHero()
	local hero_name = string.gsub( hero:GetName(), "npc_dota_hero_", "" )
	hero_name = string.lower( hero_name )
	print( "\nThis is the available cosmetics for hero: " .. hero_name )
	local lookup = {}
	
	if hero_name == "vengefulspirit" then
		table.insert( lookup, hero_name )
		table.insert( lookup, "vengeful" )
	elseif hero_name == "life_stealer" then
		table.insert( lookup, hero_name )
		table.insert( lookup, "lifestealer" )
	elseif hero_name == "tiny" then
		table.insert( lookup, hero_name )
		table.insert( lookup, "tiny_01" )
		table.insert( lookup, "tiny_02" )
		table.insert( lookup, "tiny_03" )
		table.insert( lookup, "tiny_04" )
	elseif hero_name == "doom_bringer" then
		table.insert( lookup, "doom" )
	elseif hero_name == "drow_ranger" then
		table.insert( lookup, "drow" )
	elseif hero_name == "templar_assassin" then
		table.insert( lookup, "lanaya" )
	elseif hero_name == "naga_siren" then
		table.insert( lookup, "siren" )
	elseif hero_name == "nyx_assassin" then
		table.insert( lookup, "nerubian_assassin" )
	elseif hero_name == "riki" then
		table.insert( lookup, "rikimaru" )
	elseif hero_name == "shadow_shaman" then
		table.insert( lookup, "shadowshaman" )
	elseif hero_name == "tusk" then
		table.insert( lookup, "tuskarr" )
	elseif hero_name == "witch_doctor" then
		table.insert( lookup, "witchdoctor" )
	elseif hero_name == "skeleton_king" then
		table.insert( lookup, hero_name )
		table.insert( lookup, "wraith_king" )
	else
		table.insert( lookup, hero_name )
	end
	
	for _, name in pairs( lookup ) do
		if self.model_lookup[ name ] ~= nil then
			for k, v in pairs( self.model_lookup[ name ] ) do
				print( v )
			end	
		end
	end
	print( "" )
end

-- List current cosmetic
function CAddonTemplateGameMode:ListCosmetics( cmdPlayer )
	local hero = cmdPlayer:GetAssignedHero()
	local wearable = hero:FirstMoveChild()
	
	print( "\nCurrent hero: " .. hero:GetName() )
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" then
			print( "Current cosmetic: " .. wearable:GetModelName() )
		end
		wearable = wearable:NextMovePeer()
	end
	print( "" )
end

-- Swap cosmetic
function CAddonTemplateGameMode:SwapCosmetic( cmdPlayer, toReplace, toSwap )
	local hero = cmdPlayer:GetAssignedHero()
	
	local wearable = hero:FirstMoveChild()
	
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" and hero.default_cosmetics[ toReplace ] == wearable then
			wearable:SetModel( toSwap )
			print( "\nSuccessfully swap " .. toReplace .. " with " .. toSwap )
			print( "Warning: This does not guarantee that the model will merge successfully.\n" )
			break
		end
		wearable = wearable:NextMovePeer()
	end
end

-- Revert all changes to default
function CAddonTemplateGameMode:DefaultCosmetics( cmdPlayer )
	local hero = cmdPlayer:GetAssignedHero()
	local wearable = hero:FirstMoveChild()
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" then
			for k, v in pairs( hero.default_cosmetics ) do
				if v == wearable then
					wearable:SetModel( k )
					break
				end
			end
		end
		wearable = wearable:NextMovePeer()
	end
end

-- Remove all currently playing animation
function CAddonTemplateGameMode:_RemoveAllAnimation( unit )
	self:_SafeRemoveModifier( unit, "modifier_animation_idle" )
	self:_SafeRemoveModifier( unit, "modifier_animation_run" )
	self:_SafeRemoveModifier( unit, "modifier_animation_die" )
	self:_SafeRemoveModifier( unit, "modifier_animation_flail" )
	self:_SafeRemoveModifier( unit, "modifier_animation_spawn" )
	self:_SafeRemoveModifier( unit, "modifier_animation_victory" )
	self:_SafeRemoveModifier( unit, "modifier_animation_defeat" )
	self:_SafeRemoveModifier( unit, "modifier_animation_disabled" )
	self:_SafeRemoveModifier( unit, "modifier_animation_attack_1" )
	self:_SafeRemoveModifier( unit, "modifier_animation_attack_2" )
	self:_SafeRemoveModifier( unit, "modifier_animation_ability_1" )
	self:_SafeRemoveModifier( unit, "modifier_animation_ability_2" )
	self:_SafeRemoveModifier( unit, "modifier_animation_ability_3" )
	self:_SafeRemoveModifier( unit, "modifier_animation_ability_4" )
	self:_SafeRemoveModifier( unit, "modifier_animation_channel_ability_1" )
	self:_SafeRemoveModifier( unit, "modifier_animation_channel_ability_2" )
	self:_SafeRemoveModifier( unit, "modifier_animation_channel_ability_3" )
	self:_SafeRemoveModifier( unit, "modifier_animation_channel_ability_4" )
end

-- Safely remove modifier
function CAddonTemplateGameMode:_SafeRemoveModifier( unit, modifier_name )
	if unit:HasModifier( modifier_name ) then
		unit:RemoveModifierByName( modifier_name )
	end
end

-- Set animation for model
function CAddonTemplateGameMode:SetAnimation( cmdPlayer, action )
	local hero = cmdPlayer:GetAssignedHero()
	self:_RemoveAllAnimation( hero );
	Timers:CreateTimer( 0.03, function()
			local dummy = CreateUnitByName( "npc_dummy_animation", Vector( 0, 0 ), true, nil, nil, hero:GetTeamNumber() )
			local ability = dummy:FindAbilityByName( "animation_list" )
			ability:SetLevel( 1 )
			dummy:FindAbilityByName( "generic_dummy_buff" ):SetLevel( 1 )
			
			if action == "Idle" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_idle", {} )
			elseif action == "Run" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_run", {} )
			elseif action == "Die" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_die", {} )
			elseif action == "Flail" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_flail", {} )
			elseif action == "Spawn" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_spawn", {} )
			elseif action == "Victory" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_victory", {} )
			elseif action == "Defeat" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_defeat", {} )
			elseif action == "Disabled" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_disabled", {} )
			elseif action == "Attack_1" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_attack_1", {} )
			elseif action == "Attack_2" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_attack_2", {} )
			elseif action == "Ability_1" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_ability_1", {} )
			elseif action == "Ability_2" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_ability_2", {} )
			elseif action == "Ability_3" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_ability_3", {} )
			elseif action == "Ability_4" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_ability_4", {} )
			elseif action == "Channel_1" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_channel_ability_1", {} )
			elseif action == "Channel_2" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_channel_ability_2", {} )
			elseif action == "Channel_3" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_channel_ability_3", {} )
			elseif action == "Channel_4" then
				ability:ApplyDataDrivenModifier( hero, hero, "modifier_animation_channel_ability_4", {} )
			end
			
			dummy:ForceKill( true )
		end
	)
end

-- Unit spawned then send data
function CAddonTemplateGameMode:OnUnitSpawned( keys )
	self:_SendToUI( keys )
end

-- Send all data to UI
function CAddonTemplateGameMode:_SendToUI( keys )
	local hero = EntIndexToHScript( keys.entindex )	
	Timers:CreateTimer( 0.1, function()
			if hero ~= nil and hero:IsRealHero() and hero == PlayerResource:GetPlayer( hero:GetPlayerID() ):GetAssignedHero() then
				self:_FirstTimeSetup( keys.entindex )
				self:_SendCurrentState( keys.entindex )
				self:_SendAvailableState( keys.entindex )
			end
		end
	)
end

-- Set up default cosmetic
function CAddonTemplateGameMode:_FirstTimeSetup( entindex )
	local hero = EntIndexToHScript( entindex )
	
	if hero.default_cosmetics == nil then
		hero.default_cosmetics = {}
		local wearable = hero:FirstMoveChild()
		while wearable ~= nil do
			if wearable:GetClassname() == "dota_item_wearable" then
				hero.default_cosmetics[wearable:GetModelName()] = wearable
			end
			wearable = wearable:NextMovePeer()
		end
		
		FireGameEvent( 'enable_cosmetics_panel', { player_id = hero:GetPlayerID() } )
	end
end

-- Send current data to UI
function CAddonTemplateGameMode:_SendCurrentState( entindex )
	local hero = EntIndexToHScript( entindex )
	
	local models_name = "";
	for k, v in pairs( hero.default_cosmetics ) do
		models_name = models_name .. k .. ","
	end
	
	FireGameEvent( 'update_current_panel', { player_id = hero:GetPlayerID(), models = models_name } )
end

-- Send available data to UI
function CAddonTemplateGameMode:_SendAvailableState( entindex )
	local hero = EntIndexToHScript( entindex )
	local name = string.gsub( hero:GetName(), "npc_dota_hero_", "" )
	name = string.lower( name )
	
	FireGameEvent( 'update_available_panel', { player_id = hero:GetPlayerID(), hero_name = name } )
end