--[[
	MacUI · AccentManager
	The eight macOS accent colours plus helpers to switch between them.

	local AccentManager = loadstring(game:HttpGet(".../AccentManager.lua"))()
	AccentManager:SetLibrary(MacUI)
	AccentManager:ChangeAccent("Purple")            -- by name
	AccentManager:ChangeAccent(Color3.fromRGB(...)) -- or any colour
	AccentManager:BuildAccentDropdown(Tabs.Settings)
]]

local AccentManager = {
	Library = nil,
	CurrentName = "Blue",
	CurrentAccent = Color3.fromRGB(10, 132, 255),
	Order = { "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Graphite" },
	Accents = {
		Blue = Color3.fromRGB(10, 132, 255),
		Purple = Color3.fromRGB(191, 90, 242),
		Pink = Color3.fromRGB(255, 55, 95),
		Red = Color3.fromRGB(255, 69, 58),
		Orange = Color3.fromRGB(255, 159, 10),
		Yellow = Color3.fromRGB(255, 204, 0),
		Green = Color3.fromRGB(48, 209, 88),
		Graphite = Color3.fromRGB(142, 142, 147),
	},
}
AccentManager.__index = AccentManager

local function NameOf(accents, order, color)
	for _, name in ipairs(order) do
		if accents[name] == color then
			return name
		end
	end
	return "Custom"
end

function AccentManager:SetLibrary(library)
	self.Library = library
	self.Accents = library.Accents
	self.Order = library.AccentOrder
	self.CurrentAccent = library.Accent
	self.CurrentName = NameOf(self.Accents, self.Order, library.Accent)
	library.AccentChanged:Connect(function(color)
		self.CurrentAccent = color
		self.CurrentName = NameOf(self.Accents, self.Order, color)
		for _, control in ipairs(self._controls or {}) do
			if control.Type == "Dropdown" and self.CurrentName ~= "Custom" and control.Value ~= self.CurrentName then
				control:SetValue(self.CurrentName)
			elseif control.Type == "Colorpicker" and control.Value ~= color then
				control:SetValueRGB(color)
			end
		end
	end)
end

function AccentManager:_Track(control)
	self._controls = self._controls or {}
	table.insert(self._controls, control)
	return control
end

function AccentManager:GetAccent()
	return self.CurrentAccent
end

-- Accepts an accent name ("Purple"), a Color3 or a hex string ("#ff9f0a").
function AccentManager:ChangeAccent(value)
	local color = self.Accents[value] or value
	if type(color) == "string" then
		local ok, parsed = pcall(Color3.fromHex, color)
		color = ok and parsed or nil
	end
	if typeof(color) ~= "Color3" then
		warn("[AccentManager] unknown accent: " .. tostring(value))
		return
	end
	if self.Library then
		if self.Library.Accent ~= color then
			self.Library:SetAccent(color)
		end
	else
		self.CurrentAccent = color
		self.CurrentName = self.Accents[value] and value or "Custom"
	end
end
AccentManager.SetAccent = AccentManager.ChangeAccent

-- Adds a dropdown listing the macOS accents. `callback(name)` fires after a change.
function AccentManager:BuildAccentDropdown(tab, callback)
	return self:_Track(tab:AddDropdown("AccentManager_Accent", {
		Title = "Accent colour",
		Description = "Highlight colour for controls and selections.",
		Values = self.Order,
		Default = self.CurrentName ~= "Custom" and self.CurrentName or nil,
		Callback = function(name)
			if name and name ~= self.CurrentName then
				self:ChangeAccent(name)
				if callback then
					callback(name)
				end
			end
		end,
	}))
end

-- Same as above, but as a colour picker that accepts any colour.
-- Re-theming every element is expensive, so drag updates are coalesced.
function AccentManager:BuildAccentPicker(tab, callback)
	local pending, scheduled = nil, false
	return self:_Track(tab:AddColorpicker("AccentManager_Color", {
		Title = "Custom accent",
		Description = "Pick any colour.",
		Default = self.CurrentAccent,
		Callback = function(color)
			pending = color
			if scheduled then
				return
			end
			scheduled = true
			task.delay(0.12, function()
				scheduled = false
				if pending and pending ~= self.CurrentAccent then
					self:ChangeAccent(pending)
					if callback then
						callback(pending)
					end
				end
			end)
		end,
	}))
end

return AccentManager
