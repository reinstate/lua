local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Fling Hub",
    LoadingTitle = "Fling Hub Loading...",
    LoadingSubtitle = "Premium Fling Systems",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingHub"},
    KeySystem = false,
})

local MainTab = Window:CreateTab("Fling Systems", 6035057668)
local SettingsTab = Window:CreateTab("Keybinds", 7733765391)
local Status = MainTab:CreateLabel("Status: Ready")

-- Configuration
local Config = {
    Keybinds = {
        TouchFling = Enum.KeyCode.T,
        ServerFling = Enum.KeyCode.G
    }
}

-- State Management
local States = {
    TouchFling = {Active = false},
    ServerFling = {Active = false},
    HiddenFling = {Active = false}
}

local Connections = {}

-- Touch Fling System
local function StartTouchFling()
    if States.TouchFling.Active then return end
    States.TouchFling.Active = true
    
    local function fling()
        while States.TouchFling.Active do
            RunService.Heartbeat:Wait()
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel = hrp.Velocity
                hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
            end
        end
    end
    
    task.spawn(fling)
    Status:Set("Touch Fling: ACTIVE (T to toggle)")
end

local function StopTouchFling()
    States.TouchFling.Active = false
    Status:Set("Touch Fling: OFF")
end

-- Hidden Fling System
local function StartHiddenFling()
    if States.HiddenFling.Active then return end
    States.HiddenFling.Active = true
    
    task.spawn(function()
        while States.HiddenFling.Active do
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
    States.HiddenFling.Active = false
end

-- Keybind System
local function SetupKeybinds()
    -- Touch Fling Toggle
    local touchFlingBind = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Config.Keybinds.TouchFling then
            if States.TouchFling.Active then
                StopTouchFling()
            else
                StartTouchFling()
            end
        end
    end)
    table.insert(Connections, touchFlingBind)
    
    -- Server Fling Toggle
    local serverFlingBind = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Config.Keybinds.ServerFling then
            if States.ServerFling.Active then
                StopHiddenFling()
                States.ServerFling.Active = false
                Status:Set("Server Fling: OFF")
            else
                States.ServerFling.Active = true
                Status:Set("Server Fling: ACTIVE (G to toggle)")
                StartHiddenFling()
                task.spawn(function()
                    while States.ServerFling.Active do
                        for _, player in Players:GetPlayers() do
                            if not States.ServerFling.Active or player == lp then continue end
                            local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                            if targetHRP and myHRP then
                                Status:Set("Flinging: " .. player.DisplayName)
                                for i = 1, 40 do
                                    if not States.ServerFling.Active then break end
                                    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                    StopHiddenFling()
                end)
            end
        end
    end)
    table.insert(Connections, serverFlingBind)
end

-- UI Elements
MainTab:CreateSection("Fling Types")

MainTab:CreateToggle({
    Name = "Touch Fling (Press T)",
    CurrentValue = false,
    Callback = function(v)
        if v then
            StartTouchFling()
        else
            StopTouchFling()
        end
    end
})

MainTab:CreateToggle({
    Name = "Server Fling (Press G)",
    CurrentValue = false,
    Callback = function(v)
        States.ServerFling.Active = v
        if v then
            Status:Set("Server Fling: ACTIVE")
            StartHiddenFling()
            task.spawn(function()
                while States.ServerFling.Active do
                    for _, player in Players:GetPlayers() do
                        if not States.ServerFling.Active or player == lp then continue end
                        local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and myHRP then
                            Status:Set("Flinging: " .. player.DisplayName)
                            for i = 1, 40 do
                                if not States.ServerFling.Active then break end
                                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
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

-- Keybinds Tab
SettingsTab:CreateSection("Change Keybinds")

SettingsTab:CreateKeybind({
    Name = "Touch Fling Key",
    CurrentKeybind = Config.Keybinds.TouchFling,
    Callback = function(Key)
        Config.Keybinds.TouchFling = Key
        Status:Set("Touch Fling keybind updated to: " .. Key.Name)
    end
})

SettingsTab:CreateKeybind({
    Name = "Server Fling Key",
    CurrentKeybind = Config.Keybinds.ServerFling,
    Callback = function(Key)
        Config.Keybinds.ServerFling = Key
        Status:Set("Server Fling keybind updated to: " .. Key.Name)
    end
})

-- Initialize
SetupKeybinds()

Rayfield:Notify({
    Title = "Fling Hub Loaded!",
    Content = "Fling systems activated!\n• Touch Fling (T)\n• Server Fling (G)",
    Duration = 5,
})

Status:Set("Fling Hub Ready! Check keybinds in Settings.")

print("Fling Hub - Loaded with Keybinds")
