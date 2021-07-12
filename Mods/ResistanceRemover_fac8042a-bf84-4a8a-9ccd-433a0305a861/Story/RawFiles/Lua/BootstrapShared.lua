local StatsOverrider = {
	PrintID = "ResistanceRemover",
	--Stats to ignore
	Ignored = {
		---Makes the victim immune to damage
		Stats_PermaFrost = true,
		--Lichdom
		Stats_LLLICH_ChillForm = true,
		Stats_LLLICH_LichForm = true,
		--Characters
		-- FTJ_FireSlug_Boss = true,
		-- FTJ_FireSlug_Grunt = true,
		-- FTJ_Frog_Poison = true,
		-- FTJ_Frog_Water = true,
	},
	--Stat attributes to check for > 0
	Attributes = {
		Potion = {
			FireResistance = true,
			EarthResistance = true,
			WaterResistance = true,
			AirResistance = true,
			PoisonResistance = true,
			PhysicalResistance = true,
		},
		Character = {
			FireResistance = true,
			EarthResistance = true,
			WaterResistance = true,
			AirResistance = true,
			PoisonResistance = true,
			PhysicalResistance = true,
		}
	}
}

local function ShouldChangeValue(attribute, value)
	if string.find(attribute, "Resistance", 1, true) then
		return value > 0 and value <= 100
	end
	return false
end

function StatsOverrider:OverrideStat(id, statAttributes, syncStat)
	local overwritten = false
	for property,_ in pairs(statAttributes) do
		local value = Ext.StatGetAttribute(id, property)
		if type(value) == "number" and ShouldChangeValue(property, value) then
			if not syncStat then
				Ext.StatSetAttribute(id, property, 0)
			else
				local stat = Ext.GetStat(id)
				stat[property] = 0
				Ext.SyncStat(id, false)
			end
			overwritten = true
		end
	end
	return overwritten
end

function StatsOverrider:CanOverrideStat(id, statType)
	if self.Ignored[id] then
		return false
	end
	if statType == "Potion" then
		if string.find(id, "Stats_Infusion", 1, true) then
			return false
		end
		--Consumable items. May be a potion inheriting from _Story
		if Ext.StatGetAttribute(id, "IsConsumable") == "Yes" or Ext.StatGetAttribute(id, "IsFood") == "Yes" or Ext.StatGetAttribute(id, "RootTemplate") ~= "" then
			return false
		end
	elseif statType == "Character" then
		local parent = Ext.StatGetAttribute(id, "Using")
		if parent == "_Ward" then
			return false
		elseif string.find(id, "Summon_", 1, true)
		or string.find(id, "Slug", 1, true)
		or string.find(id, "Env_", 1, true)
		then
			return false
		end
	end
	return true
end

---@param statType string
---@param syncStat boolean|nil
function StatsOverrider:OverrideStats(statType, syncStat)
	local overwrites = {}
	local statAttributes = self.Attributes[statType]
	for _,id in pairs(Ext.GetStatEntries(statType)) do
		if self:CanOverrideStat(id, statType) then
			if self:OverrideStat(id, statAttributes, syncStat) then
				overwrites[#overwrites+1] = id
			end
		end
	end
	local count = #overwrites
	if count > 0 then
		Ext.Print(string.format("[%s:OverrideStats%s] Changed resistances in (%s) stats.", self.PrintID, statType, count))
		local b,err = xpcall(function()
			table.sort(overwrites)
			local str = ""
			for i=1,count do
				str = string.format("%s%s%s", str, overwrites[i], i < count and "\n" or "")
			end
			local fileName = string.format("Logs/ResistanceRemover_Overwrites_%s_%s.txt", statType, Ext.IsClient() and "Client" or "Server")
			Ext.SaveFile(fileName, str)
			Ext.Print(string.format("[%s:OverrideStats:%s] Saved log to (%s).", self.PrintID, statType, fileName))
		end, debug.traceback)
		if not b then
			Ext.PrintError(err)
		end
	else
		Ext.Print(string.format("[%s:OverrideStats:%s] No stats needed changing (already parsed?).", self.PrintID, statType, count))
	end
end

function StatsOverrider:Init(syncStat)
	self:OverrideStats("Potion", syncStat)
	self:OverrideStats("Character", syncStat)
end

Ext.RegisterListener("StatsLoaded", function() StatsOverrider:Init() end)
Ext.RegisterListener("ModuleLoadStarted", function()
	StatsOverrider.PrintID = Ext.GetModInfo(ModuleUUID).Name
end)

if Ext.IsDeveloperMode() and Mods.LeaderLib then
	Mods.LeaderLib.RegisterListener("LuaReset", function()
		StatsOverrider:Init(true)
	end)
end