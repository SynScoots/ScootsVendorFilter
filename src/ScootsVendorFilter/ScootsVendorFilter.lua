local SVF = {}
SVF.frameStrata = 'MEDIUM'
SVF.frameHeight = 295
SVF.frameWidth = 320
SVF.textSize = 10
SVF.smallTextSize = 9
SVF.bigTextSize = 12
SVF.rowPad = 5
SVF.visibleFrameCount = 10
SVF.borderThickness = 0.7
SVF.currencyHeight = 10
SVF.currencySize = 14
SVF.optionToggleHeight = 18

-----

SVF.open = false
SVF.rowWidth = SVF.frameWidth - 20
SVF.rowHeight = SVF.frameHeight / SVF.visibleFrameCount
SVF.loaded = false
SVF.frame = CreateFrame('Frame', 'SVFMasterFrame', MerchantFrame)
SVF.items = {}
SVF.itemFrames = {}
SVF.currencyFrames = {}
SVF.activeFrame = SVF.frame
SVF.baseFrameLevel = 500
SVF.TTH = nil
SVF.optionsOpen = false
SVF.off = false
SVF.allAttuneCurrencies = {}
SVF.totalAttuneCurrency = {}
SVF.bagContents = {}

function SVF.registerTTH(tooltip)
	SVF.TTH = tooltip
end
_G['ScootsVendorFilter_RegisterTTH'] = SVF.registerTTH

function SVF.setupUi()
	local localizedClass, englishClass = UnitClass('player')
	SVF.playerClass = strupper(englishClass)
	
	local playerFaction = UnitFactionGroup('player')
	if(playerFaction == 'Alliance') then
		SVF.honorIcon = 'Interface/PVPFrame/PVP-Currency-Alliance'
	else
		SVF.honorIcon = 'Interface/PVPFrame/PVP-Currency-Horde'
	end
	
	SVF.frame:EnableMouse(true)
	SVF.frame:SetPoint('TOPLEFT', MerchantFrame, 'TOPLEFT', 20, -75)
	SVF.frame:SetFrameStrata(SVF.frameStrata)
	SVF.frame:SetHeight(SVF.frameHeight)
	SVF.frame:SetWidth(SVF.frameWidth)
	
	-- Make the frame scrollable
	-- https://www.wowinterface.com/forums/showthread.php?t=45982
	SVF.scrollframe = SVF.scrollframe or CreateFrame('ScrollFrame', 'SVFScrollFrame', SVF.frame, 'UIPanelScrollFrameTemplate')
	SVF.scrollframe:SetFrameStrata(SVF.frameStrata)
	SVF.scrollchild = SVF.scrollchild or CreateFrame('Frame', 'SVFScrollChild', SVF.scrollframe)
	SVF.scrollchild:SetFrameStrata(SVF.frameStrata)

	local scrollbarName = SVF.scrollframe:GetName()
	SVF.scrollbar = _G[scrollbarName..'ScrollBar']
	SVF.scrollupbutton = _G[scrollbarName..'ScrollBarScrollUpButton']
	SVF.scrolldownbutton = _G[scrollbarName..'ScrollBarScrollDownButton']

	SVF.scrollupbutton:ClearAllPoints()
	SVF.scrollupbutton:SetPoint('TOPRIGHT', SVF.scrollframe, 'TOPRIGHT', -2, -2)

	SVF.scrolldownbutton:ClearAllPoints()
	SVF.scrolldownbutton:SetPoint('BOTTOMRIGHT', SVF.scrollframe, 'BOTTOMRIGHT', -2, 2)

	SVF.scrollbar:ClearAllPoints()
	SVF.scrollbar:SetPoint('TOP', SVF.scrollupbutton, 'BOTTOM', 0, -2)
	SVF.scrollbar:SetPoint('BOTTOM', SVF.scrolldownbutton, 'TOP', 0, 2)

	SVF.scrollframe:SetScrollChild(SVF.scrollchild)
	SVF.scrollframe:SetAllPoints(SVF.frame)
	
	SVF.scrollchild:SetWidth(SVF.rowWidth)
	SVF.scrollchild:SetHeight(SVF.frameHeight)
	
	-- End scrollable frame
	
	SVF.frame:SetScript('OnUpdate', function()
		if(SVF.off == false) then
			SVF.hideMerchantUi()
			
			SVF.setFrameLevels()
			
			if(SVF.attemptingBackgroundLoad == true) then
				SVF.attemptBackgroundItemLoad()
			end
		end
	end)
	
	SVF.activeChatFrame = nil
	for i = 1, 10 do
		_G['ChatFrame' .. i .. 'EditBox']:HookScript('OnEditFocusGained', function()
			SVF.activeChatFrame = i
		end)

		_G['ChatFrame' .. i .. 'EditBox']:HookScript('OnEditFocusLost', function()
			SVF.activeChatFrame = nil
		end)
	end
	
	_G['MerchantFrameTab1']:HookScript('OnMouseDown', function()
		SVF.open = true
		if(SVF.off ~= true) then
			SVF.hideMerchantUi()
			SVF.activeFrame:Show()
		end
	end)
	
	_G['MerchantFrameTab2']:HookScript('OnMouseDown', function()
		SVF.open = false
		SVF.activeFrame:Hide()
		SVF.showBuybackUi()
	end)
	
	SVF.optionsButton = CreateFrame('Button', 'SVFOptionsButton', MerchantFrame, 'UIPanelButtonTemplate')
	SVF.optionsButton:SetSize(140, 24)
	SVF.optionsButton:SetText('ScootsVendorFilter')
	SVF.optionsButton:SetPoint('TOPLEFT', MerchantFrame, 'TOPLEFT', 65, -35)
	SVF.optionsButton:SetFrameStrata(SVF.frameStrata)
	
	SVF.optionsButton:SetScript('OnClick', function()
		if(SVF.optionsOpen) then
			SVF.closeOptions()
		else
			SVF.openOptions()
		end
	end)
	
	SVF.synopsisFrame = CreateFrame('Button', 'SVFSynopsisFrame', MerchantFrame)
	SVF.synopsisFrame:SetHeight(SVF.smallTextSize)
	SVF.synopsisFrame:SetPoint('TOPLEFT', MerchantFrame, 'TOPLEFT', 70, -60)
	SVF.synopsisFrame.text = SVF.synopsisFrame:CreateFontString(nil, 'ARTWORK')
	SVF.synopsisFrame.text:SetFont('Fonts\\FRIZQT__.TTF', SVF.smallTextSize)
	SVF.synopsisFrame.text:SetPoint('TOPLEFT', 0, 0)
	SVF.synopsisFrame.text:SetJustifyH('LEFT')
	SVF.synopsisFrame.text:SetTextColor(1, 1, 1)
	
	SVF.loaded = true
end

function SVF.hideMerchantUi()
	if(SVF.open) then
		_G['MerchantItem1']:Hide()
		_G['MerchantItem2']:Hide()
		_G['MerchantItem3']:Hide()
		_G['MerchantItem4']:Hide()
		_G['MerchantItem5']:Hide()
		_G['MerchantItem6']:Hide()
		_G['MerchantItem7']:Hide()
		_G['MerchantItem8']:Hide()
		_G['MerchantItem9']:Hide()
		_G['MerchantItem10']:Hide()
		_G['MerchantPrevPageButton']:Hide()
		_G['MerchantPageText']:Hide()
		_G['MerchantNextPageButton']:Hide()
	end
end

