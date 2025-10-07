--========================================================
-- 🍎 MacUI V3 Ultra - Sonoma Edition
-- Author: Kiwzu / ChatGPT build
-- Version: 3.0
-- macOS Fluent-Plus Framework for Roblox
--========================================================

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--// Core Variables
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Module
local MacUI = {}
MacUI.__index = MacUI
MacUI.Version = "3.0 - Sonoma"

--// Require Addons
local success, ThemeManager = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/YourName/MacUI/main/Addons/ThemeManager.lua"))()
end)
local success2, AccentManager = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/YourName/MacUI/main/Addons/AccentManager.lua"))()
end)

-- Fallback
ThemeManager = ThemeManager or {
	CurrentTheme = "Dark",
	GetColor = function() return Color3.fromRGB(90,170,255) end,
	ThemeColors = { Background = Color3.fromRGB(35,35,40), Text = Color3.fromRGB(240,240,240) }
}
AccentManager = AccentManager or { CurrentAccent = Color3.fromRGB(90,170,255) }

--// Configuration
getgenv().MacUI_Config = {
	Acrylic = true,
	AnimationSpeed = 0.25,
	Font = Enum.Font.SourceSansSemibold,
	Accent = AccentManager.CurrentAccent,
}

--// Helper Tween
local function Tween(o, data)
	TweenService:Create(o, TweenInfo.new(getgenv().MacUI_Config.AnimationSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), data):Play()
end

--// Notification Queue
local NotificationQueue = {}

