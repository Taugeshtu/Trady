function HandleDebugCommand( inSplit, inPlayer )
	inPlayer:SendMessage( "TD: Fractional:"..tostring(Settings.FractionalTrade)..", Barter: "..tostring(Settings.Barter)..", Item: "..tostring(Settings.BarterItem)..
	", SelfTrade: "..tostring(Settings.HaltSelfTrade)..", UsingProt: "..tostring(Settings.UsingProtection)..", BreakProt: "..tostring(Settings.BreakingProtection) )
end

--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function SafetyChecks( inPlayer, inX, inY, inZ, inBreaking )
	-- Returns: should return, return value
	-- Shop checks
	local foundShop = false
	local clickedChest = false
	if( CheckShopThere( inPlayer:GetWorld(), inX, inY, inZ ) == true ) then
		foundShop = true
	end
	if( CheckShopThere( inPlayer:GetWorld(), inX, inY + 1, inZ ) == true ) then
		foundShop = true
		clickedChest = true
	end
	
	if( foundShop ) then
		local _adress = GetAdress( inPlayer:GetWorld(), inX, inY, inZ )
		if( clickedChest ) then
			_adress = GetAdress( inPlayer:GetWorld(), inX, inY + 1, inZ )
		end
		if( ShopsData[_adress].ownername ~= inPlayer:GetName() ) then
			if( clickedChest ) then
				local returnValue = false
				if( inBreaking ) then
					returnValue = (Settings.BreakingProtection == true)
				else
					returnValue = (Settings.UsingProtection == true)
				end
				return true, returnValue -------------------
			else
				return false, false -------------------
			end
		else
			if( Settings.HaltSelfTrade or clickedChest ) then
				return true, false -------------------
			else
				return false, false -------------------
			end
		end
	end
	
	-- Cash machine checks
	local _ownername, _cashmachine = GetCashMachineThere( inPlayer:GetWorld(), inX, inY, inZ )
	if( _cashmachine == nil ) then
		_ownername, _cashmachine = GetCashMachineThere( inPlayer:GetWorld(), inX, inY + 1, inZ )
	end
	
	if( _cashmachine ~= nil ) then
		if( _ownername ~= inPlayer:GetName() ) then
			local returnValue = false
			if( inBreaking ) then
				returnValue = (Settings.BreakingProtection == true)
			else
				returnValue = (Settings.UsingProtection == true)
			end
			return true, returnValue -------------------
		else
			return true, false -------------------
		end
	end
	
	return false, false
end
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function CheckShopChest( inWorld, inX, inY, inZ )			-- RETURNS WHAT IS IN THE CHEST AND IN WHICH amount
	local ReadChest = function( inChest )
		-- stalk through chest slots...
		local slotItem
		local chestGrid = inChest:GetContents()
		local slotsCount = chestGrid:GetNumSlots()
		for index = 0, (slotsCount - 1) do
			slotItem = chestGrid:GetSlot( index )
			if( slotItem:IsEmpty() == false ) then
				if( _result.foundStuff ) then
					if( slotItem.m_ItemType == _result.type ) then
						_result.count = _result.count + slotItem.m_ItemCount
					else
						_result.clashingItems = true
						break
					end
				else
					_result.type = slotItem.m_ItemType
					_result.count = slotItem.m_ItemCount
					_result.foundStuff = true
				end
			end
		end
	end
	_result = {}
	_result.type = -1
	_result.count = 0
	_result.foundStuff = false
	_result.clashingItems = false
	inWorld:DoWithChestAt( inX, inY, inZ, ReadChest )
	return _result
end

function CheckIntegrity( inWorld, inX, inY, inZ )			-- check on SIGN placement
	local foundChest = false
	local foundSign = false
	local TestChest = function( Chest )
		if( Chest ~= nil ) then
			foundChest = true
		end
	end
	inWorld:DoWithChestAt( inX, inY - 1, inZ, TestChest )
	local sign = inWorld:GetSignLines( inX, inY, inZ)
	if( sign ~= false ) then
		foundSign = true
	end
	
	if( foundChest and foundSign ) then		return true		end
	
	DestroyShop( GetAdress( inWorld, inX, inY, inZ ) )
	return false
end

function CheckCashMachineChest( inWorld, inX, inY, inZ )	-- we just want to know if some chest is even there :D
	local ReadChest = function( Chest )
		_result = 1
	end
	_result = 0
	inWorld:DoWithChestAt( inX, inY, inZ, ReadChest )
	return _result
end

function CheckShopThere( inWorld, inX, inY, inZ )		-- is there any shop at all?
	local _adress = GetAdress( inWorld, inX, inY, inZ )
	if( ShopsData[_adress] ~= nil ) then
		return true
	end
	return false