function SVF.showMerchantUi()
	_G['MerchantItem1']:Show()
	_G['MerchantItem2']:Show()
	_G['MerchantItem3']:Show()
	_G['MerchantItem4']:Show()
	_G['MerchantItem5']:Show()
	_G['MerchantItem6']:Show()
	_G['MerchantItem7']:Show()
	_G['MerchantItem8']:Show()
	_G['MerchantItem9']:Show()
	_G['MerchantItem10']:Show()
	_G['MerchantPrevPageButton']:Show()
	_G['MerchantPageText']:Show()
	_G['MerchantNextPageButton']:Show()
end

function SVF.showBuybackUi()
	_G['MerchantItem1']:Show()
	_G['MerchantItem2']:Show()
	_G['MerchantItem3']:Show()
	_G['MerchantItem4']:Show()
	_G['MerchantItem5']:Show()
	_G['MerchantItem6']:Show()
	_G['MerchantItem7']:Show()
	_G['MerchantItem8']:Show()
	_G['MerchantItem9']:Show()
	_G['MerchantItem10']:Show()
end

function SVF.merchantShow()
	SVF.open = true
	SVF.applyFilter()
end

function SVF.MerchantClose()
	SVF.open = false
	SVF.items = {}
	SVF.clear()
	SVF.activeFrame = SVF.frame
	SVF.frame:Show()
	
	if(SVF.optionsOpen) then
		SVF.closeOptions()
	end
end

function SVF.MerchantUpdate()
	for i, item in ipairs(SVF.items) do
		if(item.available ~= -1) then
			SVF.updateItemAvailableDisplay(item)
		end
	end
end

function SVF.addS(context, count)
	local s = 's'
	if(count == 1) then
		s = ''
	end
	
	return context .. s
end

function SVF.updateBagContents()
	SVF.bagContents = {}
	for bagId = 0, 4, 1 do
		local containerLength = GetContainerNumSlots(bagId)
		for slotId = 1, containerLength, 1 do
			local _, _, _, _, _, _, itemLink = GetContainerItemInfo(bagId, slotId)
			
			if(itemLink ~= nil) then
				SVF.bagContents[itemLink] = true
			end
		end
	end
end

function SVF.applyFilter()
	SVF.items = {}
	SVF.hiddenItems = 0
	SVF.hiddenEquipment = 0
	SVF.hiddenWeapons = 0
	SVF.hiddenRecipes = 0
	
	SVF.merchantItems = GetMerchantNumItems()
	local itemsFound = 0
	for index = 1, SVF.merchantItems do
		local itemLink = GetMerchantItemLink(index)
		
		if(itemLink ~= nil) then
			itemsFound = itemsFound + 1
			
			local itemID = itemLink:gsub('^|%x+|Hitem:', ''):gsub(':.+$', '')
			local itemName, _, itemRarity, _, itemMinLevel, itemType, itemSubType, _, itemEquipLoc, itemTexture = GetItemInfo(itemLink)
			local _, _, price, _, _, isUsable, extendedCost = GetMerchantItemInfo(index)
			local itemArray = {
				['merchantIndex'] = index,
				['id'] = itemID,
				['name'] = itemName,
				['link'] = itemLink,
				['rarity'] = itemRarity,
				['level'] = itemMinLevel,
				['type'] = itemType,
				['subtype'] = itemSubType,
				['location'] = itemEquipLoc,
				['attune'] = -1,
				['icon'] = itemTexture,
				['cost'] = price,
				['extCost'] = extendedCost,
				['usable'] = isUsable,
				['available'] = numAvailable
			}
			
			if(itemArray.type == 'Weapon' and itemArray.location == 'INVTYPE_WEAPONOFFHAND' and (
				   SVF.playerClass == 'DRUID'
				or SVF.playerClass == 'MAGE'
				or SVF.playerClass == 'PRIEST'
				or SVF.playerClass == 'WARLOCK'
			)) then
				itemArray.usable = false
			end
			
			if(GetItemAttuneForge ~= nil) then
				itemArray.attune = GetItemAttuneForge(itemID)
			end
			
			if(SVF.filter(itemArray)) then
				table.insert(SVF.items, itemArray)
			else
				SVF.hiddenItems = SVF.hiddenItems + 1
			end
		end
		
		SVF.synopsisFrame.text:SetText(SVF.hiddenItems .. SVF.addS(' item', SVF.hiddenItems) .. ' filtered')
		SVF.synopsisFrame:SetWidth(SVF.synopsisFrame.text:GetStringWidth())
	end
	
	if(itemsFound ~= SVF.merchantItems) then
		if(SVF.options.debug) then
			print('ScootsVendorFilter: Expected ' .. SVF.merchantItems .. ' items. API only returned ' .. itemsFound)
		end
		
		if(SVF.previousLoadedItems == nil or SVF.previousLoadedItems ~= itemsFound) then
			SVF.previousLoadedItems = itemsFound
			SVF.attemptingBackgroundLoad = false
		end
		
		if(SVF.attemptingBackgroundLoad == false) then
			if(SVF.options.debug) then
				print('ScootsVendorFilter: Attempting to force-load items...')
			end
			SVF.attemptingBackgroundLoad = true
			return nil
		end
	end
	
	SVF.attemptingBackgroundLoad = false
	
	if(SVF.off ~= true) then
		local itemCount = table.getn(SVF.items)
		local frameHeight = itemCount * SVF.rowHeight
		if(frameHeight < SVF.frameHeight) then
			frameHeight = SVF.frameHeight
		end
		SVF.scrollchild:SetHeight(frameHeight)
		
		if(itemCount == 0) then
			if(SVF.noResultsFrame == nil) then
				SVF.noResultsFrame = SVF.createItemFrame('SVFnoItemsFrame')
			end
			SVF.noResultsFrame:Show()
			
			SVF.noResultsFrame:SetPoint('TOPLEFT', SVF.scrollchild, 'TOPLEFT', 0, 0)
			SVF.noResultsFrame.text:SetPoint('LEFT', SVF.rowPad, 0)
			SVF.noResultsFrame.text:SetWidth(SVF.rowWidth - (SVF.rowPad * 2))
			SVF.noResultsFrame.text:SetText('No unfiltered items available for purchase.')
		else
			if(SVF.noResultsFrame ~= nil) then
				SVF.noResultsFrame:Hide()
			end
			
			SVF.currencyIndex = 0
			SVF.allAttuneCurrencies = {}
			SVF.totalAttuneCurrency = {}
			for i, item in ipairs(SVF.items) do
				if(SVF.itemFrames[i] == nil) then
					SVF.itemFrames[i] = SVF.createItemFrame('SVFitemFrame' .. i, item)
				end
				
				item.frameIndex = i
				
				SVF.renderItem(item)
			end
			
			if(SVF.options.printAttunementCost == true) then
				SVF.printTotalAttunementCosts()
			end
		end
	end
end

function SVF.attemptBackgroundItemLoad()
	if(SVF.delay == nil or SVF.delay == 0) then
		SVF.delay = 10
	end
	
	SVF.delay = SVF.delay - 1
	if(SVF.delay <= 0) then
		local _, _, _, _, framePoint = MerchantItem9:GetPoint();
		if(framePoint == -8) then
			local numPages = ceil(SVF.merchantItems / 10)
			if(MerchantFrame.page == numPages) then
				if(SVF.options.debug) then
					print('ScootsVendorFilter: Finished attempting to load items. Re-rendering.')
				end
				SVF.applyFilter()
			else
				MerchantItem9:SetPoint('TOPLEFT', 'MerchantItem7', 'BOTTOMLEFT', 0, -9)
				MerchantFrame.page = MerchantFrame.page + 1
				MerchantFrame_Update()
			end
		end
	end
end

