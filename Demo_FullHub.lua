--[[
	MacUI — full API demo
	Every function in the library, one page per area. Each row names the
	call it makes, so the code below reads like a reference.

	Run it straight from GitHub:
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/Demo_FullHub.lua"))()

	To load everything from another branch, set getgenv().MacUIBase to that
	branch's raw folder URL (ending in "/") before running.
]]

local BASE = (getgenv and getgenv().MacUIBase) or "https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/"

local MacUI = loadstring(game:HttpGet(BASE .. "MacUIFramework.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE .. "SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(BASE .. "InterfaceManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(BASE .. "ThemeManager.lua"))()
local AccentManager = loadstring(game:HttpGet(BASE .. "AccentManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Options = MacUI.Options -- every element created with an index

--------------------------------------------------------------------------------
-- Custom themes (add them before building the Appearance section so its
-- picker lists them). Unlisted colour tokens come from the base theme.
--------------------------------------------------------------------------------

local rgb = Color3.fromRGB
MacUI:AddTheme("Ocean", {
	Background = rgb(14, 26, 40),
	Sidebar = rgb(19, 34, 52),
	SidebarDivider = rgb(8, 16, 26),
	Group = rgb(22, 39, 58),
	GroupStroke = rgb(34, 56, 80),
	Separator = rgb(36, 58, 82),
	SubText = rgb(150, 172, 196),
	Tertiary = rgb(96, 120, 146),
	Control = rgb(44, 70, 98),
	ControlHover = rgb(54, 84, 116),
	ControlStroke = rgb(58, 88, 120),
	Button = rgb(40, 66, 94),
	ButtonHover = rgb(50, 80, 112),
	Field = rgb(12, 22, 34),
	FieldStroke = rgb(40, 64, 90),
	Search = rgb(28, 48, 70),
	SwitchOff = rgb(44, 70, 98),
	Track = rgb(40, 64, 90),
	SegmentBg = rgb(30, 52, 76),
	SegmentSelected = rgb(64, 98, 134),
	Menu = rgb(22, 39, 58),
	MenuStroke = rgb(48, 76, 106),
	Code = rgb(10, 19, 30),
}, "Dark")

MacUI:AddTheme("Rose", {
	Background = rgb(252, 245, 247),
	Sidebar = rgb(246, 231, 236),
	Group = rgb(255, 255, 255),
	Search = rgb(238, 222, 228),
	SegmentBg = rgb(240, 225, 231),
}, "Light")

--------------------------------------------------------------------------------
-- Window: every CreateWindow option
--------------------------------------------------------------------------------

local Window = MacUI:CreateWindow({
	Title = "MacUI Demo",
	SubTitle = "Every function · v" .. MacUI.Version,
	Icon = "command", -- Lucide icon name, rbxassetid:// or a number
	IconColor = "Blue", -- tile colour for that icon (dock, dialogs)
	Size = UDim2.fromOffset(820, 600),
	MinSize = Vector2.new(620, 420),
	TabWidth = 214, -- sidebar width
	Theme = "Dark", -- "Dark" | "Light" | "Midnight" | "Ocean" | "Rose"
	Accent = "Blue", -- accent name, hex string or Color3
	SidebarStyle = "Tile", -- "Tile" | "Tinted" | "Plain"
	Profile = { Title = LocalPlayer.DisplayName, Subtitle = "@" .. LocalPlayer.Name }, -- or true
	MinimizeKey = Enum.KeyCode.RightControl,
	Acrylic = false, -- frosted-glass sidebar (graphics quality 8+)
	KeybindList = false, -- floating list of keybinds and shortcuts
	Search = true, -- toolbar search field
	SearchPlaceholder = "Search",
	Spotlight = true, -- Ctrl/Cmd + K command palette
	SpotlightKey = Enum.KeyCode.K,
	Resizable = true,
	ConfirmClose = true, -- the red button asks before unloading
	ReplaceExisting = true, -- running the script again replaces this window
	ShowDock = true, -- dock icon while minimised
	Loading = { Subtitle = "Loading every demo…" }, -- a loading card while the tabs build
	Undo = true, -- Ctrl + Z / Ctrl + Shift + Z for changes you make
	-- Watermark = true, -- a status pill; this demo turns it on from the Advanced page
})

-- A Description gives the page a System Settings-style header.
local Tabs = {
	Home = Window:AddTab({ Title = "Home", Icon = "home", Section = "Tour", Description = "Start here: what this demo covers and a few quick things to try." }),
	Controls = Window:AddTab({ Title = "Controls", Icon = "sliders", Description = "Every input: switches, sliders, steppers, menus, radio groups, text, keys and colours." }),
	Display = Window:AddTab({ Title = "Display", Icon = "layout-grid", Description = "Read-only rows and every kind of button." }),
	Methods = Window:AddTab({ Title = "Methods", Icon = "wrench", Description = "What you can do with an element after creating it." }),
	Smart = Window:AddTab({ Title = "Smart rows", Icon = "wand-2", Description = "Dependencies, tooltips, search keywords and live player lists." }),
	Advanced = Window:AddTab({ Title = "Advanced", Icon = "rocket", Description = "Live graphs, tables, undo, Spotlight commands, the watermark, loading screens and collapsible sections." }),
	Window = Window:AddTab({ Title = "Window", Icon = "app-window", Section = "Window", Description = "Title bar, layout, navigation and saved state." }),
	Alerts = Window:AddTab({ Title = "Alerts", Icon = "bell", Description = "Notifications, toasts and dialogs." }),
	Appearance = Window:AddTab({ Title = "Appearance", Icon = "palette", Section = "Settings", Description = "Themes, accent colours, fonts, frosted glass and more." }),
	Profiles = Window:AddTab({ Title = "Profiles", Icon = "folder", Description = "Save every setting and load it automatically next time." }),
	About = Window:AddTab({ Title = "About", Icon = "info", Description = "Version, utilities and how to load MacUI." }),
}

--------------------------------------------------------------------------------
-- Home
--------------------------------------------------------------------------------

local Welcome = Tabs.Home:AddSection({ Title = "Welcome", Icon = "sparkles" })
Welcome:AddParagraph({
	Title = "How to use this demo",
	Content = "Each page covers one part of the API, and each row names the function it calls. "
		.. "Press <b>Ctrl + K</b> to search everything, right-click any row for more options, "
		.. "and press <b>Right Ctrl</b> to hide or show the window.",
})

-- No index: these two update often and shouldn't count as settings.
local LastChange = Welcome:AddLabel({
	Title = "Last change",
	Description = "MacUI.OptionChanged fires for every indexed element.",
	Value = "Nothing yet",
})
local Tour = Welcome:AddProgress({
	Title = "Tour",
	Description = "Pages you've opened (Window.StateChanged).",
	Max = #Window.Tabs,
	Default = 1,
})

-- Connected once the script has finished, so values set while building
-- (and by the autoload profile) don't count as changes.
task.defer(function()
	MacUI.OptionChanged:Connect(function(idx, value, element)
		local text = element and element:GetText() or tostring(value)
		LastChange:SetValue(("%s → %s"):format(tostring(idx), tostring(text or "none")))
	end)
end)

local visited = { Home = true }
Window.StateChanged:Connect(function(state)
	if state.Tab and not visited[state.Tab] then
		visited[state.Tab] = true
		local count = 0
		for _ in pairs(visited) do
			count += 1
		end
		Tour:SetValue(count)
	end
end)

local Try = Tabs.Home:AddSection({ Title = "Try it", Icon = "mouse-pointer-click" })
Try:AddButton({
	Title = "Open Spotlight",
	Description = "Window:OpenSpotlight(), or press Ctrl + K.",
	ButtonText = "Search",
	Style = "Primary",
	Callback = function()
		Window:OpenSpotlight()
	end,
})
Try:AddButton({
	Title = "Show a toast",
	Description = "Window:Toast(text, options)",
	ButtonText = "Toast",
	Callback = function()
		Window:Toast("Saved", { Detail = "just now", Icon = "check-circle", Highlight = true })
	end,
})
Try:AddButton({
	Title = "Send a notification",
	Description = "MacUI:Notify(options), with action buttons.",
	ButtonText = "Notify",
	Callback = function()
		MacUI:Notify({
			Title = "Welcome!",
			SubContent = "MacUI demo",
			Content = "Open the Controls page to see every input.",
			Icon = "sparkles",
			IconColor = "Purple",
			Duration = 8,
			Buttons = {
				{ Title = "Open", Callback = function()
					Tabs.Controls:Select()
				end },
				{ Title = "Later" },
			},
		})
	end,
})
Try:AddButton({
	Title = "Open a dialog",
	Description = "Window:Dialog(options)",
	ButtonText = "Dialog",
	Callback = function()
		Window:Dialog({
			Title = "Enjoying MacUI?",
			Content = "Dialogs dim the window and wait for an answer.",
			Icon = "heart",
			IconColor = "Pink",
			Buttons = {
				{ Title = "Yes!", Callback = function()
					Window:Toast("Thanks!", { Icon = "heart", Highlight = true })
				end },
				{ Title = "Not yet" },
			},
		})
	end,
})

--------------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------------

local Switches = Tabs.Controls:AddSection({ Title = "Switches", Description = "AddToggle and AddCheckbox.", Icon = "toggle-right" })
Switches:AddToggle("DemoToggle", {
	Title = "Switch",
	Description = "Shortcut = \"G\": press G anywhere to flip it.",
	Default = false,
	Shortcut = "G",
	Tooltip = "Right-click the row to change or remove the shortcut.",
	Callback = function(on)
		print("[Demo] switch:", on)
	end,
})
Switches:AddCheckbox("DemoCheckbox", { Title = "Checkbox", Description = "AddCheckbox(idx, info)", Default = true })
Switches:AddToggle("DemoCheckStyle", { Title = "Checkbox style", Description = "AddToggle with Style = \"Checkbox\".", Style = "Checkbox", Default = false })

local Numbers = Tabs.Controls:AddSection({ Title = "Numbers", Description = "AddSlider and AddStepper.", Icon = "hash" })
Numbers:AddSlider("DemoSlider", {
	Title = "Slider",
	Description = "Drag, or click the value to type one.",
	Min = 0,
	Max = 100,
	Default = 50,
	Suffix = "%",
	Callback = function(value)
		print("[Demo] slider:", value)
	end,
})
Numbers:AddSlider("DemoDecimals", { Title = "Decimals", Description = "Rounding = 2", Min = 0, Max = 1, Default = 0.25, Rounding = 2 })
Numbers:AddSlider("DemoFinished", {
	Title = "Fires on release",
	Description = "Finished = true: one callback per drag.",
	Min = 0,
	Max = 500,
	Default = 100,
	Increment = 25,
	Finished = true,
	Callback = function(value)
		Window:Toast("Released at", { Detail = tostring(value) })
	end,
})
Numbers:AddStepper("DemoStepper", {
	Title = "Stepper",
	Description = "Hold − or + to repeat, or type a number.",
	Min = 0,
	Max = 20,
	Step = 1,
	Default = 5,
	Suffix = " items",
})

local fruits = {
	"Apple", "Apricot", "Banana", "Blackberry", "Blueberry", "Cherry", "Coconut", "Date",
	"Dragon fruit", "Fig", "Grape", "Guava", "Kiwi", "Lemon", "Lime", "Lychee", "Mango",
	"Melon", "Orange", "Papaya", "Peach", "Pear", "Pineapple", "Plum", "Raspberry", "Strawberry",
}
local Choices = Tabs.Controls:AddSection({ Title = "Choices", Description = "AddDropdown, AddRadio and AddSegmented.", Icon = "list" })
Choices:AddDropdown("DemoDropdown", { Title = "Dropdown", Values = { "Alpha", "Beta", "Gamma" }, Default = "Alpha" })
Choices:AddDropdown("DemoMulti", {
	Title = "Multi-select",
	Description = "Multi = true. Right-click to select or clear all.",
	Values = { "Red", "Green", "Blue", "Yellow" },
	Multi = true,
	Default = { "Red", "Blue" },
})
Choices:AddDropdown("DemoSearchable", {
	Title = "Searchable",
	Description = "Searchable = true adds a filter field.",
	Values = fruits,
	Searchable = true,
	AllowNull = true,
})
Choices:AddRadio("DemoRadio", { Title = "Radio group", Values = { "Small", "Medium", "Large" }, Default = "Medium" })
Choices:AddSegmented("DemoSegmented", { Title = "Segmented", Values = { "Day", "Week", "Month" }, Default = "Week" })

local TextKeys = Tabs.Controls:AddSection({ Title = "Text & keys", Description = "AddInput and AddKeybind.", Icon = "keyboard" })
TextKeys:AddInput("DemoInput", {
	Title = "Text field",
	Description = "Finished = true: fires when you press Enter.",
	Placeholder = "Type something",
	Finished = true,
	Callback = function(text)
		if text ~= "" then
			Window:Toast("You typed", { Detail = text })
		end
	end,
})
TextKeys:AddInput("DemoNumber", { Title = "Numbers only", Description = "Numeric = true, MaxLength = 4", Numeric = true, MaxLength = 4, Placeholder = "0–9999", Width = 110 })
TextKeys:AddKeybind("DemoKeyToggle", {
	Title = "Keybind (Toggle)",
	Description = "Each press flips it on or off.",
	Default = "F",
	Mode = "Toggle",
	Callback = function(active)
		Window:Toast("Keybind F", { Detail = active and "On" or "Off", Highlight = active })
	end,
	ChangedCallback = function(key)
		print("[Demo] toggle keybind changed to", key)
	end,
})
TextKeys:AddKeybind("DemoKeyHold", { Title = "Keybind (Hold)", Description = "Active while held; mouse buttons work too.", Default = "MB2", Mode = "Hold" })
TextKeys:AddKeybind("DemoKeyAlways", { Title = "Keybind (Always)", Description = "Always active; the key is just stored.", Default = "V", Mode = "Always" })

local Colours = Tabs.Controls:AddSection({ Title = "Colour", Description = "AddColorpicker", Icon = "pipette" })
Colours:AddColorpicker("DemoColor", { Title = "With opacity", Description = "Transparency adds an opacity slider.", Default = rgb(10, 132, 255), Transparency = 0.25 })
Colours:AddColorpicker("DemoColorSolid", { Title = "Solid", Default = rgb(255, 159, 10) })

--------------------------------------------------------------------------------
-- Display
--------------------------------------------------------------------------------

local Readouts = Tabs.Display:AddSection({ Title = "Read-only rows", Icon = "eye" })
local Status = Readouts:AddLabel("DemoStatus", { Title = "Label", Description = "AddLabel, SetValue and SetValueColor.", Value = "Online" })
Status:SetValueColor("Green") -- accent name, hex or Color3
Readouts:AddParagraph({
	Title = "Paragraph",
	Content = "Longer text wraps automatically and supports <b>bold</b>, <i>italic</i> and <font color=\"#0A84FF\">colour</font>.",
})
local Loading = Readouts:AddProgress({ Title = "Progress", Description = "AddProgress and SetValue.", Max = 100, Default = 0 })
task.spawn(function()
	while not MacUI.Unloaded do
		Loading:SetValue((Loading.Value + 1) % 101)
		task.wait(0.08)
	end
end)
Readouts:AddCode("DemoCode", {
	Title = "Code block",
	Description = "AddCode and SetCode; the button copies it.",
	Code = 'print("Hello from MacUI")',
})
local Avatar = Readouts:AddImage("DemoImage", {
	Title = "Image",
	Description = "AddImage, SetImage and SetHeight.",
	Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420",
	Height = 140,
	ScaleType = "Fit",
})
local fullBody = false
Readouts:AddButton({
	Title = "SetImage and SetHeight",
	Description = "Switches between your headshot and full avatar.",
	ButtonText = "Switch",
	Callback = function()
		fullBody = not fullBody
		Avatar:SetImage(("rbxthumb://type=%s&id=%d&w=420&h=420"):format(fullBody and "Avatar" or "AvatarHeadShot", LocalPlayer.UserId))
		Avatar:SetHeight(fullBody and 220 or 140)
	end,
})

local ButtonsSection = Tabs.Display:AddSection({ Title = "Buttons", Description = "AddButton in every style.", Icon = "mouse-pointer-2" })
ButtonsSection:AddButton({
	Title = "Chevron row",
	Description = "No ButtonText: the whole row is the button.",
	Callback = function()
		Window:Toast("Chevron row clicked")
	end,
})
ButtonsSection:AddButton({
	Title = "Custom icon",
	Description = "Icon replaces the chevron.",
	Icon = "external-link",
	Callback = function()
		Window:Toast("Custom icon clicked", { Icon = "external-link" })
	end,
})
ButtonsSection:AddButton({
	Title = "Push button",
	ButtonText = "Default",
	Callback = function()
		Window:Toast("Default button")
	end,
})
ButtonsSection:AddButton({
	Title = "Primary",
	ButtonText = "Continue",
	Style = "Primary",
	Callback = function()
		Window:Toast("Primary button", { Highlight = true })
	end,
})
ButtonsSection:AddButton({
	Title = "Destructive",
	ButtonText = "Delete",
	Style = "Destructive",
	Callback = function()
		Window:Dialog({
			Title = "Delete everything?",
			Content = "This is only a demo, so nothing is deleted.",
			Icon = "trash-2",
			IconColor = "Red",
			Buttons = {
				{ Title = "Delete", Style = "Destructive", Callback = function()
					Window:Toast("Deleted (not really)", { Icon = "trash-2" })
				end },
				{ Title = "Cancel" },
			},
		})
	end,
})
-- An index (or Flag) registers the button in Options, so SaveManager keeps its shortcut.
ButtonsSection:AddButton("DemoSavedButton", {
	Title = "Saved shortcut",
	Description = "Index + Shortcut = \"B\": press B to run it.",
	ButtonText = "Run",
	Shortcut = "B",
	Callback = function()
		Window:Toast("Button ran", { Detail = "B", Icon = "play" })
	end,
})
ButtonsSection:AddButton("Fluent style", function()
	Window:Toast("AddButton(title, callback) works too")
end)

--------------------------------------------------------------------------------
-- Methods
--------------------------------------------------------------------------------

local Targets = Tabs.Methods:AddSection({ Title = "Targets", Description = "The buttons below call methods on these rows.", Icon = "crosshair" })
local DemoToggle = Targets:AddToggle("PlayToggle", { Title = "Demo toggle", Default = false })
local DemoSlider = Targets:AddSlider("PlaySlider", { Title = "Demo slider", Min = 0, Max = 100, Default = 40 })
local DemoDropdown = Targets:AddDropdown("PlayDropdown", { Title = "Demo dropdown", Values = { "One", "Two", "Three" }, Default = "One" })

DemoToggle:OnChanged(function(value)
	print("[Demo] OnChanged:", value)
end)

local Values = Tabs.Methods:AddSection({ Title = "Values", Icon = "hash" })
Values:AddButton({
	Title = "SetValue",
	Description = "toggle true, slider 80, dropdown \"Three\"",
	ButtonText = "Set",
	Callback = function()
		DemoToggle:SetValue(true)
		DemoSlider:SetValue(80)
		DemoDropdown:SetValue("Three")
	end,
})
Values:AddButton({
	Title = "Reset",
	Description = "element:Reset() goes back to its Default.",
	ButtonText = "Reset",
	Callback = function()
		DemoToggle:Reset()
		DemoSlider:Reset()
		DemoDropdown:Reset()
	end,
})
Values:AddButton({
	Title = "IsDefault and GetText",
	Description = "Reads a row without changing it.",
	ButtonText = "Read",
	Callback = function()
		Window:Toast("Slider " .. DemoSlider:GetText(), { Detail = DemoSlider:IsDefault() and "default" or "changed" })
	end,
})
Values:AddButton({
	Title = "SetValues",
	Description = "Replaces the dropdown's list.",
	ButtonText = "Replace",
	Callback = function()
		DemoDropdown:SetValues({ "Red", "Green", "Blue" })
		DemoDropdown:SetValue("Green")
	end,
})
Values:AddButton({
	Title = "SetMin and SetMax",
	Description = "Widens the slider to 0–200.",
	ButtonText = "Widen",
	Callback = function()
		DemoSlider:SetMin(0)
		DemoSlider:SetMax(200)
	end,
})
Values:AddButton({
	Title = "Open",
	Description = "Opens the dropdown's menu from code.",
	ButtonText = "Open",
	Callback = function()
		Window:Reveal(DemoDropdown)
		task.delay(0.6, function()
			DemoDropdown:Open()
		end)
	end,
})

local State = Tabs.Methods:AddSection({ Title = "Text and state", Icon = "pencil" })
State:AddButton({
	Title = "SetTitle and SetDesc",
	ButtonText = "Rename",
	Callback = function()
		DemoToggle:SetTitle("Renamed toggle")
		DemoToggle:SetDesc("SetDesc added this line.")
	end,
})
local sliderLocked = false
State:AddButton({
	Title = "Lock and Unlock",
	Description = "Greys out the slider. SetDisabled(true) does the same.",
	ButtonText = "Lock",
	Callback = function()
		sliderLocked = not sliderLocked
		if sliderLocked then
			DemoSlider:Lock()
		else
			DemoSlider:Unlock()
		end
	end,
})
local dropdownHidden = false
State:AddButton({
	Title = "SetVisible",
	Description = "Hides or shows the dropdown row.",
	ButtonText = "Hide / show",
	Callback = function()
		dropdownHidden = not dropdownHidden
		DemoDropdown:SetVisible(not dropdownHidden)
	end,
})
State:AddButton({
	Title = "Section:SetTitle",
	Description = "Sections can be renamed too.",
	ButtonText = "Rename",
	Callback = function()
		Targets:SetTitle("Renamed section")
		Targets:SetDesc("Changed with SetTitle and SetDesc.")
	end,
})

local Events = Tabs.Methods:AddSection({ Title = "Events and shortcuts", Icon = "activity" })
Events:AddButton({
	Title = "SetShortcut",
	Description = "Press H afterwards to flip the demo toggle.",
	ButtonText = "Bind H",
	Callback = function()
		DemoToggle:SetShortcut("H")
	end,
})
Events:AddButton({
	Title = "RecordShortcut",
	Description = "Waits for the next key you press.",
	ButtonText = "Record",
	Callback = function()
		DemoToggle:RecordShortcut()
	end,
})
Events:AddButton({
	Title = "Remove shortcut",
	Description = "SetShortcut(nil)",
	ButtonText = "Remove",
	Callback = function()
		DemoToggle:SetShortcut(nil)
	end,
})
local DemoKey = Events:AddKeybind("PlayKey", { Title = "Keybind events", Description = "OnClick fires on every press of J.", Default = "J", Mode = "Toggle" })
DemoKey:OnClick(function(active)
	Window:Toast("Keybind J", { Detail = active and "active" or "inactive", Highlight = active })
end)
Events:AddButton({
	Title = "GetState and DoClick",
	Description = "Reads the keybind, then clicks it from code.",
	ButtonText = "Click",
	Callback = function()
		print("[Demo] keybind state:", DemoKey:GetState())
		DemoKey:DoClick()
	end,
})
local Target = Events:AddButton({ Title = "SetCallback", Description = "This button's callback was replaced after creation.", ButtonText = "Run" })
Target:SetCallback(function()
	Window:Toast("New callback ran")
end)
Events:AddButton({
	Title = "Fire",
	Description = "Runs the button above from code.",
	ButtonText = "Fire",
	Callback = function()
		Target:Fire()
	end,
})

local Lifecycle = Tabs.Methods:AddSection({ Title = "Create and destroy", Icon = "plus-circle" })
local temporary
Lifecycle:AddButton({
	Title = "Add a row",
	Description = "Elements can be added at any time.",
	ButtonText = "Add",
	Callback = function()
		if not temporary then
			temporary = Lifecycle:AddToggle("TempToggle", { Title = "Temporary row", Description = "Made just now." })
		end
	end,
})
Lifecycle:AddButton({
	Title = "Destroy it",
	Description = "element:Destroy()",
	ButtonText = "Destroy",
	Callback = function()
		if temporary then
			temporary:Destroy()
			temporary = nil
		end
	end,
})

--------------------------------------------------------------------------------
-- Smart rows
--------------------------------------------------------------------------------

local Deps = Tabs.Smart:AddSection({ Title = "Dependencies", Description = "DependsOn disables (or hides) rows until a condition is true.", Icon = "git-branch" })
Deps:AddToggle("DemoEsp", { Title = "Highlights", Description = "Turn this on to unlock the rows below.", Default = false })
Deps:AddColorpicker("DemoEspColor", { Title = "Colour", Description = "DependsOn = \"DemoEsp\"", Default = rgb(48, 209, 88), DependsOn = "DemoEsp" })
Deps:AddSlider("DemoEspRange", {
	Title = "Range",
	Description = "DependsMode = \"Hide\" hides the row instead.",
	Min = 50,
	Max = 1000,
	Default = 300,
	Increment = 50,
	Suffix = " studs",
	DependsOn = "DemoEsp",
	DependsMode = "Hide",
})
Deps:AddSegmented("DemoEspMode", { Title = "Mode", Values = { "Simple", "Advanced" }, Default = "Simple", DependsOn = "DemoEsp" })
Deps:AddStepper("DemoEspLayers", {
	Title = "Layers",
	Description = "DependsOn = { \"DemoEspMode\", \"Advanced\" }",
	Min = 1,
	Max = 5,
	Default = 2,
	DependsOn = { "DemoEspMode", "Advanced" },
})
Deps:AddInput("DemoEspNote", {
	Title = "Note",
	Description = "DependsOn can be a function: range of 500 or more.",
	Placeholder = "Only for long range",
	DependsOn = function()
		return Options.DemoEsp.Value and Options.DemoEspRange.Value >= 500
	end,
})

local Findable = Tabs.Smart:AddSection({ Title = "Search and tooltips", Icon = "search" })
Findable:AddToggle("DemoKeywords", {
	Title = "See through walls",
	Description = "Keywords make it findable as \"xray\".",
	Keywords = "esp wallhack xray",
	Tooltip = "Tooltips can be any text.",
	Default = false,
})
Findable:AddButton({
	Title = "Search for it",
	Description = "Window:Search(\"xray\")",
	ButtonText = "Search",
	Callback = function()
		Window:Search("xray")
	end,
})
Findable:AddButton({
	Title = "Clear the search",
	Description = "Window:Search(\"\")",
	ButtonText = "Clear",
	Callback = function()
		Window:Search("")
	end,
})
Findable:AddLabel({
	Title = "Live tooltip",
	Description = "Tooltip can be a function; hover this row.",
	Value = "Hover me",
	Tooltip = function()
		return "Opened at " .. os.date("%H:%M:%S")
	end,
})

local Live = Tabs.Smart:AddSection({ Title = "Live lists", Description = "Values = \"Players\" or \"Teams\" stays in sync with the server.", Icon = "users" })
Live:AddDropdown("DemoPlayer", { Title = "Player", Values = "Players", Searchable = true })
Live:AddDropdown("DemoPlayers", { Title = "Several players", Description = "ExcludeLocal = false includes you.", Values = "Players", ExcludeLocal = false, Multi = true })
Live:AddDropdown("DemoTeam", { Title = "Team", Values = "Teams" })
Live:AddButton({
	Title = "Use the selected player",
	Description = "Enabled once a player is picked.",
	ButtonText = "Go",
	Style = "Primary",
	DependsOn = "DemoPlayer",
	Callback = function()
		Window:Toast("Selected", { Detail = tostring(Options.DemoPlayer.Value), Icon = "user" })
	end,
})

--------------------------------------------------------------------------------
-- Advanced
--------------------------------------------------------------------------------

local LiveData = Tabs.Advanced:AddSection({ Title = "Live data", Description = "AddGraph and AddTable.", Icon = "activity" })
local FpsGraph = LiveData:AddGraph("DemoFpsGraph", {
	Title = "Frame rate",
	Description = "Graph:Push(value) twice a second.",
	Points = 40,
	Suffix = " fps",
})
local frames, elapsed = 0, 0
local heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
	frames += 1
	elapsed += dt
	if elapsed >= 0.5 then
		FpsGraph:Push(frames / elapsed)
		frames, elapsed = 0, 0
	end
end)

local PlayerTable = LiveData:AddTable("DemoPlayerTable", {
	Title = "Players",
	Description = "Click a header to sort, click a row to select it.",
	Columns = { { Title = "Name", Width = 2 }, { Title = "Account age", Align = "Right" }, "Team" },
	MaxRows = 6,
	SortBy = "Name",
	Callback = function(row)
		if row then
			Window:Toast("Selected", { Detail = tostring(row[1]), Icon = "user" })
		end
	end,
})
local function RefreshPlayers()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(rows, { player.DisplayName, player.AccountAge, player.Team and player.Team.Name or "—" })
	end
	PlayerTable:SetRows(rows)
end
RefreshPlayers()
local joined = Players.PlayerAdded:Connect(RefreshPlayers)
local left = Players.PlayerRemoving:Connect(function()
	task.defer(RefreshPlayers)
end)
MacUI:OnUnload(function()
	heartbeat:Disconnect()
	joined:Disconnect()
	left:Disconnect()
end)

local Folded = Tabs.Advanced:AddSection({
	Title = "Collapsible section",
	Description = "Collapsible = true, Collapsed = true. Click the title to open it.",
	Icon = "list",
	Collapsible = true,
	Collapsed = true,
})
Folded:AddToggle("DemoFoldedToggle", { Title = "Rarely used option", Default = false })
Folded:AddSlider("DemoFoldedSlider", { Title = "Another one", Min = 0, Max = 10, Default = 3 })
Folded:AddButton({
	Title = "Section:SetCollapsed",
	Description = "Folds this section from code.",
	ButtonText = "Fold",
	Callback = function()
		Folded:SetCollapsed(true)
	end,
})

local Changes = Tabs.Advanced:AddSection({
	Title = "Undo and redo",
	Description = "Ctrl + Z undoes a change you made; Ctrl + Shift + Z or Ctrl + Y redoes it.",
	Icon = "undo-2",
})
Changes:AddButton({
	Title = "MacUI:Undo",
	Description = "Same as Ctrl + Z. Change something first.",
	ButtonText = "Undo",
	Callback = function()
		if not MacUI:Undo() then
			Window:Toast("Nothing to undo")
		end
	end,
})
Changes:AddButton({
	Title = "MacUI:Redo",
	ButtonText = "Redo",
	Callback = function()
		if not MacUI:Redo() then
			Window:Toast("Nothing to redo")
		end
	end,
})
Changes:AddButton({
	Title = "MacUI:ClearHistory",
	ButtonText = "Clear",
	Callback = function()
		MacUI:ClearHistory()
		Window:Toast("History cleared")
	end,
})

-- Commands live in Spotlight (Ctrl + K); a Shortcut runs them from anywhere.
Window:AddCommand({
	Title = "Copy server ID",
	Description = "Copies this server's JobId.",
	Icon = "copy",
	IconColor = "Blue",
	Keywords = "jobid server",
	Callback = function()
		MacUI:SetClipboard(game.JobId)
	end,
})
Window:AddCommand({
	Title = "Reset character",
	Description = "Respawns you, like the Roblox menu's Reset.",
	Icon = "rotate-ccw",
	IconColor = "Orange",
	Keywords = "respawn",
	Shortcut = "F6",
	Callback = function()
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end,
})
Window:AddCommand({
	Title = "Rejoin server",
	Description = "Teleports you back into this game.",
	Icon = "refresh-cw",
	IconColor = "Green",
	Keywords = "reconnect",
	Callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
	end,
})
local CommandSection = Tabs.Advanced:AddSection({
	Title = "Spotlight commands",
	Description = "Window:AddCommand adds actions to Spotlight: three are added here.",
	Icon = "command",
})
CommandSection:AddButton({
	Title = "See them in Spotlight",
	Description = "“Reset character” also runs with F6.",
	ButtonText = "Open",
	Callback = function()
		Window:OpenSpotlight()
	end,
})

local Overlay = Tabs.Advanced:AddSection({ Title = "Watermark", Description = "MacUI:SetWatermark: a floating status pill you can drag.", Icon = "monitor" })
local positions = { "TopLeft", "TopCenter", "TopRight", "BottomLeft", "BottomCenter", "BottomRight" }
local function ShowWatermark()
	if Options.DemoWatermark and Options.DemoWatermark.Value then
		MacUI:SetWatermark({
			Text = "MacUI Demo",
			Icon = "command",
			Clock = true,
			Position = Options.DemoWatermarkPosition and Options.DemoWatermarkPosition.Value or "TopCenter",
		})
	else
		MacUI:SetWatermark(false)
	end
end
Overlay:AddToggle("DemoWatermark", { Title = "Show watermark", Description = "Name, FPS, ping and the time.", Default = true, Callback = ShowWatermark })
Overlay:AddDropdown("DemoWatermarkPosition", { Title = "Position", Values = positions, Default = "TopCenter", DependsOn = "DemoWatermark", Callback = ShowWatermark })

local LoadingSection = Tabs.Advanced:AddSection({
	Title = "Loading screen",
	Description = "CreateWindow({ Loading = true }) or MacUI:ShowLoading().",
	Icon = "timer",
})
LoadingSection:AddButton({
	Title = "MacUI:ShowLoading",
	Description = "A fake three-step load with SetProgress and Finish.",
	ButtonText = "Show",
	Callback = function()
		local loader = MacUI:ShowLoading({ Title = "Updating", Subtitle = "Starting…", Icon = "download", IconColor = "Green" })
		task.spawn(function()
			for step, text in ipairs({ "Fetching data…", "Applying settings…", "Almost done…" }) do
				task.wait(0.8)
				loader:SetProgress(step / 3, text)
			end
			task.wait(0.4)
			loader:Finish("Done")
		end)
	end,
})

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local TitleBar = Tabs.Window:AddSection({ Title = "Title bar", Icon = "app-window" })
TitleBar:AddInput("DemoTitle", {
	Title = "Window:SetTitle",
	Default = Window.Title,
	Finished = true,
	Callback = function(text)
		if text ~= "" and text ~= Window.Title then
			Window:SetTitle(text)
		end
	end,
})
TitleBar:AddInput("DemoSubtitle", {
	Title = "Window:SetSubtitle",
	Default = Window.SubTitle,
	Finished = true,
	Callback = function(text)
		if text ~= Window.SubTitle then
			Window:SetSubtitle(text)
		end
	end,
})

local Layout = Tabs.Window:AddSection({ Title = "Layout", Icon = "layout-grid" })
Layout:AddButton({
	Title = "Window:Minimize",
	Description = "Shrinks to the dock, then Window:Restore() after 2 seconds.",
	ButtonText = "Minimize",
	Callback = function()
		Window:Minimize()
		task.delay(2, function()
			Window:Restore()
		end)
	end,
})
Layout:AddButton({
	Title = "Window:Toggle",
	Description = "Same as the Right Ctrl key; comes back after 2 seconds.",
	ButtonText = "Toggle",
	Callback = function()
		Window:Toggle()
		task.delay(2, function()
			if Window.Minimized then
				Window:Toggle()
			end
		end)
	end,
})
Layout:AddButton({
	Title = "Window:SetMaximized",
	Description = "Zoom in and out, like the green button.",
	ButtonText = "Zoom",
	Callback = function()
		Window:SetMaximized(not Window.Maximized)
	end,
})
Layout:AddButton({
	Title = "Window:ToggleSidebar",
	Description = "Or Window:SetSidebarVisible(bool).",
	ButtonText = "Sidebar",
	Callback = function()
		Window:ToggleSidebar()
	end,
})
Layout:AddButton({
	Title = "Window:SetScale",
	Description = "Shrinks to 85% for 2 seconds.",
	ButtonText = "Scale",
	Callback = function()
		local before = Window.Scale
		Window:SetScale(before * 0.85)
		task.delay(2, function()
			Window:SetScale(before)
		end)
	end,
})

local tabTitles = {}
for _, tab in ipairs(Window.Tabs) do
	table.insert(tabTitles, tab.Title)
end
local Navigation = Tabs.Window:AddSection({ Title = "Navigation", Icon = "compass" })
Navigation:AddDropdown("DemoGoTo", {
	Title = "Window:SelectTab",
	Values = tabTitles,
	AllowNull = true,
	Callback = function(title)
		local index = title and table.find(tabTitles, title)
		if index then
			Window:SelectTab(index)
		end
	end,
})
Navigation:AddButton({
	Title = "Window:GoBack",
	ButtonText = "Back",
	Callback = function()
		Window:GoBack()
	end,
})
Navigation:AddButton({
	Title = "Window:GoForward",
	ButtonText = "Forward",
	Callback = function()
		Window:GoForward()
	end,
})
Navigation:AddButton({
	Title = "Window:Reveal",
	Description = "Jumps to the stepper on the Controls page.",
	ButtonText = "Reveal",
	Callback = function()
		Window:Reveal("DemoStepper")
	end,
})
Navigation:AddButton({
	Title = "Tab:Select",
	Description = "Tabs.About:Select()",
	ButtonText = "About",
	Callback = function()
		Tabs.About:Select()
	end,
})

local Saved = Tabs.Window:AddSection({ Title = "State", Icon = "save" })
local StateCode = Saved:AddCode({ Title = "Window:GetState()", Description = "Updates live from Window.StateChanged.", Code = "" })
local function ShowState(state)
	StateCode:SetCode(("{ X = %.0f, Y = %.0f, Width = %.0f, Height = %.0f, Tab = %q, Sidebar = %s }"):format(
		state.X,
		state.Y,
		state.Width,
		state.Height,
		tostring(state.Tab),
		tostring(state.Sidebar)
	))
end
ShowState(Window:GetState())
Window.StateChanged:Connect(ShowState)
Saved:AddButton({
	Title = "Window:ApplyState",
	Description = "Moves the window back to the middle of the screen.",
	ButtonText = "Centre",
	Callback = function()
		Window:ApplyState({ X = 0, Y = 0 })
	end,
})

local Extras = Tabs.Window:AddSection({ Title = "Extras", Icon = "sparkles" })
Extras:AddButton({
	Title = "Window:SetAcrylic",
	Description = "Frosted sidebar; needs graphics quality 8 or higher.",
	ButtonText = "Frost",
	Callback = function()
		local on = Window:SetAcrylic(not Window.Acrylic)
		Window:Toast("Frosted glass", { Detail = on and "On" or "Off", Highlight = on })
	end,
})
Extras:AddButton({
	Title = "Window:SetKeybindList",
	Description = "A floating list of every keybind and shortcut.",
	ButtonText = "Show / hide",
	Callback = function()
		Window:SetKeybindList(not Window.KeybindListVisible)
	end,
})
Extras:AddStepper("DemoBadge", {
	Title = "Tab:SetBadge",
	Description = "The number next to Alerts in the sidebar (0 hides it).",
	Min = 0,
	Max = 99,
	Default = 3,
	Callback = function(count)
		Tabs.Alerts:SetBadge(count)
	end,
})
Extras:AddInput("DemoTabName", {
	Title = "Tab:SetTitle",
	Description = "Renames the Alerts tab.",
	Default = "Alerts",
	Finished = true,
	Callback = function(text)
		if text ~= "" then
			Tabs.Alerts:SetTitle(text)
		end
	end,
})

--------------------------------------------------------------------------------
-- Alerts
--------------------------------------------------------------------------------

local Notifications = Tabs.Alerts:AddSection({ Title = "Notifications", Description = "MacUI:Notify: banners in the top-right corner.", Icon = "bell" })
Notifications:AddButton({
	Title = "Simple",
	ButtonText = "Show",
	Callback = function()
		MacUI:Notify({ Title = "Hello", Content = "A simple notification.", Duration = 4 })
	end,
})
Notifications:AddButton({
	Title = "Subtitle and colour",
	ButtonText = "Show",
	Callback = function()
		MacUI:Notify({
			Title = "Download finished",
			SubContent = "Map pack",
			Content = "Everything is ready to use.",
			Icon = "download",
			IconColor = "Green",
		})
	end,
})
Notifications:AddButton({
	Title = "With actions",
	ButtonText = "Show",
	Callback = function()
		MacUI:Notify({
			Title = "Friend request",
			Content = "Builderman wants to be friends.",
			Icon = "user-plus",
			IconColor = "Purple",
			Duration = 10,
			Buttons = {
				{ Title = "Accept", Callback = function()
					Window:Toast("Accepted", { Icon = "check-circle", Highlight = true })
				end },
				{ Title = "Ignore" },
			},
		})
	end,
})
Notifications:AddButton({
	Title = "Closed from code",
	Description = "Duration = 0 keeps it up; banner:Close() removes it after 3 seconds.",
	ButtonText = "Show",
	Callback = function()
		local banner = MacUI:Notify({ Title = "Sticky", Content = "This one stays until closed.", Icon = "pin", Duration = 0 })
		task.delay(3, function()
			if banner then
				banner:Close()
			end
		end)
	end,
})

local Toasts = Tabs.Alerts:AddSection({ Title = "Toasts", Description = "Window:Toast: a short message at the bottom of the window.", Icon = "message-square" })
Toasts:AddButton({
	Title = "Plain",
	ButtonText = "Show",
	Callback = function()
		Window:Toast("Copied")
	end,
})
Toasts:AddButton({
	Title = "Detail and highlight",
	ButtonText = "Show",
	Callback = function()
		Window:Toast("Auto Farm", { Detail = "On", Icon = "check-circle", Highlight = true })
	end,
})
Toasts:AddButton({
	Title = "Longer duration",
	ButtonText = "Show",
	Callback = function()
		Window:Toast("Teleported to Spawn", { Icon = "map-pin", Duration = 3 })
	end,
})

local Dialogs = Tabs.Alerts:AddSection({ Title = "Dialogs", Description = "Window:Dialog: sheets that dim the window.", Icon = "square" })
Dialogs:AddButton({
	Title = "Two buttons",
	Description = "The first button is the primary action.",
	ButtonText = "Show",
	Callback = function()
		Window:Dialog({
			Title = "Reset statistics?",
			Content = "Your session counters go back to zero.",
			Icon = "rotate-ccw",
			Buttons = {
				{ Title = "Reset", Callback = function()
					Window:Toast("Reset")
				end },
				{ Title = "Cancel" },
			},
		})
	end,
})
Dialogs:AddButton({
	Title = "Three buttons",
	Description = "More than two stack vertically.",
	ButtonText = "Show",
	Callback = function()
		Window:Dialog({
			Title = "Save changes?",
			Content = "You have unsaved changes.",
			Icon = "save",
			Buttons = {
				{ Title = "Save", Callback = function()
					Window:Toast("Saved")
				end },
				{ Title = "Don’t Save", Style = "Destructive" },
				{ Title = "Cancel" },
			},
		})
	end,
})
Dialogs:AddButton({
	Title = "Text field",
	Description = "Input = { Placeholder, Default }; the text goes to the callback.",
	ButtonText = "Show",
	Callback = function()
		Window:Dialog({
			Title = "What's your name?",
			Content = "Press Enter or click Done.",
			Icon = "pencil",
			Input = { Placeholder = "Name", Default = LocalPlayer.DisplayName },
			Buttons = {
				{ Title = "Done", Callback = function(text)
					Window:Toast("Hello, " .. tostring(text) .. "!", { Icon = "user" })
				end },
				{ Title = "Cancel" },
			},
		})
	end,
})
Dialogs:AddButton({
	Title = "Closed from code",
	Description = "dialog:Close() after 2 seconds.",
	ButtonText = "Show",
	Callback = function()
		local dialog = Window:Dialog({ Title = "Closing soon", Content = "This dialog closes itself.", Icon = "timer", Buttons = { { Title = "OK" } } })
		task.delay(2, function()
			dialog:Close()
		end)
	end,
})

--------------------------------------------------------------------------------
-- Appearance
--------------------------------------------------------------------------------

-- ThemeManager first, so themes saved with its editor are in the lists below.
ThemeManager:SetLibrary(MacUI)
ThemeManager:SetFolder("MacUI/Demo")
ThemeManager:LoadCustomThemes()

-- Theme, accent, frosted glass, size, reduce motion, shortcut list,
-- remember window, show/hide key and unload, all remembered between sessions.
InterfaceManager:SetLibrary(MacUI)
InterfaceManager:SetFolder("MacUI/Demo")
InterfaceManager:BuildInterfaceSection(Tabs.Appearance)

local Styling = Tabs.Appearance:AddSection({ Title = "More styling", Description = "Library-level calls.", Icon = "brush" })
Styling:AddDropdown("DemoFont", {
	Title = "MacUI:SetFont",
	Description = "Any font family name, rbxasset path or Enum.Font.",
	Values = { "BuilderSans", "GothamSSm", "Montserrat", "SourceSansPro", "Nunito" },
	Default = "BuilderSans",
	Callback = function(font)
		if font then
			MacUI:SetFont(font)
		end
	end,
})

-- AccentManager: a colour well that accepts any accent colour.
AccentManager:SetLibrary(MacUI)
AccentManager:BuildAccentPicker(Styling)

-- ThemeManager: apply themes by name, or design new ones in the editor.
Styling:AddButton({
	Title = "ThemeManager:ApplyTheme",
	Description = "Cycles through every theme, including Ocean and Rose from MacUI:AddTheme.",
	ButtonText = "Next theme",
	Callback = function()
		local themes = ThemeManager:GetThemes()
		local index = table.find(themes, MacUI.ThemeName) or 0
		ThemeManager:ApplyTheme(themes[index % #themes + 1])
	end,
})
ThemeManager:BuildThemeEditor(Tabs.Appearance) -- collapsed; click its title
MacUI.ThemeChanged:Connect(function(name)
	Window:Toast("Theme", { Detail = name, Icon = "palette" })
end)

--------------------------------------------------------------------------------
-- Profiles
--------------------------------------------------------------------------------

SaveManager:SetLibrary(MacUI)
SaveManager:SetFolder("MacUI/Demo/" .. tostring(game.PlaceId))
SaveManager:IgnoreThemeSettings()
-- rows that drive the window aren't settings
SaveManager:SetIgnoreIndexes({ "DemoTitle", "DemoSubtitle", "DemoGoTo", "DemoBadge", "DemoTabName", "DemoFont" })
SaveManager:BuildConfigSection(Tabs.Profiles)

--------------------------------------------------------------------------------
-- About
--------------------------------------------------------------------------------

local Info = Tabs.About:AddSection({ Title = "MacUI", Icon = "info" })
Info:AddLabel({ Title = "Version", Description = "MacUI.Version", Value = MacUI.Version })
Info:AddLabel({ Title = "Themes", Description = "MacUI:GetThemes()", Value = table.concat(MacUI:GetThemes(), ", ") })
Info:AddLabel({ Title = "Options", Description = "Indexed elements in MacUI.Options.", Value = (function()
	local count = 0
	for _ in pairs(Options) do
		count += 1
	end
	return tostring(count)
end)() })
Info:AddLabel({ Title = "MacUI:Round", Description = "MacUI:Round(math.pi, 3)", Value = tostring(MacUI:Round(math.pi, 3)) })
Info:AddImage({ Title = "MacUI:GetIcon", Description = "MacUI:GetIcon(\"rocket\") returns the icon's asset id.", Image = MacUI:GetIcon("rocket"), Height = 72, ScaleType = "Fit" })
Info:AddButton({
	Title = "MacUI:SafeCallback",
	Description = "Runs a function and reports errors instead of breaking.",
	ButtonText = "Try",
	Callback = function()
		MacUI:SafeCallback(function()
			error("this error was caught")
		end)
		Window:Toast("Error caught", { Detail = "see the console", Icon = "shield" })
	end,
})

local Loader = Tabs.About:AddSection({ Title = "Load MacUI", Icon = "code" })
Loader:AddCode({ Title = "Library", Code = 'local MacUI = loadstring(game:HttpGet("' .. BASE .. 'MacUIFramework.lua"))()' })
Loader:AddCode({ Title = "This demo", Code = 'loadstring(game:HttpGet("' .. BASE .. 'Demo_FullHub.lua"))()' })

MacUI:OnUnload(function()
	print("[Demo] MacUI unloaded")
end)

MacUI:Notify({
	Title = "MacUI demo",
	Content = "Press Ctrl + K to search everything and Right Ctrl to hide the window.",
	Icon = "command",
	Duration = 6,
})
SaveManager:LoadAutoloadConfig()