end

function CheckCashMachineThere( inWorld, inX, inY, inZ )
	local _result = false
	for k,v in pairs( TradersData ) do
		if( v.cashmachine.world == inWorld:GetName()
		and v.cashmachine.x == inX
		and v.cashmachine.y == inY
		and v.cashmachine.z == inZ ) then
			_result = true
		end
	end
	return _result
end
-- * * * * *
function GetShopDescription( inWorld, inX, inY, inZ )
	local _adress = GetAdress( inWorld, inX, inY, inZ )
	if( ShopsData[_adress] ~= nil ) then
		return (PluralItemName(ShopsData[_adress].item, 10 ).." @["..inX.."; "..inY.."; "..inZ.."] in "..ShopsData[_adress].world)
	end
	return "no shop found"
end

function GetCashMachineThere( inWorld, inX, inY, inZ )
	for k,v in pairs( TradersData ) do
		if( v.cashmachine ~= nil ) then
			if( v.cashmachine.world == inWorld:GetName()
			and v.cashmachine.x == inX
			and v.cashmachine.y == inY
			and v.cashmachine.z == inZ ) then
				return k, v
			end
		end
	end
	return nil, nil
end
-- * * * * *
function RegisterShop( inWorld, inOwnerName, inX, inY, inZ, inItemID, inAmount, inToChest, inFromChest, inFractionalTrade )
	LOG( "Getting adress" )
	local _adress = GetAdress( inWorld, inX, inY, inZ )
	LOG( "Got adress" )
	if( ShopsData[_adress] == nil )				then ShopsData[_adress] = {} end
	ShopsData[_adress].ownername = inOwnerName
	ShopsData[_adress].world = inWorld:GetName()
	
	ShopsData[_adress].x = inX
	ShopsData[_adress].y = inY
	ShopsData[_adress].z = inZ
	
	ShopsData[_adress].item = inItemID
	ShopsData[_adress].amount = inAmount
	ShopsData[_adress].tochest = inToChest
	ShopsData[_adress].fromchest = inFromChest
	ShopsData[_adress].fractional = inFractionalTrade
	
	if( TradersData[inOwnerName] == nil ) then
		TradersData[inOwnerName] = {}
	end
end

function RegisterCashMachine( inWorld, inOwnerName, inX, inY, inZ )
	if( TradersData[inOwnerName] == nil ) then
		TradersData[inOwnerName] = {}
	end
	if( TradersData[inOwnerName].cashmachine == nil ) then
		TradersData[inOwnerName].cashmachine = {}
	else
		-- TODO: warn merchant that he's replacing his cashmachine!
	end
	TradersData[inOwnerName].cashmachine.x = inX
	TradersData[inOwnerName].cashmachine.y = inY
	TradersData[inOwnerName].cashmachine.z = inZ
	TradersData[inOwnerName].cashmachine.world = inWorld:GetName()
end
-- * * * * *
function CheckDestroyThings( inPlayer, inX, inY, inZ )
	if( CheckShopThere( inPlayer:GetWorld(), inX, inY, inZ ) == true ) then	-- we know we're clicking on a chest with shop!
		local _adress = GetAdress( inPlayer:GetWorld(), inX, inY, inZ )
		if( ShopsData[_adress].ownername == inPlayer:GetName()
		or inPlayer:HasPermission( "trady.delete" ) ) then
			DestroyShop( _adress, inPlayer )
		end
	end
	local _ownername, _cashmachine = GetCashMachineThere( inPlayer:GetWorld(), inX, inY, inZ )
	if( _cashmachine ~= nil ) then	-- we know we're clicking on a cash machine!
		if( _ownername == inPlayer:GetName() ) then	--															<<< DOOMSDAY DEVICE
			DestroyCashMachine( _ownername, inPlayer )
		end
	end
end

function DestroyShop( inAdress, inDestroyer )
	DestroyShop( inAdress )
	inDestroyer:SendMessage( "Destroyed a shop @ "..inAdress )
end

function DestroyShop( inAdress )
	ShopsData[inAdress] = nil
	-- TODO: add console messaging here
end

function DestroyCashMachine( inOwnerName, inDestroyer )
	TradersData[inOwnerName] = nil
	inDestroyer:SendMessage( "Destroyed "..inAdress.."'s cash machine" )
	-- TODO: add console messaging here
