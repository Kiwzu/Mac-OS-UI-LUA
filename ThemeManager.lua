--[[
	MacUI · ThemeManager
	Appearance helpers: switch between Light / Dark / Midnight, remember the
	choice on disk and build an "Appearance" settings section.

	local ThemeManager = loadstring(game:HttpGet(".../ThemeManager.lua"))()
	ThemeManager:SetLibrary(MacUI)
	ThemeManager:SetFolder("MyHub")
	ThemeManager:BuildThemeSection(Tabs.Settings)

	Custom themes: ThemeManager:BuildThemeEditor(Tabs.Settings) adds a live
	editor. Saved themes live in <Folder>/themes and come back with
	ThemeManager:LoadCustomThemes(); call that before anything that lists
	themes (such as InterfaceManager:BuildInterfaceSection).
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {
	Library = nil,
	Folder = "MacUI",
	CurrentTheme = "Dark",
	-- { token, label } pairs the theme editor shows; the rest come from the base theme
	EditorTokens = {
		{ "Background", "Window" },
		{ "Sidebar", "Sidebar" },
		{ "Group", "Groups" },
		{ "Separator", "Separators" },
		{ "Control", "Controls" },
		{ "Text", "Text" },
		{ "SubText", "Secondary text" },
	},
}

local BUILT_IN = { Dark = true, Light = true, Midnight = true }
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

function ThemeManager:_ThemeFolder()
	return self.Folder .. "/themes"
end

-- Registers every theme saved with the editor.
function ThemeManager:LoadCustomThemes()
	local library = self.Library
	if not library or not HasFileApi() or type(listfiles) ~= "function" or type(isfolder) ~= "function" then
		return
	end
	local folder = self:_ThemeFolder()
	if not isfolder(folder) then
		return
	end
	for _, file in ipairs(listfiles(folder)) do
		local name = file:gsub("\\", "/"):match("([^/]+)%.json$")
		if name and not BUILT_IN[name] then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(readfile(file))
			end)
			if ok and type(data) == "table" then
				local tokens = {}
				for token, hex in pairs(type(data.Tokens) == "table" and data.Tokens or {}) do
					local parsed, color = pcall(Color3.fromHex, tostring(hex))
					if parsed then
						tokens[token] = color
					end
				end
				library:AddTheme(name, tokens, library.Themes[data.Base] and data.Base or "Dark")
			end
		end
	end
end

-- Saves and registers a theme. `tokens` maps token names to Color3s. Returns
-- true and the cleaned-up name, or false and a reason.
function ThemeManager:SaveCustomTheme(name, tokens, base)
	name = (tostring(name or ""):gsub("[^%w%s%-_]", ""))
	name = (name:gsub("^%s+", ""):gsub("%s+$", ""))
	if name == "" then
		return false, "Give the theme a name first."
	elseif BUILT_IN[name] then
		return false, "“" .. name .. "” is a built-in theme."
	end
	local encoded = {}
	for token, color in pairs(tokens or {}) do
		if typeof(color) == "Color3" then
			encoded[token] = color:ToHex()
		end
	end
	if HasFileApi() then
		EnsureFolder(self:_ThemeFolder())
		writefile(self:_ThemeFolder() .. "/" .. name .. ".json", HttpService:JSONEncode({ Base = base or "Dark", Tokens = encoded }))
	end
	self.Library:AddTheme(name, tokens, base)
	return true, name
end

-- Deletes a saved theme (built-in themes stay).
function ThemeManager:DeleteCustomTheme(name)
	if BUILT_IN[name] then
		return false
	end
	local path = self:_ThemeFolder() .. "/" .. tostring(name) .. ".json"
	if type(delfile) == "function" and HasFileApi() and isfile(path) then
		delfile(path)
	end
	return self.Library:RemoveTheme(name)
end

-- Adds a collapsible "Theme editor" section: pick colours, preview them live,
-- save the result as a named theme.
function ThemeManager:BuildThemeEditor(tab)
	assert(self.Library, "[ThemeManager] call SetLibrary(MacUI) first")
	local library = self.Library
	self:LoadCustomThemes()
	local section = tab:AddSection({
		Title = "Theme editor",
		Description = "Design your own theme. Changes preview live; save to keep them.",
		Icon = "brush",
		Collapsible = true,
		Collapsed = true,
	})
	local pickers = {}
	local ready = false
	local queued = false
	local baseControl

	local function Tokens()
		local tokens = {}
		for _, spec in ipairs(self.EditorTokens) do
			tokens[spec[1]] = pickers[spec[1]].Value
		end
		return tokens
	end
	local function Preview()
		if not ready or queued then
			return
		end
		queued = true
		task.delay(0.12, function()
			queued = false
			if not library.Unloaded then
				library:PreviewTheme(Tokens(), baseControl.Value)
			end
		end)
	end
	local function LoadFrom(name)
		local theme = library.Themes[name] or library.ThemeData
		local wasReady = ready
		ready = false
		for _, spec in ipairs(self.EditorTokens) do
			if theme[spec[1]] then
				pickers[spec[1]]:SetValueRGB(theme[spec[1]])
			end
		end
		ready = wasReady
	end
	local function Notify(title, content, failed)
		library:Notify({
			Title = title,
			Content = content,
			Icon = failed and "alert-triangle" or "palette",
			IconColor = failed and "Orange" or nil,
			Duration = 4,
		})
	end

	baseControl = section:AddDropdown("ThemeEditor_Base", {
		Title = "Start from",
		Description = "Colours you don't change here come from this theme.",
		Values = library:GetThemes(),
		Default = library.ThemeName,
		Callback = function(name)
			if name and ready then
				LoadFrom(name)
				Preview()
			end
		end,
	})
	local current = library.ThemeData or library.Themes.Dark
	for _, spec in ipairs(self.EditorTokens) do
		pickers[spec[1]] = section:AddColorpicker("ThemeEditor_" .. spec[1], {
			Title = spec[2],
			Default = current[spec[1]],
			Callback = Preview,
		})
	end
	local nameInput = section:AddInput("ThemeEditor_Name", { Title = "Name", Placeholder = "My theme" })
	section:AddButton({
		Title = "Save theme",
		Description = "Adds it to the theme list, now and next time.",
		ButtonText = "Save",
		Style = "Primary",
		Callback = function()
			local ok, result = self:SaveCustomTheme(nameInput.Value, Tokens(), baseControl.Value)
			if not ok then
				return Notify("Couldn’t save theme", result, true)
			end
			library:SetTheme(result)
			Notify("Theme saved", "“" .. result .. "” is in your theme list.")
		end,
	})
	section:AddButton({
		Title = "Discard changes",
		Description = "Go back to the theme you're using.",
		ButtonText = "Discard",
		Callback = function()
			library:SetTheme(library.ThemeName, true)
			LoadFrom(library.ThemeName)
		end,
	})
	section:AddButton({
		Title = "Delete theme",
		Description = "Deletes the “Start from” theme if you made it.",
		ButtonText = "Delete",
		Style = "Destructive",
		Callback = function()
			local name = baseControl.Value
			if not name or BUILT_IN[name] then
				return Notify("Can’t delete " .. tostring(name), "Built-in themes stay.", true)
			end
			if self:DeleteCustomTheme(name) then
				Notify("Theme deleted", "“" .. name .. "” was removed.")
			end
		end,
	})
	library.ThemesChanged:Connect(function(names)
		baseControl:SetValues(names)
	end)
	ready = true
	return section
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
	library.ThemesChanged:Connect(function(names)
		themeControl:SetValues(names)
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
