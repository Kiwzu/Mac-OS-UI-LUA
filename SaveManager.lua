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

	Toggle and button shortcuts and recorded macros are saved too, and "Save
	changes automatically" keeps the current profile up to date as you play.
	ExportConfig() / ImportConfig(text) share settings as text.
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {
	Library = nil,
	Folder = "MacUI",
	Ignore = {},
	-- indexes starting with any of these are never saved
	IgnorePrefixes = {},
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

-- Executor file functions can throw (a bad path, a full disk, a sandbox
-- rule): that's reported, never raised into a button's callback.
local function Try(fn, ...)
	local ok, result = pcall(fn, ...)
	if ok then
		return true, result
	end
	return false, tostring(result)
end

-- A profile name that works as a file name: whole UTF-8 characters, no
-- folders, none of the characters Windows refuses, at most 60 characters.
local function CleanName(name)
	name = tostring(name or "")
	if not utf8.len(name) then
		local valid = {}
		for char in name:gmatch(utf8.charpattern) do
			if utf8.len(char) == 1 then
				table.insert(valid, char)
			end
		end
		name = table.concat(valid)
	end
	name = name:gsub("[%c\\/:%*%?\"<>|]", "")
	name = name:gsub("^[%s%.]+", ""):gsub("[%s%.]+$", "")
	if utf8.len(name) > 60 then
		name = name:sub(1, utf8.offset(name, 61) - 1):gsub("[%s%.]+$", "")
	end
	return name
end

-- A name to read, overwrite or delete: anything listed, but never a path.
local function SafeName(name)
	if type(name) ~= "string" or name == "" or name:find("[\\/]") then
		return nil
	end
	return name
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
			if option and tonumber(data.value) then
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
			local ok, color = pcall(Color3.fromHex, tostring(data.value or ""))
			if option and ok then
				option:SetValueRGB(color, tonumber(data.transparency))
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
	-- recorded steps, loop and speed (see Section:AddMacro)
	Macro = {
		Save = function(idx, object)
			return { type = "Macro", idx = idx, value = object:Export(), shortcut = object.Shortcut or "None" }
		end,
		Load = function(idx, data)
			local option = SaveManager.Library.Options[idx]
			if not option then
				return
			end
			if type(data.value) == "table" and option.Import then
				option:Import(data.value)
			end
			ApplyShortcut(option, data.shortcut)
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

function SaveManager:IsIgnored(idx)
	if self.Ignore[idx] then
		return true
	end
	idx = tostring(idx)
	for _, prefix in ipairs(self.IgnorePrefixes) do
		if idx:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

function SaveManager:IgnoreThemeSettings()
	self:SetIgnoreIndexes({
		"InterfaceTheme",
		"InterfaceAccent",
		"InterfaceScale",
		"InterfaceAcrylic",
		"InterfaceReduceMotion",
		"InterfacePerformanceGuard",
		"InterfaceShortcutList",
		"InterfaceRememberWindow",
		"MenuKeybind",
		"ThemeManager_Theme",
		"ThemeManager_Accent",
		"AccentManager_Accent",
		"AccentManager_Color",
	})
	table.insert(self.IgnorePrefixes, "ThemeEditor_")
end

function SaveManager:BuildFolderTree()
	if not FileApi() then
		return false
	end
	local current = ""
	for part in string.gmatch(self.Folder .. "/settings", "[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		local ok, exists = Try(isfolder, current)
		if not ok or not exists then
			if not Try(makefolder, current) then
				return false
			end
		end
	end
	return true
end

-- Every saved option, in the profile file format.
function SaveManager:_Collect()
	local data = { objects = {} }
	for idx, option in pairs(self.Library.Options) do
		local parser = self.Parser[option.Type]
		if parser and not self:IsIgnored(idx) then
			local entry = parser.Save(idx, option)
			if entry then
				table.insert(data.objects, entry)
			end
		end
	end
	return data
end

-- Applies a decoded profile. Returns false if it isn't one.
function SaveManager:_Apply(decoded)
	local objects = type(decoded) == "table" and decoded.objects
	if type(objects) ~= "table" then
		return false
	end
	-- changes made while loading shouldn't trigger an autosave, or count
	-- towards Spotlight's suggestions
	self.Loading = true
	local library = self.Library
	if library then
		library._LoadingProfile = true
	end
	task.defer(function()
		self.Loading = false
		if library then
			library._LoadingProfile = false
		end
	end)
	for _, entry in ipairs(objects) do
		local parser = type(entry) == "table" and self.Parser[entry.type]
		local option = parser and library and library.Options[entry.idx]
		-- a value only goes back into the same kind of control (the script
		-- may have changed since the profile was saved)
		if parser and entry.idx ~= nil and not self:IsIgnored(entry.idx) and (option == nil or option.Type == entry.type) then
			task.spawn(function()
				local ok, err = pcall(parser.Load, entry.idx, entry)
				if not ok then
					warn("[SaveManager] couldn't load " .. tostring(entry.idx) .. ": " .. tostring(err))
				end
			end)
		end
	end
	return true
end

-- Returns true and the name it was saved under (cleaned up to work as a
-- file name), or false and a reason.
function SaveManager:Save(name)
	-- a profile that already exists keeps its name (older versions allowed a
	-- trailing space, say); a new one gets a name that works as a file name
	local existing = SafeName(name)
	local keep = false
	if existing and FileApi() then
		local found, exists = Try(isfile, self.Folder .. "/settings/" .. existing .. ".json")
		keep = found and exists
	end
	name = keep and existing or CleanName(name)
	if name == "" then
		return false, "no config name given"
	end
	if not FileApi() then
		return false, "your executor has no file functions"
	end
	self:BuildFolderTree()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, self:_Collect())
	if not ok then
		return false, "failed to encode data"
	end
	local written, err = Try(writefile, self.Folder .. "/settings/" .. name .. ".json", encoded)
	if not written then
		return false, "couldn't write the file (" .. err .. ")"
	end
	self.ActiveProfile = name
	self.Ready = true
	return true, name
end

function SaveManager:Load(name)
	name = SafeName(name)
	if not name then
		return false, "no config selected"
	end
	if not FileApi() then
		return false, "your executor has no file functions"
	end
	local path = self.Folder .. "/settings/" .. name .. ".json"
	local found, exists = Try(isfile, path)
	if not found or not exists then
		return false, "config does not exist"
	end
	local read, text = Try(readfile, path)
	if not read then
		return false, "couldn't read the file (" .. text .. ")"
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, text)
	if not ok or type(decoded) ~= "table" or type(decoded.objects) ~= "table" then
		return false, "config is corrupted"
	end
	self.ActiveProfile = name
	self.Ready = true
	self:_Apply(decoded)
	return true
end

-- The current settings as text to share (the profile file format).
function SaveManager:ExportConfig()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, self:_Collect())
	return ok and encoded or nil