end
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--/ / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
function BuyFromShop( inWorld, inPlayer, inX, inY, inZ )
	local OperateChest = function( Chest )
		local _c_balance, _c_free_space = ReadChestForItem(Chest, ShopsData[_adress].item )
		_trade_count = math.min( _trade_count, _c_balance )
		if( _trade_count < ShopsData[_adress].amount ) then
			if( _fractional_trade == false
			or _trade_count <= 0 )	then	--																		<<< miniDOOMSDAY DEVICE
				return 0
			end
		end
		TakeItemsFromChest(Chest, ShopsData[_adress].item, _trade_count)
	end
	_adress = GetAdress( inWorld, inX, inY, inZ )
	local _result = 0	-- will contain amount of traded items
	OperationState.success = false
	OperationState.partial = false
	local integral = CheckIntegrity( inWorld, inX, inY, inZ )
	if( not integral ) then
		return -1
	end
	
	if( ShopsData[_adress] ~= nil ) then
		if( ShopsData[_adress].fromchest ~= -1 ) then
			if( Settings.HaltSelfTrade == true
			and ShopsData[_adress].ownername == inPlayer:GetName() ) then	--											<<< DOOMSDAY DEVICE
				return -1
			end
			--/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
			_trade_count = 1
			local _transfer_item = cItem( ShopsData[_adress].item, _trade_count )
			_fractional_trade =( ShopsData[_adress].fractional and Settings.FractionalTrade )
			OperationState.itemID = ShopsData[_adress].item
			OperationState.merchantname = ShopsData[_adress].ownername
			OperationState.performed = true
			
			-- 1. Check, how much items player could afford; how much items merchant could sell( cash machine storage has limits! )
			local _unit_price =( ShopsData[_adress].fromchest/ShopsData[_adress].amount )
			local _p_balance, _p_free_space = GetPlayerTradeData( inPlayer:GetName() )
			local _m_balance, _m_free_space = GetMerchantTradeData( ShopsData[_adress].ownername )
			local _player_can_buy = math.floor( _p_balance/_unit_price )
			local _merchant_can_sell = math.floor( _m_free_space/_unit_price )
			if( _m_free_space == -1 )	then	_merchant_can_sell = ShopsData[_adress].amount	end
			_trade_count = math.min( _player_can_buy, _merchant_can_sell )
			if( _player_can_buy < ShopsData[_adress].amount ) then
				OperationState.partial = true
				OperationState.fail_reason = FailReason.player_no_money
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			if( _merchant_can_sell < ShopsData[_adress].amount ) then
				OperationState.partial = true
				OperationState.fail_reason = FailReason.merchant_no_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			-- 1.1 Also check how much items player could hold!
			_p_balance, _p_free_space = ReadPlayerForItem(inPlayer, ShopsData[_adress].item)
			_trade_count = math.min( _p_free_space, _trade_count )
			if( _trade_count < ShopsData[_adress].amount ) then
				OperationState.partial = true
				OperationState.fail_reason = FailReason.player_no_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			_trade_count = math.min( ShopsData[_adress].amount, _trade_count )
			
			-- 2. Remove as much items from chest, as possible.
			inWorld:DoWithChestAt( inX, inY - 1, inZ, OperateChest )
			-- _trade_count now contain amount of traded items
			if( _trade_count < ShopsData[_adress].amount ) then
				OperationState.partial = true
				OperationState.fail_reason = FailReason.not_enough_items
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			
			-- 3. Charge player.
			MakeTransaction( inPlayer:GetName(), ShopsData[_adress].ownername, _trade_count*_unit_price, true )
			
			-- 4. Add items to player.
			_result = _trade_count
			GiveItemsToPlayer(inPlayer, ShopsData[_adress].item, _trade_count )
			OperationState.success = true
			OperationState.amount = _result
			OperationState.money_amount = _result*_unit_price
		end
	else
		_result = -1
	end
	return _result