function getItemTooltip(item)
	if(item.tooltip ~= nil) then
		return item.tooltip
	end
	
	item.tooltip = {}
	
	SVF.TTH:ClearLines()
	SVF.TTH:SetOwner(UIParent)
	SVF.TTH:SetHyperlink(item.link)
	
	local tooltipLines = {SVF.TTH:GetRegions()}
	for _, line in ipairs(tooltipLines) do
		if(line:IsObjectType('FontString')) then
			local lineText = line:GetText()
			if(lineText ~= nil and lineText ~= '') then
				table.insert(item.tooltip, lineText)
			end
		end
	end
	
	SVF.TTH:Hide()
	
	return item.tooltip
end

function SVF.getAttunementColours(item)
	local colours = {
		['front'] = {
			['r'] = 1,
			['g'] = 1,
			['b'] = 1,
			['a'] = 0.4
		},
		['back'] = {
			['r'] = 0,
			['g'] = 0,
			['b'] = 0,
			['a'] = 0.1
		}
	}
	
	if(item.attune == -1) then
		colours.back.r = 1
		colours.back.g = 1
		colours.back.b = 1
		colours.back.a = 0
	elseif(item.attune == 0) then
		colours.front.r = 0.65
		colours.front.g = 1
		colours.front.b = 0.5
		colours.back.r = 0.5
		colours.back.g = 1
		colours.back.b = 0.5
	elseif(item.attune == 1) then
		colours.front.r = 0.5
		colours.front.g = 0.5
		colours.front.b = 1
		colours.back.r = 0.5
		colours.back.g = 0.5
		colours.back.b = 1
	elseif(item.attune == 2) then
		colours.front.r = 1
		colours.front.g = 0.65
		colours.front.b = 0.5
		colours.back.r = 1
		colours.back.g = 0.5
		colours.back.b = 0.5
	elseif(item.attune == 3) then
		colours.front.r = 1
		colours.front.g = 1
		colours.front.b = 0.65
		colours.back.r = 1
		colours.back.g = 1
		colours.back.b = 0.5
	end
	
	return colours
end

function SVF.createItemFrame(frameName, item)
	local rowFrame = CreateFrame('Frame', frameName, SVF.scrollchild)
	rowFrame:SetFrameStrata(SVF.frameStrata)
	rowFrame:SetSize(SVF.rowWidth, SVF.rowHeight)
	rowFrame.text = rowFrame:CreateFontString(nil, 'ARTWORK')
	rowFrame.text:SetFont('Fonts\\FRIZQT__.TTF', SVF.textSize)
	rowFrame.text:SetWordWrap(true)
	rowFrame.text:SetJustifyH('LEFT')
	rowFrame.texture = rowFrame:CreateTexture()
	rowFrame.texture:SetAllPoints()
	
	if(item) then
		rowFrame.itemLink = item.link
		rowFrame.merchantIndex = item.merchantIndex
		rowFrame.quantityAvailable = item.available
		rowFrame.frameIndex = item.frameIndex
		rowFrame.hover = false
		rowFrame:EnableMouse(true)
	
		rowFrame.borderTop = CreateFrame('Frame', frameName .. 'BorderTop', rowFrame)
		rowFrame.borderTop:SetFrameStrata(SVF.frameStrata)
		rowFrame.borderTop:SetSize(SVF.rowWidth, SVF.borderThickness)
		rowFrame.borderTop:SetPoint('TOPLEFT', rowFrame, 'TOPLEFT', 0, 0)
		rowFrame.borderTop.texture = rowFrame.borderTop:CreateTexture()
		rowFrame.borderTop.texture:SetAllPoints()
		
		rowFrame.borderBottom = CreateFrame('Frame', frameName .. 'BorderBottom', rowFrame)
		rowFrame.borderBottom:SetFrameStrata(SVF.frameStrata)
		rowFrame.borderBottom:SetSize(SVF.rowWidth, SVF.borderThickness)
		rowFrame.borderBottom:SetPoint('BOTTOMLEFT', rowFrame, 'BOTTOMLEFT', 0, 0)
		rowFrame.borderBottom.texture = rowFrame.borderBottom:CreateTexture()
		rowFrame.borderBottom.texture:SetAllPoints()
		
		rowFrame.iconFrame = CreateFrame('Frame', frameName .. 'IconFrame', rowFrame)
		rowFrame.iconFrame:SetFrameStrata(SVF.frameStrata)
		rowFrame.iconFrame:SetSize(SVF.rowHeight - (SVF.borderThickness * 8), SVF.rowHeight - (SVF.borderThickness * 8))
		rowFrame.iconFrame:SetPoint('TOPLEFT', rowFrame, 'TOPLEFT', (SVF.borderThickness * 4), (SVF.borderThickness * 4) * -1)
		rowFrame.iconFrame.texture = rowFrame.iconFrame:CreateTexture()
		rowFrame.iconFrame.texture:SetAllPoints()
		rowFrame.iconFrame.text = rowFrame.iconFrame:CreateFontString(nil, 'ARTWORK')
		rowFrame.iconFrame.text:SetFont('Fonts\\FRIZQT__.TTF', SVF.bigTextSize, 'THINOUTLINE')
		rowFrame.iconFrame.text:SetPoint('TOPLEFT', 0, -2)
		rowFrame.iconFrame.text:SetJustifyH('LEFT')
		rowFrame.iconFrame.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		rowFrame.iconFrame.text:SetShadowOffset(0, 0)
		rowFrame.iconFrame.text:SetShadowColor(0, 0, 0, 1)
		
		rowFrame.text:SetPoint('TOPLEFT', SVF.rowHeight, (SVF.borderThickness * 4) * -1)
		rowFrame.text:SetWidth(SVF.rowWidth - (SVF.rowHeight + SVF.rowPad))
		
		rowFrame:SetScript('OnUpdate', function(self)
			if(self.hover) then
				if(IsControlKeyDown()) then
					ShowInspectCursor()
				else
					ShowMerchantSellCursor(self.merchantIndex)
				end
			end
		end)
		
		rowFrame:SetScript('OnEnter', function(self)
			self.hover = true
			
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
			GameTooltip:SetMerchantItem(self.merchantIndex)
			GameTooltip_ShowCompareItem(GameTooltip)
			
			self.text:SetTextColor(self.colours.front.r, self.colours.front.g, self.colours.front.b)
			self.borderTop.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, (self.colours.front.a + 0.1))
			self.borderBottom.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, (self.colours.front.a + 0.1))
			self.texture:SetTexture(self.colours.back.r, self.colours.back.g, self.colours.back.b, (self.colours.back.a + 0.1))
		end)
		
		rowFrame:SetScript('OnLeave', function(self)
			self.hover = false
			SetCursor(nil)
			
			GameTooltip:Hide()			
			
			self.text:SetTextColor(self.colours.front.r, self.colours.front.g, self.colours.front.b)
			self.borderTop.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, self.colours.front.a)
			self.borderBottom.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, self.colours.front.a)
			self.texture:SetTexture(self.colours.back.r, self.colours.back.g, self.colours.back.b, self.colours.back.a)
		end)
		
		rowFrame:SetScript('OnMouseDown', function(self, button)
			if(IsShiftKeyDown()) then
				if(SVF.activeChatFrame ~= nil) then
					local editBox = DEFAULT_CHAT_FRAME.editBox
					ChatEdit_ActivateChat(editBox)
					editBox:Insert(self.itemLink)
				else
					local maxStack = GetMerchantItemMaxStack(self.merchantIndex)
					OpenStackSplitFrame(maxStack, self, 'BOTTOMLEFT', 'TOPLEFT')
				end
			elseif(IsControlKeyDown()) then
				DressUpItemLink(self.itemLink)
			elseif(button == 'LeftButton') then
				PickupMerchantItem(self.merchantIndex)
			else
				BuyMerchantItem(self.merchantIndex, 1)
			end
		end)
		
		rowFrame.SplitStack = function(self, split)
			BuyMerchantItem(self.merchantIndex, split)
		end
	end
	
	return rowFrame
