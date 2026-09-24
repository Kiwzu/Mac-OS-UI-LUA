--[[
	MacUI — full demo
	Every component in one window. Paste into your executor.
]]

local BASE = "https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/"
local MacUI = loadstring(game:HttpGet(BASE .. "MacUIFramework.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE .. "SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(BASE .. "InterfaceManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Options = MacUI.Options

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local Window = MacUI:CreateWindow({
	Title = "MacUI Hub",
	SubTitle = "Sonoma Edition",
	Icon = "command", -- any Lucide icon name or rbxassetid://
	Size = UDim2.fromOffset(780, 540),
	Theme = "Dark", -- "Dark" | "Light" | "Midnight"
	Accent = "Blue", -- macOS accent name or a Color3
	SidebarStyle = "Tile", -- "Tile" (System Settings) | "Tinted" | "Plain"
	Profile = true, -- avatar + name at the top of the sidebar
	MinimizeKey = Enum.KeyCode.RightControl,
})

local Tabs = {
	General = Window:AddTab({ Title = "General", Icon = "layers", Section = "Main" }),
	Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
	Player = Window:AddTab({ Title = "Player", Icon = "user" }),
	Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
	Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
	Appearance = Window:AddTab({ Title = "Appearance", Icon = "palette", Section = "Settings" }),
	Profiles = Window:AddTab({ Title = "Profiles", Icon = "folder" }),
}

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------

local Overview = Tabs.General:AddSection({
	Title = "Auto Farm",
	Description = "Automatically find and defeat enemies.",
	Icon = "swords",
})

local Status = Overview:AddLabel("FarmStatus", {
	Title = "Status",
	Description = "Current farming status.",
	Value = "Idle",
})

Overview:AddLabel({
	Value = "✓ 170/4 Relics  |  ✓ 7.5B Money  |  ✓ 4.4M Gems",
})

local Progress = Overview:AddProgress("FarmProgress", {
	Title = "Quest progress",
	Description = "Defeat 25 enemies.",
	Max = 25,
	Default = 0,
})

Overview:AddToggle("AutoFarm", {
	Title = "Enabled",
	Description = "Farm automatically whenever it is safe.",
	Default = false,
	Callback = function(enabled)
		Status:SetValue(enabled and "Fighting: Training Dummy" or "Idle")
		if enabled then
			task.spawn(function()
				while Options.AutoFarm.Value and Progress.Value < Progress.Max do
					task.wait(0.4)
					Progress:SetValue(Progress.Value + 1)
				end
			end)
		end
	end,
})

Overview:AddDropdown("Difficulty", {
	Title = "Difficulty",
	Description = "For enemies that support it.",
	Values = { "Easy", "Normal", "Hard", "Extreme" },
	Default = "Extreme",
})

Overview:AddDropdown("Targets", {
	Title = "Targets",
	Description = "Checked in order.",
	Values = { "Training Dummy", "Bandit", "Pirate Captain", "Sea Beast", "Blessed Maiden" },
	Multi = true,
	Default = { "Training Dummy" },
})

local Actions = Tabs.General:AddSection({ Title = "Actions", Icon = "mouse-pointer-2" })

Actions:AddButton({
	Title = "Show notification",
	Description = "A macOS-style banner in the top-right corner.",
	ButtonText = "Show",
	Callback = function()
		MacUI:Notify({
			Title = "MacUI",
			SubContent = "Notifications",
			Content = "This is what a notification banner looks like.",
			Icon = "bell",
			Duration = 5,
		})
	end,
})

Actions:AddButton({
	Title = "Open dialog",
	Description = "A sheet-style alert with a primary action.",
	Callback = function()
		Window:Dialog({
			Title = "Reset statistics?",
			Content = "Your session counters will go back to zero. This can’t be undone.",
			Icon = "rotate-ccw",
			Buttons = {
				{
					Title = "Reset",
					Callback = function()
						Progress:SetValue(0)
					end,
				},
				{ Title = "Cancel" },
			},
		})
	end,
})

--------------------------------------------------------------------------------
-- Combat
--------------------------------------------------------------------------------

local Aim = Tabs.Combat:AddSection({
	Title = "Targeting",
	Description = "How targets are picked.",
	Icon = "crosshair",
})

Aim:AddSegmented("TargetPart", {
	Title = "Target part",
	Values = { "Head", "Torso", "Random" },
	Default = "Torso",
})

Aim:AddSlider("FieldOfView", {
	Title = "Field of view",
	Description = "Radius around the cursor.",
	Min = 20,
	Max = 400,
	Default = 120,
	Suffix = "px",
})

Aim:AddSlider("Smoothness", {
	Title = "Smoothness",
	Min = 0,
	Max = 1,
	Default = 0.35,
	Rounding = 2,
})

Aim:AddKeybind("CombatKey", {
	Title = "Toggle key",
	Description = "Click, then press any key.",
	Default = "Q",
	Mode = "Toggle",
	Callback = function(active)
		print("[Combat] active:", active)
	end,
})

local Filters = Tabs.Combat:AddSection({ Title = "Filters" })
Filters:AddCheckbox("IgnoreFriends", { Title = "Ignore friends", Default = true })
Filters:AddCheckbox("IgnoreTeam", { Title = "Ignore teammates", Default = true })
Filters:AddCheckbox("VisibleOnly", { Title = "Visible targets only", Default = false })

--------------------------------------------------------------------------------
-- Player
--------------------------------------------------------------------------------

local Movement = Tabs.Player:AddSection({
	Title = "Movement",
	Description = "Changes apply to your character immediately.",
	Icon = "person-standing",
})

local function Humanoid()
	local character = LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

Movement:AddSlider("WalkSpeed", {
	Title = "Walk speed",
	Min = 16,
	Max = 120,
	Default = 16,
	Callback = function(value)
		local humanoid = Humanoid()
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

Movement:AddSlider("JumpPower", {
	Title = "Jump power",
	Min = 50,
	Max = 200,
	Default = 50,
	Callback = function(value)
		local humanoid = Humanoid()
		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = value
		end
	end,
})

Movement:AddToggle("InfiniteJump", {
	Title = "Infinite jump",
	Description = "Jump again while in the air.",
	Default = false,
})

local Identity = Tabs.Player:AddSection({ Title = "Identity" })
Identity:AddInput("Nickname", {
	Title = "Nickname",
	Description = "Shown in notifications.",
	Placeholder = LocalPlayer.DisplayName,
	Finished = true,
	Callback = function(text)
		MacUI:Notify({ Title = "Nickname updated", Content = "Hello, " .. text .. "!", Icon = "user" })
	end,
})
Identity:AddParagraph({
	Title = "About",
	Content = "Paragraphs hold longer text. They wrap automatically and support <b>rich text</b>.",
})

--------------------------------------------------------------------------------
-- Visuals
--------------------------------------------------------------------------------

local Esp = Tabs.Visuals:AddSection({
	Title = "Highlights",
	Description = "Outline players through walls.",
	Icon = "eye",
})
Esp:AddToggle("EspEnabled", { Title = "Enabled", Default = true })
Esp:AddColorpicker("EspColor", {
	Title = "Fill colour",
	Default = Color3.fromRGB(10, 132, 255),
	Transparency = 0.5,
})
Esp:AddDropdown("EspStyle", {
	Title = "Style",
	Values = { "Outline", "Fill", "Outline + Fill" },
	Default = "Outline + Fill",
})

--------------------------------------------------------------------------------
-- Teleport
--------------------------------------------------------------------------------

local Places = Tabs.Teleport:AddSection({ Title = "Locations", Icon = "map" })
for _, place in ipairs({ "Spawn", "Shop", "Arena", "Secret Island" }) do
	Places:AddButton({
		Title = place,
		Description = "Teleport to " .. place .. ".",
		Callback = function()
			MacUI:Notify({ Title = "Teleport", Content = "Travelling to " .. place .. "…", Icon = "map-pin" })
		end,
	})
end
Tabs.Teleport:SetBadge(4)

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

InterfaceManager:SetLibrary(MacUI)
InterfaceManager:SetFolder("MacUI/ExampleHub")
InterfaceManager:BuildInterfaceSection(Tabs.Appearance)

SaveManager:SetLibrary(MacUI)
SaveManager:SetFolder("MacUI/ExampleHub/" .. tostring(game.PlaceId))
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Profiles)

Window:SelectTab(1)
MacUI:Notify({
	Title = "MacUI loaded",
	Content = "Press Right Ctrl to hide or show the window.",
	Icon = "command",
	Duration = 6,
})
SaveManager:LoadAutoloadConfig()
