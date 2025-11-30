-- FLING HUB ULTIMATE – PURE FLING EDITION
-- Touch Fling (T) • Server Fling (G) • Customizable Keybinds • Saves Config

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- 100% WORKING RAYFIELD (OFFICIAL SOURCE)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "FLING HUB ULTIMATE",
    LoadingTitle = "Fling Hub",
    LoadingSubtitle = "Pure Fling Systems",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingHubUltimate"},
    KeySystem = false,
})

local MainTab = Window:CreateTab("Fling Systems", 6035057668)
local KeybindTab = Window:CreateTab("Keybinds", 7733765391)
local Status = MainTab:CreateLabel("Status: Ready")

-- Keybinds (saved automatically)
local Keybinds = {
    TouchFling = Enum.KeyCode.T,
    ServerFling = Enum.KeyCode.G
}

-- States
local TouchFlingActive = false
local ServerFlingActive = false
local HiddenFlingRunning = false

-- Hidden Fling Engine (used by both)
local function StartHiddenFling()
    if HiddenFlingRunning then return end
    HiddenFlingRunning = true
    spawn(function()
        while HiddenFlingRunning do
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local old = hrp.Velocity
                hrp.Velocity = old * 30000 + Vector3.new(0, 35000, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = old
            end
            task.wait()
        end
    end)
end

local function StopHiddenFling()
    HiddenFlingRunning = false
end

-- TOUCH FLING
local function ToggleTouchFling()
    TouchFlingActive = not TouchFlingActive
    if TouchFlingActive then
        StartHiddenFling()
        Status:Set("Touch Fling: ON (T)")
    else
        StopHiddenFling()
        Status:Set("Touch Fling: OFF")
    end
end

-- SERVER FLING (4s behind each player, forever)
local function ToggleServerFling()
    ServerFlingActive = not ServerFlingActive
    if ServerFlingActive then
        Status:Set("Server Fling: ON (G)")
        StartHiddenFling()
        task.spawn(function()
            while ServerFlingActive do
                for _, plr in Players:GetPlayers() do
                    if not ServerFlingActive or plr == lp or not plr.Character then continue end
                    local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                    local mHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if tHRP and mHRP then
                        Status:Set("Flinging → " .. plr.DisplayName)
                        for i = 1, 40 do  -- 4 seconds
                            if not ServerFlingActive then break end
                            mHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3)  -- Perfect behind
                            task.wait(0.1)
                        end
                    end
                end
            end
            StopHiddenFling()
        end)
    else
        StopHiddenFling()
        Status:Set("Server Fling: OFF")
    end
end

-- KEYBIND HANDLER
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Keybinds.TouchFling then
        ToggleTouchFling()
    elseif input.KeyCode == Keybinds.ServerFling then
        ToggleServerFling()
    end
end)

-- UI: MAIN TAB
MainTab:CreateSection("Fling Controls")

MainTab:CreateToggle({
    Name = "Touch Fling (Press T)",
    CurrentValue = false,
    Callback = function(v) 
        TouchFlingActive = v
        if v then StartHiddenFling() Status:Set("Touch Fling: ON") else StopHiddenFling() Status:Set("Touch Fling: OFF") end
    end
})

MainTab:CreateToggle({
    Name = "Server Fling (Press G)",
    CurrentValue = false,
    Callback = function(v)
        ServerFlingActive = v
        if v then
            Status:Set("Server Fling: ON")
            StartHiddenFling()
            task.spawn(function()
                while ServerFlingActive do
                    for _, plr in Players:GetPlayers() do
                        if not ServerFlingActive or plr == lp or not plr.Character then continue end
                        local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local mHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if tHRP and mHRP then
                            Status:Set("Flinging → " .. plr.DisplayName)
                            for i = 1, 40 do
                                if not ServerFlingActive then break end
                                mHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3)
                                task.wait(0.1)
                            end
                        end
                    end
                end
                StopHiddenFling()
            end)
        else
            StopHiddenFling()
            Status:Set("Server Fling: OFF")
        end
    end
})

-- KEYBINDS TAB
KeybindTab:CreateSection("Customize Keybinds")

KeybindTab:CreateKeybind({
    Name = "Touch Fling Keybind",
    CurrentKeybind = Keybinds.TouchFling,
    Callback = function(key)
        Keybinds.TouchFling = key
        Status:Set("Touch Fling key → " .. key.Name)
    end
})

KeybindTab:CreateKeybind({
    Name = "Server Fling Keybind",
    CurrentKeybind = Keybinds.ServerFling,
    Callback = function(key)
        Keybinds.ServerFling = key
        Status:Set("Server Fling key → " .. key.Name)
    end
})

-- Startup
Rayfield:Notify({
    Title = "FLING HUB ULTIMATE",
    Content = "Pure fling systems loaded.\n• Touch Fling (T)\n• Server Fling (G)\nChange keybinds in Settings tab.",
    Duration = 7,
})

Status:Set("Fling Hub Ready – Press T or G to destroy")

print("FLING HUB ULTIMATE – PURE FLING EDITION LOADED")
