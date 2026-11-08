-- Path of Building
--
-- Module: Wickerman
-- Stable slot identifiers and display labels for Wickerman equipment.
--
local slotList = {
	{ name = "Wickerman Head", label = "Head" },
	{ name = "Wickerman Torso", label = "Body" },
	{ name = "Wickerman Upper Limb", label = "Arm" },
	{ name = "Wickerman Lower Limb", label = "Leg" },
}

local slots = { }
for _, slot in ipairs(slotList) do
	slots[slot.name] = slot
end

local function GetSlotName(item)
	if not item then
		return
	end
	local slotName = item.base and item.base.wickermanSlot or item.type
	return slots[slotName] and slotName or nil
end

return {
	slotList = slotList,
	slots = slots,
	GetSlotName = GetSlotName,
	IsItem = function(item)
		return GetSlotName(item) ~= nil
	end,
	-- Temporary development override until the 3.30 tree is available upstream.
	IsEnabledForVersion = function()
		return true
	end,
}
