
CrimeUtils = {}

function CrimeUtils.DetectDudeWeaponBeforeConfrontation()

	CrimeUtils.dudeWeaponBeforeConfrontation = player.human:GetItemInHand(0)

end

function CrimeUtils.SendConfrontationResult (dc, action)

	local entity = dc['KONFRONTACE_ZLOCINCE_(MUZ)'].this.id
	local type = 'combat:confrontationFeedback'
	local content = { action = action }
	if action == 'fine' or action == 'jail' or action == 'skillCheck' then
		
		local weapon = CrimeUtils.dudeWeaponBeforeConfrontation
		if weapon ~= __null then

			local isOversized = ItemManager.IsItemOversized(weapon)
			if isOversized and action == 'jail' then
			
				player.inventory:DeleteItem(weapon, 1)
			elseif (not isOversized) then
			
				player.actor:UnequipInventoryItem(weapon)
				player.actor:EquipInventoryItem(weapon)
			
			end
			
		end
		
	end
	
	XGenAIModule.SendMessageToEntityData(entity, type, content)
	CrimeUtils.dudeWeaponBeforeConfrontation = nil
	
end

function CrimeUtils.SendFriskResult (dc, action)

	local entity = dc['SACOVANI_JINDRY_NA_BRANE_(MUZ)'].this.id
	local type = 'combat:friskFeedback'
	local content = { action = action }

	XGenAIModule.SendMessageToEntityData(entity, type, content)
	
end

function CrimeUtils.CalculateConfrontationSkillCheckDifficulty()

	local jailDays = Variables.GetGlobal('crimeConfrontationDialog_jail')
	local impossibleSkillChecks = Variables.GetGlobal('crimeConfrontationDialog_impossibleCrimeSkillChecks')

	if impossibleSkillChecks > 0 then
		return 4
	end

--	Begin Jail Time Test --
--	 if jailDays > 9 then 
--		return 4
--	end
--	
--	if jailDays > 5 then 
--		return 3		
--	end
--		
--	if jailDays > 3 then 
--		return 2
--	end
--	End Jail Time Test --

	return 1

end

CrimeUtils.crimeDetectionParams = 
{
	['lockpick'] = 
	{
		additionalSkillName = 'lockpicking', 
		additionalSkillWeight = 1,
		autoUnseenDistanceOnSkillZero = 20,
		autoUnseenDistanceOnSkillCap = 5
	},
	
	['loot'] = 
	{
		autoUnseenDistanceOnSkillZero = 20,
		autoUnseenDistanceOnSkillCap = 5
	},

	['pickpocket'] = 
	{
		additionalSkillName = 'pickpocketing',
		additionalSkillWeight = 3,
		autoUnseenDistanceOnSkillZero = 15,
		autoUnseenDistanceOnSkillCap = 1
	},
	
	['pickUpSteal'] = 
	{
		autoUnseenDistanceOnSkillZero = 20,
		autoUnseenDistanceOnSkillCap = 3
	}
}
function CrimeUtils.CanDetectCrime (observer, crime, options)

	options = options or {}
	options.thresholdRangeMod = options.thresholdRangeMod or 1

	local params = assert(CrimeUtils.crimeDetectionParams[crime], strFormat("Unknown crime param value '%s'", crime))
	
	local skillLevel = player.soul:GetSkillLevel('stealth')
	if params.additionalSkillName ~= nil then

		local additionalSkillLevel = player.soul:GetSkillLevel(params.additionalSkillName)
		skillLevel = (skillLevel + additionalSkillLevel* params.additionalSkillWeight) / (1 + params.additionalSkillWeight)
	
	end

	local thresholdRange = math.lerp(params.autoUnseenDistanceOnSkillZero, params.autoUnseenDistanceOnSkillCap, skillLevel / 20) * options.thresholdRangeMod
	return observer:GetDistance(player.id) < thresholdRange
	
end

