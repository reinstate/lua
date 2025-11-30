local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Fling Hub",
    LoadingTitle = "Fling Hub",
    LoadingSubtitle = "Loading systems...",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingControl"},
    KeySystem = false,
})

local Tab = Window:CreateTab("Main", 6035057668)
local Status = Tab:CreateLabel("Status: Ready")

local TouchFlingActive = false
local flingThread 

-- Fling Settings
local VelocityMultiplier = 10000

-- Add detection part
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

local function StartTouchFling()
    if TouchFlingActive then return end
    TouchFlingActive = true
    
    flingThread = coroutine.create(fling)
    coroutine.resume(flingThread)
end

local function StopTouchFling()
    TouchFlingActive = false
end

Tab:CreateToggle({
    Name = "Touch Fling",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartTouchFling()
            Status:Set("Touch Fling: Active | Velocity: " .. VelocityMultiplier)
        else
            StopTouchFling()
            Status:Set("Touch Fling: Inactive")
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
            Status:Set("Touch Fling: Active | Velocity: " .. value)
        else
            Status:Set("Velocity set to: " .. value)
        end
    end
})

Rayfield:Notify({
    Title = "Fling Control",
    Content = "Velocity controlled fling system loaded",
    Duration = 3,
})

Status:Set("System ready")
print("Fling Hub - Loaded")
