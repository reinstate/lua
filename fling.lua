local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Fling Hub",
    LoadingTitle = "Fling Hub",
    LoadingSubtitle = "Ultimate Fling Gui",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingHub"},
    KeySystem = false,
})

local Tab = Window:CreateTab("Fling", 6035057668)
local Status = Tab:CreateLabel("Status: Ready")

local TouchFlingActive = false
local flingThread 

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
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
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
    Name = "Touch Fling (Fling others on contact)",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartTouchFling()
            Status:Set("Touch Fling: ON – Walk into people to fling them")
        else
            StopTouchFling()
            Status:Set("Touch Fling: OFF")
        end
    end
})

Rayfield:Notify({
    Title = "Fling Hub Loaded",
    Content = "Touch Fling enabled – just bump into anyone and watch them fly.",
    Duration = 5,
})

Status:Set("Fling Hub ready – Toggle below to start")
print("Fling Hub")
