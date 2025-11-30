local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Ultimate All In One",
    LoadingTitle = "Loading",
    LoadingSubtitle = "By Nexus",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local Tab = Window:CreateTab("Main", 6035057668)
local Status = Tab:CreateLabel("Ready")

local ClickFollowTarget = nil
local HiddenFlingActive = false
local ServerFlingActive = false
local ClickTPActive = false
local WalkSpeedActive = false
local JumpPowerActive = false
local NoclipActive = false
local WalkSpeedValue = 100
local JumpPowerValue = 150
local Connections = {}

local function ApplyModifiers()
    task.wait(2)
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if WalkSpeedActive then hum.WalkSpeed = WalkSpeedValue end
    if JumpPowerActive then hum.JumpPower = JumpPowerValue end
end
lp.CharacterAdded:Connect(ApplyModifiers)

local TouchFlingEnabled = false
local FlingThread = nil

local function StartTouchFling()
    if TouchFlingEnabled then return end
    TouchFlingEnabled = true
    
    local function fling()
        local lp = Players.LocalPlayer
        local c, hrp, vel, movel = nil, nil, nil, 0.1
    
        while TouchFlingEnabled do
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
    
    FlingThread = coroutine.create(fling)
    coroutine.resume(FlingThread)
    Status:Set("Touch Fling: ON")
end

local function StopTouchFling()
    TouchFlingEnabled = false
    if FlingThread then
        FlingThread = nil
    end
    Status:Set("Touch Fling: OFF")
end

local function StartHiddenFling()
    if HiddenFlingActive then return end
    HiddenFlingActive = true
    spawn(function()
        while HiddenFlingActive do
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
    HiddenFlingActive = false
end

Tab:CreateToggle({
    Name = "Click Follow",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Status:Set("Click Follow: ON")
            local conn = RunService.Heartbeat:Connect(function()
                if ClickFollowTarget and ClickFollowTarget.Character then
                    local myhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    local tgt = ClickFollowTarget.Character:FindFirstChild("HumanoidRootPart")
                    if myhrp and tgt then
                        myhrp.CFrame = tgt.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end)
            table.insert(Connections, conn)

            local click = mouse.Button1Down:Connect(function()
                local t = mouse.Target
                if t then
                    local model = t:FindFirstAncestorWhichIsA("Model")
                    local plr = Players:GetPlayerFromCharacter(model)
                    if plr and plr ~= lp then
                        ClickFollowTarget = plr
                        Status:Set("Locked: " .. plr.DisplayName)
                    end
                end
            end)
            table.insert(Connections, click)
        else
            ClickFollowTarget = nil
            Status:Set("Click Follow: OFF")
        end
    end
})

Tab:CreateToggle({
    Name = "Touch Fling",
    CurrentValue = false,
    Callback = function(v)
        if v then
            StartTouchFling()
        else
            StopTouchFling()
        end
    end
})

Tab:CreateToggle({
    Name = "Server Fling",
    CurrentValue = false,
    Callback = function(v)
        ServerFlingActive = v
        if v then
            Status:Set("Server Fling: ON")
            StartHiddenFling()
            task.spawn(function()
                while ServerFlingActive do
                    for _, plr in Players:GetPlayers() do
                        if not ServerFlingActive or plr == lp then continue end
                        local targetHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and myHRP then
                            Status:Set("Flinging: " .. plr.DisplayName)
                            for i = 1, 40 do
                                if not ServerFlingActive then break end
                                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
                                task.wait(0.1)
                            end
                        end
                    end
                end
                StopHiddenFling()
                Status:Set("Server Fling: OFF")
            end)
        else
            StopHiddenFling()
            Status:Set("Server Fling: OFF")
        end
    end
})

local ClickTPConnection = nil
Tab:CreateToggle({
    Name = "Click TP",
    CurrentValue = false,
    Callback = function(v)
        ClickTPActive = v

        if v then
            Status:Set("Click TP: ON")

            if ClickTPConnection then
                ClickTPConnection:Disconnect()
                ClickTPConnection = nil
            end

            ClickTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if not ClickTPActive then return end
                if input.KeyCode ~= Enum.KeyCode.C then return end

                local character = lp.Character
                if not character then return end
                
                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local cam = workspace.CurrentCamera
                if not cam then return end
                
                local hit = mouse.Hit
                if not hit then return end
                
                local pos = hit.Position + Vector3.new(0, 4, 0)
                root.CFrame = CFrame.new(pos, pos + cam.CFrame.LookVector)
                Status:Set("Teleported")
            end)

        else
            Status:Set("Click TP: OFF")

            if ClickTPConnection then
                ClickTPConnection:Disconnect()
                ClickTPConnection = nil
            end
        end
    end
})

Tab:CreateSlider({
    Name = "WalkSpeed", 
    Range = {16, 500}, 
    Increment = 5, 
    CurrentValue = 100,
    Callback = function(v) 
        WalkSpeedValue = v 
        if WalkSpeedActive then
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = WalkSpeedValue end
            Status:Set("Speed: " .. WalkSpeedValue)
        end
    end
})

Tab:CreateToggle({
    Name = "WalkSpeed",
    CurrentValue = false,
    Callback = function(v)
        WalkSpeedActive = v
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and WalkSpeedValue or 16 end
        Status:Set(v and ("Speed: " .. WalkSpeedValue) or "Speed: OFF")
    end
})

Tab:CreateSlider({
    Name = "JumpPower", 
    Range = {50, 500}, 
    Increment = 5, 
    CurrentValue = 150,
    Callback = function(v) 
        JumpPowerValue = v 
        if JumpPowerActive then
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = JumpPowerValue end
            Status:Set("Jump: " .. JumpPowerValue)
        end
    end
})

Tab:CreateToggle({
    Name = "JumpPower", 
    CurrentValue = false,
    Callback = function(v)
        JumpPowerActive = v
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v and JumpPowerValue or 50 end
        Status:Set(v and ("Jump: " .. JumpPowerValue) or "Jump: OFF")
    end
})

Tab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        NoclipActive = v
        if v then
            local conn = RunService.Stepped:Connect(function()
                if lp.Character then
                    for _, p in ipairs(lp.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
            table.insert(Connections, conn)
            Status:Set("Noclip: ON")
        else
            Status:Set("Noclip: OFF")
        end
    end
})

Rayfield:Notify({
    Title = "Ready",
    Content = "All features loaded",
    Duration = 3,
})

print("Ultimate All In One - Loaded")