end

function SVF.getCurrencyFrame(index)
	if(SVF.currencyFrames[index] ~= nil) then
		SVF.currencyFrames[index]:Show()
		return SVF.currencyFrames[index]
	end
	
	SVF.currencyFrames[index] = CreateFrame('Frame', 'SVFCurrencyFrame' .. index)
	SVF.currencyFrames[index]:SetFrameStrata(SVF.frameStrata)
	SVF.currencyFrames[index]:EnableMouse(true)
	
	SVF.currencyFrames[index].text = SVF.currencyFrames[index]:CreateFontString(nil, 'ARTWORK')
	SVF.currencyFrames[index].text:SetFont('Fonts\\FRIZQT__.TTF', SVF.textSize)
	SVF.currencyFrames[index].text:SetJustifyH('LEFT')
	SVF.currencyFrames[index].text:SetPoint('BOTTOMLEFT', 0, 0)
	SVF.currencyFrames[index].text:SetTextColor(1, 1, 1)
				
	SVF.currencyFrames[index]:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(self.currencyName)
		GameTooltip:Show()
	end)
	
	SVF.currencyFrames[index]:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	return SVF.currencyFrames[index]
end

function SVF.buildCurrencyArray(item)
	local currencies = {}
			
	if(item.cost ~= nil and item.cost > 0) then
		local gold = math.floor(item.cost / 10000)
		if(gold > 0) then
			table.insert(currencies, {
				['name'] = 'Gold',
				['icon'] = 'Interface/MoneyFrame/UI-GoldIcon',
				['amnt'] = gold
			})
		end
		
		local silver = math.floor(item.cost / 100) % 100
		if(silver > 0) then
			table.insert(currencies, {
				['name'] = 'Silver',
				['icon'] = 'Interface/MoneyFrame/UI-SilverIcon',
				['amnt'] = silver
			})
		end
		
		local copper = item.cost % 100
		if(copper > 0) then
			table.insert(currencies, {
				['name'] = 'Copper',
				['icon'] = 'Interface/MoneyFrame/UI-CopperIcon',
				['amnt'] = copper
			})
		end
	end
	
	if(item.extCost == 1) then
		local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(item.merchantIndex)
		
		if(honorPoints > 0) then
			table.insert(currencies, {
				['name'] = 'Honor Points',
				['icon'] = SVF.honorIcon,
				['amnt'] = honorPoints
			})
		end
		
		if(arenaPoints > 0) then
			table.insert(currencies, {
				['name'] = 'Arena Points',
				['icon'] = 'Interface/PVPFrame/PVP-ArenaPoints-Icon',
				['amnt'] = arenaPoints
			})
		end
		
		if(itemCount > 0) then
			for currencyIndex = 1, 3 do
				local currencyTexture, currencyCount, currencyItemLink = GetMerchantItemCostItem(item.merchantIndex, currencyIndex)
				
				if(currencyItemLink ~= nil) then
					local itemName = GetItemInfo(currencyItemLink)
					
					table.insert(currencies, {
						['name'] = itemName,
						['icon'] = currencyTexture,
						['amnt'] = currencyCount
					})
				end
			end
		end
	end
	
	return currencies
end

function SVF.renderItem(item)
	local i = item.frameIndex
	
	SVF.itemFrames[i]:Show()
	SVF.itemFrames[i].merchantIndex = item.merchantIndex
	SVF.itemFrames[i].frameIndex = item.frameIndex
	SVF.itemFrames[i].itemLink = item.link
	SVF.itemFrames[i].quantityAvailable = item.available
	
	SVF.itemFrames[i]:SetPoint('TOPLEFT', SVF.scrollchild, 'TOPLEFT', 0, ((i - 1) * SVF.rowHeight) * -1)
	SVF.itemFrames[i].text:SetText(item.name)
	
	SVF.itemFrames[i].iconFrame:SetBackdrop({
		bgFile = item.icon
	})
	
	if(item.usable) then
		SVF.itemFrames[i].iconFrame.texture:SetTexture(0, 0, 0, 0)
	else
		SVF.itemFrames[i].iconFrame.texture:SetTexture(1, 0, 0, 0.5)
	end
	
	SVF.updateItemAvailableDisplay(item)
	
	SVF.itemFrames[i].colours = SVF.getAttunementColours(item)
	
	SVF.itemFrames[i].text:SetTextColor(SVF.itemFrames[i].colours.front.r, SVF.itemFrames[i].colours.front.g, SVF.itemFrames[i].colours.front.b)
	SVF.itemFrames[i].borderTop.texture:SetTexture(SVF.itemFrames[i].colours.front.r, SVF.itemFrames[i].colours.front.g, SVF.itemFrames[i].colours.front.b, SVF.itemFrames[i].colours.front.a)
	SVF.itemFrames[i].borderBottom.texture:SetTexture(SVF.itemFrames[i].colours.front.r, SVF.itemFrames[i].colours.front.g, SVF.itemFrames[i].colours.front.b, SVF.itemFrames[i].colours.front.a)
	SVF.itemFrames[i].texture:SetTexture(SVF.itemFrames[i].colours.back.r, SVF.itemFrames[i].colours.back.g, SVF.itemFrames[i].colours.back.b, SVF.itemFrames[i].colours.back.a)
	
	local currencies = SVF.buildCurrencyArray(item)
	
	leftOffset = SVF.rowHeight
	for currencyIndex, currency in ipairs(currencies) do
		SVF.currencyIndex = SVF.currencyIndex + 1
		local currencyFrame = SVF.getCurrencyFrame(SVF.currencyIndex)
		
		currencyFrame:SetParent(SVF.itemFrames[i])
		currencyFrame.currencyName = currency.name
		
		currencyFrame.text:SetText('|T' .. currency.icon .. ':' .. SVF.currencySize .. ':' .. SVF.currencySize .. '|t' .. currency.amnt)
		currencyFrame:SetSize(currencyFrame.text:GetStringWidth(), SVF.currencySize)
		
		currencyFrame:SetPoint('BOTTOMLEFT', SVF.itemFrames[i], 'BOTTOMLEFT', leftOffset, SVF.borderThickness * 4)
		leftOffset = leftOffset + currencyFrame:GetWidth() + 10
		
		if(CanAttuneItemHelper ~= nil and CanAttuneItemHelper(tonumber(item.id)) == 1) then
			if(SVF.totalAttuneCurrency[currency.name] == nil) then
				table.insert(SVF.allAttuneCurrencies, currency.name)
				
				SVF.totalAttuneCurrency[currency.name] = {
					['name'] = currency.name,
					['icon'] = currency.icon,
					['total'] = 0
				}
			end
			
			SVF.totalAttuneCurrency[currency.name].total = SVF.totalAttuneCurrency[currency.name].total + currency.amnt
		end
	end
end

function SVF.updateItemAvailableDisplay(item)
	local i = item.frameIndex
	
	if(SVF.itemFrames[i] ~= nil) then
		SVF.itemFrames[i]:SetAlpha(1)
		local _, _, _, _, numAvailable = GetMerchantItemInfo(item.merchantIndex)
		item.available = numAvailable
		
		if(item.available <= 0) then
			SVF.itemFrames[i].iconFrame.text:Hide()
			
			if(item.available == 0) then
				SVF.itemFrames[i]:SetAlpha(0.5)
			end
		else
			SVF.itemFrames[i].iconFrame.text:Show()
			SVF.itemFrames[i].iconFrame.text:SetText('(' .. item.available .. ')')
		end
	end