end
function SellToShop( inWorld, inPlayer, inX, inY, inZ )
	local OperateChest = function( Chest )
		local _c_balance, _c_free_space = ReadChestForItem(Chest, ShopsData[_adress].item)
		_trade_count = math.min( _trade_count, _c_free_space )
		LOGWARN( "Free space: ".._c_free_space )
		if( _trade_count < ShopsData[_adress].amount ) then
			if( _fractional_trade == false
			or _trade_count <= 0 )	then	--																		<<< miniDOOMSDAY DEVICE
				return 0
			end
		end
		PutItemsToChest(Chest, ShopsData[_adress].item, _trade_count)
	end
	_adress = GetAdress( inWorld, inX, inY, inZ )
	local _result = 0	-- will contain amount of traded items
	OperationState.success = false
	OperationState.partial = false
	local integral = CheckIntegrity( inWorld, inX, inY, inZ )
	if( not integral ) then
		return -1
	end
	
	if( ShopsData[_adress] ~= nil ) then
		if( ShopsData[_adress].tochest ~= -1 ) then
			if( Settings.HaltSelfTrade == true
			and ShopsData[_adress].ownername == inPlayer:GetName() ) then	--												<<< DOOMSDAY DEVICE
				return -1
			end
			--/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
			_trade_count = 1
			local _transfer_item = cItem( ShopsData[_adress].item, _trade_count )
			_fractional_trade =( ShopsData[_adress].fractional and Settings.FractionalTrade )
			OperationState.itemID = ShopsData[_adress].item
			OperationState.merchantname = ShopsData[_adress].ownername
			OperationState.performed = true
			
			-- 1. Check, how much coins player could take; how much items merchant could buy( cash machine has limits! )
			local _unit_price =( ShopsData[_adress].tochest/ShopsData[_adress].amount )
			local _p_balance, _p_free_space = GetPlayerTradeData( inPlayer:GetName() )
			local _m_balance, _m_free_space = GetMerchantTradeData( ShopsData[_adress].ownername )
			local _player_can_sell = math.floor( _p_free_space/_unit_price )
			local _merchant_can_buy = math.floor( _m_balance/_unit_price )
			if( _p_free_space == -1 )	then	_player_can_sell = ShopsData[_adress].amount	end
			_trade_count = math.min( _player_can_sell, _merchant_can_buy )
			if( _player_can_sell < ShopsData[_adress].amount ) then
				OperationState.partial = true
				OperationState.fail_reason = FailReason.player_no_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			if( _merchant_can_buy < ShopsData[_adress].amount ) then
				OperationState.partial = true
				OperationState.fail_reason = FailReason.merchant_no_money
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			-- 1.1 Also check how much items player could sell!
			_p_balance, _p_free_space = ReadPlayerForItem(inPlayer, ShopsData[_adress].item)
			_trade_count = math.min( _p_balance, _trade_count )
			if( _trade_count < ShopsData[_adress].amount ) then
				OperationState.partial = true
				OperationState.fail_reason = FailReason.not_enough_items
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			_trade_count = math.min( ShopsData[_adress].amount, _trade_count )
			
			-- 2. Put as much items into chest, as possible.
			inWorld:DoWithChestAt( inX, inY - 1, inZ, OperateChest )
			-- _trade_count now contain amount of traded items
			if( _trade_count < ShopsData[_adress].amount ) then
				LOGWARN( "Sooo... Trade count: ".._trade_count )
				OperationState.partial = true
				OperationState.fail_reason = FailReason.not_enough_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			
			-- 3. Charge player.
			MakeTransaction( inPlayer:GetName(), ShopsData[_adress].ownername, _trade_count *-_unit_price, false )
			
			-- 4. Remove items from player.
			_result = _trade_count
			TakeItemsFromPlayer(inPlayer, ShopsData[_adress].item, _trade_count)
			OperationState.success = true
			OperationState.amount = _result
			OperationState.money_amount = _result *_unit_price
		end
	else
		_result = -1
	end
	return _result
end
--\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function GetMerchantTradeData( inMerchantName )
	local CheckCashMachine = function( Chest )
		_balance, _free_space = ReadChestForItem(Chest, Settings.BarterItem)
	end
	_balance = 0
	_free_space = 0
	
	if( Settings.Barter == false ) then
		_balance = PM:CallPlugin("Coiny", "getBalanceByName", inMerchantName)
		_free_space = -1	-- makes no sense, but still...
	else
		if( TradersData[inMerchantName] ~= nil ) then
			if( TradersData[inMerchantName].cashmachine ~= nil ) then
				local _x = TradersData[inMerchantName].cashmachine.x
				local _y = TradersData[inMerchantName].cashmachine.y -1
				local _z = TradersData[inMerchantName].cashmachine.z
				local world = cRoot:Get():GetWorld( TradersData[inMerchantName].cashmachine.world )
				world:DoWithChestAt( _x, _y, _z, CheckCashMachine )
			end
		end
	end
	return _balance, _free_space
end

function GetPlayerTradeData( inPlayerName )
	_balance = 0
	_free_space = 0
	local _player = GetPlayerByName(inPlayerName)
	if( Settings.Barter == false ) then
		_balance = PM:CallPlugin("Coiny", "getBalanceByName", inPlayerName)
		_free_space = -1	-- makes no sense, but still...
	else
		_balance, _free_space = ReadPlayerForItem(_player, Settings.BarterItem)
	end
	return _balance, _free_space
end