end

-- Applies text from ExportConfig(). Returns true, or false and a reason.
function SaveManager:ImportConfig(text)
	if type(text) ~= "string" or text:gsub("%s", "") == "" then
		return false, "paste a profile code first"
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, text)
	if not ok or not self:_Apply(decoded) then
		return false, "that isn't a profile code"
	end
	return true
end

function SaveManager:Delete(name)
	name = SafeName(name)
	if not name then
		return false, "no config selected"
	end
	if type(delfile) ~= "function" or type(isfile) ~= "function" then
		return false, "your executor can't delete files"
	end
	local path = self.Folder .. "/settings/" .. name .. ".json"
	local found, exists = Try(isfile, path)
	if not found or not exists then
		return false, "config does not exist"
	end
	local deleted, err = Try(delfile, path)
	if not deleted then
		return false, "couldn't delete the file (" .. err .. ")"
	end
	if self.ActiveProfile == name then
		self.ActiveProfile = nil
	end
	if self:GetAutoloadConfig() == name then
		self:SetAutoloadConfig(nil)
	end
	return true
end

function SaveManager:RefreshConfigList()
	if not FileApi() or type(listfiles) ~= "function" then
		return {}
	end
	self:BuildFolderTree()
	local ok, files = Try(listfiles, self.Folder .. "/settings")
	local out = {}
	for _, file in ipairs(ok and type(files) == "table" and files or {}) do
		local name = tostring(file):gsub("\\", "/"):match("([^/]+)%.json$")
		if name then
			table.insert(out, name)
		end
	end
	table.sort(out)
	return out
end

function SaveManager:GetAutoloadConfig()
	local path = self.Folder .. "/settings/autoload.txt"
	if FileApi() then
		local found, exists = Try(isfile, path)
		if found and exists then
			local read, name = Try(readfile, path)
			if read and type(name) == "string" and name ~= "" then
				return name
			end
		end
	end
	return nil