end

function SVF.formatNumber(num)
	local formatted = num
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then
			break
		end
	end
	return formatted
end

function SVF.printTotalAttunementCosts()
	if(table.getn(SVF.allAttuneCurrencies) == 0) then
		return nil
	end
	
	print('|cff3bd17a+---------------------------------------------------|r')
	print('|cff3bd17a|||r |cffd98148Cost to purchase all visible items:|r')
	print('|cff3bd17a+---------------------------------------------------|r')
	
	local copper = 0
	
	table.sort(SVF.allAttuneCurrencies)
	for i, currency in ipairs(SVF.allAttuneCurrencies) do
		if(currency == 'Gold') then
			copper = copper + (SVF.totalAttuneCurrency[currency].total * 10000)
		elseif(currency == 'Silver') then
			copper = copper + (SVF.totalAttuneCurrency[currency].total * 100)
		elseif(currency == 'Copper') then
			copper = copper + SVF.totalAttuneCurrency[currency].total
		else
			print(table.concat({
				'|cff3bd17a|||r ',
				'|T' .. SVF.totalAttuneCurrency[currency].icon .. ':0|t',
				SVF.formatNumber(SVF.totalAttuneCurrency[currency].total),
			}, ''))
		end
	end
	
	if(copper > 0) then
		print(table.concat({
			'|cff3bd17a|||r ',
			'|TInterface/MoneyFrame/UI-GoldIcon:0|t',
			ScootsCurrency_FormatNumber(math.floor(copper / 10000)),
			' ',
			'|TInterface/MoneyFrame/UI-SilverIcon:0|t',
			math.floor(copper / 100) % 100,
			' ',
			'|TInterface/MoneyFrame/UI-CopperIcon:0|t',
			copper % 100
		}, ''))
	end
	
	print('|cff3bd17a+---------------------------------------------------|r')
end

function SVF.clear()
	for _, frame in ipairs(SVF.itemFrames) do
		frame:Hide()
	end
	
	for _, frame in ipairs(SVF.currencyFrames) do
		frame:Hide()
	end
end

function SVF.filter(itemArray)
	if(itemArray.type == 'Weapon') then
		return SVF.weaponFilter(itemArray) and SVF.attuneFilter(itemArray) and SVF.bagFilter(itemArray)
	elseif(itemArray.type == 'Armor') then
		return SVF.armourFilter(itemArray) and SVF.attuneFilter(itemArray) and SVF.bagFilter(itemArray)
	elseif(itemArray.type == 'Recipe') then
		return SVF.recipeFilter(itemArray) and SVF.bagFilter(itemArray)
	end
	
	if(SVF.options.debug) then
		local knownTypes = {
			['Quest'] = true,
			['Money'] = true,
			['Trade Goods'] = true,
			['Miscellaneous'] = true,
			['Gem'] = true,
			['Consumable'] = true,
			['Projectile'] = true,
			['Reagent'] = true,
			['Container'] = true
		}
	
		if(knownTypes[itemArray.type] == nil) then
			print('ScootsVendorFilter: unhandled type: ' .. itemArray.type)
			print(itemArray.link)
		end
	end
	
	return true
end

function SVF.weaponFilter(itemArray)
	if(SVF.options.showUnusableWeapons == true) then
		return true
	end

	if(SVF.options.alwaysShowHeirlooms == true and itemArray.rarity == 7) then
		return true
	end
	
	local validForAll = {
		['Miscellaneous'] = true,
		['Fishing Poles'] = true
	}
	
	if(validForAll[itemArray.subtype] ~= nil) then
		return true
	end

	local map = {
		['Daggers'] = {
			['DRUID'] = true,
			['HUNTER'] = true,
			['MAGE'] = true,
			['PRIEST'] = true,
			['ROGUE'] = true,
			['SHAMAN'] = true,
			['WARLOCK'] = true,
			['WARRIOR'] = true
		},
		['Fist Weapons'] = {
			['DRUID'] = true,
			['HUNTER'] = true,
			['ROGUE'] = true,
			['SHAMAN'] = true,
			['WARRIOR'] = true
		},
		['One-Handed Swords'] = {
			['DEATHKNIGHT'] = true,
			['HUNTER'] = true,
			['MAGE'] = true,
			['PALADIN'] = true,
			['ROGUE'] = true,
			['WARLOCK'] = true,
			['WARRIOR'] = true
		},
		['Two-Handed Swords'] = {
			['DEATHKNIGHT'] = true,
			['HUNTER'] = true,
			['PALADIN'] = true,
			['WARRIOR'] = true
		},
		['One-Handed Axes'] = {
			['DEATHKNIGHT'] = true,
			['HUNTER'] = true,
			['PALADIN'] = true,
			['ROGUE'] = true,
			['SHAMAN'] = true,
			['WARRIOR'] = true
		},
		['Two-Handed Axes'] = {
			['DEATHKNIGHT'] = true,
			['HUNTER'] = true,
			['PALADIN'] = true,
			['SHAMAN'] = true,
			['WARRIOR'] = true
		},
		['One-Handed Maces'] = {
			['DEATHKNIGHT'] = true,
			['DRUID'] = true,
			['PALADIN'] = true,
			['PRIEST'] = true,
			['ROGUE'] = true,
			['SHAMAN'] = true,
			['WARRIOR'] = true
		},
		['Two-Handed Maces'] = {
			['DEATHKNIGHT'] = true,
			['DRUID'] = true,
			['PALADIN'] = true,
			['SHAMAN'] = true,
			['WARRIOR'] = true
		},
		['Polearms'] = {
			['DEATHKNIGHT'] = true,
			['HUNTER'] = true,
			['PALADIN'] = true,
			['WARRIOR'] = true
		},
		['Staves'] = {
			['DRUID'] = true,
			['HUNTER'] = true,
			['MAGE'] = true,
			['PRIEST'] = true,
			['SHAMAN'] = true,
			['WARLOCK'] = true,
			['WARRIOR'] = true
		},
		['Thrown'] = {
			['HUNTER'] = true,
			['ROGUE'] = true,
			['WARRIOR'] = true
		},
		['Bows'] = {
			['HUNTER'] = true,
			['ROGUE'] = true,
			['WARRIOR'] = true
		},
		['Crossbows'] = {
			['HUNTER'] = true,
			['ROGUE'] = true,
			['WARRIOR'] = true
		},
		['Guns'] = {
			['HUNTER'] = true,
			['ROGUE'] = true,
			['WARRIOR'] = true
		},
		['Wands'] = {
			['MAGE'] = true,
			['PRIEST'] = true,
			['WARLOCK'] = true
		}
	}
	
	if(map[itemArray.subtype] ~= nil) then
		if(map[itemArray.subtype][SVF.playerClass] ~= nil) then
			if(itemArray.location == 'INVTYPE_WEAPONOFFHAND' and (
				   SVF.playerClass == 'DRUID'
				or SVF.playerClass == 'MAGE'
				or SVF.playerClass == 'PRIEST'
				or SVF.playerClass == 'WARLOCK'
			)) then
				return false
			end
			
			return true
		else
			SVF.hiddenWeapons = SVF.hiddenWeapons + 1
			return false
		end
	elseif(SVF.options.debug) then
		print('ScootsVendorFilter: Unhandled weapon subtype: ' .. itemArray.subtype)
		print(itemArray.link)
	end
	
	return true
end

