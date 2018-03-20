
Trainers = {}

Trainers.__data__ = 
{
	tiers = 4,

	skillLevelThresholds = 
	{
		1, 6, 11, 16
	},
	
	skills = 
	{	
		
		['drinking'] = 
		{
			price = { 720, 2180, 6480, 19440 }
		},
		
		['stealth'] = 
		{
			price = { 900, 2700, 8100, 24300 }
		},
		
		['lockpicking'] = 
		{
			price = { 975, 2925, 8775, 26325 }
		},
		
		['pickpocketing'] = 
		{
			price = { 975, 2925, 8775, 26325 }
		},
		
		['reading'] = 
		{
			price = { 1050, 3150, 9450, 28350 }
		},
		
		['herbalism'] = 
		{
			price = { 640, 1920, 5760, 17280 }
		},
		
		['hunter'] = 
		{
			price = { 670, 2010, 6030, 18090 }
		},
		
		['horse_riding'] = 
		{
			price = { 720, 2180, 6480, 19440 }
		},
		
		['alchemy'] = 
		{
			price = { 780, 2340, 7020, 21060 }
		},
		
		['repairing'] = 
		{
			price = { 840, 2520, 7560, 22680 }
		},
		
		['weapon_unarmed'] = 
		{
			price = { 600, 1800, 5400, 16200 }
		},
		
		['weapon_dagger'] = 
		{
			price = { 640, 1920, 5760, 17280 }
		},
		
		['weapon_axe'] = 
		{
			price = { 670, 2010, 6030, 18090 }
		},
		
		['weapon_bow'] = 
		{
			price = { 720, 2180, 6480, 19440 }
		},
		
		['weapon_shield'] = 
		{
			price = { 750, 2250, 6750, 20250 }
		},
		
		['weapon_sword'] = 
		{
			price = { 780, 2340, 7020, 21060 }
		},
		
		['weapon_mace'] = 
		{
			price = { 840, 2520, 7560, 22680 }
		},
		
		['weapon_large'] = 
		{
			price = { 900, 2700, 8100, 24300 }
		},
		
		['defense'] = 
		{
			price = { 975, 2925, 8775, 26325 }
		},
		
		['fencing'] = 
		{
			price = { 1050, 3150, 9450, 28350 }
		}
	}
}

function Trainers.setContextSkill (skill)

	Trainers.skill = skill

end

function Trainers.setContextTrainer (trainer)

	Trainers.trainer = trainer

end

function Trainers.getContextSkill()

	return assert(Trainers.skill, "Trainers: Invalid context skill")

end

function Trainers.getContextTrainer()

	return assert(Trainers.trainer, "Trainers: Invalid context trainer")

end

function Trainers.buildGlobalVarName (skill, tier)

	return strFormat('trainers_lessonLearned_%s_%d', skill, tier)

end

function Trainers.exp_hasLessonStillAvailable (tier)

	tier = tonumber(tier)
	
	local skill = Trainers.getContextSkill()
	local varName = Trainers.buildGlobalVarName(skill, tier)
	
	local var = Variables.GetGlobal(varName)
	return pick(var == 0, 1, 0)

end

function Trainers.exp_hasAnyLessonAvailableForSkill (skill)

	for tier = 1, Trainers.__data__.tiers do
	
		local varName = Trainers.buildGlobalVarName(skill, tier)
		local var = Variables.GetGlobal(varName)
		
		if var == 0 then 
			return 1
		end
	
	end
	
	return 0

end

function Trainers.exp_meetsLevelRequirementToTrainLesson (tier)

	tier = tonumber(tier)
	if tier == 1 then
		return 1
	end
	
	local skill = Trainers.getContextSkill()
	local level = player.soul:GetSkillLevel(Trainers.skill)
	local requiredLevel = Trainers.__data__.skillLevelThresholds[tier] - 1
	
	return pick(level < requiredLevel, 0, 1)

end

function Trainers.calcLessonPrice (tier)

	local skill = Trainers.getContextSkill()
	
	local skillData = assert(Trainers.__data__.skills[skill], strFormat("No trainer data for skill '%s'", skill))
	return assert(skillData.price[tier], strFormat("No trainer price for skill '%s' and lesson tier %d", skill, tier))

end

function Trainers.showLessonPrice (tier)

	local price = Trainers.calcLessonPrice(tier)

	Variables.SetGlobal('dlg_crimeFineAmount', price / 10)
	Variables.SetGlobal('dlg_crimeFineShown', 1)
	
	Utils.SetLocalVar('price', price)

end

function Trainers.clearShownLessonPrice()

	Variables.SetGlobal('dlg_crimeFineAmount', 0)
	Variables.SetGlobal('dlg_crimeFineShown', 0)

end

function Trainers.setupNegotiationForLesson (tier)

	local price = Trainers.calcLessonPrice(tier)
	NegotiationUtils.SetupNegotiation(NegotiationReason.Trainer, price, 0, 0, 0)
	
end

function Trainers.trainLesson (tier, price)

	tier = tonumber(tier)
	
	local skill = Trainers.getContextSkill()
	local trainer = Trainers.getContextTrainer()
	
	assert(price, "Invalid lesson price")
	local varName = Trainers.buildGlobalVarName(skill, tier)
	Variables.SetGlobal(varName, 1)
	local level = Trainers.__data__.skillLevelThresholds[tier]
	local dudeStartLevel = player.soul:GetSkillLevel(skill)
	local xp = player.soul:GetNextLevelSkillXP(skill, level - 1)
	player.soul:AddSkillXP(skill, xp)
	player.inventory:MoveItemOfClass(trainer.inventory:GetId(), Utils.itemIDs.money, price, true)
	XGenAIModule.SendMessageToEntity(player.this.id, 'trainers:faderRequest', '')
	if dudeStartLevel == player.soul:GetSkillLevel(skill) then
	
		RPG.NotifyLevelXpGain(skill)
	
	end

end