function CrimeUtils.InitInformationData()

	local result = {}
	local function addLabel (label, values)
	
		values.isCrime = values.isCrime or false
		values.isUnattributedCrime = values.isUnattributedCrime or false
		values.produceInformationStimulus = values.produceInformationStimulus or false
		values.soldiersAlwaysRespondWithinDistance = values.soldiersAlwaysRespondWithinDistance or 12
		values.soldiersMaxResponderCount = values.soldiersMaxResponderCount or 3
		values.civiliansAutoReactWithinDistance = values.civiliansAutoReactWithinDistance or -1
		values.civiliansCanReactWithinDistance = values.civiliansCanReactWithinDistance or -1
		values.reactorsAutoSuccessCount = values.reactorsAutoSuccessCount or 1
		values.reactorsChanceDecreasePerEachExtra = values.reactorsChanceDecreasePerEachExtra or 0.65
		values.reputationHitName = values.reputationHitName or ''
		values.resolvedByCircators = values.resolvedByCircators or false
		values.isOnlyMonasteryCrime = values.isOnlyMonasteryCrime or false
		values.importance = values.importance or 0
		values.reportMoveSpeed = values.reportMoveSpeed or 1
		values.reportMetaroleFirstBark = values.reportMetaroleFirstBark or ''
		values.reportMetarole = values.reportMetarole or 'VOLANI_STRAZE'
		values.reportAlwaysMove = values.reportAlwaysMove or false
		values.fine = values.fine or 0
		values.jail = values.jail or 0
		values.confiscation = values.confiscation or false
		values.expiration = values.expiration or 0
		values.useGenericLineInConfrontationDialog = values.useGenericLineInConfrontationDialog or false
		values.gracePeriod = values.gracePeriod or 0
		values.maxConfronters = values.maxConfronters or 2

		result[label] = values
		
	end

	addLabel('alert',
	{
		isCrime = false,
		expiration = 60
	})
	
	addLabel('assault', 
	{ 
		isCrime = true, 
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 7,
		reputationHitName = 'assault', 
		resolvedByCircators = true,
		importance = 60,
		reportMetarole = 'NASILI_POPLACH',
		reportMetaroleFirstBark = 'NASILI_UTEK',
		reportAlwaysMove = true,
		reportMoveSpeed = 2,
		fine = 1200, 
		jail = 7, 
		expiration = 3 * 3600,
	})
	
	addLabel('assist', 
	{ 
		isCrime = false 
	})
	
	addLabel('combat', 
	{ 
		isCrime = false,
		expiration = 60
	})
	
	addLabel('corpse', 
	{ 
		isCrime = false,
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 5,
		reportMetarole = 'VOLANI_STRAZE_MRTVOLA',
		reportMetaroleFirstBark = 'UVIDI_MRTVOLU',
	})
	
	addLabel('carriedCorpse', 
	{ 
		isCrime = true,
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 5,
		reputationHitName = 'carriedCorpse',
		importance = 75,
		reportMoveSpeed = 2,
		fine = 1000,
		jail = 7,
		expiration = 4 * 3600
	})
	
	addLabel('hafhaf', 
	{ 
		isCrime = false 
	})
	
	addLabel('lockpick', 
	{ 
		isCrime = true, 
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 2,
		reputationHitName = 'lockpick', 
		resolvedByCircators = true,
		reportMetarole = 'VOLANI_STRAZE_KRADEZ',
		reportMetaroleFirstBark = 'REAKCE_NA_KRADEZ',
		importance = 40,
		fine = 1000, 
		jail = 5, 
		confiscation = true,
		expiration = 2 * 3600
	})
	
	addLabel('mon_assault', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('mon_equipWeapon', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('mon_goToChurch', 
	{  
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('mon_outsideMonastery', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('mon_robe', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('mon_slacking', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})	
	
	addLabel('mon_trespass', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('mon_workInFrateria', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('mon_workInLibrary', 
	{ 
		resolvedByCircators = true,
		isOnlyMonasteryCrime = true
	})
	
	addLabel('murder', 
	{ 
		isCrime = true, 
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 10,
		reactorsAutoSuccessCount = 2,
		reactorsChanceDecreasePerEachExtra = 0.33,
		reputationHitName = 'murder', 
		reportMetarole = 'VOLANI_STRAZE_VRAZDA',
		reportMetaroleFirstBark = 'REAKCE_NA_VRAZDU',
		reportAlwaysMove = true,
		importance = 100,
		reportMoveSpeed = 2,
		fine = 10000,
		jail = 14,
		maxConfronters = 6
	})
	
	addLabel('refuseFrisk',
	{
		isCrime = true,
		produceInformationStimulus = true,
		reputationHitName = 'refuseFrisk',
		importance = 20,
		fine = 900,
		jail = 1,
		expiration = 2 * 3600,
		useGenericLineInConfrontationDialog = true
	})
	
	addLabel('shotAt', 
	{ 
		isUnattributedCrime = true, 
		produceInformationStimulus = true,
		civiliansAutoReactWithinDistance = 1,
		expiration = 360
	})
	
	addLabel('sneak', 
	{ 
		isCrime = true, 
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 5,
		reputationHitName = 'sneak', 
		importance = 10,
		fine = 450, 
		jail = 1, 
		expiration = 1 * 3600,
		gracePeriod = 300,
		maxConfronters = 1
	})
	
	addLabel('theft', 
	{ 
		isCrime = true, 
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 5,
		reputationHitName = 'theft', 
		resolvedByCircators = true,
		reportMetarole = 'VOLANI_STRAZE_KRADEZ',
		reportMetaroleFirstBark = 'REAKCE_NA_KRADEZ',
		importance = 40,
		fine = 2000, 
		jail = 5, 
		confiscation = true,
		expiration = 3 * 3600
	})
	
	addLabel('theftExPost', 
	{ 
		isUnattributedCrime = true,
		produceInformationStimulus = true,
		soldiersMaxResponderCount = 1,
		reportMetarole = 'VOLANI_STRAZE_KE_KRADEZI_POZDE'
	})
	
	addLabel('threat', 
	{
		produceInformationStimulus = true,
		expiration = 600
	})
	
	addLabel('trespass', 
	{ 
		isCrime = true, 
		produceInformationStimulus = true,
		reputationHitName = 'theft', 
		importance = 40,
		fine = 500, 
		jail = 1, 
		expiration = 1 * 3600,
		gracePeriod = 12
	})
	
	addLabel('unattributedAssault',
	{
		isUnattributedCrime = true, 
		produceInformationStimulus = true,
		soldiersMaxResponderCount = 2
	})
	
	addLabel('weapon', 
	{ 
		isCrime = true, 
		produceInformationStimulus = true,
		civiliansCanReactWithinDistance = 7,
		importance = 33,
		fine = 400, 
		jail = 1, 
		expiration = 1 * 3600,
		maxConfronters = 1
	})
  
	return result

end

function CrimeUtils.SendMercyDialogResult (entity, enumValueName)

	local type = 'combat:mercy:dialogResult'
	local content = strFormat('outcome($enum:combatMercyOutcome.%s)', enumValueName)
	entity.soul:RestrictDialog(true)
	
	XGenAIModule.SendMessageToEntity(entity.this.id, type, content)
	
end

function CrimeUtils.ProduceAiSoundOnDudePosition (soundKind, bonusPerStealthSkill)

	local stealth = player.soul:GetSkillLevel('stealth')
	local multiplier = 1 - stealth * bonusPerStealthSkill

	XGenAIModule.ProduceSoundWUID(soundKind, player.this.id, multiplier)

end

function CrimeUtils.CalcPayToTalkPrice (entity)

	local socialClassData = SocialClass.GetEntitySocialClassData(entity)
	local socialClassPriceMod = socialClassData.persuadeToTalkWithLowReputationPriceMultiplier
	local price = 1000 * socialClassPriceMod
	price = math.max(math.round(price / 10) * 10, 10)
	
	return price

end

function CrimeUtils.IncreasePayToTalkReputation (entity)

	local soul = assert(entity.soul, "Provided entity does not have a soul")	
	for _ = 1, 4 do
	
		soul:ModifyPlayerReputation('payToTalk')
		if soul:GetRelationship(player.this.id, 'Current') >= 0.2 then
		
			return
			
		end
	
	end
	
	TError("Pay-to-talk: unable to increase reputation above the required level.")

end
function CrimeUtils.DetermineSuspiciousDealReaction (entity)

	local reaction = Variables.GetGlobal('haggle_suspiciousness_reaction') 

	local socialClassData = SocialClass.GetEntitySocialClassData(entity)
	local dealsWithStolenItems = socialClassData.dealsWithStolenItems
	
	if reaction > 0 then 

		local reaction = pick(dealsWithStolenItems, 1, 2)
		Variables.SetGlobal('haggle_suspiciousness_reaction', reaction)

	end
	
end

function CrimeUtils.BuildLockpickPromptStrName (lockDifficulty)

	local levels = 
	{
		{ minLockDifficulty = 0.75, strName = 'ui_hud_lockpick_difficulty_4' },
		{ minLockDifficulty = 0.5, strName = 'ui_hud_lockpick_difficulty_3' },
		{ minLockDifficulty = 0.25, strName = 'ui_hud_lockpick_difficulty_2' },
		{ minLockDifficulty = 0, strName = 'ui_hud_lockpick_difficulty_1' }
	}
	
	for _, level in ipairs(levels) do
	
		if lockDifficulty >= level.minLockDifficulty then
		
			return level.strName
		
		end
	
	end
	return 'ui_hud_lockpick'
	
end
