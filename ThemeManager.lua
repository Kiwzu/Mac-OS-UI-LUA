--========================================================
-- 🍎 MacUI ThemeManager.lua  (Sonoma Edition)
-- Handles Light/Dark mode, blur transition, and accent sync
--========================================================

local TweenService = game:GetService("TweenService")

local ThemeManager = {}
ThemeManager.__index = ThemeManager
ThemeManager.CurrentTheme = "Dark"

--// Default Theme Palettes
ThemeManager.Colors = {
	Dark = {
		Background = Color3.fromRGB(38, 38, 42),
		Sidebar = Color3.fromRGB(30, 30, 34),
		Text = Color3.fromRGB(235, 235, 235),
		Element = Color3.fromRGB(55, 55, 60)
	},
	Light = {
		Background = Color3.fromRGB(238, 238, 244),
		Sidebar = Color3.fromRGB(225, 225, 230),
		Text = Color3.fromRGB(40, 40, 45),
		Element = Color3.fromRGB(210, 210, 220)
	}
}

--// Active Colors table (runtime cache)
ThemeManager.ThemeColors = ThemeManager.Colors.Dark

--// Helper tween
local function Tween(obj, props)
	TweenService:Create(obj, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

--// ✅ Accent Connection (from AccentManager)
function ThemeManager:LinkAccent(accentFunc)
	self.GetAccent = accentFunc
end

--// Apply Theme instantly
function ThemeManager:ApplyTheme(mode)
	mode = mode or "Dark"
	local target = ThemeManager.Colors[mode]
	if not target then return end
	ThemeManager.CurrentTheme = mode
	ThemeManager.ThemeColors = target
end

--// Smooth transition with blur overlay
function ThemeManager:Transition(rootUI, newMode)
	newMode = newMode or (self.CurrentTheme == "Dark" and "Light" or "Dark")

	local Fade = Instance.new("Frame", rootUI)
	Fade.BackgroundColor3 = ThemeManager.ThemeColors.Background
	Fade.BackgroundTransparency = 1
	Fade.Size = UDim2.new(1,0,1,0)
	Fade.ZIndex = 999
	Tween(Fade, {BackgroundTransparency = 0.1})
	task.wait(0.15)

	self:ApplyTheme(newMode)
	Tween(Fade, {BackgroundTransparency = 1})
	task.wait(0.3)
	Fade:Destroy()
end

--// Retrieve a theme color
function ThemeManager:GetColor(which)
	local t = self.ThemeColors
	return t[which] or Color3.fromRGB(255,255,255)
end

return ThemeManager