function SVF.armourFilter(itemArray)
	if(SVF.options.alwaysShowHeirlooms == true and itemArray.rarity == 7) then
		return true
	end
	
	if(
		   itemArray.location == 'INVTYPE_NECK'
		or itemArray.location == 'INVTYPE_FINGER'
		or itemArray.location == 'INVTYPE_TRINKET'
		or itemArray.location == 'INVTYPE_CLOAK'
		or itemArray.location == 'INVTYPE_HOLDABLE'
		or itemArray.location == 'INVTYPE_TABARD'
	) then
		return true
	end
	
	-- 0: not wearable, 1: wearable, 2: attuneable
	local map = {}
	if(itemArray.subtype == 'Cloth') then
		map = {
			['DEATHKNIGHT'] = 1,
			['DRUID'] = 1,
			['HUNTER'] = 1,
			['MAGE'] = 2,
			['PALADIN'] = 1,
			['PRIEST'] = 2,
			['ROGUE'] = 1,
			['SHAMAN'] = 1,
			['WARLOCK'] = 2,
			['WARRIOR'] = 1
		}
	elseif(itemArray.subtype == 'Leather') then
		map = {
			['DEATHKNIGHT'] = 1,
			['DRUID'] = 2,
			['HUNTER'] = 1,
			['MAGE'] = 0,
			['PALADIN'] = 1,
			['PRIEST'] = 0,
			['ROGUE'] = 2,
			['SHAMAN'] = 1,
			['WARLOCK'] = 0,
			['WARRIOR'] = 1
		}
		
		if(itemArray.level < 40) then
			map.HUNTER = 2
			map.SHAMAN = 2
		end
	elseif(itemArray.subtype == 'Mail') then
		map = {
			['DEATHKNIGHT'] = 1,
			['DRUID'] = 0,
			['HUNTER'] = 2,
			['MAGE'] = 0,
			['PALADIN'] = 1,
			['PRIEST'] = 0,
			['ROGUE'] = 0,
			['SHAMAN'] = 2,
			['WARLOCK'] = 0,
			['WARRIOR'] = 1
		}
		
		if(itemArray.level < 40) then
			map.HUNTER = 1
			map.SHAMAN = 1
			map.PALADIN = 2
			map.WARRIOR = 2
		end
	elseif(itemArray.subtype == 'Plate') then
		map = {
			['DEATHKNIGHT'] = 2,
			['DRUID'] = 0,
			['HUNTER'] = 0,
			['MAGE'] = 0,
			['PALADIN'] = 2,
			['PRIEST'] = 0,
			['ROGUE'] = 0,
			['SHAMAN'] = 0,
			['WARLOCK'] = 0,
			['WARRIOR'] = 2
		}
	elseif(itemArray.subtype == 'Idols') then
		map = {
			['DEATHKNIGHT'] = 0,
			['DRUID'] = 2,
			['HUNTER'] = 0,
			['MAGE'] = 0,
			['PALADIN'] = 0,
			['PRIEST'] = 0,
			['ROGUE'] = 0,
			['SHAMAN'] = 0,
			['WARLOCK'] = 0,
			['WARRIOR'] = 0
		}
	elseif(itemArray.subtype == 'Librams') then
		map = {
			['DEATHKNIGHT'] = 0,
			['DRUID'] = 0,
			['HUNTER'] = 0,
			['MAGE'] = 0,
			['PALADIN'] = 2,
			['PRIEST'] = 0,
			['ROGUE'] = 0,
			['SHAMAN'] = 0,
			['WARLOCK'] = 0,
			['WARRIOR'] = 0
		}
	elseif(itemArray.subtype == 'Totems') then
		map = {
			['DEATHKNIGHT'] = 0,
			['DRUID'] = 0,
			['HUNTER'] = 0,
			['MAGE'] = 0,
			['PALADIN'] = 0,
			['PRIEST'] = 0,
			['ROGUE'] = 0,
			['SHAMAN'] = 2,
			['WARLOCK'] = 0,
			['WARRIOR'] = 0
		}
	elseif(itemArray.subtype == 'Sigils') then
		map = {
			['DEATHKNIGHT'] = 2,
			['DRUID'] = 0,
			['HUNTER'] = 0,
			['MAGE'] = 0,
			['PALADIN'] = 0,
			['PRIEST'] = 0,
			['ROGUE'] = 0,
			['SHAMAN'] = 0,
			['WARLOCK'] = 0,
			['WARRIOR'] = 0
		}
	elseif(itemArray.subtype == 'Shields') then
		map = {
			['DEATHKNIGHT'] = 0,
			['DRUID'] = 0,
			['HUNTER'] = 0,
			['MAGE'] = 0,
			['PALADIN'] = 2,
			['PRIEST'] = 0,
			['ROGUE'] = 0,
			['SHAMAN'] = 2,
			['WARLOCK'] = 0,
			['WARRIOR'] = 2
		}
	else
		if(SVF.options.debug) then
			print('ScootsVendorFilter: Unhandled armour subtype: ' .. itemArray.subtype)
			print(itemArray.link)
		end
		
		return true
	end
	
	if(map[SVF.playerClass] >= SVF.options.armourFilterThreshold) then
		return true
	else
		SVF.hiddenEquipment = SVF.hiddenEquipment + 1
		return false
	end
end

function SVF.attuneFilter(itemArray)
	if(SVF.options.alwaysShowHeirlooms == true and itemArray.rarity == 7) then
		return true
	end
	
	if(itemArray.attune <= SVF.options.maxAttunementToShow) then
		return true
	end
	
	if(itemArray.type == 'Weapon') then
		SVF.hiddenWeapons = SVF.hiddenWeapons + 1
	elseif(itemArray.type == 'Armor') then
		SVF.hiddenEquipment = SVF.hiddenEquipment + 1
	end
	
	return false
end

function SVF.recipeFilter(itemArray)
	if(SVF.options.showLearnedRecipes == true) then
		return true
	end

	local tooltip = getItemTooltip(itemArray)

	for _, line in ipairs(tooltip) do
		if(line == 'Already known') then
			return false
		end
	end
	
	return true
end

function SVF.bagFilter(itemArray)
	if(SVF.options.showItemsInBag == true) then
		return true
	end
	
	if(SVF.bagContents[itemArray.link] ~= nil and SVF.bagContents[itemArray.link] == true) then
		return false
	end
	
	return true
end

function SVF.openOptions()
	if(SVF.optionsFrame == nil) then
		SVF.buildOptionsPanel()
	end
	
	SVF.hideMerchantUi()
	SVF.updateOptionCounts()
	SVF.optionsFrame:Show()
	SVF.frame:Hide()
	SVF.synopsisFrame:Hide()
	SVF.activeFrame = SVF.optionsFrame
	
	SVF.optionsButton:SetText('Close Options')
	SVF.optionsOpen = true
end

function SVF.closeOptions()
	if(SVF.off ~= true) then
		SVF.frame:Show()
		SVF.synopsisFrame:Show()
	else
		SVF.showMerchantUi()
	end
	
	SVF.optionsFrame:Hide()
	SVF.activeFrame = SVF.frame
	SVF.optionsButton:SetText('ScootsVendorFilter')
	SVF.optionsOpen = false
end

function SVF.updateOptionCounts()
	local filterBreakdownString = SVF.hiddenItems .. SVF.addS(' item', SVF.hiddenItems) .. ' filtered'
	
	if(SVF.hiddenEquipment > 0) then
		filterBreakdownString = filterBreakdownString .. '\n(' .. SVF.hiddenEquipment .. SVF.addS(' armour piece', SVF.hiddenEquipment) .. ')'
	end
	
	if(SVF.hiddenWeapons > 0) then
		filterBreakdownString = filterBreakdownString .. '\n(' .. SVF.hiddenWeapons .. SVF.addS(' weapon', SVF.hiddenWeapons) .. ')'
	end
	
	if(SVF.hiddenRecipes > 0) then
		filterBreakdownString = filterBreakdownString .. '\n(' .. SVF.hiddenRecipes .. SVF.addS(' recipe', SVF.hiddenRecipes) .. ')'
	end
	
	SVF.optionsFrame.text:SetText(filterBreakdownString)
