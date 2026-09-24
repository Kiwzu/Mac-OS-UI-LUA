--[[
	MacUI · ThemeManager
	Appearance helpers: switch between Light / Dark / Midnight, remember the
	choice on disk and build an "Appearance" settings section.

	local ThemeManager = loadstring(game:HttpGet(".../ThemeManager.lua"))()
	ThemeManager:SetLibrary(MacUI)
	ThemeManager:SetFolder("MyHub")
	ThemeManager:BuildThemeSection(Tabs.Settings)
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {
	Library = nil,
	Folder = "MacUI",
	CurrentTheme = "Dark",
}
ThemeManager.__index = ThemeManager

local function HasFileApi()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function EnsureFolder(path)
	if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		return
	end
	local current = ""
	for part in string.gmatch(path, "[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

function ThemeManager:SetLibrary(library)
	self.Library = library
	self.Themes = library.Themes
	self.CurrentTheme = library.ThemeName
end

function ThemeManager:SetFolder(folder)
	self.Folder = folder
end

function ThemeManager:GetThemes()
	return self.Library and self.Library:GetThemes() or { "Dark", "Light", "Midnight" }
end

-- Applies a theme with MacUI's animated transition.
function ThemeManager:ApplyTheme(name)
	if not self.Library then
		warn("[ThemeManager] call SetLibrary(MacUI) first")
		return
	end
	self.Library:SetTheme(name)
	self.CurrentTheme = self.Library.ThemeName
end
ThemeManager.SetTheme = ThemeManager.ApplyTheme

-- Kept for scripts written against MacUI v3: ThemeManager:Transition(root, "Light")
function ThemeManager:Transition(_, name)
	name = name or (self.CurrentTheme == "Dark" and "Light" or "Dark")
	self:ApplyTheme(name)
end

-- v3 compatibility; the accent is owned by the library now.
function ThemeManager:LinkAccent(getter)
	self.GetAccent = getter
end

function ThemeManager:GetColor(token)
	local theme = self.Library and self.Library.ThemeData
	return theme and theme[token] or Color3.new(1, 1, 1)
end

function ThemeManager:SaveDefault(name)
	if not HasFileApi() then
		return
	end
	EnsureFolder(self.Folder)
	writefile(self.Folder .. "/theme.json", HttpService:JSONEncode({
		Theme = name or self.CurrentTheme,
		Accent = self.Library and self.Library.Accent:ToHex() or nil,
	}))
end

function ThemeManager:LoadDefault()
	if not HasFileApi() or not self.Library then
		return
	end
	local path = self.Folder .. "/theme.json"
	if not isfile(path) then
		return
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(data) ~= "table" then
		return
	end
	if data.Theme and self.Library.Themes[data.Theme] then
		self.Library:SetTheme(data.Theme, true)
		self.CurrentTheme = data.Theme
	end
	if data.Accent then
		self.Library:SetAccent("#" .. data.Accent, true)
	end
end

-- Adds an "Appearance" section: theme picker, accent colours and a save button.
function ThemeManager:BuildThemeSection(tab)
	assert(self.Library, "[ThemeManager] call SetLibrary(MacUI) first")
	local library = self.Library
	local section = tab:AddSection({
		Title = "Appearance",
		Description = "Choose how the interface looks.",
		Icon = "palette",
	})
	local themeControl = section:AddSegmented("ThemeManager_Theme", {
		Title = "Theme",
		Values = self:GetThemes(),
		Default = library.ThemeName,
		Callback = function(value)
			if value ~= library.ThemeName then
				self:ApplyTheme(value)
			end
		end,
	})
	local accentNames = table.clone(library.AccentOrder)
	local current = "Blue"
	for _, name in ipairs(accentNames) do
		if library.Accents[name] == library.Accent then
			current = name
		end
	end
	local accentControl = section:AddDropdown("ThemeManager_Accent", {
		Title = "Accent colour",
		Description = "Used for selections, switches and sliders.",
		Values = accentNames,
		Default = current,
		Callback = function(value)
			library:SetAccent(value)
		end,
	})
	library.ThemeChanged:Connect(function(name)
		self.CurrentTheme = name
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
	section:AddButton({
		Title = "Save as default",
		Description = "Load this appearance automatically next time.",
		ButtonText = "Save",
		Callback = function()
			self:SaveDefault()
			library:Notify({ Title = "Appearance saved", Content = "Theme: " .. library.ThemeName, Icon = "palette" })
		end,
	})
	return section
end

return ThemeManager
