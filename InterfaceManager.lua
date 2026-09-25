--[[
	MacUI · InterfaceManager
	Builds the "Interface" settings section (theme, accent, frosted glass,
	scale, motion, frame-rate protection, shortcut list, window memory,
	toggle key) and remembers those choices between sessions, along with
	what Spotlight learned about the settings you use most. API-compatible with Fluent's
	InterfaceManager.

	InterfaceManager:SetLibrary(MacUI)
	InterfaceManager:SetFolder("MyHub")
	InterfaceManager:BuildInterfaceSection(Tabs.Settings)

	Only settings the user changes are written to options.json; everything
	else keeps following the window's own CreateWindow config.
]]

local HttpService = game:GetService("HttpService")

local InterfaceManager = {
	Library = nil,
	Folder = "MacUI",
	-- The values in effect. Filled from the window when the section is built.
	Settings = {
		Theme = "Dark",
		Accent = "Blue",
		Scale = 100,
		MenuKeybind = "RightControl",
		Acrylic = false,
		ReduceMotion = false,
		PerformanceGuard = false,
		ShortcutList = false,
		RememberWindow = true,
		Window = nil, -- last position, size, page and sidebar state
	},
	-- The subset the user chose (or that options.json already had).
	Saved = {},
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
	writefile(self.Folder .. "/options.json", HttpService:JSONEncode(self.Saved))
end

-- Records a choice the user made and saves it.
function InterfaceManager:Set(key, value)
	self.Settings[key] = value
	self.Saved[key] = value
	self:SaveSettings()
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
			self.Saved[key] = value
		end
	end
end

function InterfaceManager:BuildInterfaceSection(tab)
	assert(self.Library, "[InterfaceManager] call SetLibrary(MacUI) first")
	local library = self.Library
	local settings = self.Settings
	local saved = self.Saved
	-- Controls report their initial values while they're built; only changes
	-- made after that are the user's and get saved.
	local ready = false

	local function EachWindow(fn)
		for _, window in ipairs(library.Windows or {}) do
			fn(window)
		end
	end

	-- Start from what the window is actually using...
	settings.Theme = library.ThemeName or settings.Theme
	for name, color in pairs(library.Accents) do
		if color == library.Accent then
			settings.Accent = name
		end
	end
	-- (the Get* versions ignore effects the performance guard has paused)
	if library.GetReduceMotion then
		settings.ReduceMotion = library:GetReduceMotion()
	else
		settings.ReduceMotion = library.ReduceMotion == true
	end
	settings.PerformanceGuard = library.PerformanceGuard == true
	local first = library.Windows and library.Windows[1]
	if first then
		if first.GetAcrylic then
			settings.Acrylic = first:GetAcrylic()
		else
			settings.Acrylic = first.Acrylic == true
		end
		settings.ShortcutList = first.KeybindListVisible == true
		settings.MenuKeybind = first.MinimizeKey and first.MinimizeKey.Name or "None"
		settings.Scale = math.clamp(math.floor((first.Scale or 1) * 20 + 0.5) * 5, 60, 130)
	end
	-- ...then apply what the user chose last time.
	self:LoadSettings()
	-- a saved custom theme may only be registered later (ThemeManager)
	local pendingTheme
	if saved.Theme and library.Themes[saved.Theme] then
		library:SetTheme(saved.Theme, true)
	elseif saved.Theme then
		pendingTheme = saved.Theme
	end
	if saved.Accent and library.Accents[saved.Accent] then
		library:SetAccent(saved.Accent, true)
	end
	if saved.MenuKeybind then
		library:SetMinimizeKey(saved.MenuKeybind)
	end
	if saved.ReduceMotion ~= nil and library.SetReduceMotion then
		library:SetReduceMotion(saved.ReduceMotion == true)
	end
	-- what Spotlight learned about which settings get used most
	if type(saved.Usage) == "table" and library.SetUsage then
		library:SetUsage(saved.Usage)
	end
	if library.UsageChanged then
		library.UsageChanged:Connect(function()
			if ready then
				self:Set("Usage", library:GetUsage())
			end
		end)
	end

	local section = tab:AddSection({
		Title = "Interface",
		Description = "Customise how this window looks and opens.",
		Icon = "monitor",
	})

	-- a segmented control for a few themes; it turns into a menu by itself
	-- once there are more (custom themes added later included)
	local themeNames = library:GetThemes()
	local themeInfo = {
		Title = "Appearance",
		Values = themeNames,
		Default = library.ThemeName,
		Callback = function(value)
			if value and value ~= library.ThemeName then
				library:SetTheme(value)
			end
			if ready and value then
				self:Set("Theme", value)
			end
		end,
	}
	local themeControl = section:AddSegmented("InterfaceTheme", themeInfo)
	if library.ThemesChanged then
		library.ThemesChanged:Connect(function(names)
			themeControl:SetValues(names)
			if pendingTheme and library.Themes[pendingTheme] then
				local name = pendingTheme
				pendingTheme = nil
				library:SetTheme(name, true)
			end
		end)
	end

	local accentNames = table.clone(library.AccentOrder)
	local accentControl = section:AddDropdown("InterfaceAccent", {
		Title = "Accent colour",
		Description = "Selections, switches, sliders and buttons.",
		Values = accentNames,
		Default = table.find(accentNames, settings.Accent) and settings.Accent or "Blue",
		Callback = function(value)
			-- a custom Color3 accent shows as "Blue" here until the user picks one
			if ready then
				if library.Accents[value] and library.Accents[value] ~= library.Accent then
					library:SetAccent(value)
				end
				self:Set("Accent", value)
			end
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

	section:AddToggle("InterfaceAcrylic", {
		Title = "Frosted glass",
		Description = "Blur the game behind the sidebar. Needs graphics quality 8 or higher.",
		Default = settings.Acrylic == true,
		Callback = function(value)
			local applied = value
			EachWindow(function(window)
				if window.SetAcrylic then
					applied = window:SetAcrylic(value) and applied
				end
			end)
			if not ready then
				return
			end
			if value and not applied then
				library:Notify({
					Title = "Frosted glass unavailable",
					Content = "Raise your graphics quality to 8 or higher, then turn it on again.",
					Icon = "alert-triangle",
					IconColor = "Orange",
					Duration = 5,
				})
			end
			self:Set("Acrylic", value)
		end,
	})

	section:AddSlider("InterfaceScale", {
		Title = "Interface size",
		Description = "Scale the whole window.",
		Min = 60,
		Max = 130,
		Default = settings.Scale or 100,
		Increment = 5,
		Suffix = "%",
		Finished = true, -- rescale once the drag ends, not on every step
		Callback = function(value)
			if ready then
				library:SetScale(value / 100)
				self:Set("Scale", value)
			end
		end,
	})
	if saved.Scale then
		library:SetScale(saved.Scale / 100)
	end

	section:AddToggle("InterfaceReduceMotion", {
		Title = "Reduce motion",
		Description = "Turn off window, menu and switch animations.",
		Default = settings.ReduceMotion == true,
		Callback = function(value)
			library:SetReduceMotion(value)
			if ready then
				self:Set("ReduceMotion", value)
			end
		end,
	})

	if library.SetPerformanceGuard then
		section:AddToggle("InterfacePerformanceGuard", {
			Title = "Protect frame rate",
			Description = "Pause blur and animations while the game is running slowly.",
			Default = settings.PerformanceGuard == true,
			Callback = function(value)
				if value ~= (library.PerformanceGuard == true) then
					library:SetPerformanceGuard(value)
				end
				if ready then
					self:Set("PerformanceGuard", value)
				end
			end,
		})
	end

	section:AddToggle("InterfaceShortcutList", {
		Title = "Shortcut list",
		Description = "A floating panel with every keybind and shortcut.",
		Default = settings.ShortcutList == true,
		Callback = function(value)
			EachWindow(function(window)
				if window.SetKeybindList then
					window:SetKeybindList(value)
				end
			end)
			if ready then
				self:Set("ShortcutList", value)
			end
		end,
	})

	section:AddToggle("InterfaceRememberWindow", {
		Title = "Remember window",
		Description = "Reopen at the same size, position and page.",
		Default = settings.RememberWindow ~= false,
		Callback = function(value)
			if not ready then
				return
			end
			if not value then
				settings.Window = nil
				saved.Window = nil
			end
			self:Set("RememberWindow", value)
		end,
	})
	EachWindow(function(window)
		if not window.StateChanged then
			return
		end
		window.StateChanged:Connect(function(state)
			if ready and settings.RememberWindow ~= false then
				self:Set("Window", state)
			end
		end)
		if settings.RememberWindow ~= false and type(saved.Window) == "table" then
			-- deferred so the script can finish adding tabs first
			task.defer(function()
				window:ApplyState(saved.Window)
			end)
		end
	end)

	local keybind = section:AddKeybind("MenuKeybind", {
		Title = "Show / hide window",
		Description = "Press this key to minimise or restore the window.",
		Default = settings.MenuKeybind,
		Mode = "Toggle",
	})
	keybind:OnChanged(function(key)
		settings.MenuKeybind = key
		library:SetMinimizeKey(key)
		if ready then
			self:Set("MenuKeybind", key)
		end
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
	ready = true
	return section
end

return InterfaceManager