end

function SaveManager:SetAutoloadConfig(name)
	if not FileApi() then
		return false
	end
	self:BuildFolderTree()
	return (Try(writefile, self.Folder .. "/settings/autoload.txt", name or ""))
end

-- A moment after a saved option changes, writes the current profile (the
-- one last loaded or saved, else the autoload one, else a new "Autosave").
function SaveManager:SetAutosave(enabled)
	self.Autosave = enabled == true
	if FileApi() then
		self:BuildFolderTree()
		Try(writefile, self.Folder .. "/settings/autosave.txt", self.Autosave and "1" or "0")
	end
	if not self.Autosave or self.AutosaveConnection or not self.Library or not self.Library.OptionChanged then
		return
	end
	local queued = false
	self.AutosaveConnection = self.Library.OptionChanged:Connect(function(idx, _, element)
		if not self.Autosave or not self.Ready or self.Loading or self:IsIgnored(idx) or queued then
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
			local ok, result = self:Save(nameInput.Value)
			if not ok then
				return Notify("Couldn’t save profile", result, true)
			end
			Notify("Profile created", "Saved “" .. result .. "”.")
			list:SetValues(self:RefreshConfigList())
			list:SetValue(result)
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
		Title = "Delete profile",
		Description = "Remove the selected profile for good.",
		ButtonText = "Delete",
		Style = "Destructive",
		Callback = function()
			local name = list.Value
			if not name then
				return Notify("No profile selected", "Pick a profile first.", true)
			end
			local window = library.Windows and library.Windows[1]
			local function Remove()
				local ok, err = self:Delete(name)
				if not ok then
					return Notify("Couldn’t delete profile", err, true)
				end
				Notify("Profile deleted", "Removed “" .. name .. "”.")
				list:SetValues(self:RefreshConfigList())
				autoload:SetValue(self:GetAutoloadConfig() or "None")
			end
			if not window then
				return Remove()
			end
			window:Dialog({
				Title = "Delete “" .. name .. "”?",
				Content = "The profile file is removed. This can't be undone.",
				Icon = "trash-2",
				IconColor = "Red",
				Buttons = {
					{ Title = "Delete", Style = "Destructive", Callback = Remove },
					{ Title = "Cancel" },
				},
			})
		end,
	})
	section:AddButton({
		Title = "Refresh list",
		ButtonText = "Refresh",
		Callback = function()
			list:SetValues(self:RefreshConfigList())
		end,
	})

	section:AddButton({
		Title = "Share profile",
		Description = "Copy the current settings as text for someone else.",
		ButtonText = "Copy",
		Callback = function()
			local code = self:ExportConfig()
			if code and library.SetClipboard and library:SetClipboard(code) then
				Notify("Profile copied", "Paste it into “Import profile” to use these settings.")
			else
				Notify("Couldn’t copy", "Your executor has no clipboard function.", true)
			end
		end,
	})
	section:AddButton({
		Title = "Import profile",
		Description = "Apply settings someone shared with you.",
		ButtonText = "Import",
		Callback = function()
			local window = library.Windows and library.Windows[1]
			if not window then
				return
			end
			window:Dialog({
				Title = "Import profile",
				Content = "Paste a profile code copied with “Share profile”.",
				Icon = "download",
				Input = { Placeholder = "Profile code" },
				Buttons = {
					{ Title = "Import", Callback = function(text)
						local ok, err = self:ImportConfig(text)
						if ok then
							Notify("Profile imported", "The shared settings are applied.")
						else
							Notify("Couldn’t import", err, true)
						end
					end },
					{ Title = "Cancel" },
				},
			})
		end,
	})

	self.OnAutoloadChanged = function(name)
		autoload:SetValue(name)
		list:SetValues(self:RefreshConfigList())
	end
	self:SetIgnoreIndexes({ "SaveManager_ConfigName", "SaveManager_ConfigList", "SaveManager_Autosave" })
	local savedAutosave = false
	if FileApi() then
		local path = self.Folder .. "/settings/autosave.txt"
		local found, exists = Try(isfile, path)
		if found and exists then
			local read, text = Try(readfile, path)
			savedAutosave = read and text == "1"
		end
	end
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