function MacUI:Notify(cfg)
	local gui = Instance.new("ScreenGui")
	gui.IgnoreGuiInset = true
	gui.Parent = PlayerGui
	gui.DisplayOrder = 999

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0, 280, 0, 80)
	Frame.Position = UDim2.new(1, -300, 1, -120 - (#NotificationQueue * 90))
	Frame.BackgroundColor3 = ThemeManager.ThemeColors.Background
	Frame.BackgroundTransparency = 0.2
	Frame.BorderSizePixel = 0
	Frame.ClipsDescendants = true
	Frame.Parent = gui

	local Corner = Instance.new("UICorner", Frame)
	Corner.CornerRadius = UDim.new(0, 10)

	local Title = Instance.new("TextLabel", Frame)
	Title.Size = UDim2.new(1, -20, 0, 24)
	Title.Position = UDim2.new(0, 10, 0, 8)
	Title.BackgroundTransparency = 1
	Title.Font = getgenv().MacUI_Config.Font
	Title.Text = cfg.Title or "Notification"
	Title.TextSize = 18
	Title.TextColor3 = AccentManager.CurrentAccent
	Title.TextXAlignment = Enum.TextXAlignment.Left

	local Content = Instance.new("TextLabel", Frame)
	Content.Size = UDim2.new(1, -20, 1, -40)
	Content.Position = UDim2.new(0, 10, 0, 30)
	Content.BackgroundTransparency = 1
	Content.Font = getgenv().MacUI_Config.Font
	Content.Text = cfg.Content or "Hello from macOS 🍎"
	Content.TextSize = 15
	Content.TextColor3 = ThemeManager.ThemeColors.Text
	Content.TextXAlignment = Enum.TextXAlignment.Left
	Content.TextYAlignment = Enum.TextYAlignment.Top
	Content.TextWrapped = true

	table.insert(NotificationQueue, Frame)
	Tween(Frame, {Position = UDim2.new(1, -300, 1, -100 - ((#NotificationQueue-1) * 90))})

	task.delay(cfg.Duration or 3, function()
		Tween(Frame, {Position = UDim2.new(1, 50, 1, -100)})
		task.wait(0.3)
		gui:Destroy()
		table.remove(NotificationQueue, 1)
	end)
end

--// Create Window
function MacUI:CreateWindow(config)
	local Window = {}
	setmetatable(Window, MacUI)
	local Theme = ThemeManager.ThemeColors
	local Accent = AccentManager.CurrentAccent

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = PlayerGui

	local Main = Instance.new("Frame")
	Main.Size = config.Size or UDim2.fromOffset(620, 480)
	Main.Position = UDim2.new(0.5, -310, 0.5, -240)
	Main.BackgroundColor3 = Theme.Background
	Main.BorderSizePixel = 0
	Main.Parent = ScreenGui

	Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
	local Stroke = Instance.new("UIStroke", Main)
	Stroke.Color = Color3.fromRGB(255,255,255)
	Stroke.Transparency = 0.9

	-- Acrylic blur layer
	if getgenv().MacUI_Config.Acrylic then
		local Glass = Instance.new("ImageLabel", Main)
		Glass.Size = UDim2.new(1, 0, 1, 0)
		Glass.Image = "rbxassetid://5553946656"
		Glass.ScaleType = Enum.ScaleType.Tile
		Glass.TileSize = UDim2.new(0, 300, 0, 300)
		Glass.ImageTransparency = 0.85
		Glass.ZIndex = -1
		Glass.BackgroundTransparency = 1
	end

	-- Titlebar
	local TitleFrame = Instance.new("Frame", Main)
	TitleFrame.Size = UDim2.new(1, 0, 0, 40)
	TitleFrame.BackgroundTransparency = 1

	local Title = Instance.new("TextLabel", TitleFrame)
	Title.Text = (config.Title or "MacUI Window")
	Title.Font = getgenv().MacUI_Config.Font
	Title.TextSize = 20
	Title.TextColor3 = Accent
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 20, 0, 0)
	Title.Size = UDim2.new(1, -40, 1, 0)
	Title.TextXAlignment = Enum.TextXAlignment.Left

	local Subtitle = Instance.new("TextLabel", TitleFrame)
	Subtitle.Text = config.SubTitle or ""
	Subtitle.Font = getgenv().MacUI_Config.Font
	Subtitle.TextSize = 14
	Subtitle.TextColor3 = Theme.Text
	Subtitle.BackgroundTransparency = 1
	Subtitle.Position = UDim2.new(0, 20, 0, 22)
	Subtitle.TextXAlignment = Enum.TextXAlignment.Left

	-- Tabs sidebar
	local Sidebar = Instance.new("Frame", Main)
	Sidebar.Size = UDim2.new(0, config.TabWidth or 180, 1, -40)
	Sidebar.Position = UDim2.new(0, 0, 0, 40)
	Sidebar.BackgroundColor3 = Theme.Background
	Sidebar.BorderSizePixel = 0

	local SidebarList = Instance.new("UIListLayout", Sidebar)
	SidebarList.Padding = UDim.new(0, 2)

	local Content = Instance.new("Frame", Main)
	Content.Size = UDim2.new(1, -(config.TabWidth or 180), 1, -40)
	Content.Position = UDim2.new(0, (config.TabWidth or 180), 0, 40)
	Content.BackgroundTransparency = 1

	local Tabs = {}
	local CurrentTab = nil

	function Window:AddTab(info)
		local Btn = Instance.new("TextButton", Sidebar)
		Btn.Size = UDim2.new(1, 0, 0, 36)
		Btn.Text = "   " .. info.Title
		Btn.TextXAlignment = Enum.TextXAlignment.Left
		Btn.TextColor3 = Theme.Text
		Btn.Font = getgenv().MacUI_Config.Font
		Btn.TextSize = 16
		Btn.BackgroundTransparency = 1

		local TabPage = Instance.new("ScrollingFrame", Content)
		TabPage.Size = UDim2.new(1, 0, 1, 0)
		TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
		TabPage.Visible = false
		TabPage.BackgroundTransparency = 1
		local Layout = Instance.new("UIListLayout", TabPage)
		Layout.Padding = UDim.new(0, 8)

		Tabs[info.Title] = TabPage
		Btn.MouseButton1Click:Connect(function()
			for _, v in pairs(Tabs) do v.Visible = false end
			TabPage.Visible = true
			Tween(Btn, {TextColor3 = Accent})
			if CurrentTab then CurrentTab.TextColor3 = Theme.Text end
			CurrentTab = Btn
		end)

		if not CurrentTab then
			CurrentTab = Btn
			TabPage.Visible = true
			Btn.TextColor3 = Accent
		end

		return TabPage
	end

	-- Example element
	function Window:AddButton(tab, info)
		local Button = Instance.new("TextButton", tab)
		Button.Size = UDim2.new(1, -20, 0, 35)
		Button.BackgroundColor3 = Theme.Background
		Button.Text = info.Title or "Button"
		Button.TextColor3 = Theme.Text
		Button.Font = getgenv().MacUI_Config.Font
		Button.TextSize = 15
		Button.AutoButtonColor = false
		Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

		Button.MouseEnter:Connect(function()
			Tween(Button, {BackgroundColor3 = Accent})
			Tween(Button, {TextColor3 = Color3.fromRGB(255,255,255)})
		end)
		Button.MouseLeave:Connect(function()
			Tween(Button, {BackgroundColor3 = Theme.Background})
			Tween(Button, {TextColor3 = Theme.Text})
		end)
		Button.MouseButton1Click:Connect(info.Callback or function() end)
	end

	function Window:Dialog(cfg)
		local Dialog = Instance.new("Frame", Main)
		Dialog.Size = UDim2.new(0, 300, 0, 180)
		Dialog.Position = UDim2.new(0.5, -150, 0.5, -90)
		Dialog.BackgroundColor3 = Theme.Background
		Dialog.BorderSizePixel = 0
		Dialog.ClipsDescendants = true
		Instance.new("UICorner", Dialog).CornerRadius = UDim.new(0, 12)

		local Title = Instance.new("TextLabel", Dialog)
		Title.Text = cfg.Title or "Dialog"
		Title.Font = getgenv().MacUI_Config.Font
		Title.TextColor3 = Accent
		Title.Size = UDim2.new(1, -20, 0, 30)
		Title.Position = UDim2.new(0, 10, 0, 10)
		Title.BackgroundTransparency = 1
		Title.TextXAlignment = Enum.TextXAlignment.Left

		local Text = Instance.new("TextLabel", Dialog)
		Text.Text = cfg.Content or "Confirm this action?"
		Text.Font = getgenv().MacUI_Config.Font
		Text.TextColor3 = Theme.Text
		Text.Size = UDim2.new(1, -20, 1, -70)
		Text.Position = UDim2.new(0, 10, 0, 40)
		Text.BackgroundTransparency = 1
		Text.TextWrapped = true
		Text.TextXAlignment = Enum.TextXAlignment.Left
		Text.TextYAlignment = Enum.TextYAlignment.Top

		local Buttons = Instance.new("Frame", Dialog)
		Buttons.Size = UDim2.new(1, -20, 0, 35)
		Buttons.Position = UDim2.new(0, 10, 1, -45)
		Buttons.BackgroundTransparency = 1
		local Layout = Instance.new("UIListLayout", Buttons)
		Layout.FillDirection = Enum.FillDirection.Horizontal
		Layout.Padding = UDim.new(0, 8)

		for _, b in ipairs(cfg.Buttons or {}) do
			local Btn = Instance.new("TextButton", Buttons)
			Btn.Size = UDim2.new(0.5, -4, 1, 0)
			Btn.BackgroundColor3 = Theme.Background
			Btn.Text = b.Title
			Btn.Font = getgenv().MacUI_Config.Font
			Btn.TextColor3 = Theme.Text
			Btn.TextSize = 15
			Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

			Btn.MouseButton1Click:Connect(function()
				if b.Callback then b.Callback() end
				Tween(Dialog, {Size = UDim2.new(0, 300, 0, 0)})
				task.wait(0.2)
				Dialog:Destroy()
			end)
		end
	end

	return Window
end

return MacUI
