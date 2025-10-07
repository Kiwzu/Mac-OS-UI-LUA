--========================================================
-- 🍎 MacUI Addon: SaveManager.lua
-- Handles saving/loading of UI configurations (Fluent-compatible)
--========================================================

local HttpService = game:GetService("HttpService")
local SaveManager = {}
SaveManager.__index = SaveManager

SaveManager.Library = nil
SaveManager.SaveFolder = "MacUI/Configs"
SaveManager.IgnoreList = {}
SaveManager.ThemeIgnored = true

-- Set reference to main UI
function SaveManager:SetLibrary(lib)
	self.Library = lib
end

function SaveManager:SetFolder(path)
	self.SaveFolder = path
end

function SaveManager:SetIgnoreIndexes(tbl)
	self.IgnoreList = tbl
end

function SaveManager:IgnoreThemeSettings()
	self.ThemeIgnored = true
end

-- Save configuration table
function SaveManager:Save(name, data)
	local path = self.SaveFolder .. "/" .. name .. ".json"
	if not isfolder(self.SaveFolder) then makefolder(self.SaveFolder) end
	writefile(path, HttpService:JSONEncode(data))
end

-- Load configuration
function SaveManager:Load(name)
	local path = self.SaveFolder .. "/" .. name .. ".json"
	if isfile(path) then
		local success, decoded = pcall(function()
			return HttpService:JSONDecode(readfile(path))
		end)
		if success then return decoded end
	end
	return {}
end

-- Build config section inside tab
function SaveManager:BuildConfigSection(tab)
	tab:AddParagraph({
		Title = "Configuration",
		Content = "Save or load your UI settings."
	})

	tab:AddButton({
		Title = "Save Config",
		Description = "Save current UI state",
		Callback = function()
			local data = {}
			for name, val in pairs(getgenv().MacUI_Config or {}) do
				if not table.find(self.IgnoreList, name) then
					data[name] = val
				end
			end
			self:Save("Default", data)
			if self.Library and self.Library.Notify then
				self.Library:Notify({Title="Config Saved", Content="Settings saved to file.", Duration=3})
			end
		end
	})

	tab:AddButton({
		Title = "Load Config",
		Description = "Load saved UI state",
		Callback = function()
			local data = self:Load("Default")
			for name, val in pairs(data) do
				getgenv().MacUI_Config[name] = val
			end
			if self.Library and self.Library.Notify then
				self.Library:Notify({Title="Config Loaded", Content="Settings loaded successfully.", Duration=3})
			end
		end
	})
end

-- Auto-load support
function SaveManager:LoadAutoloadConfig()
	local data = self:Load("Default")
	for name, val in pairs(data) do
		getgenv().MacUI_Config[name] = val
	end
end

return SaveManager
