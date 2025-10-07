--========================================================
-- 🍎 MacUI Addon: InterfaceManager.lua
-- Handles multi-interface setup (Fluent-compatible)
--========================================================

local InterfaceManager = {}
InterfaceManager.__index = InterfaceManager

InterfaceManager.Library = nil
InterfaceManager.InterfaceFolder = "MacUI/Interfaces"

function InterfaceManager:SetLibrary(lib)
	self.Library = lib
end

function InterfaceManager:SetFolder(path)
	self.InterfaceFolder = path
end

function InterfaceManager:BuildInterfaceSection(tab)
	tab:AddParagraph({
		Title = "Interface Manager",
		Content = "Manage multiple MacUI interfaces."
	})

	tab:AddButton({
		Title = "Reload Interface",
		Description = "Rebuild current interface",
		Callback = function()
			if self.Library and self.Library.Notify then
				self.Library:Notify({
					Title = "Rebuilt",
					Content = "Interface reloaded successfully.",
					Duration = 3
				})
			end
		end
	})

	tab:AddButton({
		Title = "Unload UI",
		Description = "Destroys MacUI from memory",
		Callback = function()
			for _, obj in ipairs(game:GetService("CoreGui"):GetChildren()) do
				if obj:IsA("ScreenGui") and string.find(obj.Name, "MacUI") then
					obj:Destroy()
				end
			end
			if self.Library and self.Library.Notify then
				self.Library:Notify({
					Title = "Unloaded",
					Content = "MacUI was unloaded successfully.",
					Duration = 3
				})
			end
		end
	})
end

return InterfaceManager