end

function SVF.buildOptionsPanel()
	SVF.optionToggles = {}

	SVF.optionsFrame = CreateFrame('Frame', 'SVFOptionsFrame', MerchantFrame)
	SVF.optionsFrame:SetPoint('TOPLEFT', MerchantFrame, 'TOPLEFT', 20, -75)
	SVF.optionsFrame:SetFrameStrata(SVF.frameStrata)
	SVF.optionsFrame:SetHeight(SVF.frameHeight)
	SVF.optionsFrame:SetWidth(SVF.frameWidth)
	
	SVF.optionsFrame.text = SVF.optionsFrame:CreateFontString(nil, 'ARTWORK')
	SVF.optionsFrame.text:SetFont('Fonts\\FRIZQT__.TTF', SVF.smallTextSize)
	SVF.optionsFrame.text:SetPoint('TOPRIGHT', -4, -2)
	SVF.optionsFrame.text:SetJustifyH('RIGHT')
	SVF.optionsFrame.text:SetTextColor(1, 1, 1)
	
	local heirlooms = SVF.createOptionToggleFrame('alwaysShowHeirlooms', 'Always show heirlooms', true, false)
	local recipes = SVF.createOptionToggleFrame('showLearnedRecipes', 'Show learned recipes', true, false)
	local weapons = SVF.createOptionToggleFrame('showUnusableWeapons', 'Show unusable weapons', true, false)
	local attuneCost = SVF.createOptionToggleFrame('printAttunementCost', 'Show total cost to purchase visible items in chat', true, false)
	local inBag = SVF.createOptionToggleFrame('showItemsInBag', 'Show items already in your bag', true, false)
	
	local equipLevel2 = SVF.createOptionToggleFrame('armourFilterThreshold', 'Show only optimal armour', 2)
	local equipLevel1 = SVF.createOptionToggleFrame('armourFilterThreshold', 'Show equippable armour', 1)
	local equipLevel0 = SVF.createOptionToggleFrame('armourFilterThreshold', 'Show all armour', 0)
	
	local attuneUn = SVF.createOptionToggleFrame('maxAttunementToShow', 'Show only unattuned equipment', -1)
	local attuneL0 = SVF.createOptionToggleFrame('maxAttunementToShow', 'Show up to attuned-baseline equipment', 0)
	local attuneL1 = SVF.createOptionToggleFrame('maxAttunementToShow', 'Show up to attuned-titanforged equipment', 1)
	local attuneL2 = SVF.createOptionToggleFrame('maxAttunementToShow', 'Show up to attuned-warforged equipment', 2)
	local attuneL3 = SVF.createOptionToggleFrame('maxAttunementToShow', 'Show up to attuned-lightforged equipment', 3)
	
	local debugOption = SVF.createOptionToggleFrame('debug', 'Show debug output', true, false)
	
	heirlooms:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, -10)
	recipes:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + SVF.optionToggleHeight) * -1)
	weapons:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 2)) * -1)
	attuneCost:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 3)) * -1)
	inBag:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 4)) * -1)
	
	equipLevel2:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 5) + 10) * -1)
	equipLevel1:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 6) + 10) * -1)
	equipLevel0:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 7) + 10) * -1)
	
	attuneUn:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 8) + 20) * -1)
	attuneL0:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 9) + 20) * -1)
	attuneL1:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 10) + 20) * -1)
	attuneL2:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 11) + 20) * -1)
	attuneL3:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 12) + 20) * -1)
	
	debugOption:SetPoint('TOPLEFT', SVF.optionsFrame, 'TOPLEFT', 10, (10 + (SVF.optionToggleHeight * 13) + 30) * -1)
	
	SVF.toggleOffButton = CreateFrame('Button', 'SVFToggleOffButton', SVF.optionsFrame, 'UIPanelButtonTemplate')
	SVF.toggleOffButton:SetSize(160, 24)
	SVF.toggleOffButton:SetText('Use default vendor')
	SVF.toggleOffButton:SetPoint('BOTTOMRIGHT', SVF.optionsFrame, 'BOTTOMRIGHT', 0, 0)
	SVF.toggleOffButton:SetFrameStrata(SVF.frameStrata)
	
	SVF.toggleOffButton:SetScript('OnClick', function()
		if(SVF.off == true) then
			SVF.off = false
			SVF.toggleOffButton:SetText('Use default vendor')
		else
			SVF.off = true
			SVF.toggleOffButton:SetText('Use ScootsVendorFilter')
		end
	end)
end

function SVF.createOptionToggleFrame(optionName, label, optionValueTrue, optionValueFalse)
	if(SVF.optionToggleFrameCount == nil) then
		SVF.optionToggleFrameCount = 0
	end
	
	SVF.optionToggleFrameCount = SVF.optionToggleFrameCount + 1

	local toggleFrame = CreateFrame('Frame', 'OptionsToggleFrame' .. SVF.optionToggleFrameCount, SVF.optionsFrame)
	toggleFrame:SetFrameStrata(SVF.frameStrata)
	toggleFrame:SetHeight(SVF.optionToggleHeight)
	toggleFrame.text = toggleFrame:CreateFontString(nil, 'ARTWORK')
	toggleFrame.text:SetFont('Fonts\\FRIZQT__.TTF', SVF.textSize)
	toggleFrame.text:SetPoint('LEFT', SVF.optionToggleHeight + 2, 0)
	toggleFrame.text:SetJustifyH('LEFT')
	toggleFrame.text:SetTextColor(1, 1, 1)
	toggleFrame.text:SetText(label)
	toggleFrame:SetWidth(toggleFrame.text:GetStringWidth() + SVF.optionToggleHeight + 2)
	toggleFrame:EnableMouse(true)
	
	toggleFrame.checkBorder = CreateFrame('Frame', 'OptionsToggleFrame' .. SVF.optionToggleFrameCount .. 'CheckBorder', toggleFrame)
	toggleFrame.checkBorder:SetFrameStrata(SVF.frameStrata)
	toggleFrame.checkBorder:SetSize(SVF.optionToggleHeight, SVF.optionToggleHeight)
	toggleFrame.checkBorder:SetPoint('TOPLEFT', toggleFrame, 'TOPLEFT', 0, -1)
	toggleFrame.checkBorder.texture = toggleFrame.checkBorder:CreateTexture()
	toggleFrame.checkBorder.texture:SetAllPoints()
	toggleFrame.checkBorder.texture:SetTexture('Interface/AchievementFrame/UI-Achievement-Progressive-IconBorder')
	toggleFrame.checkBorder.texture:SetTexCoord(0, 0.65625, 0, 0.65625)
	toggleFrame.checkBorder:SetAlpha(0.8)
	
	toggleFrame.check = CreateFrame('Frame', 'OptionsToggleFrame' .. SVF.optionToggleFrameCount .. 'Check', toggleFrame)
	toggleFrame.check:SetFrameStrata(SVF.frameStrata)
	toggleFrame.check:SetSize(SVF.optionToggleHeight, SVF.optionToggleHeight)
	toggleFrame.check:SetPoint('TOPLEFT', toggleFrame, 'TOPLEFT', 1, -2)
	toggleFrame.check.texture = toggleFrame.check:CreateTexture()
	toggleFrame.check.texture:SetAllPoints()
	toggleFrame.check.texture:SetTexture('Interface/AchievementFrame/UI-Achievement-Criteria-Check')
	toggleFrame.check.texture:SetTexCoord(0, 0.65625, 0, 1)
	
	if(SVF.options[optionName] ~= optionValueTrue) then
		toggleFrame.check:Hide()
	end
	
	toggleFrame.toggleInfo = {
		['option'] = optionName,
		['t'] = optionValueTrue,
		['f'] = optionValueFalse
	}
		
	toggleFrame:SetScript('OnEnter', function(self)
		if(SVF.options[self.toggleInfo.option] ~= self.toggleInfo.t or self.toggleInfo.f ~= nil) then
			self.checkBorder:SetAlpha(1)
		end
	end)
	
	toggleFrame:SetScript('OnLeave', function(self)
		self.checkBorder:SetAlpha(0.8)
	end)
	
	toggleFrame:SetScript('OnMouseDown', function(self, button)
		if(button == 'LeftButton') then
			if(SVF.options[self.toggleInfo.option] == self.toggleInfo.t) then
				if(self.toggleInfo.f ~= nil) then
					SVF.options[self.toggleInfo.option] = self.toggleInfo.f
					self.check:Hide()
					SVF.items = {}
					SVF.clear()
					SVF.applyFilter()
					SVF.updateOptionCounts()
				end
			else
				if(self.toggleInfo.f == nil) then
					for _, optFrame in ipairs(SVF.optionToggles) do
						if(optFrame.toggleInfo.option == self.toggleInfo.option) then
							optFrame.check:Hide()
						end
					end
				end
				
				SVF.options[self.toggleInfo.option] = self.toggleInfo.t
				self.check:Show()
				SVF.items = {}
				SVF.clear()
				SVF.applyFilter()
				SVF.updateOptionCounts()
			end
		end
	end)
	
	table.insert(SVF.optionToggles, toggleFrame)
	return toggleFrame
