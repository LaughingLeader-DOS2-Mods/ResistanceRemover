local StatsOverrider = {
	PrintID = "ResistanceRemover",
	--Stats to ignore
	Ignored = {
		---Makes the victim immune to damage
		Stats_PermaFrost = true,
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
		}
	}
}

function StatsOverrider:OverrideStat(id, statAttributes, syncStat)
	local overwritten = false
	for property,_ in pairs(statAttributes) do
		local value = Ext.StatGetAttribute(id, property)
		if value > 0 then
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

---@param entries string[]
function StatsOverrider:OverridePotions(entries, syncStat)
	local overwrites = {}
	local statAttributes = self.Attributes.Potion
	for _,id in pairs(entries) do
		if not self.Ignored[id] then
			if self:OverrideStat(id, statAttributes, syncStat) then
				overwrites[#overwrites+1] = id
			end
		end
	end
	local count = #overwrites
	if count > 0 then
		Ext.Print(string.format("[%s:OverridePotions] Changed resistances in (%s) stats.", self.PrintID, count))
	else
		Ext.Print(string.format("[%s:OverridePotions] No stats needed changing (already parsed?).", self.PrintID, count))
	end
	if Ext.IsDeveloperMode() then
		local str = ""
		for i=1,count do
			str = str + overwrites[i]
			if i < count then
				str = str + "\n"
			end
		end
		Ext.SaveFile(string.format("Logs/ResistanceRemover_Overwrites_Potion_%s.txt", Ext.IsClient() and "Client" or "Server"), str)
	end
end

function StatsOverrider:Init(syncStat)
	self:OverridePotions(Ext.GetStatEntries("Potion"), syncStat)
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