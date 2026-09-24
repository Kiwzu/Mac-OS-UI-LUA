--[[
	MacUI · SaveManager
	Saves and loads the values of every element that was created with an
	index (Library.Options). The file format is compatible with Fluent's
	SaveManager, so existing configs keep working.

	SaveManager:SetLibrary(MacUI)
	SaveManager:SetFolder("MyHub/SomeGame")
	SaveManager:IgnoreThemeSettings()
	SaveManager:BuildConfigSection(Tabs.Settings)
	SaveManager:LoadAutoloadConfig()

	Toggle and button shortcuts are saved too, and "Save changes
	automatically" keeps the current profile up to date as you play.
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {
	Library = nil,
	Folder = "MacUI",
	Ignore = {},
	Loading = false,
	Autosave = false,
	-- The profile last loaded or saved; autosave writes here.
	ActiveProfile = nil,
	-- Autosave waits until the saved state has been loaded, so values that
	-- are still being set up never overwrite a profile.
	Ready = false,
}

-- Shortcuts are stored as a key name, or "None" when removed.
local function ApplyShortcut(option, shortcut)
	if type(shortcut) ~= "string" or not option.SetShortcut then
		return
	end
	local want = shortcut ~= "None" and shortcut or nil
	if option.Shortcut ~= want then
		option:SetShortcut(want)
	end
end
SaveManager.__index = SaveManager

local function FileApi()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
		and type(isfolder) == "function"
		and type(makefolder) == "function"
end

SaveManager.Parser = {
	Toggle = {
		Save = function(idx, object)
			return { type = "Toggle", idx = idx, value = object.Value, shortcut = object.Shortcut or "None" }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if not option then
				return
			end
			if option.Value ~= data.value then
				option:SetValue(data.value)
			end
			ApplyShortcut(option, data.shortcut)
		end,
	},
	Button = {
		Save = function(idx, object)
			return { type = "Button", idx = idx, shortcut = object.Shortcut or "None" }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option then
				ApplyShortcut(option, data.shortcut)
			end
		end,
	},
	Stepper = {
		Save = function(idx, object)
			return { type = "Stepper", idx = idx, value = tostring(object.Value) }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option and tonumber(data.value) then
				option:SetValue(tonumber(data.value))
			end
		end,
	},
	Radio = {
		Save = function(idx, object)
			return { type = "Radio", idx = idx, value = object.Value }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option and data.value ~= nil then
				option:SetValue(data.value)
			end
		end,
	},
	Slider = {
		Save = function(idx, object)
			return { type = "Slider", idx = idx, value = tostring(object.Value) }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option then
				option:SetValue(tonumber(data.value))
			end
		end,
	},
	Dropdown = {
		Save = function(idx, object)
			-- multi-selections are stored as a list so numeric values survive JSON
			local value = object.Multi and object:GetActiveValues() or object.Value
			return { type = "Dropdown", idx = idx, value = value, multi = object.Multi }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option then
				option:SetValue(data.value)
			end
		end,
	},
	Colorpicker = {
		Save = function(idx, object)
			return { type = "Colorpicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option then
				option:SetValueRGB(Color3.fromHex(data.value), data.transparency)
			end
		end,
	},
	Keybind = {
		Save = function(idx, object)
			return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option then
				option:SetValue(data.key, data.mode)
			end
		end,
	},
	Input = {
		Save = function(idx, object)
			return { type = "Input", idx = idx, text = object.Value }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option and type(data.text) == "string" then
				option:SetValue(data.text)
			end
		end,
	},
	Segmented = {
		Save = function(idx, object)
			return { type = "Segmented", idx = idx, value = object.Value }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if option then
				option:SetValue(data.value)
			end
		end,
	},
}

function SaveManager:SetLibrary(library)
	self.Library = library
end

function SaveManager:SetFolder(folder)
	self.Folder = folder
	self:BuildFolderTree()
end

function SaveManager:SetIgnoreIndexes(list)
	for _, idx in ipairs(list) do
		self.Ignore[idx] = true
	end
end

function SaveManager:IgnoreThemeSettings()
	self:SetIgnoreIndexes({
		"InterfaceTheme",
		"InterfaceAccent",
		"InterfaceScale",
		"InterfaceAcrylic",
		"InterfaceReduceMotion",
		"InterfaceShortcutList",
		"InterfaceRememberWindow",
		"MenuKeybind",
		"ThemeManager_Theme",
		"ThemeManager_Accent",
		"AccentManager_Accent",
		"AccentManager_Color",
	})
end

function SaveManager:BuildFolderTree()
	if not FileApi() then
		return
	end
	local current = ""
	for part in string.gmatch(self.Folder .. "/settings", "[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

function SaveManager:Save(name)
	if not name or name:gsub("%s", "") == "" then
		return false, "no config name given"
	end
	if not FileApi() then
		return false, "your executor has no file functions"
	end
	self:BuildFolderTree()
	local data = { objects = {} }
	for idx, option in pairs(self.Library.Options) do
		local parser = self.Parser[option.Type]
		if parser and not self.Ignore[idx] then
			local entry = parser.Save(idx, option)
			if entry then
				table.insert(data.objects, entry)
			end
		end
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then
		return false, "failed to encode data"
	end
	writefile(self.Folder .. "/settings/" .. name .. ".json", encoded)
	self.ActiveProfile = name
	self.Ready = true
	return true
end

function SaveManager:Load(name)
	if not name then
		return false, "no config selected"
	end
	if not FileApi() then
		return false, "your executor has no file functions"
	end
	local path = self.Folder .. "/settings/" .. name .. ".json"
	if not isfile(path) then
		return false, "config does not exist"
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(path))
	if not ok or type(decoded) ~= "table" then
		return false, "config is corrupted"
	end
	self.ActiveProfile = name
	self.Ready = true
	-- changes made while loading shouldn't trigger an autosave
	self.Loading = true
	for _, entry in ipairs(decoded.objects or {}) do
		local parser = self.Parser[entry.type]
		if parser and not self.Ignore[entry.idx] then
			task.spawn(parser.Load, entry.idx, entry)
		end
	end
	task.defer(function()
		self.Loading = false
	end)
	return true
end

function SaveManager:Delete(name)
	local path = self.Folder .. "/settings/" .. tostring(name) .. ".json"
	if type(delfile) == "function" and type(isfile) == "function" and isfile(path) then
		delfile(path)
		return true
	end
	return false, "config does not exist"
end

function SaveManager:RefreshConfigList()
	if not FileApi() or type(listfiles) ~= "function" then
		return {}
	end
	self:BuildFolderTree()
	local out = {}
	for _, file in ipairs(listfiles(self.Folder .. "/settings")) do
		local name = file:gsub("\\", "/"):match("([^/]+)%.json$")
		if name then
			table.insert(out, name)
		end
	end
	table.sort(out)
	return out
end

function SaveManager:GetAutoloadConfig()
	local path = self.Folder .. "/settings/autoload.txt"
	if FileApi() and isfile(path) then
		local name = readfile(path)
		if name ~= "" then
			return name
		end
	end
	return nil
end

function SaveManager:SetAutoloadConfig(name)
	if not FileApi() then
		return false
	end
	self:BuildFolderTree()
	writefile(self.Folder .. "/settings/autoload.txt", name or "")
	return true
end

-- A moment after a saved option changes, writes the current profile (the
-- one last loaded or saved, else the autoload one, else a new "Autosave").
function SaveManager:SetAutosave(enabled)
	self.Autosave = enabled == true
	if FileApi() then
		self:BuildFolderTree()
		writefile(self.Folder .. "/settings/autosave.txt", self.Autosave and "1" or "0")
	end
	if not self.Autosave or self.AutosaveConnection or not self.Library or not self.Library.OptionChanged then
		return
	end
	local queued = false
	self.AutosaveConnection = self.Library.OptionChanged:Connect(function(idx, _, element)
		if not self.Autosave or not self.Ready or self.Loading or self.Ignore[idx] or queued then
			return
		end
		if element and not self.Parser[element.Type] then
			return -- labels, progress bars and the like aren't saved
		end
		queued = true
		task.delay(1, function()
			queued = false
			if not self.Autosave or self.Library.Unloaded then
				return
			end
			-- resolved now, so a profile loaded in the meantime is the one updated
			local name = self.ActiveProfile or self:GetAutoloadConfig()
			local created = name == nil
			name = name or "Autosave"
			if self:Save(name) and created then
				self:SetAutoloadConfig(name)
				if self.OnAutoloadChanged then
					self.OnAutoloadChanged(name)
				end
			end
		end)
	end)
end

function SaveManager:LoadAutoloadConfig()
	local name = self:GetAutoloadConfig()
	if not name then
		self.Ready = true -- nothing to load: the current values are the state
		return
	end
	local ok, err = self:Load(name)
	if self.Library then
		if ok then
			self.Library:Notify({ Title = "Configuration", Content = "Loaded “" .. name .. "” automatically.", Icon = "folder" })
		else
			self.Library:Notify({ Title = "Configuration", Content = "Could not autoload “" .. name .. "”: " .. tostring(err), Icon = "alert-triangle", IconColor = "Orange" })
		end
	end
end

function SaveManager:BuildConfigSection(tab)
	assert(self.Library, "[SaveManager] call SetLibrary(MacUI) first")
	local library = self.Library
	local function Notify(title, content, failed)
		library:Notify({
			Title = title,
			Content = content,
			Icon = failed and "alert-triangle" or "folder",
			IconColor = failed and "Orange" or nil,
			Duration = 4,
		})
	end

	local section = tab:AddSection({
		Title = "Configurations",
		Description = "Save every setting in this window to a named profile.",
		Icon = "folder",
	})
	local nameInput = section:AddInput("SaveManager_ConfigName", {
		Title = "Profile name",
		Placeholder = "e.g. Farming",
	})
	local list = section:AddDropdown("SaveManager_ConfigList", {
		Title = "Saved profiles",
		Values = self:RefreshConfigList(),
		AllowNull = true,
		Searchable = true,
	})
	section:AddButton({
		Title = "Create profile",
		Description = "Save the current settings under the name above.",
		ButtonText = "Create",
		Style = "Primary",
		Callback = function()
			local name = nameInput.Value
			local ok, err = self:Save(name)
			if not ok then
				return Notify("Couldn’t save profile", err, true)
			end
			Notify("Profile created", "Saved “" .. name .. "”.")
			list:SetValues(self:RefreshConfigList())
			list:SetValue(name)
		end,
	})
	section:AddButton({
		Title = "Load profile",
		Description = "Apply the selected profile.",
		ButtonText = "Load",
		Callback = function()
			local ok, err = self:Load(list.Value)
			if not ok then
				return Notify("Couldn’t load profile", err, true)
			end
			Notify("Profile loaded", "Applied “" .. list.Value .. "”.")
		end,
	})
	section:AddButton({
		Title = "Overwrite profile",
		Description = "Replace the selected profile with the current settings.",
		ButtonText = "Overwrite",
		Callback = function()
			local ok, err = self:Save(list.Value)
			if not ok then
				return Notify("Couldn’t overwrite profile", err, true)
			end
			Notify("Profile saved", "Overwrote “" .. list.Value .. "”.")
		end,
	})
	local autoload = section:AddLabel({
		Title = "Autoload",
		Description = "Loaded automatically when the script starts.",
		Value = self:GetAutoloadConfig() or "None",
	})
	section:AddButton({
		Title = "Set as autoload",
		Description = "Use the selected profile on every launch.",
		ButtonText = "Set",
		Callback = function()
			if not list.Value then
				return Notify("No profile selected", "Pick a profile first.", true)
			end
			self:SetAutoloadConfig(list.Value)
			autoload:SetValue(list.Value)
			Notify("Autoload set", "“" .. list.Value .. "” will load automatically.")
		end,
	})
	section:AddButton({
		Title = "Refresh list",
		ButtonText = "Refresh",
		Callback = function()
			list:SetValues(self:RefreshConfigList())
		end,
	})

	self.OnAutoloadChanged = function(name)
		autoload:SetValue(name)
		list:SetValues(self:RefreshConfigList())
	end
	self:SetIgnoreIndexes({ "SaveManager_ConfigName", "SaveManager_ConfigList", "SaveManager_Autosave" })
	local savedAutosave = FileApi() and isfile(self.Folder .. "/settings/autosave.txt") and readfile(self.Folder .. "/settings/autosave.txt") == "1"
	local built = false
	section:AddToggle("SaveManager_Autosave", {
		Title = "Save changes automatically",
		Description = "Keep the current profile up to date as you change settings.",
		Default = savedAutosave,
		Callback = function(value)
			if value ~= self.Autosave then
				self:SetAutosave(value)
			end
			if built then
				self.Ready = true -- turned on by hand: what's on screen is the state
			end
		end,
	})
	built = true
	return section
end

return SaveManager
