--[[
	MacUI — full demo
	Every component in one window. Paste into your executor.

	Once it's open:
	  • Ctrl + K (Cmd + K on Mac) opens Spotlight: type to find any setting,
	    press Enter to flip a toggle or run a button.
	  • Right-click any row to reset it, copy its value or give it a
	    keyboard shortcut.
	  • Right Ctrl hides and shows the window.
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
	Size = UDim2.fromOffset(800, 560),
	Theme = "Dark", -- "Dark" | "Light" | "Midnight"
	Accent = "Blue", -- macOS accent name or a Color3
	SidebarStyle = "Tile", -- "Tile" (System Settings) | "Tinted" | "Plain"
	Profile = true, -- avatar + name at the top of the sidebar
	MinimizeKey = Enum.KeyCode.RightControl,
	Acrylic = false, -- frosted-glass sidebar (users can switch it on in Appearance)
})

-- A description turns the top of a page into a System Settings-style header.
local Tabs = {
	General = Window:AddTab({
		Title = "General",
		Icon = "layers",
		Section = "Main",
		Description = "Farm automatically, follow your quest and run quick actions.",
	}),
	Combat = Window:AddTab({
		Title = "Combat",
		Icon = "swords",
		Description = "Choose how targets are picked and when combat kicks in.",
	}),
	Player = Window:AddTab({
		Title = "Player",
		Icon = "user",
		Description = "Movement and identity settings for your character.",
	}),
	Visuals = Window:AddTab({
		Title = "Visuals",
		Icon = "eye",
		Description = "Highlight players and tune what you see.",
	}),
	Teleport = Window:AddTab({
		Title = "Teleport",
		Icon = "map-pin",
		Description = "Travel to any location or player in one click.",
	}),
	Appearance = Window:AddTab({
		Title = "Appearance",
		Icon = "palette",
		Section = "Settings",
		Description = "Theme, accent colour, frosted glass, size and shortcuts.",
	}),
	Profiles = Window:AddTab({
		Title = "Profiles",
		Icon = "folder",
		Description = "Save your setup and load it automatically next time.",
	}),
	About = Window:AddTab({
		Title = "About",
		Icon = "info",
		Description = "What MacUI can do and how to load it.",
	}),
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
	Shortcut = "G", -- press G anywhere to flip it (right-click the row to change)
	Tooltip = "Pauses by itself while you're in a menu.",
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

Overview:AddStepper("FarmRadius", {
	Title = "Search radius",
	Description = "How far to look for enemies.",
	Min = 20,
	Max = 300,
	Step = 20,
	Default = 100,
	Suffix = " studs",
})

local Actions = Tabs.General:AddSection({ Title = "Actions", Icon = "mouse-pointer-2" })

Actions:AddButton({
	Title = "Show notification",
	Description = "A macOS-style banner with action buttons.",
	ButtonText = "Show",
	Callback = function()
		MacUI:Notify({
			Title = "Quest complete",
			SubContent = "Blessed Maiden",
			Content = "Your reward is waiting. Open the Appearance page to try another theme?",
			Icon = "trophy",
			IconColor = "Yellow",
			Duration = 8,
			Buttons = {
				{
					Title = "Open",
					Callback = function()
						Window:SelectTab(Tabs.Appearance)
					end,
				},
				{ Title = "Later" },
			},
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

Actions:AddButton({
	Title = "Rename window",
	Description = "A dialog that asks for text.",
	Callback = function()
		Window:Dialog({
			Title = "Rename window",
			Content = "Choose a new title for this window.",
			Icon = "pencil",
			Input = { Placeholder = "Title", Default = Window.Title },
			Buttons = {
				{
					Title = "Rename",
					Callback = function(text)
						if text and text:gsub("%s", "") ~= "" then
							Window:SetTitle(text)
						end
					end,
				},
				{ Title = "Cancel" },
			},
		})
	end,
})

Actions:AddButton({
	Title = "Open Spotlight",
	Description = "Or press Ctrl + K anywhere.",
	ButtonText = "Search",
	Callback = function()
		Window:OpenSpotlight()
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

Aim:AddRadio("TargetPriority", {
	Title = "Priority",
	Description = "Which target wins when several are in range.",
	Values = { "Closest to cursor", "Lowest health", "Nearest" },
	Default = "Closest to cursor",
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
	Tooltip = "0 snaps instantly, 1 moves slowest.",
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
Filters:AddStepper("MaxTargets", {
	Title = "Targets at once",
	Min = 1,
	Max = 8,
	Default = 3,
})

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
-- DependsOn greys a row out until the flag is on (DependsMode = "Hide" hides it instead).
Esp:AddColorpicker("EspColor", {
	Title = "Fill colour",
	Default = Color3.fromRGB(10, 132, 255),
	Transparency = 0.5,
	DependsOn = "EspEnabled",
})
Esp:AddDropdown("EspStyle", {
	Title = "Style",
	Values = { "Outline", "Fill", "Outline + Fill" },
	Default = "Outline + Fill",
	DependsOn = "EspEnabled",
})
Esp:AddSlider("EspDistance", {
	Title = "Max distance",
	Min = 50,
	Max = 2000,
	Default = 800,
	Increment = 50,
	Suffix = " studs",
	DependsOn = "EspEnabled",
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

local People = Tabs.Teleport:AddSection({ Title = "Players", Icon = "users" })
-- Values = "Players" keeps the list in sync as people join and leave.
People:AddDropdown("TeleportTarget", {
	Title = "Player",
	Values = "Players",
	Searchable = true,
})
People:AddButton({
	Title = "Go to player",
	ButtonText = "Teleport",
	Style = "Primary",
	DependsOn = "TeleportTarget", -- enabled once a player is picked
	Callback = function()
		MacUI:Notify({ Title = "Teleport", Content = "Travelling to " .. tostring(Options.TeleportTarget.Value) .. "…", Icon = "users" })
	end,
})

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

--------------------------------------------------------------------------------
-- About
--------------------------------------------------------------------------------

local Tips = Tabs.About:AddSection({ Title = "Tips", Icon = "sparkles" })
Tips:AddParagraph({
	Title = "Spotlight",
	Content = "Press <b>Ctrl + K</b> to search every setting in this window. Enter flips a toggle or runs a button; Shift + Enter just shows it.",
})
Tips:AddParagraph({
	Title = "Right-click menus",
	Content = "Right-click (or long-press) any row to reset it, copy its value or assign a keyboard shortcut.",
})

local Loader = Tabs.About:AddSection({ Title = "Load MacUI" })
Loader:AddCode({
	Title = "Loader",
	Description = "Paste this at the top of your own script.",
	Code = 'local MacUI = loadstring(game:HttpGet("' .. BASE .. 'MacUIFramework.lua"))()',
})

MacUI:Notify({
	Title = "MacUI loaded",
	Content = "Press Ctrl + K to search, Right Ctrl to hide the window.",
	Icon = "command",
	Duration = 6,
})
SaveManager:LoadAutoloadConfig()
