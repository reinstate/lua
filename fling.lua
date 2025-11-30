local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Fling Hub",
    LoadingTitle = "Fling Hub",
    LoadingSubtitle = "Loading systems...",
    ConfigurationSaving = {Enabled = true, FolderName = "FlingHub"},
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main")
local SettingsTab = Window:CreateTab("Settings")
local Status = MainTab:CreateLabel("Status: Ready")

local TouchFlingActive = false
local FlyFlingActive = false
local flingThread 
local flyThread

-- Fling Settings
local VelocityMultiplier = 10000
local FlySpeed = 50

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

local function flyFling()
    local character = lp.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- HD Admin style fly - uses humanoid state changes
    humanoid.PlatformStand = true
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Parent = rootPart
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.D = 50
    bodyGyro.P = 1000
    bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    while FlyFlingActive and character and rootPart do
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- Movement controls with better handling for high speeds
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        -- Apply movement with better speed control
        if moveDirection.Magnitude > 0 then
            -- Use a smoother acceleration curve for high speeds
            local currentSpeed = FlySpeed
            if FlySpeed > 100 then
                -- Reduce sensitivity at very high speeds
                currentSpeed = 100 + (FlySpeed - 100) * 0.5
            end
            bodyVelocity.Velocity = moveDirection.Unit * currentSpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Maintain orientation
        bodyGyro.CFrame = camera.CFrame
        
        -- Apply fling while flying
        if rootPart then
            local vel = rootPart.Velocity
            rootPart.Velocity = vel * VelocityMultiplier + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            rootPart.Velocity = vel
        end
        
        RunService.Heartbeat:Wait()
    end
    
    -- Cleanup
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if humanoid then humanoid.PlatformStand = false end
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

local function StartFlyFling()
    if FlyFlingActive then return end
    FlyFlingActive = true
    
    flyThread = coroutine.create(flyFling)
    coroutine.resume(flyThread)
end

local function StopFlyFling()
    FlyFlingActive = false
end

-- Main Tab (Toggles)
MainTab:CreateToggle({
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

MainTab:CreateToggle({
    Name = "Fly Fling",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartFlyFling()
            Status:Set("Fly Fling: Active | Speed: " .. FlySpeed)
        else
            StopFlyFling()
            Status:Set("Fly Fling: Inactive")
        end
    end
})

-- Settings Tab (Sliders)
SettingsTab:CreateSlider({
    Name = "Velocity Multiplier",
    Range = {1000, 1000000},
    Increment = 1000,
    CurrentValue = VelocityMultiplier,
    Callback = function(value)
        VelocityMultiplier = value
        if TouchFlingActive then
            Status:Set("Touch Fling: Active | Velocity: " .. value)
        elseif FlyFlingActive then
            Status:Set("Fly Fling: Active | Velocity: " .. value)
        else
            Status:Set("Velocity set to: " .. value)
        end
    end
})

SettingsTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = FlySpeed,
    Callback = function(value)
        FlySpeed = value
        if FlySpeed > 100 then
            -- Show adjusted speed in status for high values
            local adjustedSpeed = 100 + (FlySpeed - 100) * 0.5
            if FlyFlingActive then
                Status:Set("Fly Fling: Active | Speed: " .. value .. " (Adjusted: " .. math.floor(adjustedSpeed) .. ")")
            else
                Status:Set("Fly Speed set to: " .. value .. " (Adjusted: " .. math.floor(adjustedSpeed) .. ")")
            end
        else
            if FlyFlingActive then
                Status:Set("Fly Fling: Active | Speed: " .. value)
            else
                Status:Set("Fly Speed set to: " .. value)
            end
        end
    end
})

Rayfield:Notify({
    Title = "Fling Hub",
    Content = "Touch Fling & Fly Fling systems loaded",
    Duration = 3,
})

Status:Set("System ready")
print("Fling Hub - Loaded")