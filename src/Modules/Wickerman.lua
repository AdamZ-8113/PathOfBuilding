-- Path of Building
--
-- Module: Wickerman
-- Stable slot identifiers and display labels for Wickerman equipment.
--
local slotList = {
	{ name = "Wickerman Head", label = "Head" },
	{ name = "Wickerman Torso", label = "Torso" },
	{ name = "Wickerman Upper Limb", label = "Upper Limb" },
	{ name = "Wickerman Lower Limb", label = "Lower Limb" },
}

local slots = { }
for _, slot in ipairs(slotList) do
	slots[slot.name] = slot
end

return {
	slotList = slotList,
	slots = slots,
}