end

function SVF.setFrameLevels()
	SVF.baseFrameLevel = MerchantFrame:GetFrameLevel()

	if(SVF.frame ~= nil) then
		SVF.frame:SetFrameLevel(SVF.baseFrameLevel + 1)
	end

	if(SVF.scrollframe ~= nil) then
		SVF.scrollframe:SetFrameLevel(SVF.baseFrameLevel + 2)
	end

	if(SVF.scrollchild ~= nil) then
		SVF.scrollchild:SetFrameLevel(SVF.baseFrameLevel + 3)
	end

	if(SVF.optionsButton ~= nil) then
		SVF.optionsButton:SetFrameLevel(SVF.baseFrameLevel + 4)
	end

	if(SVF.toggleOffButton ~= nil) then
		SVF.toggleOffButton:SetFrameLevel(SVF.baseFrameLevel + 4)
	end

	if(SVF.noResultsFrame ~= nil) then
		SVF.noResultsFrame:SetFrameLevel(SVF.baseFrameLevel + 4)
	end

	if(SVF.items ~= nil and SVF.itemFrames ~= nil) then
		for i = 1, table.getn(SVF.items) do
			if(SVF.itemFrames[i] ~= nil) then
				SVF.itemFrames[i]:SetFrameLevel(SVF.baseFrameLevel + 4)
				SVF.itemFrames[i].borderTop:SetFrameLevel(SVF.baseFrameLevel + 5)
				SVF.itemFrames[i].borderBottom:SetFrameLevel(SVF.baseFrameLevel + 5)
				SVF.itemFrames[i].iconFrame:SetFrameLevel(SVF.baseFrameLevel + 5)
			end
		end
	end

	if(SVF.currencyFrames ~= nil) then
		for i = 1, table.getn(SVF.currencyFrames) do
			if(SVF.currencyFrames[i] ~= nil) then
				SVF.currencyFrames[i]:SetFrameLevel(SVF.baseFrameLevel + 5)
			end
		end
	end

	if(SVF.optionToggles ~= nil) then
		for i = 1, table.getn(SVF.optionToggles) do
			if(SVF.optionToggles[i] ~= nil) then
				SVF.optionToggles[i]:SetFrameLevel(SVF.baseFrameLevel + 4)
				SVF.optionToggles[i].checkBorder:SetFrameLevel(SVF.baseFrameLevel + 4)
				SVF.optionToggles[i].check:SetFrameLevel(SVF.baseFrameLevel + 5)
			end
		end
	end
end

function SVF.onLoad()
	SVF.options = {
		['armourFilterThreshold'] = 2,
		['alwaysShowHeirlooms'] = true,
		['showUnusableWeapons'] = false,
		['showLearnedRecipes'] = false,
		['maxAttunementToShow'] = -1,
		['printAttunementCost'] = true,
		['showItemsInBag'] = false,
		['debug'] = false
	}
	
	if(_G['SVF_OPTIONS'] ~= nil) then
		if(_G['SVF_OPTIONS'].armourFilterThreshold ~= nil) then
			SVF.options.armourFilterThreshold = _G['SVF_OPTIONS'].armourFilterThreshold
		end
		if(_G['SVF_OPTIONS'].alwaysShowHeirlooms ~= nil) then
			SVF.options.alwaysShowHeirlooms = _G['SVF_OPTIONS'].alwaysShowHeirlooms
		end
		if(_G['SVF_OPTIONS'].showUnusableWeapons ~= nil) then
			SVF.options.showUnusableWeapons = _G['SVF_OPTIONS'].showUnusableWeapons
		end
		if(_G['SVF_OPTIONS'].showLearnedRecipes ~= nil) then
			SVF.options.showLearnedRecipes = _G['SVF_OPTIONS'].showLearnedRecipes
		end
		if(_G['SVF_OPTIONS'].maxAttunementToShow ~= nil) then
			SVF.options.maxAttunementToShow = _G['SVF_OPTIONS'].maxAttunementToShow
		end
		if(_G['SVF_OPTIONS'].printAttunementCost ~= nil) then
			SVF.options.printAttunementCost = _G['SVF_OPTIONS'].printAttunementCost
		end
		if(_G['SVF_OPTIONS'].showItemsInBag ~= nil) then
			SVF.options.showItemsInBag = _G['SVF_OPTIONS'].showItemsInBag
		end
		if(_G['SVF_OPTIONS'].debug ~= nil) then
			SVF.options.debug = _G['SVF_OPTIONS'].debug
		end
	end
end

function SVF.onLogout()
	_G['SVF_OPTIONS'] = SVF.options
end

function SVF.eventHandler(self, event, arg1)
	if(event == 'ADDON_LOADED' and arg1 == 'ScootsVendorFilter') then
		SVF.onLoad()
	elseif(event == 'PLAYER_LOGOUT') then
		SVF.onLogout()
	elseif(event == 'MERCHANT_SHOW') then
		if(SVF.loaded ~= true) then
			SVF.setupUi()
		end
		SVF.updateBagContents()
		SVF.merchantShow()
	elseif(event == 'UNIT_INVENTORY_CHANGED' or event == 'BAG_UPDATE') then
		if(SVF.loaded == true) then
			SVF.updateBagContents()
			SVF.applyFilter()
		end
	elseif(event == 'MERCHANT_CLOSED') then
		SVF.MerchantClose()
	elseif(event == 'MERCHANT_UPDATE') then
		SVF.MerchantUpdate()
	end
end

SVF.frame:SetScript('OnEvent', SVF.eventHandler)

SVF.frame:RegisterEvent('ADDON_LOADED')
SVF.frame:RegisterEvent('PLAYER_LOGOUT')
SVF.frame:RegisterEvent('MERCHANT_SHOW')
SVF.frame:RegisterEvent('MERCHANT_CLOSED')
SVF.frame:RegisterEvent('MERCHANT_UPDATE')
SVF.frame:RegisterEvent('UNIT_INVENTORY_CHANGED')
SVF.frame:RegisterEvent('BAG_UPDATE')