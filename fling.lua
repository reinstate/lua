local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Fling Hub",
    LoadingTitle = "Fling Hub",
    LoadingSubtitle = "Loading systems...",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingHub"},
    KeySystem = false,
})

local Tab = Window:CreateTab("Main", 6035057668)
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
        
        task.wait(0.1)
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
            Status:Set("Locked: " .. player.DisplayName .. " - Teleporting every 0.1s")
        end
    end
end)

Tab:CreateToggle({
    Name = "Touch Fling",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartTouchFling()
            Status:Set("Touch Fling: ON - Velocity: " .. VelocityMultiplier)
        else
            StopTouchFling()
            Status:Set("Touch Fling: OFF")
        end
    end
})

Tab:CreateToggle({
    Name = "Lock Target",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartLockTarget()
            Status:Set("Lock Target: ACTIVE - Click player to lock")
        else
            StopLockTarget()
            Status:Set("Lock Target: OFF")
        end
    end
})

Tab:CreateSlider({
    Name = "Velocity Multiplier",
    Range = {1000, 100000},
    Increment = 1000,
    CurrentValue = VelocityMultiplier,
    Callback = function(value)
        VelocityMultiplier = value
        if TouchFlingActive then
            Status:Set("Touch Fling: ON - Velocity: " .. value)
        end
    end
})

Rayfield:Notify({
    Title = "Fling Hub Loaded",
    Content = "Touch Fling and Lock Target systems ready",
    Duration = 3,
})

Status:Set("Ready - Toggle features below")
print("Fling Hub Loaded")
