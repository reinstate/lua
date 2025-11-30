local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Fling Hub",
    LoadingTitle = "Fling Hub",
    LoadingSubtitle = "Player Fling Gui",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingHub"},
    KeySystem = false,
})

local Tab = Window:CreateTab("Fling", 6035057668)
local Status = Tab:CreateLabel("Status: Ready")

local TouchFlingActive = false
local LockTargetActive = false
local LockTarget = nil
local flingThread 
local lockThread 

-- Fling Settings
local VelocityMultiplier = 10000

-- Add detection part (from the GUI script)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
    local detection = Instance.new("Decal")
    detection.Name = "juisdfj0i32i0eidsuf0iok"
    detection.Parent = ReplicatedStorage
end

local function fling()
    local lp = Players.LocalPlayer
    local c, hrp, vel, movel = nil, nil, nil, 0.1

    while TouchFlingActive do
        RunService.Heartbeat:Wait()
        c = lp.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")

        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * VelocityMultiplier + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

local function lockFollow()
    while LockTargetActive and LockTarget do
        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = LockTarget.Character and LockTarget.Character:FindFirstChild("HumanoidRootPart")
        
        if myHRP and targetHRP then
            myHRP.CFrame = targetHRP.CFrame
        end
        
        task.wait(0.1) -- Continuous spam every 0.1 seconds
    end
end

local function StartTouchFling()
    if TouchFlingActive then return end
    TouchFlingActive = true
    
    flingThread = coroutine.create(fling)
    coroutine.resume(flingThread)
end

local function StopTouchFling()
    TouchFlingActive = false
end

local function StartLockTarget()
    LockTargetActive = true
    lockThread = coroutine.create(lockFollow)
    coroutine.resume(lockThread)
end

local function StopLockTarget()
    LockTargetActive = false
    LockTarget = nil
end

-- Mouse click to select target
mouse.Button1Down:Connect(function()
    if not LockTargetActive then return end
    
    local target = mouse.Target
    if target then
        local model = target:FindFirstAncestorWhichIsA("Model")
        local player = Players:GetPlayerFromCharacter(model)
        if player and player ~= lp then
            LockTarget = player
            Status:Set("🔒 LOCKED: " .. player.DisplayName .. " - Following every 0.1s")
        end
    end
end)

Tab:CreateToggle({
    Name = "Touch Fling (Fling others on contact)",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartTouchFling()
            Status:Set("Touch Fling: ON – Velocity: " .. VelocityMultiplier)
        else
            StopTouchFling()
            Status:Set("Touch Fling: OFF")
        end
    end
})

Tab:CreateToggle({
    Name = "Lock Target (Click player to lock)",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartLockTarget()
            Status:Set("Player Lock: ACTIVE - Click any player to lock onto them")
        else
            StopLockTarget()
            Status:Set("Player Lock: OFF")
        end
    end
})

-- Velocity Multiplier Slider
Tab:CreateSlider({
    Name = "Velocity Multiplier",
    Range = {1000, 100000},
    Increment = 1000,
    CurrentValue = VelocityMultiplier,
    Callback = function(value)
        VelocityMultiplier = value
        if TouchFlingActive then
            Status:Set("Touch Fling: ON – Velocity: " .. value)
        end
    end
})

Rayfield:Notify({
    Title = "Fling Hub Loaded",
    Content = "Touch Fling + Lock Target enabled!\nClick players while Lock is active to follow them every 0.1s",
    Duration = 5,
})

Status:Set("Fling Hub ready – Toggle below to start")
print("Fling Hub - With Lock Target Feature")