function MakeTransaction( inPlayerName, inMerchantName, inAmount, inOperationFromChest )	-- UNSAFE, CHECK FIRST
	if( Settings.Barter == false ) then
		PM:CallPlugin("Coiny", "transferMoneyByName", inPlayerName, inMerchantName, inAmount )
	else
		-- coins, coins everywhere!
		local OperateCashMachine = function( Chest )
			if( inOperationFromChest == true ) then
				PutItemsToChest(Chest, Settings.BarterItem, inAmount)
			else
				TakeItemsFromChest(Chest, Settings.BarterItem, inAmount)
			end
		end
		local _player = GetPlayerByName(inPlayerName)
		local _merchant = GetPlayerByName(inMerchantName)
		
		-- 1. Make operations with cash machine
		local _x = TradersData[inMerchantName].cashmachine.x
		local _y = TradersData[inMerchantName].cashmachine.y - 1
		local _z = TradersData[inMerchantName].cashmachine.z
		local world = cRoot:Get():GetWorld( TradersData[inMerchantName].cashmachine.world )
		world:DoWithChestAt( _x, _y, _z, OperateCashMachine )
		
		-- 2. Make operations with pockets
		if( inOperationFromChest == true ) then
			TakeItemsFromPlayer(_player, Settings.BarterItem, inAmount)
		else
			GiveItemsToPlayer(_player, Settings.BarterItem, inAmount)
		end
	end
