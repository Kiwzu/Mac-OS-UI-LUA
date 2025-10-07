--========================================================
-- 🍎 MacUI AccentManager.lua  (Sonoma Edition)
-- Handles dynamic accent colors & smooth transitions
--========================================================

local TweenService = game:GetService("TweenService")

local AccentManager = {}
AccentManager.__index = AccentManager

-- Default accent
AccentManager.CurrentAccent = Color3.fromRGB(90, 170, 255)

-- Preset macOS accent palette
AccentManager.Accents = {
	Blue      = Color3.fromRGB(90, 170, 255),
	Purple    = Color3.fromRGB(175, 140, 255),
	Pink      = Color3.fromRGB(255, 120, 200),
	Red       = Color3.fromRGB(255, 95, 95),
	Orange    = Color3.fromRGB(255, 160, 90),
	Yellow    = Color3.fromRGB(255, 200, 80),
	Green     = Color3.fromRGB(80, 220, 140),
	Mint      = Color3.fromRGB(120, 255, 230),
	Graphite  = Color3.fromRGB(160, 160, 165),
}

-- Animation speed
AccentManager.TweenTime = 0.25

-- Tween helper
local function Tween(obj, props)
	TweenService:Create(obj, TweenInfo.new(AccentManager.TweenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

-- Storage of all accent-linked UI objects
AccentManager.LinkedObjects = {}

-- Link UI object to accent updates
function AccentManager:Link(obj, prop)
	table.insert(self.LinkedObjects, {Object = obj, Property = prop})
	obj[prop] = self.CurrentAccent
end

-- Smooth color update for all linked objects
function AccentManager:ApplyAccent(newColor)
	for _, data in ipairs(self.LinkedObjects) do
		if data.Object and data.Object.Parent then
			Tween(data.Object, {[data.Property] = newColor})
		end
	end
end

-- Change accent by name or Color3
function AccentManager:ChangeAccent(accent)
	local color = nil
	if typeof(accent) == "Color3" then
		color = accent
	elseif typeof(accent) == "string" then
		color = self.Accents[accent] or self.CurrentAccent
	end

	if color then
		self.CurrentAccent = color
		self:ApplyAccent(color)
	end
end

-- Build a dropdown UI for selecting accent (optional helper)
function AccentManager:BuildAccentDropdown(parent, callback)
	local accents = {}
	for name, _ in pairs(self.Accents) do
		table.insert(accents, name)
	end
	table.sort(accents)
	
	local Dropdown = parent:AddDropdown("AccentSelector", {
		Title = "Accent Color",
		Values = accents,
		Multi = false,
		Default = "Blue",
	})
	
	Dropdown:OnChanged(function(value)
		self:ChangeAccent(value)
		if callback then callback(value) end
	end)
	
	return Dropdown
end

return AccentManager
