
Sleepover = {}

Sleepover.rentKind = 
{
	temp = 
	{ 
		str = 'temp'
	},
	
	permanent = 
	{ 
		str = 'permanent'
	}
}

Sleepover.places = 
{
	['ledecko'] = 
	{  
		innkeepers = { 'led_innkeeper', 'led_bartender' },
		smartAreaName = 'sa_sleepoverRoom_ledecko',
		tempRentPrice = 40,
		permanentRentPrice = 10000,
		directionsVariant = 2
	},
	
	['mytinka'] = 
	{  
		innkeepers = { 'cros_ondrej', 'cros_bartender' },
		smartAreaName = 'sa_sleepoverRoom_mytinka',
		tempRentPrice = 44,
		permanentRentPrice = 12000,
		directionsVariant = 1
	},
	
	['rataje'] = 
	{  
		innkeepers = { 'rato_innkeeper1' , 'rato_bartender1' },
		smartAreaName = 'sa_sleepoverRoom_rataje',
		tempRentPrice = 42,
		permanentRentPrice = 11000,
		directionsVariant = 1
	},

	['sazava'] = 
	{  
		innkeepers = { 'saso_innkeeper1', 'saso_bartender1' },
		smartAreaName = 'sa_sleepoverRoom_sazava',
		tempRentPrice = 46,
		permanentRentPrice = 13000,
		directionsVariant = 1
	},
	
	['talmberk'] = 
	{  
		innkeepers = { 'tal_innkeeper', 'tal_marta', 'tal_bartender2' },
		smartAreaName = 'sa_sleepoverRoom_talmberk',
		tempRentPrice = 36,
		permanentRentPrice = 6000,
		directionsVariant = 3
	},
	
	['uzice'] = 
	{  
		innkeepers = { 'aus_innkeeper', 'aus_bartender' },
		smartAreaName = 'sa_sleepoverRoom_uzice',
		tempRentPrice = 38,
		permanentRentPrice = 8000,
		directionsVariant = 4
	},
}

Sleepover.utils = {}

Sleepover.utils.parseRentKindEnumStr = function (str)

	for _, val in pairs(Sleepover.rentKind) do
	
		if val.str == str then
			return val
		end
	
	end
	
	TError(strFormat("Sleepover: Unable to cast str '%s' as a rent kind enum value.", str))

end

Sleepover.utils.calcAmountForRent = function (placeID, rentKind)

	local placeData = Sleepover.places[placeID]
	assert(placeData, strFormat("Sleepover: Invalid place ID '%s'.", placeID))

	if rentKind == Sleepover.rentKind.temp then
	
		return placeData.tempRentPrice
		
	end
	
	if rentKind == Sleepover.rentKind.permanent then
		
		return placeData.permanentRentPrice
		
	end

	TError("Sleepover: Cannot determine rent price due to an unexpected rent kind.")
	
end

Sleepover.utils.buildGlobalVarNameForRent = function (placeID, rentKind)

	return strFormat('sleepover_%s_%s', placeID, rentKind.str)

end

Sleepover.utils.sendSmartAreaEvent = function (placeID, event)

	local placeData = Sleepover.places[placeID]
	assert(placeData, strFormat("Sleepover: Invalid place ID '%s'.", placeID))
	
	local smartAreaEnt = System.GetEntityByName(placeData.smartAreaName)
	assert(smartAreaEnt, strFormat("Sleepover: Cannot locate entity '%s'", placeData.smartAreaName))
	
	XGenAIModule.SendMessageToEntity(smartAreaEnt.this.id, 'sleepover:event', strFormat('kind($enum:sleepoverEventKind.%s)', event))

end

Sleepover.setupHaggleForRent = function (rentKindStr)

	local rentKind = Sleepover.utils.parseRentKindEnumStr(rentKindStr)
	if rentKind == nil then
	
		return 
		
	end
	
	local amount = Sleepover.utils.calcAmountForRent(Sleepover.conversationPlaceID, rentKind)
	NegotiationUtils.SetupNegotiation(NegotiationReason.Sleepover, amount, 0, 0, 0)

end

Sleepover.purchaseRent = function (placeID, rentKind)

	assert(rentKind, "Sleepover: The rentKind parameter has to be a rentKind enum value.")
	
	local varName = Sleepover.utils.buildGlobalVarNameForRent(placeID, rentKind)
	Variables.SetGlobal(varName, 1)
	
	local event
	if rentKind == Sleepover.rentKind.temp then
	
		event = 'tempRentPurchased'
		
	end
	
	if rentKind == Sleepover.rentKind.permanent then
	
		event = 'permanentRentPurchased'
		
	end
	
	assert(event, "Sleepover: Cannot determine an event to be sent to the sleepover smart area.")
	Sleepover.utils.sendSmartAreaEvent(placeID, event)
	
end

Sleepover.expireRent = function (placeID, rentKind)

	assert(rentKind, "Sleepover: The rentKind parameter has to be a rentKind enum value.")
	
	local varName = Sleepover.utils.buildGlobalVarNameForRent(placeID, rentKind)
	Variables.SetGlobal(varName, 0)
	
	Sleepover.utils.sendSmartAreaEvent(placeID, 'tempRentExpired')

end

Sleepover.getDirectionsVariant = function (placeID)

	local placeData = Sleepover.places[placeID]
	assert(placeData, strFormat("Sleepover: Invalid place ID '%s'.", placeID))
	
	return placeData.directionsVariant

end

Sleepover.conversationEval_determinePlace = function()

	local tolerance = 4
	for placeID, placeData in pairs(Sleepover.places) do
	
		for _, innkeeperName in ipairs(placeData.innkeepers) do
		
			local innkeeperEnt = System.GetEntityByName(innkeeperName)
			if innkeeperEnt ~= nil then
			
				local distance = player:GetDistance(innkeeperEnt.id)
				if distance < tolerance then
				
					Sleepover.conversationPlaceID = placeID
					return 1
				
				end
			
			else
			
				TWarning(strFormat("Sleepover: Unable to locate innkeeper entity '%s'.", innkeeperName))
			
			end
		
		end
	
	end
	
	TWarning("Sleepover: Unable to determine conversation place.")
	return 0

end

Sleepover.conversationEval_hasRent = function (rentKindStr)

	local rentKind = Sleepover.utils.parseRentKindEnumStr(rentKindStr)
	if rentKind == nil then
	
		return 0
		
	end
	
	local varName = Sleepover.utils.buildGlobalVarNameForRent(Sleepover.conversationPlaceID, rentKind)
	return pick(Variables.GetGlobal(varName) > 0, 1, 0)

end

Sleepover.conversationEval_canAffordRent = function (rentKindStr)

	local item = player.inventory:FindItem('5ef63059-322e-4e1b-abe8-926e100c770e')
	if item == nil then

		return 0
		
	end
	
	local itemData = ItemManager.GetItem(item)
	if itemData == nil then
	
		TError("Sleepover: Cannot retrieve item data for player's money.")
		return 0
	
	end
	
	local rentKind = Sleepover.utils.parseRentKindEnumStr(rentKindStr)
	if rentKind == nil then
	
		return 0
		
	end
	
	local result = Sleepover.utils.calcAmountForRent(Sleepover.conversationPlaceID, rentKind) <= itemData.amount
	return pick(result, 1, 0)

end
