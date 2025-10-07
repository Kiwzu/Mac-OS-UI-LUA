--========================================================
-- 🍎 MacUI V3 Ultra (Sonoma Edition)
-- Example_Main.lua – Full Demo
--========================================================

--// Import main framework and addons

local MacUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/MacUIFramework.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/InterfaceManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/ThemeManager.lua"))()
local AccentManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/AccentManager.lua"))()


--// Connect managers to the main library
SaveManager:SetLibrary(MacUI)
InterfaceManager:SetLibrary(MacUI)
ThemeManager:LinkAccent(function() return AccentManager.CurrentAccent end)

InterfaceManager:SetFolder("MacUI/ExampleHub")
SaveManager:SetFolder("MacUI/ExampleHub/ExampleGame")

------------------------------------------------------------
-- 🪟 Create the main window
------------------------------------------------------------

local Window = MacUI:CreateWindow({
    Title = "🍎 MacUI V3 Ultra " .. MacUI.Version,
    SubTitle = "Sonoma Edition",
    TabWidth = 180,
    Size = UDim2.fromOffset(620, 480),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "apple" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

------------------------------------------------------------
-- 🧩 Main Tab Elements
------------------------------------------------------------

Tabs.Main:AddButton({
    Title = "Show Notification",
    Description = "macOS Toast Preview",
    Callback = function()
        MacUI:Notify({
            Title = "MacUI Framework",
            Content = "This is a native-style macOS notification 🍏",
            Duration = 4
        })
    end
})

local Toggle = Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Default = false,
    Callback = function(state)
        print("[AutoFarm]:", state)
    end
})

local Slider = Tabs.Main:AddSlider("Speed", {
    Title = "Player Speed",
    Description = "Adjust walk speed value",
    Default = 16,
    Min = 10,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        print("[Speed]:", value)
    end
})

local Dropdown = Tabs.Main:AddDropdown("MapSelector", {
    Title = "Select Map",
    Values = { "Forest", "Desert", "Dungeon", "Castle" },
    Multi = false,
    Default = 1,
    Callback = function(val)
        print("[Map Selected]:", val)
    end
})

local ColorPicker = Tabs.Main:AddColorpicker("AccentColor", {
    Title = "Accent Color",
    Description = "Change the global accent",
    Default = Color3.fromRGB(90, 170, 255),
    Callback = function(color)
        AccentManager:ChangeAccent(color)
        MacUI:Notify({
            Title = "Accent Updated",
            Content = "Accent color changed dynamically 🌈",
            Duration = 3
        })
    end
})

Tabs.Main:AddButton({
    Title = "Open Dialog",
    Description = "macOS Style Dialog Box",
    Callback = function()
        Window:Dialog({
            Title = "Exit Confirmation",
            Content = "Do you really want to exit the hub?",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        MacUI:Notify({
                            Title = "Confirmed",
                            Content = "Exit confirmed. Shutting down...",
                            Duration = 3
                        })
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        print("[Dialog] Cancelled")
                    end
                }
            }
        })
    end
})

------------------------------------------------------------
-- ⚙️ Settings Tab
------------------------------------------------------------

AccentManager:BuildAccentDropdown(Tabs.Settings, function(selected)
    MacUI:Notify({
        Title = "Accent Changed",
        Content = "Switched to " .. selected,
        Duration = 3
    })
end)

Tabs.Settings:AddButton({
    Title = "Toggle Theme",
    Description = "Switch Light/Dark mode instantly",
    Callback = function()
        local nextTheme = ThemeManager.CurrentTheme == "Dark" and "Light" or "Dark"
        ThemeManager:Transition(game:GetService("CoreGui"), nextTheme)
        MacUI:Notify({
            Title = "Theme Changed",
            Content = "Now using " .. nextTheme .. " mode",
            Duration = 3
        })
    end
})

------------------------------------------------------------
-- 💾 Config + Interface Manager sections
------------------------------------------------------------

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

MacUI:Notify({
    Title = "MacUI V3 Ultra",
    Content = "Framework loaded successfully ✨",
    Duration = 6
})

SaveManager:LoadAutoloadConfig()