end
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function LoadData()
	local _split = ""
	file = io.open( PLUGIN:GetLocalFolder().."/trady_shops.dat", "r" )
	if( file == nil ) then		return 1	end
	for line in file:lines() do
		_split = LineSplit( line, ":" )
		-- _split validation!!!
		if( #_split == 10 ) then
			local _adress = GetAdress( cRoot:Get():GetWorld( _split[2] ), _split[3], _split[4], _split[5] )
			if( ShopsData[_adress] == nil ) then
				ShopsData[_adress] = {}	-- create shop's page
			end
			ShopsData[_adress].ownername = _split[1]
			ShopsData[_adress].world = _split[2]
			ShopsData[_adress].x = tonumber( _split[3] )
			ShopsData[_adress].y = tonumber( _split[4] )
			ShopsData[_adress].z = tonumber( _split[5] )
			ShopsData[_adress].item = tonumber( _split[6] )
			ShopsData[_adress].amount = tonumber( _split[7] )
			ShopsData[_adress].tochest = tonumber( _split[8] )
			ShopsData[_adress].fromchest = tonumber( _split[9] )
			ShopsData[_adress].fractional = StringToBool( _split[10] )
		end
	end
	file:close()
	-- / / / / / / / / / / / /
	file = io.open( PLUGIN:GetLocalFolder().."/trady_merchants.dat", "r" )
	if( file == nil ) then		return 1	end
	for line in file:lines() do
		_split = LineSplit( line, ":" )
		-- _split validation!!!
		if( #_split == 5 ) then
			if( TradersData[_split[1]] == nil ) then
				TradersData[_split[1]] = {}	-- create merchant's page
			end
			if( TradersData[_split[1]].cashmachine == nil ) then
				TradersData[_split[1]].cashmachine = {}	-- and don't forget his cash machine too!
			end
			TradersData[_split[1]].cashmachine.world = _split[2]
			TradersData[_split[1]].cashmachine.x = _split[3]
			TradersData[_split[1]].cashmachine.y = _split[4]
			TradersData[_split[1]].cashmachine.z = _split[5]
		end
	end
	file:close()
	LOGINFO( PLUGIN:GetName().." v"..PLUGIN:GetVersion()..": BA DUM TSSSSSS.... Loading complete!" )
end
function SaveData()
	local line = ""
	file = io.open( PLUGIN:GetLocalFolder().."/trady_shops.dat", "w" )
	for k,v in pairs( ShopsData ) do
		line = ""..v.ownername
		line = line..":"..v.world
		line = line..":"..v.x..":"..v.y..":"..v.z
		line = line..":"..v.item
		line = line..":"..v.amount
		line = line..":"..v.tochest
		line = line..":"..v.fromchest
		line = line..":"..tostring( v.fractional )
		file:write( line.."\n" )
	end
	file:close()
	-- / / / / / / / / / / / /
	file = io.open( PLUGIN:GetLocalFolder().."/trady_merchants.dat", "w" )
	for k,v in pairs( TradersData ) do
		if( v.cashmachine ~= nil ) then
			line = ""..k
			line = line..":"..v.cashmachine.world
			line = line..":"..v.cashmachine.x..":"..v.cashmachine.y..":"..v.cashmachine.z
			file:write( line.."\n" )
		end
	end
	file:close()
	LOG( PLUGIN:GetName().." v"..PLUGIN:GetVersion()..": Data was saved" )
end
-- * * * * *
function LoadSettings()
	iniFile = cIniFile()
	iniFile:ReadFile( PLUGIN:GetLocalFolder().."/trady_settings.ini" )
	local saveMode = iniFile:GetValueSet( "Settings", "SaveMode", "Timed" )
	local barterItem = iniFile:GetValueSet( "Settings", "BarterItem", ItemTypeToString( E_ITEM_GOLD_NUGGET ) )
	if( saveMode == "Timed" )		then Settings.SaveMode = eSaveMode_Timed	end
	if( saveMode == "Paranoid" )	then Settings.SaveMode = eSaveMode_Paranoid	end
	if( saveMode == "Relaxed" )		then Settings.SaveMode = eSaveMode_Relaxed	end
	if( saveMode == "Dont" )		then Settings.SaveMode = eSaveMode_Dont		end
	Settings.SaveEveryNthTick = 	iniFile:GetValueSetI( "Settings", "TicksPerSave", 		10000 )
	Settings.FractionalTrade = 		iniFile:GetValueSetB( "Settings", "AllowFractionalTrade", true )
	Settings.Barter = 				iniFile:GetValueSetB( "Settings", "Barter", 				false )
	Settings.BarterItem	= 			BlockStringToType( barterItem )
	Settings.HaltSelfTrade = 		iniFile:GetValueSetB( "Settings", "HaltSelfTrade", 			true )
	LOG( "Ini reading on HaltSelf: "..tostring(Settings.HaltSelfTrade) )
	Settings.UsingProtection = 		iniFile:GetValueSetB( "Settings", "UsingProtection", 	true )
	Settings.BreakingProtection = 	iniFile:GetValueSetB( "Settings", "BreakingProtection",true )
	iniFile:WriteFile( PLUGIN:GetLocalFolder().."/trady_settings.ini" )
end
function SaveSettings()
	iniFile = cIniFile()
	iniFile:ReadFile( PLUGIN:GetLocalFolder().."/trady_settings.ini" )
	local saveMode = iniFile:GetValueSet( "Settings", "SaveMode", "Timed" )
	local _barter_item = iniFile:GetValueSet( "Settings", "BarterItem", ItemTypeToString( E_ITEM_GOLD_NUGGET ) )
	if( Settings.SaveMode == eSaveMode_Timed )		then	saveMode = "Timed"		end
	if( Settings.SaveMode == eSaveMode_Paranoid )	then	saveMode = "Paranoid"	end
	if( Settings.SaveMode == eSaveMode_Relaxed )	then	saveMode = "Relaxed"	end
	if( Settings.SaveMode == eSaveMode_Dont )		then	saveMode = "Dont"		end
	iniFile:SetValueI( "Settings", "TicksPerSave", 			Settings.SaveEveryNthTick, 				false )
	iniFile:SetValue(  "Settings", "SaveMode", 				saveMode, 								false )
	iniFile:SetValueB( "Settings", "AllowFractionalTrade", 	Settings.FrationalTrade, 				false )
	iniFile:SetValueB( "Settings", "Barter", 				Settings.Barter, 						false )
	iniFile:SetValue(  "Settings", "BarterItem", 			ItemTypeToString( Settings.BarterItem ),false )
	iniFile:SetValueB( "Settings", "HaltSelfTrade", 		Settings.HaltSelfTrade, 				false )
	iniFile:SetValueB( "Settings", "UsingProtection", 		Settings.UsingProtection, 				false )
	iniFile:SetValueB( "Settings", "BreakingProtection", 	Settings.BreakingProtection, 			false )
	iniFile:WriteFile( PLUGIN:GetLocalFolder().."/trady_settings.ini" )
end
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- splits line by any desired symbol
function LineSplit( pString, pPattern )		-- THANK YOU, stackoverflow!
	local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find( fpat, 1 )
	while s do
		if( s ~= 1 or cap ~= "" ) then
			table.insert( Table,cap )
		end
		last_end = e + 1
		s, e, cap = pString:find( fpat, last_end )
	end
	if( last_end <= #pString ) then
		cap = pString:sub( last_end )
		table.insert( Table, cap )
	end
	return Table
end

function GetAdress( inWorld, inX, inY, inZ )
	return inWorld:GetName().." x:"..tostring( inX ).." y:"..tostring( inY ).." z:"..tostring( inZ )
end

function GetAdressWorldname( inWorldname, inX, inY, inZ )	-- PROBABLY USELESS
	return inWorldname.." x:"..tostring( inX ).." y:"..tostring( inY ).." z:"..tostring( inZ )
end
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function StringToBool( inString )
	if( inString == "true" ) then	return true		end
	return false
end


--Functions exported from handy--

function GetChestHeightCheat( inChest )
	local chestGrid = inChest:GetContents()
	LOGINFO( "This function serves no purpose now! You should consider chest:GetContents():GetHeight() now!" )
	LOGINFO( "Also, you might find Handy's new 'IsChestDouble()' useful for your case" )
	return chestGrid:GetHeight()
end
function IsChestDouble( inChest )
	local chestHeight = inChest:GetContents():GetHeight()
	if( chestHeight == 3 ) then
		return false
	end
	return true
end
-- Those two checks how many items of given inItemID chest and player have, and how much they could fit inside them
function ReadChestForItem( inChest, inItemID )
	return ReadGridForItems( inChest:GetContents(), inItemID )
end
function ReadPlayerForItem( inPlayer, inItemID )
	local inventoryFound, inventoryFree = ReadGridForItems( inPlayer:GetInventory():GetInventoryGrid(), inItemID )
	local hotbarFound, hotbarFree = ReadGridForItems( inPlayer:GetInventory():GetHotbarGrid(), inItemID )
	local itemsFound = inventoryFound + hotbarFound
	local freeSpace = inventoryFree + hotbarFree
	return itemsFound, freeSpace
end
-- Following functions are for chest-related operations
-- BEWARE! Those assume you did checked if chest has items/space in it!
function ReadGridForItems( inGrid, inItemID )
	local itemsFound = 0
	local freeSpace = 0
	local slotsCount = inGrid:GetNumSlots()
	local testerItem = cItem( inItemID )
	local maxStackSize = testerItem:GetMaxStackSize()
	for index = 0, (slotsCount - 1) do
		slotItem = inGrid:GetSlot( index )
		if( slotItem:IsEmpty() ) then
			freeSpace = freeSpace + maxStackSize
		else
			if( slotItem:IsEqual( testerItem ) ) then
				itemsFound = itemsFound + slotItem.m_ItemCount
				freeSpace = maxStackSize - slotItem.m_ItemCount
			end
		end
	end
	return itemsFound, freeSpace
end

function TakeItemsFromGrid( inGrid, inItem )
	local slotsCount = inGrid:GetNumSlots()
	local removedItem = cItem( inItem )
	for index = 0, (slotsCount - 1) do
		slotItem = inGrid:GetSlot( index )
		if( slotItem:IsSameType( removedItem ) ) then
			if( slotItem.m_ItemCount <= removedItem.m_ItemCount ) then
				removedItem.m_ItemCount = removedItem.m_ItemCount - slotItem.m_ItemCount
				inGrid:EmptySlot( index )
			else
				removedItem.m_ItemCount = slotItem.m_ItemCount - removedItem.m_ItemCount
				inGrid:SetSlot( index, removedItem )
				removedItem.m_ItemCount = 0
			end
			if( removedItem.m_ItemCount <= 0 ) then		break	end
		end
	end
	return removedItem.m_ItemCount
end
--------------
function TakeItemsFromChest( inChest, inItemID, inAmount )	-- MIGHT BE UNSAFE! CHECK FOR ITEMS FIRST!!
	local chestGrid = inChest:GetContents()
	local removedItem = cItem( inItemID, inAmount )
	TakeItemsFromGrid( chestGrid, removedItem )
end
function PutItemsToChest( inChest, inItemID, inAmount )
	local chestGrid = inChest:GetContents()
	local addedItem = cItem( inItemID, inAmount )
	chestGrid:AddItem( addedItem )
end
-- Similar to chest-related.
function TakeItemsFromPlayer( inPlayer, inItemID, inAmount )	-- MIGHT BE UNSAFE! CHECK FIRST!
	local removedItem = cItem( inItemID, inAmount )
	local inventoryGrid = inPlayer:GetInventory():GetInventoryGrid()
	local hotbarGrid = inPlayer:GetInventory():GetHotbarGrid()
	local itemsLeft = TakeItemsFromGrid( inventoryGrid, removedItem )
	if( itemsLeft > 0 ) then
		removedItem = cItem( inItemID, itemsLeft )
		TakeItemsFromGrid( hotbarGrid, removedItem )
	end
end
function GiveItemsToPlayer( inPlayer, inItemID, inAmount )
	local addedItem = cItem( inItemID, inAmount )
	local inventoryGrid = inPlayer:GetInventory():GetInventoryGrid()
	local hotbarGrid = inPlayer:GetInventory():GetHotbarGrid()
	local itemsAdded = inventoryGrid:AddItem( addedItem )
	if( itemsAdded < inAmount ) then
		addedItem.m_ItemCount = addedItem.m_ItemCount - itemsAdded
		hotbarGrid:AddItem( addedItem )
	end
end
-- This function returns item max stack for a given itemID. It uses vanilla max stack size, and uses several non-common items notations;
-- Those are:
-- oneonerecord( because aparently 11record wasn't the best idea in lua scripting application )
-- carrotonastick( because it wasn't added to items.txt yet )
-- waitrecord( for same reason )
-- Feel free to ignore the difference, or to add those to items.txt
function GetItemMaxStack( inItemID )
	local testerItem = cItem( inItemID )
	LOGINFO( "This function serves no real purpose now, maybe consider using cItem:GetMaxStackSize()?" )
	return testerItem:GetMaxStackSize()
end
function ItemIsArmor( inItemID, inCheckForHorseArmor )
	inCheckForHorseArmor = inCheckForHorseArmor or false
	if( inItemID == E_ITEM_LEATHER_CAP )		then	return true		end
	if( inItemID == E_ITEM_LEATHER_TUNIC )		then	return true		end
	if( inItemID == E_ITEM_LEATHER_PANTS )		then	return true		end
	if( inItemID == E_ITEM_LEATHER_BOOTS )		then	return true		end
	
	if( inItemID == E_ITEM_CHAIN_HELMET )		then	return true		end
	if( inItemID == E_ITEM_CHAIN_CHESTPLATE )	then	return true		end
	if( inItemID == E_ITEM_CHAIN_LEGGINGS )		then	return true		end
	if( inItemID == E_ITEM_CHAIN_BOOTS )		then	return true		end
	
	if( inItemID == E_ITEM_IRON_HELMET )		then	return true		end
	if( inItemID == E_ITEM_IRON_CHESTPLATE )	then	return true		end
	if( inItemID == E_ITEM_IRON_LEGGINGS )		then	return true		end
	if( inItemID == E_ITEM_IRON_BOOTS )			then	return true		end
	
	if( inItemID == E_ITEM_DIAMOND_HELMET )		then	return true		end
	if( inItemID == E_ITEM_DIAMOND_CHESTPLATE )	then	return true		end
	if( inItemID == E_ITEM_DIAMOND_LEGGINGS )	then	return true		end
	if( inItemID == E_ITEM_DIAMOND_BOOTS )		then	return true		end
	
	if( inItemID == E_ITEM_GOLD_HELMET )		then	return true		end
	if( inItemID == E_ITEM_GOLD_CHESTPLATE )	then	return true		end
	if( inItemID == E_ITEM_GOLD_LEGGINGS )		then	return true		end
	if( inItemID == E_ITEM_GOLD_BOOTS )			then	return true		end
	
	if( inCheckForHorseArmor ) then
		if( inItemID == E_ITEM_IRON_HORSE_ARMOR )		then	return true		end
		if( inItemID == E_ITEM_GOLD_HORSE_ARMOR )		then	return true		end
		if( inItemID == E_ITEM_DIAMOND_HORSE_ARMOR )	then	return true		end
	end
	return false
end
-- Returns full-length playername for a short name( usefull for parsing commands )
function GetExactPlayername( inPlayerName )
	local _result = inPlayerName
	local function SetProcessingPlayername( inPlayer )
		_result = inPlayer:GetName()
	end
	cRoot:Get():FindAndDoWithPlayer( inPlayerName, SetProcessingPlayername )
	return _result
end
function GetPlayerByName( inPlayerName )
	local _player
	local PlayerSetter = function( Player )
		_player = Player
	end
	cRoot:Get():FindAndDoWithPlayer( inPlayerName, PlayerSetter )
	return _player
end
--[[
Not-so-usual math _functions
]]
-- Rounds floating point number. Because lua guys think this function doesn't deserve to be presented in lua's math
function round( inX )
  if( inX%2 ~= 0.5 ) then
    return math.floor( inX + 0.5 )
  end
  return inX - 0.5
end
--[[
Functions I use for filework and stringswork
]]
function PluralString( inValue, inSingularString, inPluralString )
	local _value_string = tostring( inValue )
	if( _value_string[#_value_string] == "1" ) then
		return inSingularString
	end
	return inPluralString
end
function PluralItemName( inItemID, inAmount )	-- BEWARE! TEMPORAL SOLUTION THERE! :D
	local _value_string = tostring( inValue )
	local _name = ""
	if( _value_string[#_value_string] == "1" ) then
		-- singular names
		_name = ItemTypeToString( inItemID )
	else
		-- plural names
		_name = ItemTypeToString( inItemID ).."s"
	end
	return _name
end
-- for filewriting purposes. 0 = false, 1 = true
function StringToBool( inValue )
	if( inValue == "1" ) then return true end
	return false
end
-- same, but reversal
function BoolToString( inValue )
	if( inValue == true ) then return 1 end
	return 0
end











