local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Fling Hub",
    LoadingTitle = "Fling Hub",
    LoadingSubtitle = "Touch Fling Only",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingHub"},
    KeySystem = false,
})

local Tab = Window:CreateTab("Fling", 6035057668)
local Status = Tab:CreateLabel("Status: Ready")

local TouchFlingActive = false

local function StartTouchFling()
    if TouchFlingActive then return end
    TouchFlingActive = true
    
    spawn(function()
        while TouchFlingActive do
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local oldVel = hrp.Velocity
                
                hrp.Velocity = oldVel * 30000 + Vector3.new(0, 200, 0)  
                RunService.RenderStepped:Wait()
                
                hrp.Velocity = oldVel
            end
            task.wait()
        end
    end)
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
