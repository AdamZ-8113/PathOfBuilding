describe("TestWickerman", function()
	local wickerman = require("Modules.Wickerman")
	local isEnabledForVersion = wickerman.IsEnabledForVersion
	local parts = {
		{ slotName = "Wickerman Head", label = "Head", baseName = "Test Wickerman Head" },
		{ slotName = "Wickerman Torso", label = "Body", baseName = "Test Wickerman Torso" },
		{ slotName = "Wickerman Upper Limb", label = "Arm", baseName = "Test Wickerman Upper Limb" },
		{ slotName = "Wickerman Lower Limb", label = "Leg", baseName = "Test Wickerman Lower Limb" },
	}

	local function createPart(part, modLine)
		local raw = "Rarity: Rare\nTest Part\n"..part.baseName.."\nImplicits: 0"
		if modLine then
			raw = raw.."\n"..modLine
		end
		local item = new("Item"):Item(raw)
		assert.truthy(item.base)
		build.itemsTab:AddItem(item, true)
		return item
	end

	local function equip(slotName, item)
		build.itemsTab.slots[slotName]:SetSelItemId(item.id)
		build.itemsTab:PopulateSlots()
		build.buildFlag = true
	end

	before_each(function()
		wickerman.IsEnabledForVersion = function()
			return true
		end
		newBuild()
		for _, part in ipairs(parts) do
			data.itemBases[part.baseName] = {
				type = part.slotName,
				tags = { default = true, wickerman = true },
				req = { },
			}
		end
	end)

	after_each(function()
		wickerman.IsEnabledForVersion = isEnabledForVersion
		for _, part in ipairs(parts) do
			data.itemBases[part.baseName] = nil
		end
	end)

	it("creates an empty four-slot Wickerman loadout", function()
		assert.is_true(isEnabledForVersion("3_30"))
		assert.is_true(isEnabledForVersion("3_30_alternate"))
		assert.is_true(isEnabledForVersion("3_29"))
		assert.are.equal("^7Wickerman:", build.itemsTab.controls.wickermanHeader.label)
		assert.is_true(build.itemsTab.controls.wickermanHeader:IsShown())
		assert.is_true(build.itemsTab.slotOrder["Flask 5"] < build.itemsTab.slotOrder[parts[1].slotName])
		for _, part in ipairs(parts) do
			local slot = build.itemsTab.slots[part.slotName]
			assert.truthy(slot)
			assert.are.equal(part.label, slot.label)
			assert.are.equal(0, slot.selItemId)
			assert.is_true(slot:IsShown())
		end
	end)

	it("copies Wickerman selections when duplicating an item set", function()
		local head = createPart(parts[1])
		equip(parts[1].slotName, head)
		local setList = new("ItemSetListControl"):ItemSetListControl(nil, { 0, 0, 300, 200 }, build.itemsTab)
		setList.selValue = 1
		setList.controls.copy.onClick()

		assert.are.equal(head.id, build.itemsTab.itemSets[2][parts[1].slotName].selItemId)
		assert.are.equal(0, build.itemsTab.itemSets[2][parts[2].slotName].selItemId)
		main:ClosePopup()
	end)

	it("assigns every part only to its compatible slot", function()
		for index, part in ipairs(parts) do
			local item = createPart(part)
			assert.are.equal(part.slotName, item:GetPrimarySlot())
			assert.is_true(build.itemsTab:IsItemValidForSlot(item, part.slotName))
			assert.is_false(build.itemsTab:IsItemValidForSlot(item, parts[index % #parts + 1].slotName))
			equip(part.slotName, item)
			assert.are.equal(item.id, build.itemsTab.slots[part.slotName].selItemId)
		end
	end)

	it("keeps partial Wickerman equipment separate between item sets", function()
		local head = createPart(parts[1])
		local leg = createPart(parts[4])
		equip(parts[1].slotName, head)
		equip(parts[4].slotName, leg)

		local secondSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, secondSet.id)
		local torso = createPart(parts[2])
		secondSet[parts[2].slotName].selItemId = torso.id

		build.itemsTab:SetActiveItemSet(secondSet.id)
		assert.are.equal(0, build.itemsTab.slots[parts[1].slotName].selItemId)
		assert.are.equal(torso.id, build.itemsTab.slots[parts[2].slotName].selItemId)
		build.itemsTab:SetActiveItemSet(1)
		assert.are.equal(head.id, build.itemsTab.slots[parts[1].slotName].selItemId)
		assert.are.equal(leg.id, build.itemsTab.slots[parts[4].slotName].selItemId)
	end)

	it("round trips all four parts through build XML", function()
		for _, part in ipairs(parts) do
			equip(part.slotName, createPart(part))
		end
		runCallback("OnFrame")

		loadBuildFromXML(build:SaveDB("code"))

		for _, part in ipairs(parts) do
			local itemId = build.itemsTab.slots[part.slotName].selItemId
			assert.are.equal(part.baseName, build.itemsTab.items[itemId].baseName)
		end
	end)

	it("loads older builds without Wickerman slot data", function()
		loadBuildFromXML([[
<PathOfBuilding>
	<Build level="1" targetVersion="3_0" className="Scion" ascendClassName="None" mainSocketGroup="1"/>
	<Items activeItemSet="1">
		<ItemSet id="1"/>
	</Items>
</PathOfBuilding>]])

		for _, part in ipairs(parts) do
			assert.are.equal(0, build.itemsTab.slots[part.slotName].selItemId)
		end
	end)

	it("applies supported Wickerman modifiers through the item calculation path", function()
		runCallback("OnFrame")
		local baseLife = build.calcsTab.mainOutput.Life
		local item = createPart(parts[1], "+35 to maximum Life")
		equip(parts[1].slotName, item)
		runCallback("OnFrame")

		assert.are.equal(baseLife + 35, build.calcsTab.mainOutput.Life)
		assert.is_nil(build.calcsTab.mainEnv.player.modDB.multipliers.RareItem)
	end)

	it("preserves unsupported Wickerman modifier text without applying a modifier", function()
		local item = createPart(parts[2], "Eat a Soul when you consume the corpse of a Rare Monster")
		local modLine = item.explicitModLines[1]
		assert.are.equal(0, #modLine.modList)
		assert.are.equal("Eat a Soul when you consume the corpse of a Rare Monster", modLine.extra)
	end)

	it("infers a Wickerman slot when the item API inventory id is not yet known", function()
		build.importTab:ImportItem({
			id = "test-wickerman-import",
			frameType = 2,
			name = "Test Part",
			typeLine = parts[3].baseName,
			inventoryId = "UnpublishedWickermanInventoryId",
			ilvl = 1,
			properties = { },
			implicitMods = { },
			explicitMods = { "+35 to maximum Life" },
		})

		local itemId = build.itemsTab.slots[parts[3].slotName].selItemId
		assert.are.equal(parts[3].baseName, build.itemsTab.items[itemId].baseName)
	end)
end)
