# 🍎 MacUI

**A macOS System Settings–style interface library for Roblox.**

Traffic lights, a sidebar with colourful icon tiles, grouped inset rows, native-looking switches, pop-up menus, sheets, and Notification Center banners. The API is compatible with [Fluent](https://github.com/dawid-scripts/Fluent).

![MacUI dark](assets/preview-dark.png)

| Light | Colour picker | Alert |
| :---: | :---: | :---: |
| ![light](assets/preview-light.png) | ![picker](assets/preview-colorpicker.png) | ![dialog](assets/preview-dialog.png) |

> These previews were rendered outside Roblox. In game the text uses Builder Sans and the icons come from Roblox assets, so glyphs look slightly different.

---

## Features

- **Real macOS window chrome**: traffic lights with hover glyphs (close asks for confirmation, minimise goes to a dock icon, zoom maximises), a draggable toolbar (double-click to zoom), a resize grip and a soft shadow.
- **Sidebar**: section headers, icon tiles in the System Settings style (or tinted/plain icons), a selection highlight that slides between tabs, badges, an optional avatar and name card, and a collapse button.
- **Toolbar**: back and forward history, title and subtitle, and a live **search** that filters rows across every tab, dims tabs with no matches, and shows a "No Results" state.
- **Grouped rows**: every element sits in a rounded group with inset separators, like macOS.
- **Controls**: switch, checkbox, slider (with an editable value), pop-up menu (single, multi or searchable), text field, shortcut recorder, colour well with an HSV and hex popover, segmented control, progress bar, key/value label, paragraph and push buttons.
- **Themes**: Dark, Light and Midnight, plus the eight macOS accent colours or any `Color3`. Every colour animates when you switch.
- **Notifications** that stack at the top right, and **dialogs** that dim the window.
- **Addons**: SaveManager (profiles and autoload, compatible with Fluent config files), InterfaceManager, ThemeManager and AccentManager.
- Scales automatically on small screens and works with touch.

---

## Quick start

```lua
local MacUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/MacUIFramework.lua"))()

local Window = MacUI:CreateWindow({
    Title = "My Hub",
    SubTitle = "Sonoma Edition",
    Icon = "command",
    Size = UDim2.fromOffset(780, 540),
    Theme = "Dark",
    Accent = "Blue",
    MinimizeKey = Enum.KeyCode.RightControl,
})

local Main = Window:AddTab({ Title = "General", Icon = "layers", Section = "Main" })
local Farm = Main:AddSection({ Title = "Auto Farm", Description = "Automatically defeat enemies.", Icon = "swords" })

Farm:AddToggle("AutoFarm", {
    Title = "Enabled",
    Description = "Farm whenever it is safe.",
    Default = false,
    Callback = function(on) print("Auto farm:", on) end,
})
```

`Example_Main.lua` shows every component in one window.

---

## Window

```lua
local Window = MacUI:CreateWindow({
    Title = "My Hub",               -- toolbar title
    SubTitle = "v1.0",              -- toolbar subtitle
    Icon = "command",               -- Lucide icon name or rbxassetid:// (dock, dialogs)
    IconColor = "Purple",           -- tile colour for that icon (defaults to accent)
    Size = UDim2.fromOffset(780, 540),
    MinSize = Vector2.new(560, 380),
    TabWidth = 214,                 -- sidebar width
    Theme = "Dark",                 -- "Dark" | "Light" | "Midnight"
    Accent = "Blue",                -- accent name, hex string or Color3
    SidebarStyle = "Tile",          -- "Tile" | "Tinted" | "Plain"
    Profile = true,                 -- avatar card; or { Title = "", Subtitle = "", Image = "" }
    MinimizeKey = Enum.KeyCode.RightControl,
    Search = true,                  -- show the toolbar search field
    Resizable = true,
    ConfirmClose = true,            -- ask before the red button unloads the UI
    Scale = nil,                    -- fixed UI scale; nil picks one to fit the screen
})
```

| Method | Description |
| --- | --- |
| `Window:AddTab({ Title, Icon, IconColor, Section, Badge })` | Adds a sidebar tab. `Section` starts a new sidebar heading. |
| `Window:AddTabSection(title)` | Adds a sidebar heading such as "Settings". |
| `Window:SelectTab(indexOrTab)` | Switches tab. |
| `Window:GoBack()` / `Window:GoForward()` | Navigates the tab history. |
| `Window:Dialog({ Title, Content, Icon, Buttons })` | Shows an alert sheet. The first button is the primary action. |
| `Window:Minimize()` / `Window:Restore()` / `Window:Toggle()` | Hides or shows the window, with a dock icon while hidden. |
| `Window:SetMaximized(bool)` | Zoom. |
| `Window:SetSidebarVisible(bool)` / `Window:ToggleSidebar()` | Collapses or expands the sidebar. |
| `Window:SetTitle(text)` / `Window:SetSubtitle(text)` | Updates the toolbar text. |
| `Window:SetScale(number)` | Scales the whole window. |
| `Window:SetMinimizeKey(KeyCode or name)` | Changes the show/hide key. |
| `Window:Search(text)` | Runs the search programmatically. |

Tabs have `Tab:SetBadge(number | text | nil)`, `Tab:SetTitle(text)` and `Tab:Select()`.

## Sections

```lua
local Section = Tab:AddSection({ Title = "Movement", Description = "Applies instantly.", Icon = "person-standing" })
-- or the Fluent form: Tab:AddSection("Movement")
```

Elements added to a section go into its rounded group. Elements added straight to a tab go into a group without a header.

## Elements

Each element takes an optional index as its first argument, just like Fluent. Elements that have an index are stored in `MacUI.Options[index]` and are picked up by SaveManager.

```lua
-- Switch (Style = "Checkbox" or AddCheckbox for a checkbox)
local Toggle = Section:AddToggle("Idx", { Title = "Enabled", Description = "…", Default = false, Callback = function(v) end })

-- Slider
Section:AddSlider("Speed", { Title = "Walk speed", Min = 16, Max = 120, Default = 16, Rounding = 0, Increment = 1, Suffix = "", Callback = function(v) end })

-- Pop-up menu (Multi = true for checkmarks; Searchable = true for a filter field)
Section:AddDropdown("Mode", { Title = "Difficulty", Values = { "Easy", "Hard" }, Default = "Easy", Multi = false, AllowNull = false, Callback = function(v) end })

-- Text field
Section:AddInput("Name", { Title = "Nickname", Placeholder = "…", Default = "", Numeric = false, Finished = true, MaxLength = 20, Width = 180, Callback = function(text) end })

-- Shortcut recorder (Mode: "Toggle" | "Hold" | "Always")
Section:AddKeybind("Key", { Title = "Toggle key", Default = "Q", Mode = "Toggle", Callback = function(active) end, ChangedCallback = function(key) end })

-- Colour well (Transparency adds an opacity slider)
Section:AddColorpicker("Color", { Title = "Fill", Default = Color3.fromRGB(10, 132, 255), Transparency = 0.5, Callback = function(color) end })

-- Segmented control
Section:AddSegmented("Part", { Title = "Target", Values = { "Head", "Torso" }, Default = "Head", Callback = function(v) end })

-- Buttons: a chevron row, or a push button when ButtonText is set (Style: "Primary" | "Destructive")
Section:AddButton({ Title = "Rejoin", Description = "…", ButtonText = "Rejoin", Style = "Primary", Callback = function() end })

-- Read-only rows
local Status = Section:AddLabel("Status", { Title = "Status", Description = "…", Value = "Idle" })  -- Status:SetValue("Fighting")
Section:AddParagraph({ Title = "About", Content = "Longer text, <b>rich text</b> supported." })
local Bar = Section:AddProgress("Quest", { Title = "Quest progress", Max = 25, Default = 0 })         -- Bar:SetValue(10)
```

Every element has `:SetTitle(text)`, `:SetDesc(text)`, `:SetVisible(bool)`, `:SetDisabled(bool)` (also `:Lock()` and `:Unlock()`), `:OnChanged(fn)` and `:Destroy()`. Value elements expose `.Value` and `:SetValue(...)`. Dropdowns and segmented controls also have `:SetValues(list)`, and dropdowns have `:Open()`.

## Notifications & dialogs

```lua
MacUI:Notify({
    Title = "Farm finished",
    SubContent = "Blessed Maiden",   -- optional bold second line
    Content = "Collected 7.5B money.",
    Icon = "bell", IconColor = "Green",
    Duration = 5,                    -- seconds; 0 or false keeps it until clicked
})

Window:Dialog({
    Title = "Reset statistics?",
    Content = "This can’t be undone.",
    Icon = "rotate-ccw",
    Buttons = {
        { Title = "Reset", Callback = function() end },  -- primary
        { Title = "Cancel" },
    },
})
```

## Themes & accents

```lua
MacUI:SetTheme("Light")                     -- "Dark" | "Light" | "Midnight"
MacUI:SetAccent("Purple")                   -- Blue, Purple, Pink, Red, Orange, Yellow, Green, Graphite
MacUI:SetAccent(Color3.fromRGB(255, 0, 128))
MacUI:SetFont("GothamSSm")                  -- any font family name, rbxasset path or Enum.Font
MacUI.ThemeChanged:Connect(function(name) end)
```

To add your own theme, copy an entry in `MacUI.Themes`, change the colours, and pass its name to `SetTheme`.

## Addons

```lua
local SaveManager      = loadstring(game:HttpGet(BASE .. "SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(BASE .. "InterfaceManager.lua"))()

InterfaceManager:SetLibrary(MacUI)
InterfaceManager:SetFolder("MyHub")
InterfaceManager:BuildInterfaceSection(SettingsTab)   -- appearance, accent, size, toggle key, unload

SaveManager:SetLibrary(MacUI)
SaveManager:SetFolder("MyHub/" .. game.PlaceId)
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(SettingsTab)           -- create/load/overwrite profiles + autoload
SaveManager:LoadAutoloadConfig()
```

`ThemeManager` (`BuildThemeSection`, `ApplyTheme`, `SaveDefault`/`LoadDefault`) and `AccentManager` (`ChangeAccent`, `BuildAccentDropdown`, `BuildAccentPicker`) are optional helpers. They also keep the MacUI v3 calls working.

## Coming from Fluent?

Change the loadstring and it should run: `CreateWindow`, `AddTab`, `AddSection`, every `Add*` element, `Options`, `Notify`, `Dialog`, `SaveManager` and `InterfaceManager` behave the same. MacUI adds segmented controls, checkboxes, labels, progress bars, badges, search and sidebar sections.

## Icons

Pass any [Lucide](https://lucide.dev/icons) name (`"settings"`, `"swords"`, `"map-pin"` and so on), a full `rbxassetid://` string or a number. The icon asset ids come from Fluent, so the icon set matches Lucide from around 2023.

---

**Author:** [Kiwzu](https://github.com/Kiwzu) · **Icons:** Lucide (ISC) · **Inspired by:** dawid-scripts' Fluent
