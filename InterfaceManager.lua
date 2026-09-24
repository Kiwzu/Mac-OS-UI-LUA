--[[
	MacUI · InterfaceManager
	Builds the "Interface" settings section (theme, accent, scale, toggle key)
	and remembers those choices between sessions. API-compatible with
	Fluent's InterfaceManager.

	InterfaceManager:SetLibrary(MacUI)
	InterfaceManager:SetFolder("MyHub")
	InterfaceManager:BuildInterfaceSection(Tabs.Settings)
]]

local HttpService = game:GetService("HttpService")

local InterfaceManager = {
	Library = nil,
	Folder = "MacUI",
	Settings = {
		Theme = "Dark",
		Accent = "Blue",
		Scale = 100,
		MenuKeybind = "RightControl",
	},
}
InterfaceManager.__index = InterfaceManager

local function FileApi()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
		and type(isfolder) == "function"
		and type(makefolder) == "function"
end

function InterfaceManager:SetLibrary(library)
	self.Library = library
end

function InterfaceManager:SetFolder(folder)
	self.Folder = folder
	self:BuildFolderTree()
end

function InterfaceManager:BuildFolderTree()
	if not FileApi() then
		return
	end
	local current = ""
	for part in string.gmatch(self.Folder, "[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

function InterfaceManager:SaveSettings()
	if not FileApi() then
		return
	end
	self:BuildFolderTree()
	writefile(self.Folder .. "/options.json", HttpService:JSONEncode(self.Settings))
end

function InterfaceManager:LoadSettings()
	if not FileApi() then
		return
	end
	local path = self.Folder .. "/options.json"
	if not isfile(path) then
		return
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
	if ok and type(data) == "table" then
		for key, value in pairs(data) do
			self.Settings[key] = value
		end
	end
end

function InterfaceManager:BuildInterfaceSection(tab)
	assert(self.Library, "[InterfaceManager] call SetLibrary(MacUI) first")
	local library = self.Library
	local settings = self.Settings
	self:LoadSettings()

	-- Apply the saved values before the controls are built.
	if library.Themes[settings.Theme] then
		library:SetTheme(settings.Theme, true)
	end
	if library.Accents[settings.Accent] then
		library:SetAccent(settings.Accent, true)
	end
	library:SetMinimizeKey(settings.MenuKeybind)

	local section = tab:AddSection({
		Title = "Interface",
		Description = "Customise how this window looks and opens.",
		Icon = "monitor",
	})

	local themeControl = section:AddSegmented("InterfaceTheme", {
		Title = "Appearance",
		Values = library:GetThemes(),
		Default = library.ThemeName,
		Callback = function(value)
			if value ~= library.ThemeName then
				library:SetTheme(value)
			end
			settings.Theme = value
			self:SaveSettings()
		end,
	})

	local accentNames = table.clone(library.AccentOrder)
	local accentControl = section:AddDropdown("InterfaceAccent", {
		Title = "Accent colour",
		Description = "Selections, switches, sliders and buttons.",
		Values = accentNames,
		Default = table.find(accentNames, settings.Accent) and settings.Accent or "Blue",
		Callback = function(value)
			library:SetAccent(value)
			settings.Accent = value
			self:SaveSettings()
		end,
	})

	library.ThemeChanged:Connect(function(name)
		if themeControl.Value ~= name then
			themeControl:SetValue(name)
		end
	end)
	library.AccentChanged:Connect(function(color)
		for _, name in ipairs(accentNames) do
			if library.Accents[name] == color and accentControl.Value ~= name then
				accentControl:SetValue(name)
			end
		end
	end)

	local scaleReady = false
	section:AddSlider("InterfaceScale", {
		Title = "Interface size",
		Description = "Scale the whole window.",
		Min = 60,
		Max = 130,
		Default = settings.Scale or 100,
		Increment = 5,
		Suffix = "%",
		Callback = function(value)
			settings.Scale = value
			if scaleReady then
				library:SetScale(value / 100)
				self:SaveSettings()
			end
		end,
	})
	scaleReady = true
	if settings.Scale and settings.Scale ~= 100 then
		library:SetScale(settings.Scale / 100)
	end

	local keybind = section:AddKeybind("MenuKeybind", {
		Title = "Show / hide window",
		Description = "Press this key to minimise or restore the window.",
		Default = settings.MenuKeybind,
		Mode = "Toggle",
	})
	keybind:OnChanged(function(key)
		settings.MenuKeybind = key
		library:SetMinimizeKey(key)
		self:SaveSettings()
	end)
	library.MinimizeKeybind = keybind

	section:AddButton({
		Title = "Unload interface",
		Description = "Destroy the window and disconnect everything.",
		ButtonText = "Unload",
		Style = "Destructive",
		Callback = function()
			library:Destroy()
		end,
	})
	return section
end

return InterfaceManager
