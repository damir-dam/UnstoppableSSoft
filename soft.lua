print("CeloMolochnoye -- Booga Booga")
local Library = loadstring(game:HttpGetAsync("https://github.com/1dontgiveaf/Fluent-Renewed/releases/download/v1.0/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/1dontgiveaf/Fluent-Renewed/refs/heads/main/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/1dontgiveaf/Fluent-Renewed/refs/heads/main/Addons/InterfaceManager.luau"))()

local Players = game:GetService("Players")

local VirtualUser = cloneref(game:GetService("VirtualUser"))
		Players.LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
		print("NIGGAS AFK")
end)



local Window = Library:CreateWindow{
    Title = "CeloMolochnoye",
    SubTitle = "Created By fan",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl
}

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "menu" }),
	Maain = Window:AddTab({ Title = "Waypoints", Icon = "map-pin" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "skull" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "layout-dashboard" }),
    Item = Window:AddTab({ Title = "Item", Icon = "backpack" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local PS = game:GetService('PathfindingService')
local rs = game:GetService("ReplicatedStorage")
local packets = require(rs.Modules.Packets)
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local runs = game:GetService("RunService")
local httpservice = game:GetService("HttpService")
local Players = game:GetService("Players")
local localiservice = game:GetService("LocalizationService")
local marketservice = game:GetService("MarketplaceService")
local rbxservice = game:GetService("RbxAnalyticsService")
local virtualInput = game:GetService("VirtualInputManager")
local fpsBoostEnabled = false
local fpsOriginalSettings = {}
local fpsOriginalAssets = {}
local waypoints = {}
local waypointParts = {}
local running = false
local currentWaypointIndex = 1
local tweenSpeed = 16
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local tweenService = game:GetService("TweenService")
local currentTween = nil
local autoWalkThread = nil
local antiGravityForce = nil
local waitingInAir = false
local autoSpawnWaypoints = false
local spawnInterval = 0.5
local autoSpawnThread = nil
local managedWaypointIndex = nil
local managedWaypointColor = Color3.fromRGB(0, 255, 0)
local normalWaypointColor = Color3.fromRGB(255, 0, 0)
local defaultWaypointColor = Color3.fromRGB(255, 0, 0)

-- ===== НОВЫЕ ФУНКЦИИ ДЛЯ ADVANCED TWEEN =====
local antigravityConnection = nil
local noclipConnection = nil
local moveConnection = nil
local startHeight = nil
local startDirection = nil
local originalCollision = {}

local function enableAntiGravity()
    if antigravityConnection then antigravityConnection:Disconnect() end
    antigravityConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if hum and root then
            hum.PlatformStand = true
            -- ЖЕСТКАЯ фиксация высоты
            root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            
            -- Если вдруг высота изменилась - возвращаем
            if math.abs(root.Position.Y - startHeight) > 0.1 then
                root.CFrame = CFrame.new(
                    root.Position.X,
                    startHeight,
                    root.Position.Z
                ) * CFrame.Angles(0, root.Orientation.Y, 0)
            end
        end
    end)
end

local function disableAntiGravity()
    if antigravityConnection then
        antigravityConnection:Disconnect()
        antigravityConnection = nil
        if hum then
            hum.PlatformStand = false
        end
    end
end

local function saveNoclipState()
    originalCollision = {}
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollision[part] = part.CanCollide
            end
        end
    end
end

local function restoreCollision()
    for part, state in pairs(originalCollision) do
        if part and part.Parent then
            part.CanCollide = state
        end
    end
    originalCollision = {}
end

local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    saveNoclipState()
    
    noclipConnection = game:GetService("RunService").Stepped:Connect(function()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    restoreCollision()
end

local function stopAdvancedTween()
    if moveConnection then
        moveConnection:Disconnect()
        moveConnection = nil
    end
    startHeight = nil
    startDirection = nil
    disableAntiGravity()
    disableNoclip()
end
-- ===== КОНЕЦ НОВЫХ ФУНКЦИЙ =====

local placestructure

makefolder('Goldfarm_V1');

local tspmo = game:GetService("TweenService")
local itemslist = {
"Adurite", "Berry", "Bloodfruit", "Bluefruit", "Coin", "Essence", "Hide", "Ice Cube", "Iron", "Jelly", "Leaves", "Log", "Steel", "Stone", "Wood", "Gold", "Raw Gold", "Crystal Chunk", "Raw Emerald", "Pink Diamond", "Raw Adurite", "Raw Iron", "Coal"}
local Options = Library.Options

--------------------------------------------------
-- FPS BOOST FUNCTIONS
--------------------------------------------------

local function applyFPSBoost()
    fpsOriginalSettings.QualityLevel = settings():GetService("RenderSettings").QualityLevel
    settings():GetService("RenderSettings").QualityLevel = 1

    local lighting = game:GetService("Lighting")
    fpsOriginalSettings.GlobalShadows = lighting.GlobalShadows
    fpsOriginalSettings.Brightness = lighting.Brightness
    fpsOriginalSettings.FogEnd = lighting.FogEnd

    lighting.GlobalShadows = false
    lighting.Brightness = 1
    lighting.FogEnd = 1e10

    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") then
            fpsOriginalAssets[obj] = obj.Enabled
            obj.Enabled = false
        end

        if obj:IsA("Texture") then
            fpsOriginalAssets[obj] = obj.Texture
            obj.Texture = ""
        end

        if obj:IsA("Decal") then
            fpsOriginalAssets[obj] = obj.Texture
            obj.Texture = ""
        end

        if obj:IsA("BasePart") then
            fpsOriginalAssets[obj] = {
                Material = obj.Material,
                Reflectance = obj.Reflectance
            }
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        end
    end
end

local function restoreFPSBoost()
    if fpsOriginalSettings.QualityLevel then
        settings():GetService("RenderSettings").QualityLevel = fpsOriginalSettings.QualityLevel
    end

    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = fpsOriginalSettings.GlobalShadows or true
    lighting.Brightness = fpsOriginalSettings.Brightness or 2
    lighting.FogEnd = fpsOriginalSettings.FogEnd or 100000

    for obj, data in pairs(fpsOriginalAssets) do
        if obj and obj.Parent then
            if typeof(data) == "boolean" then
                obj.Enabled = data
            elseif typeof(data) == "string" then
                obj.Texture = data
            elseif typeof(data) == "table" then
                obj.Material = data.Material
                obj.Reflectance = data.Reflectance
            end
        end
    end
    fpsOriginalAssets = {}
end

-- Function to create visual marker
local function createWaypointVisual(position, index, waitTime, isManaged)
    local part = Instance.new("Part")
    part.Name = "Waypoint_" .. index
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(1.7, 1.7, 1.7)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.ForceField
    part.Transparency = 0.3
    
    if isManaged then
        part.Color = managedWaypointColor
    else
        part.Color = normalWaypointColor
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WaypointInfo"
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 100
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = part
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.Text = index .. (waitTime and waitTime > 0 and "\nwait(" .. waitTime .. ")" or "")
    textLabel.Parent = billboard
    
    part.Parent = workspace
    return part
end

-- Function to update visuals
local function updateWaypointVisuals()
    for _, part in pairs(waypointParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    waypointParts = {}
    
    for i, waypoint in ipairs(waypoints) do
        local isManaged = (i == managedWaypointIndex)
        local part = createWaypointVisual(waypoint.position, i, waypoint.waitTime, isManaged)
        table.insert(waypointParts, part)
    end
end

-- Function to manage waypoint
local function manageWaypoint(index)
    if index < 1 or index > #waypoints then
        Library:Notify({ Title = "Waypoint System", Content = "Waypoint #" .. index .. " doesn't exist!", Duration = 4 })
        return false
    end
    
    if managedWaypointIndex then
        normalWaypointColor = defaultWaypointColor
        managedWaypointIndex = nil
    end
    
    managedWaypointIndex = index
    normalWaypointColor = Color3.fromRGB(255, 0, 0)
    updateWaypointVisuals()
    Library:Notify({ Title = "Waypoint System", Content = "Managing waypoint #" .. index .. " (green)", Duration = 4 })
    return true
end

-- Function to unmanage waypoint
local function unmanageWaypoint()
    if not managedWaypointIndex then
        Library:Notify({ Title = "Waypoint System", Content = "No waypoint being managed", Duration = 4 })
        return false
    end
    
    normalWaypointColor = defaultWaypointColor
    managedWaypointIndex = nil
    updateWaypointVisuals()
    Library:Notify({ Title = "Waypoint System", Content = "Stopped managing waypoint", Duration = 4 })
    return true
end

-- Function to replace managed waypoint position
local function replaceManagedWaypoint()
    if not managedWaypointIndex then
        Library:Notify({ Title = "Waypoint System", Content = "No managed waypoint to replace!", Duration = 4 })
        return false
    end
    
    local newPosition = root.Position
    local oldPosition = waypoints[managedWaypointIndex].position
    
    waypoints[managedWaypointIndex].position = newPosition
    updateWaypointVisuals()
    
    Library:Notify({ 
        Title = "Waypoint System", 
        Content = string.format("Waypoint #%d moved to new position", managedWaypointIndex), 
        Duration = 4 
    })
    return true
end

-- Function to add waypoint with management
local function addWaypointWithManagement()
    local position = root.Position
    
    if managedWaypointIndex then
        replaceManagedWaypoint()
        unmanageWaypoint()
        return "replaced"
    else
        table.insert(waypoints, { position = position, waitTime = 0 })
        updateWaypointVisuals()
        return "added"
    end
end

-- Function to create anti-gravity force
local function createAntiGravity()
    if not antiGravityForce or not antiGravityForce.Parent then
        antiGravityForce = Instance.new("BodyForce")
        antiGravityForce.Name = "AntiGravity"
        antiGravityForce.Force = Vector3.new(0, workspace.Gravity * root.AssemblyMass, 0)
        antiGravityForce.Parent = root
    end
    return antiGravityForce
end

-- Function to remove anti-gravity force
local function removeAntiGravity()
    if antiGravityForce and antiGravityForce.Parent then
        antiGravityForce:Destroy()
        antiGravityForce = nil
    end
end

-- Function to check if waypoint is in air
local function isWaypointInAir(position)
    local ray = Ray.new(position + Vector3.new(0, 10, 0), Vector3.new(0, -1000, 0))
    local part, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, {character})
    
    if not part or (position.Y - hitPosition.Y) > 5 then
        return true
    end
    return false
end

local function holdInAir(position, duration)
    if not running or not character or not root then return end
    
    waitingInAir = true
    root.Anchored = true
    
    local startTime = tick()
    while tick() - startTime < duration and running do
        task.wait(0.1)
    end
    
    root.Anchored = false
    waitingInAir = false
end

-- Function to add waypoint
local function addWaypoint()
    return addWaypointWithManagement() == "added"
end

-- Function to remove all waypoints
local function removeAllWaypoints()
    running = false
    waitingInAir = false
    autoSpawnWaypoints = false
    managedWaypointIndex = nil
    normalWaypointColor = defaultWaypointColor
    
    if autoWalkThread then
        coroutine.close(autoWalkThread)
        autoWalkThread = nil
    end
    
    if autoSpawnThread then
        coroutine.close(autoSpawnThread)
        autoSpawnThread = nil
    end
    
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    
    removeAntiGravity()
    waypoints = {}
    updateWaypointVisuals()
    currentWaypointIndex = 1
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    if Options.AutoSpawnToggle then
        Options.AutoSpawnToggle:SetValue(false)
    end
    
    Library:Notify({ Title = "Waypoint System", Content = "All waypoints removed", Duration = 4 })
end

-- Function to remove last waypoint
local function removeLastWaypoint()
    if #waypoints > 0 then
        if managedWaypointIndex == #waypoints then
            unmanageWaypoint()
        end
        table.remove(waypoints, #waypoints)
        updateWaypointVisuals()
        Library:Notify({ Title = "Waypoint System", Content = "Last waypoint removed", Duration = 4 })
    end
end

local function goToWaypointTween(index)
    if not running or #waypoints == 0 or not waypoints[index] then return false end
    local waypoint = waypoints[index]
    local targetPos = waypoint.position
    
    local gyro = root:FindFirstChild("WaypointGyro")
    if not gyro then
        gyro = Instance.new("BodyGyro")
        gyro.Name = "WaypointGyro"
        gyro.Parent = root
    end

    gyro.P = 20000
    gyro.D = 500
    gyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    
    humanoid.AutoRotate = false
    humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)

    local reached = false
    while running and not reached do
        local currentPos = root.Position
        local distance = (targetPos - currentPos).Magnitude
        
        if distance < 0.5 then 
            reached = true
            break
        end

        local deltaTime = task.wait()
        local direction = (targetPos - currentPos).Unit
        local moveStep = direction * (tweenSpeed * deltaTime)

        if distance > moveStep.Magnitude then
            root.CFrame = root.CFrame + moveStep
        else
            root.CFrame = CFrame.new(targetPos)
            reached = true
        end
        
        local lookTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
        if (lookTarget - root.Position).Magnitude > 0.1 then
            gyro.CFrame = CFrame.new(root.Position, lookTarget)
        end
        
        root.Velocity = Vector3.new(0, 0, 0)
    end
    
    return reached
end

local function goToWaypoint(index)
    if not running or #waypoints == 0 or not waypoints[index] then return end
    local waypoint = waypoints[index]

    local reached = goToWaypointTween(index)

    if running and reached then
        if waypoint.waitTime and waypoint.waitTime > 0 then
            root.CFrame = CFrame.new(waypoint.position)
            root.Velocity = Vector3.new(0,0,0)
            
            root.Anchored = true
            
            local startWait = tick()
            while tick() - startWait < waypoint.waitTime and running do
                task.wait(0.1)
            end
            
            root.Anchored = false
        end
    end
end

local function startAutoWalk()
    if running or #waypoints == 0 then return end
    running = true
    
    autoWalkThread = coroutine.create(function()
        while running and #waypoints > 0 do
            for i = 1, #waypoints do
                if not running or #waypoints == 0 then break end
                currentWaypointIndex = i
                
                if not root:FindFirstChild("WaypointGyro") then
                    local g = Instance.new("BodyGyro")
                    g.Name = "WaypointGyro"
                    g.P = 10000
                    g.MaxTorque = Vector3.new(400000, 400000, 400000)
                    g.CFrame = root.CFrame
                    g.Parent = root
                end

                goToWaypoint(i)
            end
            task.wait()
        end
        stopAutoWalk()
    end)
    coroutine.resume(autoWalkThread)
end

local function stopAutoWalk()
    running = false
    waitingInAir = false
    
    if root then
        root.Anchored = false
    end
    
    if root:FindFirstChild("WaypointGyro") then
        root.WaypointGyro:Destroy()
    end
    
    humanoid.AutoRotate = true 
    
    if autoWalkThread then
        coroutine.close(autoWalkThread)
        autoWalkThread = nil
    end
    
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end

    removeAntiGravity()
    
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    root.Velocity = Vector3.new(0, 0, 0)
end

-- Function to set wait time for specific waypoint
local function setWaitTime(waypointIndex, waitTime)
    if waypoints[waypointIndex] then
        waypoints[waypointIndex].waitTime = tonumber(waitTime) or 0
        updateWaypointVisuals()
        Library:Notify({ Title = "Waypoint System", Content = "Wait time set for waypoint #" .. waypointIndex, Duration = 4 })
    end
end

-- Function to copy waypoints to clipboard
local function copyWaypoints()
    if #waypoints == 0 then
        return ""
    end
    
    local waypointData = {}
    for i, waypoint in ipairs(waypoints) do
        table.insert(waypointData, {
            x = waypoint.position.X,
            y = waypoint.position.Y,
            z = waypoint.position.Z,
            wait = waypoint.waitTime or 0
        })
    end
    
    local copyText = "-- Waypoints Data (with wait times)\n"
    copyText = copyText .. "local waypointsData = {\n"
    
    for i, data in ipairs(waypointData) do
        local waitText = data.wait > 0 and string.format(" -- wait: %.1fs", data.wait) or ""
        copyText = copyText .. string.format(" {position = Vector3.new(%.2f, %.2f, %.2f), waitTime = %.1f},%s\n",
            data.x, data.y, data.z, data.wait, waitText)
    end
    
    copyText = copyText .. "}\n\n"
    copyText = copyText .. "-- JSON format for sharing:\n"
    local jsonString = game:GetService("HttpService"):JSONEncode(waypointData)
    copyText = copyText .. jsonString
    
    setclipboard(copyText)
    return copyText
end

-- Function to load waypoints from string
local function loadWaypointsFromString(inputString)
    local success = false
    
    local jsonSuccess, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(inputString)
    end)
    
    if jsonSuccess and type(data) == "table" then
        removeAllWaypoints()
        for i, waypoint in ipairs(data) do
            if waypoint.x and waypoint.y and waypoint.z then
                table.insert(waypoints, {
                    position = Vector3.new(waypoint.x, waypoint.y, waypoint.z),
                    waitTime = waypoint.wait or waypoint.waitTime or 0
                })
            end
        end
        updateWaypointVisuals()
        success = true
    else
        local luaTableMatch = inputString:match("waypointsData%s*=%s*%{([^}]+)%}")
        if luaTableMatch then
            removeAllWaypoints()
            local lines = {}
            for line in inputString:gmatch("[^\r\n]+") do
                table.insert(lines, line)
            end
            
            for _, line in ipairs(lines) do
                local x, y, z = line:match("Vector3%.new%(([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%)")
                local waitTime = line:match("waitTime%s*=%s*([%-%d%.]+)")
                
                if x and y and z then
                    table.insert(waypoints, {
                        position = Vector3.new(tonumber(x), tonumber(y), tonumber(z)),
                        waitTime = tonumber(waitTime) or 0
                    })
                end
            end
            updateWaypointVisuals()
            success = true
        else
            removeAllWaypoints()
            for line in inputString:gmatch("[^\r\n]+") do
                local x, y, z, wait = line:match("([%-%d%.]+)[,%s]+([%-%d%.]+)[,%s]+([%-%d%.]+)[%s%(]wait%s:")
                
                if not x then
                    x, y, z = line:match("([%-%d%.]+)[,%s]+([%-%d%.]+)[,%s]+([%-%d%.]+)")
                end
                
                if x and y and z then
                    table.insert(waypoints, {
                        position = Vector3.new(tonumber(x), tonumber(y), tonumber(z)),
                        waitTime = tonumber(wait) or 0
                    })
                end
            end
            
            if #waypoints > 0 then
                updateWaypointVisuals()
                success = true
            end
        end
    end
    
    return success
end

-- Function to generate random waypoints
local function generateRandomWaypoints()
    removeAllWaypoints()
    local basePos = root.Position
    local currentY = basePos.Y
    
    for i = 1, 20 do
        local randomOffset = Vector3.new(
            math.random(-50, 50),
            math.random(-10, 20),
            math.random(-50, 50)
        )
        
        local newPos = Vector3.new(
            basePos.X + randomOffset.X,
            basePos.Y + randomOffset.Y,
            basePos.Z + randomOffset.Z
        )
        
        table.insert(waypoints, {
            position = newPos,
            waitTime = 0
        })
    end
    
    updateWaypointVisuals()
    copyWaypoints()
    Library:Notify({ Title = "Waypoint System", Content = "Generated 20 random waypoints", Duration = 4 })
end

-- Function to auto spawn waypoints
local function toggleAutoSpawn(interval)
    if autoSpawnWaypoints and autoSpawnThread then
        coroutine.close(autoSpawnThread)
        autoSpawnThread = nil
    end
    
    if interval > 0 then
        autoSpawnWaypoints = true
        spawnInterval = interval
        autoSpawnThread = coroutine.create(function()
            while autoSpawnWaypoints do
                addWaypoint()
                task.wait(spawnInterval)
            end
        end)
        coroutine.resume(autoSpawnThread)
    else
        autoSpawnWaypoints = false
    end
end

local PlayerSection = Tabs.Main:Section("Player")

local wstoggle = PlayerSection:CreateToggle("wstoggle", { Title = "Walkspeed", Default = false })
local wsslider = PlayerSection:CreateSlider("wsslider", { Title = "Value", Min = 16, Max = 21, Rounding = 0, Default = 16 })
local hheighttoggle = PlayerSection:CreateToggle("hheighttoggle", { Title = "HipHeight", Default = false })
local hheightslider = PlayerSection:CreateSlider("hheightslider", { Title = "Value", Min = 2.0, Max = 6.5, Rounding = 1, Default = 2 })
local msatoggle = PlayerSection:CreateToggle("msatoggle", { Title = "MountainClimber", Default = false })

local CombatSection = Tabs.Combat:Section("Combat")
local HealSection = Tabs.Combat:Section("Eating")
local sectionStructure = Tabs.Farm:Section("Interactable Structure")
local PlantsSection = Tabs.Farm:Section("Plants")
local BuildSection = Tabs.Farm:Section("Building")
local MojoSection = Tabs.Farm:Section("Mojo")
local DropSection = Tabs.Item:Section("Item Drop")
local PickSection = Tabs.Item:Section("Item PickUp")
local ShopSection = Tabs.Item:Section("Shop")
local AutoHitSect = Tabs.Main:Section("AutoHits")

local killauratoggle = CombatSection:CreateToggle("killauratoggle", { Title = "Kill Aura", Default = false })
local resourceauratoggle = AutoHitSect:CreateToggle("resourceauratoggle", { Title = "Resource Aura", Default = false })
local BuidlingToggle = AutoHitSect:CreateToggle("BuidlingToggle", { Title = "Buildings Aura", Default = false })
local critterauratoggle = AutoHitSect:CreateToggle("critterauratoggle", { Title = "Critter Aura", Default = false })

local EatToggle = HealSection:AddToggle("EatToggle", { Title = "Auto Heal", Default = false })
local eatdropdown = HealSection:AddDropdown("eatdropdown", {Title = "Select Food", Values = {"Bloodfruit", "Bluefruit", "Lemon", "Coconut", "Jelly", "Banana", "Orange", "Oddberry", "Berry", "Strangefruit", "Strawberry", "Sunjfruit", "Pumpkin", "Prickly Pear", "Apple",  "Barley", "Cloudberry", "Carrot"}, Default = "Bloodfruit"})
local HealthCount = HealSection:CreateSlider("HealthCount", { Title = "Set Health", Min = 1, Max = 100, Rounding = 0, Default = 2 })
local EatPerSecond = HealSection:CreateSlider("EatPerSecond", { Title = "Eat Per Second", Min = 1, Max = 1000, Rounding = 0, Default = 1 })

local autopickuptoggle = PickSection:CreateToggle("autopickuptoggle", { Title = "Auto Pickup", Default = false })
local chestpickuptoggle = PickSection:CreateToggle("chestpickuptoggle", { Title = "Auto Pickup From Chests", Default = false })
local itemdropdown = PickSection:CreateDropdown("itemdropdown", {Title = "Auto Pickup Items", Values = {"Berry", "Bloodfruit", "Bluefruit", "Lemon", "Strawberry", "Gold", "Raw Gold", "Crystal Chunk", "Coin", "Coins", "Coin2", "Coin Stack", "Essence", "Emerald", "Raw Emerald", "Pink Diamond", "Raw Pink Diamond", "Void Shard","Jelly", "Magnetite", "Raw Magnetite", "Adurite", "Raw Adurite", "Ice Cube", "Stone", "Iron", "Raw Iron", "Steel", "Hide", "Leaves", "Log", "Wood", "Pie"}, Multi = true, Default = { Leaves = true, Log = true }})
local droptogglemanual = DropSection:AddToggle("droptogglemanual", { Title = "AutoDrop Item", Default = false })
local droptextbox = DropSection:AddInput("droptextbox", { Title = "Custom Item", Default = "Bloodfruit", Numeric = false, Finished = false })

local function itemtoid(name)
	local map = {
		["Gold"] = 597,
		["Crystal Chunk"] = 436,
		["Log"] = 320,
		["Wood"] = 1,
		["Leaves"] = 166,
		["Ice Cube"] = 183,
		["Stone"] = 336,
		["Obsidian"] = 306,
		["Cooked Meat"] = 643,
		["Bloodfruit"] = 94,
		["Berry"] = 35,
		["Bluefruit"] = 377,
		["Adurite"] = 418,
		["Steel"] = 174,
		["Iron"] = 177,
		["Lemon"] = 99,
		["Jelly"] = 604,
		["Hide"] = 345,
		["Fire Hide"] = 324
	}
	return map[name]
end

local shopItemDropdown = ShopSection:CreateDropdown("ShopItemDropdown", {
	Title = "Shop Item",
	Values = {"Gold","Crystal Chunk","Log","Wood","Leaves","Ice Cube","Stone","Obsidian","Cooked Meat","Bloodfruit","Berry","Bluefruit","Adurite","Steel","Iron","Lemon","Jelly","Hide","Fire Hide"},
	Default = "Bloodfruit"
})
local shopQuantityInput = ShopSection:AddInput("ShopQuantity", { Title = "Quantity (X)", Default = "1", Numeric = true, Finished = false })
ShopSection:CreateButton({Title = "Buy Item", Callback = function()
	local itemName = Options.ShopItemDropdown.Value
	local qtyStr = tostring(Options.ShopQuantity.Value or "1")
	local qtyNum = tonumber(qtyStr) or 1
	qtyNum = math.clamp(qtyNum, 1, 9999)
	local id = itemtoid(itemName)
	if id and packets.PurchaseFromShop and packets.PurchaseFromShop.send then
		for i = 1, qtyNum do
			packets.PurchaseFromShop.send(id)
			task.wait(0.05)
		end
	else
		Library:Notify({ Title = "AmethystHub", Content = "Invalid shop item selected.", Duration = 4 })
	end
end})

local fruitdropdown = PlantsSection:CreateDropdown("fruitdropdown", {Title = "Select Fruit",Values = {"Bloodfruit", "Bluefruit", "Lemon", "Coconut", "Jelly", "Banana", "Orange", "Oddberry", "Berry", "Strangefruit", "Strawberry", "Sunjfruit", "Pumpkin", "Prickly Pear", "Apple",  "Barley", "Cloudberry", "Carrot"}, Default = "Bloodfruit"})
local planttoggle = PlantsSection:CreateToggle("planttoggle", { Title = "Auto Plant", Default = false })

-- Новые слайдеры для Auto Plant
local plantDelaySlider = PlantsSection:CreateSlider("plantDelaySlider", {
    Title = "Plant Delay",
    Description = "Задержка между посадками (секунды)",
    Min = 0.001,
    Max = 1,
    Default = 0.1,
    Rounding = 3
})

local plantRangeSlider = PlantsSection:CreateSlider("plantRangeSlider", {
    Title = "Plant Range",
    Description = "Радиус поиска plant box (1-50)",
    Min = 1,
    Max = 50,
    Default = 30,
    Rounding = 1
})

local AutoCamFire = sectionStructure:CreateToggle("AutoCamFire", { Title = "Auto Camp Fire", Default = false })
local ItemsToCamp = sectionStructure:CreateDropdown("ItemsToCamp", {Title = "Select Items To Campfire",Values = {"Log",'Leaves', 'Wood', 'Coal'}, Default = "Wood"})
local harvesttoggle = PlantsSection:CreateToggle("harvesttoggle", { Title = "Auto Harvest", Default = false })
-- Advanced Tween Toggles
local tweenplantboxtoggle = PlantsSection:AddToggle("tweentoplantbox", { 
    Title = "Advanced Tween to Plant Box", 
    Default = false 
})
local tweenbushtoggle = PlantsSection:AddToggle("tweentobush", { 
    Title = "Advanced Tween to Plant Box and Bushes", 
    Default = false 
})

-- Sliders для Advanced Tween
local tweenSpeedSlider = PlantsSection:CreateSlider("tweenSpeedSlider", {
    Title = "Tween Speed",
    Description = "Скорость движения (студий/сек)",
    Min = 5,
    Max = 32,
    Default = 16,
    Rounding = 1
})

local tweenRangeSlider = PlantsSection:CreateSlider("tweenRangeSlider", {
    Title = "Tween Range",
    Description = "Максимальная дистанция поиска",
    Min = 10,
    Max = 500,
    Default = 250,
    Rounding = 1
})
local GridSize = BuildSection:AddInput("GridSize", { Title = "Grid size", Default = "5", Numeric = true, Finished = false })
MojoSection:CreateButton({Title = "AutoExpFarm (Mojo)", Callback = function()
	Window:Dialog({
		Title = "AutoExpFarm (Mojo)",
		Content = "Put GodAxe on slot 2\nMUST BE IN LOADING SCREEN\nMust have coins (250 per mojo)\nPut bed on flying island 2",
		Buttons = {
			{
				Title = "Confirm",
				Callback = function()
					local url = "https://pastebin.com/raw/Pkzkzphj"
					local ok, err = pcall(function()
						loadstring(game:HttpGet(url, true))()
					end)
					if not ok then
						Library:Notify({ Title = "AmethystHub", Content = "Failed to load AutoExpFarm: " .. tostring(err), Duration = 6 })
					end
				end
			},
			{
				Title = "Cancel",
				Callback = function()
					Library:Notify({ Title = "AmethystHub", Content = "AutoExpFarm cancelled.", Duration = 3 })
				end
			}
		}
	})
end })
BuildSection:CreateButton({Title = "Create Waypoints", Callback = function() waypointsforbuild() end })

BuildSection:CreateButton({Title = "Place Plantboxes", Callback = function() placestructure() end })

local function swingtool(entityid)
    if packets.SwingTool and packets.SwingTool.send then
        packets.SwingTool.send(entityid)
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://10761451679"
        Track = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid"):LoadAnimation(animation)
        Track:Play()
    end
end

local function pickup(entityid)
    if packets.Pickup and packets.Pickup.send then
        packets.Pickup.send(entityid)
    end
end

local function createPathWithCharacter()
    local character = plr.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return nil end
    
    local agentHeight = 5.5
    local agentRadius = 1.7
    
    local rootSize = rootPart.Size
    local hipHeight = humanoid.HipHeight or 2
    
    if rootSize.Y > 1 and rootSize.Y < 4 and hipHeight > 1 and hipHeight < 4 then
        agentHeight = rootSize.Y + hipHeight + 1.5
        agentRadius = math.max(rootSize.X, rootSize.Z) / 2 + 0.1
    end
    
    agentHeight = math.clamp(agentHeight, 4.5, 5)
    agentRadius = math.clamp(agentRadius, 1.7, 2)
    
    return PS:CreatePath({
        AgentCanJump = true,
        WaypointSpacing = 2,
        AgentRadius = agentRadius,
        AgentHeight = agentHeight,
        AgentCanClimb = true,
        Costs = {
            Jump = 1.5
        }
    })
end

local Path = createPathWithCharacter() or PS:CreatePath({
    AgentCanJump = true,
    WaypointSpacing = 2,
    AgentRadius = 1.7,
    AgentHeight = 4.7,
    AgentCanClimb = true,
    Costs = {
            Jump = 1.5
    }
})

if not workspace:FindFirstChild("PathVisualization") then
    local pathFolder = Instance.new("Folder")
    pathFolder.Name = "PathVisualization"
    pathFolder.Parent = workspace
end

local currentTweenWaypointIndex = 1
local isMovingTween = false

local function clearPathVisualization()
    for _, part in ipairs(workspace.PathVisualization:GetChildren()) do
        if part:IsA("Part") then
            part:Destroy()
        end
    end
end

local function createPathDot(position)
    local dot = Instance.new("Part")
    dot.Name = "PathDot"
    dot.Size = Vector3.new(0.3, 0.3, 0.3)
    dot.Position = position
    dot.Anchored = true
    dot.CanCollide = false
    dot.Material = Enum.Material.Neon
    dot.Color = Color3.fromRGB(0, 150, 255)
    dot.Shape = Enum.PartType.Ball
    dot.Transparency = 0.3
    dot.Parent = workspace.PathVisualization
    
    game:GetService("Debris"):AddItem(dot, 5)
    return dot
end

local function shouldJump(fromPosition, toPosition, character)
    if not character then return false end
    
    local heightDiff = toPosition.Y - fromPosition.Y
    if heightDiff > 0.01 then
        return true
    end
    
    local ignoreList = {character}
    if character:IsA("Model") then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(ignoreList, part)
            end
        end
    end
    
    local direction = (toPosition - fromPosition)
    local distance = direction.Magnitude
    if distance < 0.1 then return false end
    direction = direction.Unit
    
    for _, height in ipairs({1, 1.5, 2, 2.5}) do
        local rayOrigin = fromPosition + Vector3.new(0, height, 0)
        local checkDist = math.min(distance, 4)
        local ray = Ray.new(rayOrigin, direction * checkDist)
        local hitPart, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
        
        if hitPart and hitPart.CanCollide and hitPos then
            local obstacleHeight = hitPos.Y - fromPosition.Y
            local hitDistance = (hitPos - rayOrigin).Magnitude
            
            if obstacleHeight > 0.1 and hitDistance < 4 then
                return true
            end
        end
    end
    
    return false
end


local selecteditems = {}
itemdropdown:OnChanged(function(Value)
    selecteditems = {} 
    for item, State in pairs(Value) do
        if State then
            table.insert(selecteditems, item)
        end
    end
end)

-- Kill Aura Target Selection System
local targetSelection = CombatSection:AddDropdown("TargetSelection", {
    Title = "Target Selection",
    Description = "Choose who to attack",
    Values = {"All", "Nearest", "Furthest"},
    Default = "All"
})

-- Dynamic player list dropdown (обновляется автоматически)
local playerTargetDropdown = CombatSection:AddDropdown("PlayerTargetDropdown", {
    Title = "Specific Players",
    Description = "Select players to target (when 'All' is disabled)",
    Values = {}, -- будет заполнено динамически
    Multi = true,
    Default = {}
})

-- Функция для обновления списка игроков
local function updatePlayerList()
    local players = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= plr then
            table.insert(players, player.Name)
        end
    end
    table.sort(players)
    playerTargetDropdown:SetValues(players)
end

-- Обновляем список при заходе/выходе игроков
game:GetService("Players").PlayerAdded:Connect(updatePlayerList)
game:GetService("Players").PlayerRemoving:Connect(updatePlayerList)
task.spawn(updatePlayerList) -- первоначальное заполнение

-- Toggle для включения/выключения фильтрации по выбранным игрокам
local useTargetFilter = CombatSection:AddToggle("UseTargetFilter", {
    Title = "Use Specific Players Only",
    Description = "If disabled, attacks all players based on selection mode",
    Default = false
})

-- Улучшенная Kill Aura
task.spawn(function()
    local function getTargetPlayers()
        local targets = {}
        local players = game:GetService("Players"):GetPlayers()
        
        -- Если включена фильтрация по конкретным игрокам
        if Options.UseTargetFilter.Value then
            local selectedPlayers = Options.PlayerTargetDropdown.Value or {}
            for playerName, selected in pairs(selectedPlayers) do
                if selected then
                    local player = game:GetService("Players"):FindFirstChild(playerName)
                    if player and player ~= plr then
                        table.insert(targets, player)
                    end
                end
            end
        else
            -- Иначе берем всех игроков
            for _, player in ipairs(players) do
                if player ~= plr then
                    table.insert(targets, player)
                end
            end
        end
        
        return targets
    end

    while true do
        if not Options.killauratoggle.Value then
            task.wait(0.1)
            continue
        end

        local range = 20
        local targetcount = 1
        local cooldown = 0.1
        local targets = {}
        
        local potentialTargets = getTargetPlayers()
        local selectionMode = Options.TargetSelection.Value

        for _, player in ipairs(potentialTargets) do
            local playerfolder = workspace.Players:FindFirstChild(player.Name)
            if playerfolder then
                local rootpart = playerfolder:FindFirstChild("HumanoidRootPart")
                local entityid = playerfolder:GetAttribute("EntityID")

                if rootpart and entityid then
                    local dist = (rootpart.Position - root.Position).Magnitude
                    if dist <= range then
                        table.insert(targets, { 
                            eid = entityid, 
                            dist = dist,
                            player = player
                        })
                    end
                end
            end
        end

        if #targets > 0 then
            -- Сортировка в зависимости от режима
            if selectionMode == "Nearest" then
                table.sort(targets, function(a, b)
                    return a.dist < b.dist
                end)
            elseif selectionMode == "Furthest" then
                table.sort(targets, function(a, b)
                    return a.dist > b.dist
                end)
            end
            -- Для "All" оставляем как есть (без сортировки)

            local selectedtargets = {}
            for i = 1, math.min(targetcount, #targets) do
                table.insert(selectedtargets, targets[i].eid)
            end
            
            swingtool(selectedtargets)
        end

        task.wait(cooldown)
    end
end)

task.spawn(function()
        while true do
            if not Options.resourceauratoggle.Value then
                task.wait(0.1)
                continue
            end

            local range = 20
            local targetcount = 6
            local cooldown = 0.1
            local targets = {}

            for _, res in pairs(workspace.Resources:GetChildren()) do
                if res:IsA("Model") and res:GetAttribute("EntityID") then
                    local eid = res:GetAttribute("EntityID")
                    local ppart = res.PrimaryPart or res:FindFirstChildWhichIsA("BasePart")

                    if ppart then
                        local dist = (ppart.Position - root.Position).Magnitude
                        if dist <= range then
                            table.insert(targets, { eid = eid, dist = dist })
                        end
                    end
                end
            end

            if #targets > 0 then
                table.sort(targets, function(a, b)
                    return a.dist < b.dist
                end)

                local selectedtargets = {}
                for i = 1, math.min(targetcount, #targets) do
                    table.insert(selectedtargets, targets[i].eid)
                end
        
                swingtool(selectedtargets)
            end

            task.wait(cooldown)
        end
    end)

    task.spawn(function()
        while true do
            if not Options.BuidlingToggle.Value then
                task.wait(0.1)
                continue
            end

            local range = 20
            local targetcount = 6
            local cooldown = 0.1
            local targets = {}

            local allDeployables = {}
            for _, res in pairs(workspace.Deployables:GetChildren()) do
                table.insert(allDeployables, res)
            end
            if workspace:FindFirstChild("Rubble") then
                for _, res in pairs(workspace.Rubble:GetChildren()) do
                    table.insert(allDeployables, res)
                end
            end
            if workspace:FindFirstChild("Totems") then
                for _, res in pairs(workspace.Totems:GetChildren()) do
                    table.insert(allDeployables, res)
                end
            end
            if workspace:FindFirstChild("ScavengerMounds") then
                for _, res in pairs(workspace.ScavengerMounds:GetChildren()) do
                    table.insert(allDeployables, res)
                end
            end
            for _, res in pairs(allDeployables) do
                if res:IsA("Model") and res:GetAttribute("EntityID") then
                    local eid = res:GetAttribute("EntityID")
                    local ppart = res.PrimaryPart or res:FindFirstChildWhichIsA("BasePart")

                    if ppart then
                        local dist = (ppart.Position - root.Position).Magnitude
                        if dist <= range then
                            table.insert(targets, { eid = eid, dist = dist })
                        end
                    end
                end
            end

            if #targets > 0 then
                table.sort(targets, function(a, b)
                    return a.dist < b.dist
                end)

                local selectedtargets = {}
                for i = 1, math.min(targetcount, #targets) do
                    table.insert(selectedtargets, targets[i].eid)
                end
        
                swingtool(selectedtargets)
            end

            task.wait(cooldown)
        end
    end)

task.spawn(function()
    while true do
        if not Options.critterauratoggle.Value then
            task.wait(0.1)
            continue
        end

        local range = 20
        local targetcount = 3
        local cooldown = 0.1
        local targets = {}

        for _, critter in pairs(workspace.Critters:GetChildren()) do
            if critter:IsA("Model") and critter:GetAttribute("EntityID") then
                local eid = critter:GetAttribute("EntityID")
                local ppart = critter.PrimaryPart or critter:FindFirstChildWhichIsA("BasePart")

                if ppart then
                    local dist = (ppart.Position - root.Position).Magnitude
                    if dist <= range then
                        table.insert(targets, { eid = eid, dist = dist })
                    end
                end
            end
        end

        if #targets > 0 then
            table.sort(targets, function(a, b)
                return a.dist < b.dist
            end)

            local selectedtargets = {}
            for i = 1, math.min(targetcount, #targets) do
                table.insert(selectedtargets, targets[i].eid)
            end
   
            swingtool(selectedtargets)
        end

        task.wait(cooldown)
    end
end)

task.spawn(function()
    while true do
        local range =35

        if Options.autopickuptoggle.Value then
            for _, item in ipairs(workspace.Items:GetChildren()) do
                if item:IsA("BasePart") or item:IsA("MeshPart") then
                    local selecteditem = item.Name
                    local entityid = item:GetAttribute("EntityID")

                    if entityid and table.find(selecteditems, selecteditem) then
                        local dist = (item.Position - root.Position).Magnitude
                        if dist <= range then
                            pickup(entityid)
                        end
                    end
                end
            end
        end

        if Options.chestpickuptoggle.Value then
            for _, chest in ipairs(workspace.Deployables:GetChildren()) do
                if chest:IsA("Model") and chest:FindFirstChild("Contents") then
                    for _, item in ipairs(chest.Contents:GetChildren()) do
                        if item:IsA("BasePart") or item:IsA("MeshPart") then
                            local selecteditem = item.Name
                            local entityid = item:GetAttribute("EntityID")

                            if entityid and table.find(selecteditems, selecteditem) then
                                local dist = (chest.PrimaryPart.Position - root.Position).Magnitude
                                if dist <= range then
                                    pickup(entityid)
                                end
                            end
                        end
                    end
                end
            end
        end

        task.wait(0.01)
    end
end)

local function getlayout(itemname)
    local inventory = plr.PlayerGui.MainGui.RightPanel.Inventory.List
    for _, child in ipairs(inventory:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name == itemname then
            print(child.LayoutOrder)
            return child.LayoutOrder
        end
    end
    return nil
end


local function drop(itemname)
    local layout = getlayout(itemname)
    if layout then
        if packets.DropBagItem and packets.DropBagItem.send then
            packets.DropBagItem.send(layout)
        end
    end
end



local function useItem(itemname)
    local layout = getlayout(itemname)
    if layout then
        if packets.UseBagItem and packets.UseBagItem.send then
            packets.UseBagItem.send(layout)
        end
    end
end

-- Auto Eat с настраиваемой скоростью (это уже есть в вашем коде)
task.spawn(function()
    local lastEatTime = 0
    
    while true do
        if Options.EatToggle.Value then
            local currentTime = tick()
            local eatInterval = 1 / (Options.EatPerSecond.Value or 1)
            
            if currentTime - lastEatTime >= eatInterval then
                if game:GetService('Players').LocalPlayer.Character.Humanoid.Health <= Options.HealthCount.Value then
                    local selectedItem = Options.eatdropdown.Value
                    useItem(selectedItem)
                    lastEatTime = currentTime
                end
            end
        end
        task.wait(0.01)
    end
end)




runs.Heartbeat:Connect(function()
    if Options.droptogglemanual.Value then
        local itemname = Options.droptextbox.Value
        drop(itemname)
    end
end)



local plantedboxes = {}

local itemtouseID = {
    Gold = 597,
    Wood = 1,
    Coal = 178,
    Leaves = 166,
    Log = 320

}

local fruittoitemid = {
    Bloodfruit = 94,
    Bluefruit = 377,
    Lemon = 99,
    Coconut = 1,
    Jelly = 604,
    Banana = 606,
    Orange = 602,
    Oddberry = 32,
    Berry = 35,
    Strangefruit = 302,
    Strawberry = 282,
    Sunfruit = 128,
    Pumpkin = 80,
    ["Prickly Pear"] = 378,
    Apple = 243,
    Barley = 247,
    Cloudberry = 101,
    Carrot = 147
}

local function plant(entityid, itemID)
    if packets.InteractStructure and packets.InteractStructure.send then
        packets.InteractStructure.send({ entityID = entityid, itemID = itemID })
        plantedboxes[entityid] = true
    end
end


local function UseCampFire(entityid, itemID)
    if packets.InteractStructure and packets.InteractStructure.send then
        packets.InteractStructure.send({ entityID = entityid, itemID = itemID })
        
    end
end

local function getpbs(range)
    local plantboxes = {}
    for _, deployable in ipairs(workspace.Deployables:GetChildren()) do
        if deployable:IsA("Model") and deployable.Name == "Plant Box" then
            local entityid = deployable:GetAttribute("EntityID")
            local ppart = deployable.PrimaryPart or deployable:FindFirstChildWhichIsA("BasePart")
            if entityid and ppart then
                local dist = (ppart.Position - root.Position).Magnitude
                if dist <= range then
                    table.insert(plantboxes, { entityid = entityid, deployable = deployable, dist = dist })
                end
            end
        end
    end
    return plantboxes
end



local function getCamps(range)
    local Camps = {}
    for _, deployable in ipairs(workspace.Deployables:GetChildren()) do
        if deployable:IsA("Model") and deployable.Name == 'Campfire' and deployable:FindFirstChild("Effect"):FindFirstChild('PointLight').Enabled == false then
            local entityid = deployable:GetAttribute("EntityID")
            local ppart = deployable.PrimaryPart or deployable:FindFirstChildWhichIsA("BasePart")
            print(deployable)
            if entityid and ppart then
                local dist = (ppart.Position - root.Position).Magnitude
                if dist <= range then
                    table.insert(Camps, { entityid = entityid, deployable = deployable, dist = dist })
                    print(deployable)
                  
                end
            end
        end
    end
    return Camps
end

local function getbushes(range, fruitname)
    local bushes = {}
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:find(fruitname) then
            local ppart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if ppart then
                local dist = (ppart.Position - root.Position).Magnitude
                if dist <= range then
                    local entityid = model:GetAttribute("EntityID")
                    if entityid then
                        table.insert(bushes, { entityid = entityid, model = model, dist = dist })
                    end
                end
            end
        end
    end
    return bushes
end



local tweening = nil
local function tween(target)
    if tweening then tweening:Cancel() end
    local distance = (root.Position - target.Position).Magnitude
    local duration = distance / 21
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = tspmo:Create(root, tweenInfo, { CFrame = target })
    tween:Play()
    
    tweening = tween
end



-- ===== НОВЫЙ ADVANCED TWEEN =====
local function getTargetForTween(mode)
    local range = Options.tweenRangeSlider.Value or 250
    local selectedfruit = Options.fruitdropdown.Value
    
    -- Получаем кусты
    local bushes = getbushes(range, selectedfruit)
    for _, bush in ipairs(bushes) do
        bush.type = "bush"
        bush.part = bush.model.PrimaryPart or bush.model:FindFirstChildWhichIsA("BasePart")
    end
    
    -- Получаем plant boxes
    local plantboxes = getpbs(range)
    local availablePlantBoxes = {}
    for _, box in ipairs(plantboxes) do
        if not box.deployable:FindFirstChild("Seed") then
            box.type = "plantbox"
            box.part = box.deployable.PrimaryPart or box.deployable:FindFirstChildWhichIsA("BasePart")
            table.insert(availablePlantBoxes, box)
        end
    end
    
    -- Сортируем по расстоянию
    for _, list in ipairs({bushes, availablePlantBoxes}) do
        table.sort(list, function(a, b) return a.dist < b.dist end)
    end
    
    -- Выбираем цель в зависимости от режима
    if mode == "plantbox" then
        return availablePlantBoxes[1]
    elseif mode == "both" then
        if #bushes > 0 then
            return bushes[1]
        elseif #availablePlantBoxes > 0 then
            return availablePlantBoxes[1]
        end
    end
    
    return nil
end

local function startAdvancedTween(mode)
    -- Останавливаем предыдущий твин если был
    stopAdvancedTween()
    
    -- Сохраняем начальную высоту - она больше НИКОГДА не изменится!
    startHeight = root.Position.Y
    local lookVector = root.CFrame.LookVector
    startDirection = CFrame.lookAt(Vector3.new(0,0,0), Vector3.new(lookVector.X, 0, lookVector.Z).Unit)
    
    -- Включаем антигравитацию (ОСТАВЛЯЕМ!)
    enableAntiGravity()
    enableNoclip()
    
    local lastTargetCheck = 0
    local currentTarget = nil
    local targetPos = nil
    
    -- Главный цикл движения
    moveConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        if not (tweenplantboxtoggle.Value or tweenbushtoggle.Value) then
            stopAdvancedTween()
            return
        end
        
        local currentTime = tick()
        local speed = Options.tweenSpeedSlider.Value or 16
        
        -- Обновляем цель раз в 0.2 секунды
        if currentTime - lastTargetCheck > 0.2 then
            lastTargetCheck = currentTime
            currentTarget = getTargetForTween(mode)
            
            if currentTarget and currentTarget.part then
                -- ФИКСИРУЕМ ВЫСОТУ НАВСЕГДА!
                -- Берем X и Z от цели, НО ВЫСОТА ВСЕГДА startHeight
                targetPos = Vector3.new(
                    currentTarget.part.Position.X,
                    startHeight,  -- ВСЕГДА ОДНА И ТА ЖЕ ВЫСОТА!
                    currentTarget.part.Position.Z
                )
            end
        end
        
        -- Движение к цели
        if currentTarget and targetPos and root then
            local currentPos = root.Position
            local direction = (targetPos - currentPos).Unit
            local distanceToTarget = (targetPos - currentPos).Magnitude
            
            local moveDistance = speed * deltaTime
            
            if moveDistance >= distanceToTarget then
                -- Достигли цели
                root.CFrame = CFrame.lookAt(targetPos, targetPos + startDirection.LookVector)
            else
                -- Двигаемся к цели, но ВЫСОТА ВСЕГДА ОДИНАКОВАЯ
                local newPos = currentPos + direction * moveDistance
                -- Принудительно фиксируем высоту еще раз (на всякий случай)
                newPos = Vector3.new(newPos.X, startHeight, newPos.Z)
                root.CFrame = CFrame.lookAt(newPos, newPos + startDirection.LookVector)
            end
            
            -- Антигравитация уже работает через enableAntiGravity(),
            -- поэтому дополнительно фиксируем вертикальную скорость
            root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
        end
    end)
end

-- Обработчики для тогглов
tweenplantboxtoggle:OnChanged(function()
    if tweenplantboxtoggle.Value then
        tweenbushtoggle:SetValue(false) -- Выключаем другой режим
        task.spawn(function() startAdvancedTween("plantbox") end)
    else
        if not tweenbushtoggle.Value then
            stopAdvancedTween()
        end
    end
end)

tweenbushtoggle:OnChanged(function()
    if tweenbushtoggle.Value then
        tweenplantboxtoggle:SetValue(false) -- Выключаем другой режим
        task.spawn(function() startAdvancedTween("both") end)
    else
        if not tweenplantboxtoggle.Value then
            stopAdvancedTween()
        end
    end
end)

-- Обработчик смены персонажа
player.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.5)
    char = newCharacter
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    stopAdvancedTween()
end)

-- ===== КОНЕЦ НОВОГО ADVANCED TWEEN =====



task.spawn(function()
    while true do
        if not Options.AutoCamFire.Value then
           task.wait(0.1)
           continue
        end
    
    local selectedItemCamp = Options.ItemsToCamp.Value
    local itemID = itemtouseID[selectedItemCamp] or 1
    local range = 50
    local CampFires = getCamps(range)
    print(Options.ItemsToCamp.Value)
    print(itemtouseID[selectedItemCamp])
    for _, Press in ipairs(CampFires) do
    UseCampFire(Press.entityid, itemID)
   end

task.wait(0.1)
end
end)

task.spawn(function()
    while true do
        if not Options.planttoggle.Value then
            task.wait(0.1)
            continue
        end

        -- Используем значения из слайдеров
        local range = Options.plantRangeSlider.Value or 30
        local delay = Options.plantDelaySlider.Value or 0.1
        local selectedfruit = Options.fruitdropdown.Value
        local itemID = fruittoitemid[selectedfruit] or 94
        
        -- Получаем plant boxes в радиусе
        local plantboxes = getpbs(range)
        table.sort(plantboxes, function(a, b) return a.dist < b.dist end)

        for _, box in ipairs(plantboxes) do
            if not box.deployable:FindFirstChild("Seed") then
                plant(box.entityid, itemID)
                -- Небольшая задержка после посадки
                task.wait(delay)
            else
                plantedboxes[box.entityid] = true
            end
        end
        
        -- Ждем перед следующим циклом
        task.wait(delay)
    end
end)

task.spawn(function()
    while true do
        if not Options.harvesttoggle.Value then
            task.wait(0.1)
            continue
        end
        local harvestrange = 30
        local selectedfruit = Options.fruitdropdown.Value
        local bushes = getbushes(harvestrange, selectedfruit)
        table.sort(bushes, function(a, b) return a.dist < b.dist end)
        for _, bush in ipairs(bushes) do
            pickup(bush.entityid)
        end
        task.wait(0.1)
    end
end)



task.spawn(function()
    while true do
        if not tweenbushtoggle.Value then
            task.wait(0.1)
            continue
        end
        local range = 200
        local selectedfruit = Options.fruitdropdown.Value
        tweenpbs(range, selectedfruit)
    end
end)

waypointsforbuild = function()
    if not plr or not plr.Character then return end
    local torso = plr.Character:FindFirstChild("HumanoidRootPart")
    if not torso then return end


    if game.workspace:FindFirstChild("BuildDotsFolder") then
    for _, waypoint in ipairs(game.workspace:FindFirstChild("BuildDotsFolder"):GetChildren())  do
    waypoint:Remove()
    end
    end 
    task.wait(0.1)
    local startpos = torso.Position
    local spacing = 6.05
    local gridSize = tonumber(Options.GridSize.Value) or 5
    if gridSize < 1 then gridSize = 5 end

    for x = 0, gridSize - 1 do
        for z = 0, gridSize - 1 do
            local position = startpos + Vector3.new(x * spacing, 0, z * spacing)
            local wpbuild = Instance.new('Part')
            wpbuild.Parent = game.workspace:FindFirstChild("BuildDotsFolder")
            wpbuild.Position = position
            wpbuild.Size = Vector3.new(0.5, 0.5, 0.5)
            wpbuild.Material = Enum.Material.Neon
            wpbuild.Anchored = true
            wpbuild.CanCollide = false
            print(wpbuild.position)
        end
    end
end

placestructure = function()
    if not plr or not plr.Character then return end
    local torso = plr.Character:FindFirstChild("HumanoidRootPart")
    local hum = plr.Character:FindFirstChild("Humanoid")
    if not hum then return end



    for _, waypoint in ipairs(game.workspace:FindFirstChild("BuildDotsFolder"):GetChildren())  do
        local startpos = waypoint.Position - Vector3.new(0, 3, 0)
        local position = startpos 
            hum:MoveTo(waypoint.Position)
            


            hum.MoveToFinished:Connect(function()
            if packets.PlaceStructure and packets.PlaceStructure.send then
                
                packets.PlaceStructure.send{
                    ["buildingName"] = "Plant Box",
                    ["yrot"] = 45,
                    ["vec"] = position,
                    ["isMobile"] = false
                }
                
            end
        end)
        hum.MoveToFinished:Wait()
    end
end

local wscon, hhcon
local walkAnimTrack, idleAnimTrack

local function updws()
    if wscon then wscon:Disconnect() end

    if Options.wstoggle.Value then
        wscon = runs.RenderStepped:Connect(function()
            if hum then
                hum.WalkSpeed = Options.wstoggle.Value and Options.wsslider.Value or 16
            end
        end)
    end
end

local function updhh()
    if hhcon then hhcon:Disconnect() end

    if Options.hheighttoggle.Value then
        hhcon = runs.RenderStepped:Connect(function()
            if hum then
                hum.HipHeight = Options.hheightslider.Value
            end
        end)
    end
end

local function onplradded(newChar)
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")

    updws()
    updhh()
end

plr.CharacterAdded:Connect(onplradded)

plr.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    if isMovingTween and Options.strttween.Value then
        Path = createPathWithCharacter() or Path
    end
end)

Options.wstoggle:OnChanged(updws)
Options.hheighttoggle:OnChanged(updhh)

local slopecon
local function updmsa()
    if slopecon then slopecon:Disconnect() end

    if Options.msatoggle.Value then
        slopecon = game:GetService("RunService").RenderStepped:Connect(function()
            if hum then
                hum.MaxSlopeAngle = 90
            end
        end)
    else
        if hum then
            hum.MaxSlopeAngle = 46
        end
    end
end

Options.msatoggle:OnChanged(updmsa)

-- Keybinds Section (СОЗДАЕМ KEYBIND'Ы)
local eatKeybind = HealSection:AddKeybind("EatKeybind", {
    Title = "Toggle Auto Eat",
    Mode = "Toggle",
    Key = Enum.KeyCode.E,
    HoldCtrl = false,
    HoldAlt = false,
    HoldShift = false
})

local killauraKeybind = CombatSection:AddKeybind("KillauraKeybind", {
    Title = "Toggle Kill Aura", 
    Mode = "Toggle",
    Key = Enum.KeyCode.K,
    HoldCtrl = false,
    HoldAlt = false,
    HoldShift = false
})

local modeKeybind = CombatSection:AddKeybind("ModeKeybind", {
    Title = "Cycle Target Mode",
    Mode = "Toggle",
    Key = Enum.KeyCode.M,
    HoldCtrl = false,
    HoldAlt = false,
    HoldShift = false
})

-- Keybind Handlers (ТЕПЕРЬ ДОБАВЛЯЕМ ОБРАБОТЧИКИ)
eatKeybind:OnClick(function()
    Options.EatToggle:SetValue(not Options.EatToggle.Value)
    Library:Notify({
        Title = "Keybind",
        Content = "Auto Eat: " .. (Options.EatToggle.Value and "ON" or "OFF"),
        Duration = 2
    })
end)

killauraKeybind:OnClick(function()
    Options.killauratoggle:SetValue(not Options.killauratoggle.Value)
    Library:Notify({
        Title = "Keybind",
        Content = "Kill Aura: " .. (Options.killauratoggle.Value and "ON" or "OFF"),
        Duration = 2
    })
end)

modeKeybind:OnClick(function()
    if not Options.killauratoggle.Value then 
        Library:Notify({
            Title = "Target Mode",
            Content = "Kill Aura is OFF!",
            Duration = 2
        })
        return 
    end
    
    local modes = {"All", "Nearest", "Furthest"}
    local currentMode = Options.TargetSelection.Value
    local currentIndex = 0
    
    for i, mode in ipairs(modes) do
        if mode == currentMode then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #modes) + 1
    Options.TargetSelection:SetValue(modes[nextIndex])
    
    Library:Notify({
        Title = "Target Mode",
        Content = "Switched to: " .. modes[nextIndex],
        Duration = 2
    })
end)

-- Create UI Sections

-- Waypoint Management Section
local WaypointManagement = Tabs.Maain:Section("Waypoint Management")

local manageWaypointInput = WaypointManagement:AddInput("ManageWaypointInput", {
    Title = "Waypoint Number to Manage",
    Default = "",
    Placeholder = "Enter waypoint number...",
    Numeric = true,
    Finished = false
})

WaypointManagement:AddButton({
    Title = "Manage Waypoint",
    Callback = function()
        local index = tonumber(Options.ManageWaypointInput.Value)
        if index then
            manageWaypoint(index)
        else
            Library:Notify({ Title = "Waypoint System", Content = "Enter a valid waypoint number!", Duration = 4 })
        end
    end
})

WaypointManagement:AddButton({
    Title = "Unmanage Waypoint",
    Callback = function()
        unmanageWaypoint()
    end
})

-- Waypoint Controls Section
local WaypointControls = Tabs.Maain:Section("Waypoint Controls")

WaypointControls:AddButton({
    Title = "Add Waypoint at Current Position",
    Callback = function()
        local result = addWaypointWithManagement()
        if result == "replaced" then
            Library:Notify({ Title = "Waypoint System", Content = "Managed waypoint replaced!", Duration = 4 })
        else
            Library:Notify({ Title = "Waypoint System", Content = "New waypoint added!", Duration = 4 })
        end
    end
})

WaypointControls:AddButton({
    Title = "Remove All Waypoints",
    Callback = function()
        removeAllWaypoints()
    end
})

WaypointControls:AddButton({
    Title = "Remove Last Waypoint",
    Callback = function()
        removeLastWaypoint()
    end
})

WaypointControls:AddButton({
    Title = "Generate 20 Random Waypoints",
    Callback = function()
        generateRandomWaypoints()
    end
})

-- Auto Tween Section
local AutoTween = Tabs.Maain:Section("Auto Tween")

local autoWalkToggle = AutoTween:AddToggle("AutoWalkToggle", {
    Title = "Auto Tween",
    Default = false
})

autoWalkToggle:OnChanged(function()
    if Options.AutoWalkToggle.Value then
        startAutoWalk()
    else
        stopAutoWalk()
    end
end)

AutoTween:AddSlider("TweenSpeed", {
    Title = "Tween Speed",
    Min = 10,
    Max = 32,
    Default = 20,
    Rounding = 0
})

Options.TweenSpeed:OnChanged(function()
    tweenSpeed = Options.TweenSpeed.Value
end)

-- Wait System Section
local WaitSystem = Tabs.Maain:Section("Wait System")

local waypointIndexInput = WaitSystem:AddInput("WaypointIndexInput", {
    Title = "Waypoint Number",
    Default = "1",
    Placeholder = "Enter waypoint number...",
    Numeric = true,
    Finished = false
})

local waitTimeInput = WaitSystem:AddInput("WaitTimeInput", {
    Title = "Wait Time (seconds)",
    Default = "0",
    Placeholder = "Enter wait time...",
    Numeric = true,
    Finished = false
})

WaitSystem:AddButton({
    Title = "Set Wait Time",
    Callback = function()
        local index = tonumber(Options.WaypointIndexInput.Value)
        local waitTime = tonumber(Options.WaitTimeInput.Value)
        if index and waitTime then
            setWaitTime(index, waitTime)
        end
    end
})

-- Copy/Paste System Section
local CopyPaste = Tabs.Maain:Section("Copy/Paste System")

local waypointDataInput = CopyPaste:AddInput("WaypointDataInput", {
    Title = "Waypoint Data",
    Default = "",
    Placeholder = "Paste waypoint data here...",
    Numeric = false,
    Finished = false,
    MultiLine = true
})

CopyPaste:AddButton({
    Title = "📋 Copy All Waypoints (with wait times)",
    Callback = function()
        local data = copyWaypoints()
        if data ~= "" then
            Options.WaypointDataInput:SetValue(data)
            Library:Notify({ Title = "Waypoint System", Content = "Waypoints copied to clipboard!", Duration = 4 })
        end
    end
})

CopyPaste:AddButton({
    Title = "Load Waypoints",
    Callback = function()
        local data = Options.WaypointDataInput.Value
        if data ~= "" then
            if loadWaypointsFromString(data) then
                Library:Notify({ Title = "Waypoint System", Content = "Waypoints loaded successfully!", Duration = 4 })
            else
                Library:Notify({ Title = "Waypoint System", Content = "Failed to load waypoints!", Duration = 4 })
            end
            Options.WaypointDataInput:SetValue("")
        end
    end
})

-- Auto Spawn Section
local AutoSpawn = Tabs.Maain:Section("Auto Spawn Waypoints")

local autoSpawnToggle = AutoSpawn:AddToggle("AutoSpawnToggle", {
    Title = "Auto Spawn Waypoints",
    Default = false
})

autoSpawnToggle:OnChanged(function()
    if Options.AutoSpawnToggle.Value then
        toggleAutoSpawn(spawnInterval)
    else
        autoSpawnWaypoints = false
        if autoSpawnThread then
            coroutine.close(autoSpawnThread)
            autoSpawnThread = nil
        end
    end
end)

AutoSpawn:AddSlider("SpawnInterval", {
    Title = "Spawn Interval (seconds)",
    Min = 0.01,
    Max = 10,
    Default = 0.5,
    Rounding = 2
})

Options.SpawnInterval:OnChanged(function()
    spawnInterval = Options.SpawnInterval.Value
    if autoSpawnWaypoints then
        toggleAutoSpawn(spawnInterval)
    end
end)

AutoSpawn:AddButton({
    Title = "Clear Auto Spawned Waypoints",
    Callback = function()
        removeAllWaypoints()
    end
})

-- Settings Tab

-- FPS Boost Section
local FPSBoost = Tabs.Settings:Section("FPS Boost")

FPSBoost:AddToggle("FPSBoostToggle", {
    Title = "FPS Boost (Low Graphics)",
    Default = false
})

Options.FPSBoostToggle:OnChanged(function()
    fpsBoostEnabled = Options.FPSBoostToggle.Value
    
    if fpsBoostEnabled then
        applyFPSBoost()
        Library:Notify({ Title = "Waypoint System", Content = "FPS Boost Enabled", Duration = 4 })
    else
        restoreFPSBoost()
        Library:Notify({ Title = "Waypoint System", Content = "FPS Boost Disabled", Duration = 4 })
    end
end)

-- External Scripts Section
local ExternalScripts = Tabs.Settings:Section("External Scripts")

ExternalScripts:AddButton({
    Title = "Load Nilhub",
    Callback = function()
        local success, errorMsg = pcall(function()
            loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/2c5f110f91165707959fc626b167e036.lua"))()
        end)
        if not success then
            warn("Failed to load Luarmor script:", errorMsg)
            Library:Notify({ Title = "Waypoint System", Content = "Failed to load script", Duration = 4 })
        end
    end
})

-- Place Waypoints Button (with embedded data)
local PlaceWaypoints = Tabs.Settings:Section("Quick Load")

PlaceWaypoints:AddButton({
    Title = "Place Waypoints (Example Route)",
    Callback = function()
        -- 1. Cleanup
        stopAutoWalk()
        if Options.AutoWalkToggle then Options.AutoWalkToggle:SetValue(false) end
        removeAllWaypoints()

        -- 2. Paste your waypoint data here
        local rawText = [[
-- Waypoints Data (with wait times)
local waypointsData = {
 {position = Vector3.new(-142.17, -34.43, -171.42), waitTime = 1.8}, -- wait: 1.8s
 {position = Vector3.new(-128.09, -34.09, -188.91), waitTime = 0.0},
 {position = Vector3.new(-120.60, -24.94, -195.87), waitTime = 1.8}, -- wait: 1.8s
 {position = Vector3.new(-120.76, -19.36, -198.05), waitTime = 0.0},
 {position = Vector3.new(-115.74, -3.76, -210.01), waitTime = 0.0},
 {position = Vector3.new(-94.77, -3.00, -234.34), waitTime = 0.0},
 {position = Vector3.new(-67.87, -3.00, -246.48), waitTime = 0.0},
 {position = Vector3.new(-7.19, -3.00, -261.32), waitTime = 0.0},
 {position = Vector3.new(69.77, -3.00, -264.90), waitTime = 0.0},
 {position = Vector3.new(129.48, -3.21, -268.54), waitTime = 0.0},
 {position = Vector3.new(142.71, -3.29, -267.13), waitTime = 0.0},
 {position = Vector3.new(153.58, -3.47, -261.69), waitTime = 0.0},
 {position = Vector3.new(173.90, -3.17, -249.79), waitTime = 0.0},
 {position = Vector3.new(218.12, -3.00, -199.52), waitTime = 0.0},
 {position = Vector3.new(247.56, -3.00, -145.65), waitTime = 0.0},
 {position = Vector3.new(256.18, -2.46, -113.38), waitTime = 0.0},
 {position = Vector3.new(307.36, -11.17, -60.68), waitTime = 0.0},
 {position = Vector3.new(319.16, -11.40, -43.42), waitTime = 0.0},
 {position = Vector3.new(347.59, -12.06, 0.42), waitTime = 0.0},
 {position = Vector3.new(372.64, -11.44, 45.88), waitTime = 0.0},
 {position = Vector3.new(396.64, -11.01, 91.50), waitTime = 0.0},
 {position = Vector3.new(417.85, -3.00, 135.94), waitTime = 0.0},
 {position = Vector3.new(431.87, -3.00, 170.63), waitTime = 0.0},
 {position = Vector3.new(434.66, -3.00, 177.99), waitTime = 0.0},
 {position = Vector3.new(440.24, -3.00, 180.25), waitTime = 0.0},
 {position = Vector3.new(446.19, -3.00, 209.31), waitTime = 0.0},
 {position = Vector3.new(445.23, -3.19, 225.13), waitTime = 0.0},
 {position = Vector3.new(452.75, 6.74, 227.55), waitTime = 0.0},
 {position = Vector3.new(456.41, 11.94, 236.67), waitTime = 1.8}, -- wait: 1.8s
 {position = Vector3.new(472.75, 16.50, 199.77), waitTime = 0.0},
 {position = Vector3.new(478.46, 11.90, 149.47), waitTime = 1.6}, -- wait: 1.6s
 {position = Vector3.new(484.20, -11.42, 105.83), waitTime = 0.0},
 {position = Vector3.new(521.16, -11.61, 15.95), waitTime = 0.0},
 {position = Vector3.new(553.80, -11.08, -24.67), waitTime = 0.0},
 {position = Vector3.new(591.10, -11.06, -61.43), waitTime = 0.0},
 {position = Vector3.new(626.37, -8.14, -99.80), waitTime = 0.0},
 {position = Vector3.new(661.05, -3.53, -137.55), waitTime = 0.0},
 {position = Vector3.new(669.71, 8.80, -148.51), waitTime = 0.0},
 {position = Vector3.new(674.25, 22.90, -156.83), waitTime = 0.0},
 {position = Vector3.new(685.31, 32.54, -177.03), waitTime = 0.0},
 {position = Vector3.new(710.10, 24.99, -204.65), waitTime = 1.8}, -- wait: 1.8s
 {position = Vector3.new(719.13, 26.02, -217.47), waitTime = 0.0},
 {position = Vector3.new(726.43, 22.42, -248.08), waitTime = 0.0},
 {position = Vector3.new(719.32, 25.65, -284.40), waitTime = 0.0},
 {position = Vector3.new(707.34, 33.24, -309.27), waitTime = 0.0},
 {position = Vector3.new(694.24, 38.10, -314.47), waitTime = 0.0},
 {position = Vector3.new(688.08, 44.19, -312.89), waitTime = 0.0},
 {position = Vector3.new(681.10, 57.58, -333.48), waitTime = 0.0},
 {position = Vector3.new(685.18, 74.15, -363.20), waitTime = 0.0},
 {position = Vector3.new(679.00, 77.96, -387.01), waitTime = 2.0}, -- wait: 2.0s
 {position = Vector3.new(655.02, 62.79, -380.18), waitTime = 0.0},
 {position = Vector3.new(628.67, 52.13, -371.98), waitTime = 0.0},
 {position = Vector3.new(591.94, 27.54, -362.05), waitTime = 0.0},
 {position = Vector3.new(582.76, 15.03, -354.73), waitTime = 0.0},
 {position = Vector3.new(586.98, 12.33, -352.45), waitTime = 0.0},
 {position = Vector3.new(591.30, 7.13, -350.20), waitTime = 0.0},
 {position = Vector3.new(592.92, -2.52, -349.53), waitTime = 0.0},
 {position = Vector3.new(614.01, -7.75, -361.08), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(627.44, -7.37, -383.56), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(584.49, 0.30, -390.75), waitTime = 0.0},
 {position = Vector3.new(553.44, 11.79, -395.00), waitTime = 0.0},
 {position = Vector3.new(516.73, 7.85, -418.26), waitTime = 0.0},
 {position = Vector3.new(439.74, -11.80, -436.32), waitTime = 0.0},
 {position = Vector3.new(317.02, -11.56, -492.37), waitTime = 0.0},
 {position = Vector3.new(268.01, -11.26, -509.73), waitTime = 0.0},
 {position = Vector3.new(218.77, -11.90, -522.97), waitTime = 0.0},
 {position = Vector3.new(169.58, -4.11, -536.75), waitTime = 0.0},
 {position = Vector3.new(118.46, -3.00, -549.04), waitTime = 0.0},
 {position = Vector3.new(66.97, -10.96, -551.97), waitTime = 0.0},
 {position = Vector3.new(14.67, -8.61, -554.96), waitTime = 0.0},
 {position = Vector3.new(-37.30, -3.00, -559.61), waitTime = 0.0},
 {position = Vector3.new(-88.93, -3.00, -569.28), waitTime = 0.0},
 {position = Vector3.new(-136.96, 3.48, -586.95), waitTime = 0.0},
 {position = Vector3.new(-185.35, 5.00, -607.08), waitTime = 0.0},
 {position = Vector3.new(-206.64, 12.66, -622.02), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(-209.19, 6.73, -614.39), waitTime = 0.0},
 {position = Vector3.new(-300.93, -3.02, -603.51), waitTime = 0.0},
 {position = Vector3.new(-378.45, -6.31, -606.76), waitTime = 0.0},
 {position = Vector3.new(-396.41, -22.88, -602.11), waitTime = 0.0},
 {position = Vector3.new(-405.63, -30.02, -571.49), waitTime = 0.0},
 {position = Vector3.new(-405.29, -36.47, -558.41), waitTime = 0.0},
 {position = Vector3.new(-387.65, -43.25, -551.86), waitTime = 0.0},
 {position = Vector3.new(-375.67, -43.73, -558.70), waitTime = 2.0}, -- wait: 2.0s
 {position = Vector3.new(-331.80, -47.33, -567.65), waitTime = 0.0},
 {position = Vector3.new(-316.65, -48.70, -568.45), waitTime = 0.0},
 {position = Vector3.new(-292.06, -56.85, -566.69), waitTime = 0.0},
 {position = Vector3.new(-257.24, -55.80, -556.48), waitTime = 0.0},
 {position = Vector3.new(-222.23, -59.09, -544.08), waitTime = 0.0},
 {position = Vector3.new(-192.62, -63.29, -541.81), waitTime = 0.0},
 {position = Vector3.new(-172.34, -63.39, -567.02), waitTime = 0.0},
 {position = Vector3.new(-180.49, -64.21, -608.34), waitTime = 0.0},
 {position = Vector3.new(-198.56, -62.15, -623.69), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(-177.39, -63.35, -596.42), waitTime = 0.0},
 {position = Vector3.new(-173.78, -63.19, -558.42), waitTime = 0.0},
 {position = Vector3.new(-170.41, -63.88, -541.20), waitTime = 0.0},
 {position = Vector3.new(-166.88, -63.09, -502.88), waitTime = 0.0},
 {position = Vector3.new(-177.20, -66.46, -466.42), waitTime = 0.0},
 {position = Vector3.new(-168.88, -67.64, -464.13), waitTime = 0.0},
 {position = Vector3.new(-165.75, -79.83, -464.19), waitTime = 0.0},
 {position = Vector3.new(-160.75, -97.96, -470.18), waitTime = 0.0},
 {position = Vector3.new(-160.00, -98.97, -484.17), waitTime = 0.0},
 {position = Vector3.new(-161.94, -100.22, -499.85), waitTime = 0.0},
 {position = Vector3.new(-173.72, -101.24, -504.41), waitTime = 0.0},
 {position = Vector3.new(-179.45, -102.25, -503.96), waitTime = 0.0},
 {position = Vector3.new(-186.70, -103.21, -501.82), waitTime = 0.0},
 {position = Vector3.new(-190.46, -103.45, -497.89), waitTime = 0.0},
 {position = Vector3.new(-192.43, -103.00, -483.81), waitTime = 0.0},
 {position = Vector3.new(-191.65, -103.78, -459.64), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(-193.34, -103.23, -497.81), waitTime = 0.0},
 {position = Vector3.new(-179.90, -102.98, -506.38), waitTime = 0.0},
 {position = Vector3.new(-162.37, -100.16, -500.11), waitTime = 0.0},
 {position = Vector3.new(-147.52, -102.87, -490.59), waitTime = 0.0},
 {position = Vector3.new(-142.84, -96.97, -490.44), waitTime = 0.0},
 {position = Vector3.new(-130.05, -103.00, -488.87), waitTime = 0.0},
 {position = Vector3.new(-121.58, -103.00, -478.98), waitTime = 0.0},
 {position = Vector3.new(-79.36, -103.00, -475.12), waitTime = 0.0},
 {position = Vector3.new(-41.24, -103.00, -453.57), waitTime = 0.0},
 {position = Vector3.new(1.79, -103.00, -425.30), waitTime = 0.0},
 {position = Vector3.new(19.58, -99.16, -403.40), waitTime = 0.0},
 {position = Vector3.new(23.33, -99.00, -377.83), waitTime = 0.0},
 {position = Vector3.new(45.49, -99.18, -359.19), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(22.19, -99.00, -383.44), waitTime = 0.0},
 {position = Vector3.new(13.55, -102.05, -413.85), waitTime = 0.0},
 {position = Vector3.new(-43.06, -103.48, -393.17), waitTime = 0.0},
 {position = Vector3.new(-89.14, -103.00, -356.08), waitTime = 0.0},
 {position = Vector3.new(-107.86, -102.92, -340.73), waitTime = 0.0},
 {position = Vector3.new(-123.95, -90.92, -286.27), waitTime = 0.0},
 {position = Vector3.new(-159.60, -85.38, -304.09), waitTime = 0.0},
 {position = Vector3.new(-162.74, -79.49, -316.68), waitTime = 0.0},
 {position = Vector3.new(-181.33, -79.34, -314.76), waitTime = 0.0},
 {position = Vector3.new(-209.83, -76.82, -308.67), waitTime = 0.0},
 {position = Vector3.new(-228.68, -79.34, -304.84), waitTime = 0.0},
 {position = Vector3.new(-262.89, -79.00, -346.57), waitTime = 0.0},
 {position = Vector3.new(-296.23, -76.90, -366.04), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(-254.81, -77.57, -337.87), waitTime = 0.0},
 {position = Vector3.new(-234.43, -79.05, -308.82), waitTime = 0.0},
 {position = Vector3.new(-228.88, -81.70, -264.52), waitTime = 0.0},
 {position = Vector3.new(-239.37, -84.12, -242.11), waitTime = 2.0}, -- wait: 2.0s
 {position = Vector3.new(-232.10, -95.02, -232.06), waitTime = 0.0},
 {position = Vector3.new(-219.59, -98.37, -214.83), waitTime = 0.0},
 {position = Vector3.new(-211.24, -95.58, -172.60), waitTime = 0.0},
 {position = Vector3.new(-272.77, -95.13, -114.63), waitTime = 0.0},
 {position = Vector3.new(-305.23, -95.16, -75.56), waitTime = 0.0},
 {position = Vector3.new(-336.40, -91.02, -47.84), waitTime = 2.0}, -- wait: 2.0s
 {position = Vector3.new(-324.84, -87.78, -95.42), waitTime = 0.0},
 {position = Vector3.new(-317.70, -84.38, -109.74), waitTime = 0.0},
 {position = Vector3.new(-302.48, -75.21, -101.97), waitTime = 0.0},
 {position = Vector3.new(-288.67, -71.79, -94.34), waitTime = 0.0},
 {position = Vector3.new(-239.42, -71.66, -74.63), waitTime = 2.2}, -- wait: 2.2s
 {position = Vector3.new(-261.46, -72.43, -75.07), waitTime = 0.0},
 {position = Vector3.new(-264.46, -76.18, -72.65), waitTime = 0.0},
 {position = Vector3.new(-268.09, -90.10, -72.27), waitTime = 0.0},
 {position = Vector3.new(-265.66, -95.65, -76.61), waitTime = 0.0},
 {position = Vector3.new(-237.69, -93.87, -120.35), waitTime = 0.0},
 {position = Vector3.new(-206.25, -95.01, -124.74), waitTime = 0.0},
 {position = Vector3.new(-152.04, -95.18, -84.48), waitTime = 0.0},
 {position = Vector3.new(-114.44, -95.64, -57.43), waitTime = 0.0},
 {position = Vector3.new(-76.34, -95.18, -29.56), waitTime = 0.0},
 {position = Vector3.new(-51.61, -94.88, -22.01), waitTime = 0.0},
 {position = Vector3.new(-26.98, -93.12, -5.24), waitTime = 2.0}, -- wait: 2.0s
 {position = Vector3.new(-47.66, -94.82, -22.79), waitTime = 0.0},
 {position = Vector3.new(-65.99, -91.53, -50.03), waitTime = 0.0},
 {position = Vector3.new(-65.59, -82.18, -70.32), waitTime = 0.0},
 {position = Vector3.new(-59.26, -77.12, -76.40), waitTime = 0.0},
 {position = Vector3.new(-30.20, -75.00, -58.51), waitTime = 0.0},
 {position = Vector3.new(-23.07, -76.13, -41.10), waitTime = 0.0},
 {position = Vector3.new(10.04, -75.00, -37.14), waitTime = 0.0},
 {position = Vector3.new(4.51, -81.60, -75.82), waitTime = 1.8}, -- wait: 1.8s
 {position = Vector3.new(5.84, -76.25, -95.41), waitTime = 0.0},
 {position = Vector3.new(17.82, -72.74, -107.09), waitTime = 0.0},
 {position = Vector3.new(35.06, -75.00, -118.85), waitTime = 0.0},
 {position = Vector3.new(60.09, -75.20, -133.56), waitTime = 0.0},
 {position = Vector3.new(78.74, -72.99, -121.64), waitTime = 0.0},
 {position = Vector3.new(73.74, -50.59, -63.31), waitTime = 0.0},
 {position = Vector3.new(52.88, -40.07, -53.42), waitTime = 0.0},
 {position = Vector3.new(3.02, -36.63, -92.84), waitTime = 0.0},
 {position = Vector3.new(-34.52, -35.52, -125.86), waitTime = 0.0},
 {position = Vector3.new(-116.47, -35.04, -153.29), waitTime = 12.0}, -- wait: 12.0s
}

-- JSON format for sharing:
[{"y":-34.43000030517578,"x":-142.1699981689453,"wait":1.8,"z":-171.4199981689453},{"y":-34.09000015258789,"x":-128.08999633789063,"wait":0,"z":-188.91000366210938},{"y":-24.940000534057618,"x":-120.5999984741211,"wait":1.8,"z":-195.8699951171875},{"y":-19.360000610351564,"x":-120.76000213623047,"wait":0,"z":-198.0500030517578},{"y":-3.759999990463257,"x":-115.73999786376953,"wait":0,"z":-210.00999450683595},{"y":-3,"x":-94.7699966430664,"wait":0,"z":-234.33999633789063},{"y":-3,"x":-67.87000274658203,"wait":0,"z":-246.47999572753907},{"y":-3,"x":-7.190000057220459,"wait":0,"z":-261.32000732421877},{"y":-3,"x":69.7699966430664,"wait":0,"z":-264.8999938964844},{"y":-3.2100000381469728,"x":129.47999572753907,"wait":0,"z":-268.5400085449219},{"y":-3.2899999618530275,"x":142.7100067138672,"wait":0,"z":-267.1300048828125},{"y":-3.4700000286102297,"x":153.5800018310547,"wait":0,"z":-261.69000244140627},{"y":-3.1700000762939455,"x":173.89999389648438,"wait":0,"z":-249.7899932861328},{"y":-3,"x":218.1199951171875,"wait":0,"z":-199.52000427246095},{"y":-3,"x":247.55999755859376,"wait":0,"z":-145.64999389648438},{"y":-2.4600000381469728,"x":256.17999267578127,"wait":0,"z":-113.37999725341797},{"y":-11.170000076293946,"x":307.3599853515625,"wait":0,"z":-60.68000030517578},{"y":-11.399999618530274,"x":319.1600036621094,"wait":0,"z":-43.41999816894531},{"y":-12.0600004196167,"x":347.5899963378906,"wait":0,"z":0.41999998688697817},{"y":-11.4399995803833,"x":372.6400146484375,"wait":0,"z":45.880001068115237},{"y":-11.010000228881836,"x":396.6400146484375,"wait":0,"z":91.5},{"y":-3,"x":417.8500061035156,"wait":0,"z":135.94000244140626},{"y":-3,"x":431.8699951171875,"wait":0,"z":170.6300048828125},{"y":-3,"x":434.6600036621094,"wait":0,"z":177.99000549316407},{"y":-3,"x":440.239990234375,"wait":0,"z":180.25},{"y":-3,"x":446.19000244140627,"wait":0,"z":209.30999755859376},{"y":-3.190000057220459,"x":445.2300109863281,"wait":0,"z":225.1300048828125},{"y":6.739999771118164,"x":452.75,"wait":0,"z":227.5500030517578},{"y":11.9399995803833,"x":456.4100036621094,"wait":1.8,"z":236.6699981689453},{"y":16.5,"x":472.75,"wait":0,"z":199.77000427246095},{"y":11.899999618530274,"x":478.4599914550781,"wait":1.6,"z":149.47000122070313},{"y":-11.420000076293946,"x":484.20001220703127,"wait":0,"z":105.83000183105469},{"y":-11.609999656677246,"x":521.1599731445313,"wait":0,"z":15.949999809265137},{"y":-11.079999923706055,"x":553.7999877929688,"wait":0,"z":-24.670000076293947},{"y":-11.0600004196167,"x":591.0999755859375,"wait":0,"z":-61.43000030517578},{"y":-8.140000343322754,"x":626.3699951171875,"wait":0,"z":-99.80000305175781},{"y":-3.5299999713897707,"x":661.0499877929688,"wait":0,"z":-137.5500030517578},{"y":8.800000190734864,"x":669.7100219726563,"wait":0,"z":-148.50999450683595},{"y":22.899999618530275,"x":674.25,"wait":0,"z":-156.8300018310547},{"y":32.540000915527347,"x":685.3099975585938,"wait":0,"z":-177.02999877929688},{"y":24.989999771118165,"x":710.0999755859375,"wait":1.8,"z":-204.64999389648438},{"y":26.020000457763673,"x":719.1300048828125,"wait":0,"z":-217.47000122070313},{"y":22.420000076293947,"x":726.4299926757813,"wait":0,"z":-248.0800018310547},{"y":25.649999618530275,"x":719.3200073242188,"wait":0,"z":-284.3999938964844},{"y":33.2400016784668,"x":707.3400268554688,"wait":0,"z":-309.2699890136719},{"y":38.099998474121097,"x":694.239990234375,"wait":0,"z":-314.4700012207031},{"y":44.189998626708987,"x":688.0800170898438,"wait":0,"z":-312.8900146484375},{"y":57.58000183105469,"x":681.0999755859375,"wait":0,"z":-333.4800109863281},{"y":74.1500015258789,"x":685.1799926757813,"wait":0,"z":-363.20001220703127},{"y":77.95999908447266,"x":679,"wait":2,"z":-387.010009765625},{"y":62.790000915527347,"x":655.02001953125,"wait":0,"z":-380.17999267578127},{"y":52.130001068115237,"x":628.6699829101563,"wait":0,"z":-371.9800109863281},{"y":27.540000915527345,"x":591.9400024414063,"wait":0,"z":-362.04998779296877},{"y":15.029999732971192,"x":582.760009765625,"wait":0,"z":-354.7300109863281},{"y":12.329999923706055,"x":586.97998046875,"wait":0,"z":-352.45001220703127},{"y":7.130000114440918,"x":591.2999877929688,"wait":0,"z":-350.20001220703127},{"y":-2.5199999809265138,"x":592.9199829101563,"wait":0,"z":-349.5299987792969},{"y":-7.75,"x":614.010009765625,"wait":2.2,"z":-361.0799865722656},{"y":-7.369999885559082,"x":627.4400024414063,"wait":2.2,"z":-383.55999755859377},{"y":0.30000001192092898,"x":584.489990234375,"wait":0,"z":-390.75},{"y":11.789999961853028,"x":553.4400024414063,"wait":0,"z":-395},{"y":7.849999904632568,"x":516.72998046875,"wait":0,"z":-418.260009765625},{"y":-11.800000190734864,"x":439.739990234375,"wait":0,"z":-436.32000732421877},{"y":-11.5600004196167,"x":317.0199890136719,"wait":0,"z":-492.3699951171875},{"y":-11.260000228881836,"x":268.010009765625,"wait":0,"z":-509.7300109863281},{"y":-11.899999618530274,"x":218.77000427246095,"wait":0,"z":-522.969970703125},{"y":-4.110000133514404,"x":169.5800018310547,"wait":0,"z":-536.75},{"y":-3,"x":118.45999908447266,"wait":0,"z":-549.0399780273438},{"y":-10.960000038146973,"x":66.97000122070313,"wait":0,"z":-551.969970703125},{"y":-8.609999656677246,"x":14.670000076293946,"wait":0,"z":-554.9600219726563},{"y":-3,"x":-37.29999923706055,"wait":0,"z":-559.6099853515625},{"y":-3,"x":-88.93000030517578,"wait":0,"z":-569.280029296875},{"y":3.4800000190734865,"x":-136.9600067138672,"wait":0,"z":-586.9500122070313},{"y":5,"x":-185.35000610351563,"wait":0,"z":-607.0800170898438},{"y":12.65999984741211,"x":-206.63999938964845,"wait":2.2,"z":-622.02001953125},{"y":6.730000019073486,"x":-209.19000244140626,"wait":0,"z":-614.3900146484375},{"y":-3.0199999809265138,"x":-300.92999267578127,"wait":0,"z":-603.510009765625},{"y":-6.309999942779541,"x":-378.45001220703127,"wait":0,"z":-606.760009765625},{"y":-22.8799991607666,"x":-396.4100036621094,"wait":0,"z":-602.1099853515625},{"y":-30.020000457763673,"x":-405.6300048828125,"wait":0,"z":-571.489990234375},{"y":-36.470001220703128,"x":-405.2900085449219,"wait":0,"z":-558.4099731445313},{"y":-43.25,"x":-387.6499938964844,"wait":0,"z":-551.8599853515625},{"y":-43.72999954223633,"x":-375.6700134277344,"wait":2,"z":-558.7000122070313},{"y":-47.33000183105469,"x":-331.79998779296877,"wait":0,"z":-567.6500244140625},{"y":-48.70000076293945,"x":-316.6499938964844,"wait":0,"z":-568.4500122070313},{"y":-56.849998474121097,"x":-292.05999755859377,"wait":0,"z":-566.6900024414063},{"y":-55.79999923706055,"x":-257.239990234375,"wait":0,"z":-556.47998046875},{"y":-59.09000015258789,"x":-222.22999572753907,"wait":0,"z":-544.0800170898438},{"y":-63.290000915527347,"x":-192.6199951171875,"wait":0,"z":-541.8099975585938},{"y":-63.38999938964844,"x":-172.33999633789063,"wait":0,"z":-567.02001953125},{"y":-64.20999908447266,"x":-180.49000549316407,"wait":0,"z":-608.3400268554688},{"y":-62.150001525878909,"x":-198.55999755859376,"wait":2.2,"z":-623.6900024414063},{"y":-63.349998474121097,"x":-177.38999938964845,"wait":0,"z":-596.4199829101563},{"y":-63.189998626708987,"x":-173.77999877929688,"wait":0,"z":-558.4199829101563},{"y":-63.880001068115237,"x":-170.41000366210938,"wait":0,"z":-541.2000122070313},{"y":-63.09000015258789,"x":-166.8800048828125,"wait":0,"z":-502.8800048828125},{"y":-66.45999908447266,"x":-177.1999969482422,"wait":0,"z":-466.4200134277344},{"y":-67.63999938964844,"x":-168.8800048828125,"wait":0,"z":-464.1300048828125},{"y":-79.83000183105469,"x":-165.75,"wait":0,"z":-464.19000244140627},{"y":-97.95999908447266,"x":-160.75,"wait":0,"z":-470.17999267578127},{"y":-98.97000122070313,"x":-160,"wait":0,"z":-484.1700134277344},{"y":-100.22000122070313,"x":-161.94000244140626,"wait":0,"z":-499.8500061035156},{"y":-101.23999786376953,"x":-173.72000122070313,"wait":0,"z":-504.4100036621094},{"y":-102.25,"x":-179.4499969482422,"wait":0,"z":-503.9599914550781},{"y":-103.20999908447266,"x":-186.6999969482422,"wait":0,"z":-501.82000732421877},{"y":-103.44999694824219,"x":-190.4600067138672,"wait":0,"z":-497.8900146484375},{"y":-103,"x":-192.42999267578126,"wait":0,"z":-483.80999755859377},{"y":-103.77999877929688,"x":-191.64999389648438,"wait":2.2,"z":-459.6400146484375},{"y":-103.2300033569336,"x":-193.33999633789063,"wait":0,"z":-497.80999755859377},{"y":-102.9800033569336,"x":-179.89999389648438,"wait":0,"z":-506.3800048828125},{"y":-100.16000366210938,"x":-162.3699951171875,"wait":0,"z":-500.1099853515625},{"y":-102.87000274658203,"x":-147.52000427246095,"wait":0,"z":-490.5899963378906},{"y":-96.97000122070313,"x":-142.83999633789063,"wait":0,"z":-490.44000244140627},{"y":-103,"x":-130.0500030517578,"wait":0,"z":-488.8699951171875},{"y":-103,"x":-121.58000183105469,"wait":0,"z":-478.9800109863281},{"y":-103,"x":-79.36000061035156,"wait":0,"z":-475.1199951171875},{"y":-103,"x":-41.2400016784668,"wait":0,"z":-453.57000732421877},{"y":-103,"x":1.7899999618530274,"wait":0,"z":-425.29998779296877},{"y":-99.16000366210938,"x":19.579999923706056,"wait":0,"z":-403.3999938964844},{"y":-99,"x":23.329999923706056,"wait":0,"z":-377.8299865722656},{"y":-99.18000030517578,"x":45.4900016784668,"wait":2.2,"z":-359.19000244140627},{"y":-99,"x":22.190000534057618,"wait":0,"z":-383.44000244140627},{"y":-102.05000305175781,"x":13.550000190734864,"wait":0,"z":-413.8500061035156},{"y":-103.4800033569336,"x":-43.060001373291019,"wait":0,"z":-393.1700134277344},{"y":-103,"x":-89.13999938964844,"wait":0,"z":-356.0799865722656},{"y":-102.91999816894531,"x":-107.86000061035156,"wait":0,"z":-340.7300109863281},{"y":-90.91999816894531,"x":-123.94999694824219,"wait":0,"z":-286.2699890136719},{"y":-85.37999725341797,"x":-159.60000610351563,"wait":0,"z":-304.0899963378906},{"y":-79.48999786376953,"x":-162.74000549316407,"wait":0,"z":-316.67999267578127},{"y":-79.33999633789063,"x":-181.3300018310547,"wait":0,"z":-314.760009765625},{"y":-76.81999969482422,"x":-209.8300018310547,"wait":0,"z":-308.6700134277344},{"y":-79.33999633789063,"x":-228.67999267578126,"wait":0,"z":-304.8399963378906},{"y":-79,"x":-262.8900146484375,"wait":0,"z":-346.57000732421877},{"y":-76.9000015258789,"x":-296.2300109863281,"wait":2.2,"z":-366.0400085449219},{"y":-77.56999969482422,"x":-254.80999755859376,"wait":0,"z":-337.8699951171875},{"y":-79.05000305175781,"x":-234.42999267578126,"wait":0,"z":-308.82000732421877},{"y":-81.69999694824219,"x":-228.8800048828125,"wait":0,"z":-264.5199890136719},{"y":-84.12000274658203,"x":-239.3699951171875,"wait":2,"z":-242.11000061035157},{"y":-95.0199966430664,"x":-232.10000610351563,"wait":0,"z":-232.05999755859376},{"y":-98.37000274658203,"x":-219.58999633789063,"wait":0,"z":-214.8300018310547},{"y":-95.58000183105469,"x":-211.24000549316407,"wait":0,"z":-172.60000610351563},{"y":-95.12999725341797,"x":-272.7699890136719,"wait":0,"z":-114.62999725341797},{"y":-95.16000366210938,"x":-305.2300109863281,"wait":0,"z":-75.55999755859375},{"y":-91.0199966430664,"x":-336.3999938964844,"wait":2,"z":-47.84000015258789},{"y":-87.77999877929688,"x":-324.8399963378906,"wait":0,"z":-95.41999816894531},{"y":-84.37999725341797,"x":-317.70001220703127,"wait":0,"z":-109.73999786376953},{"y":-75.20999908447266,"x":-302.4800109863281,"wait":0,"z":-101.97000122070313},{"y":-71.79000091552735,"x":-288.6700134277344,"wait":0,"z":-94.33999633789063},{"y":-71.66000366210938,"x":-239.4199981689453,"wait":2.2,"z":-74.62999725341797},{"y":-72.43000030517578,"x":-261.4599914550781,"wait":0,"z":-75.06999969482422},{"y":-76.18000030517578,"x":-264.4599914550781,"wait":0,"z":-72.6500015258789},{"y":-90.0999984741211,"x":-268.0899963378906,"wait":0,"z":-72.2699966430664},{"y":-95.6500015258789,"x":-265.6600036621094,"wait":0,"z":-76.61000061035156},{"y":-93.87000274658203,"x":-237.69000244140626,"wait":0,"z":-120.3499984741211},{"y":-95.01000213623047,"x":-206.25,"wait":0,"z":-124.73999786376953},{"y":-95.18000030517578,"x":-152.0399932861328,"wait":0,"z":-84.4800033569336},{"y":-95.63999938964844,"x":-114.44000244140625,"wait":0,"z":-57.43000030517578},{"y":-95.18000030517578,"x":-76.33999633789063,"wait":0,"z":-29.559999465942384},{"y":-94.87999725341797,"x":-51.61000061035156,"wait":0,"z":-22.010000228881837},{"y":-93.12000274658203,"x":-26.979999542236329,"wait":2,"z":-5.239999771118164},{"y":-94.81999969482422,"x":-47.65999984741211,"wait":0,"z":-22.790000915527345},{"y":-91.52999877929688,"x":-65.98999786376953,"wait":0,"z":-50.029998779296878},{"y":-82.18000030517578,"x":-65.58999633789063,"wait":0,"z":-70.31999969482422},{"y":-77.12000274658203,"x":-59.2599983215332,"wait":0,"z":-76.4000015258789},{"y":-75,"x":-30.200000762939454,"wait":0,"z":-58.5099983215332},{"y":-76.12999725341797,"x":-23.06999969482422,"wait":0,"z":-41.099998474121097},{"y":-75,"x":10.039999961853028,"wait":0,"z":-37.13999938964844},{"y":-81.5999984741211,"x":4.510000228881836,"wait":1.8,"z":-75.81999969482422},{"y":-76.25,"x":5.840000152587891,"wait":0,"z":-95.41000366210938},{"y":-72.73999786376953,"x":17.81999969482422,"wait":0,"z":-107.08999633789063},{"y":-75,"x":35.060001373291019,"wait":0,"z":-118.8499984741211},{"y":-75.19999694824219,"x":60.09000015258789,"wait":0,"z":-133.55999755859376},{"y":-72.98999786376953,"x":78.73999786376953,"wait":0,"z":-121.63999938964844},{"y":-50.59000015258789,"x":73.73999786376953,"wait":0,"z":-63.310001373291019},{"y":-40.06999969482422,"x":52.880001068115237,"wait":0,"z":-53.41999816894531},{"y":-36.630001068115237,"x":3.0199999809265138,"wait":0,"z":-92.83999633789063},{"y":-35.52000045776367,"x":-34.52000045776367,"wait":0,"z":-125.86000061035156},{"y":-35.040000915527347,"x":-116.47000122070313,"wait":12,"z":-153.2899932861328}]
}
]]

        -- 3. Smart parsing
        local count = 0
        
        -- Look for JSON
        local jsonPart = rawText:match("(%[.*%])") 
        if not jsonPart then
            jsonPart = rawText:match("%[(.+)%]")
            if jsonPart then jsonPart = "[" .. jsonPart .. "]" end
        end

        if jsonPart then
            local success, data = pcall(function()
                return game:GetService("HttpService"):JSONDecode(jsonPart)
            end)
            
            if success and type(data) == "table" then
                for _, wp in ipairs(data) do
                    table.insert(waypoints, {
                        position = Vector3.new(tonumber(wp.x), tonumber(wp.y), tonumber(wp.z)),
                        waitTime = tonumber(wp.wait) or 0
                    })
                    count = count + 1
                end
            end
        end

        -- 4. If JSON not found, look for Vector3.new
        if count == 0 then
            for x, y, z in rawText:gmatch("Vector3%.new%s*%(%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*%)") do
                local currentLine = rawText:match("Vector3%.new%("..x..".-waitTime%s*=%s*([%-%d%.]+)")
                table.insert(waypoints, {
                    position = Vector3.new(tonumber(x), tonumber(y), tonumber(z)),
                    waitTime = tonumber(currentLine) or 0
                })
                count = count + 1
            end
        end

        updateWaypointVisuals()
        Library:Notify({ Title = "Waypoint System", Content = "✅ Loaded Waypoints: " .. count, Duration = 5 })
    end
})

-- Character handling
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    root = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    if running then
        stopAutoWalk()
        if Options.AutoWalkToggle then
            Options.AutoWalkToggle:SetValue(false)
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if not character or not character.Parent then
        character = player.Character
        if character then
            root = character:WaitForChild("HumanoidRootPart")
            humanoid = character:WaitForChild("Humanoid")
        end
    end
    
    if running and #waypoints == 0 then
        stopAutoWalk()
        if Options.AutoWalkToggle then
            Options.AutoWalkToggle:SetValue(false)
        end
    end
    
    if waitingInAir and root and not root.Anchored then
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
    
    if not autoSpawnWaypoints and autoSpawnThread then
        coroutine.close(autoSpawnThread)
        autoSpawnThread = nil
    end
end)

local function removeAllOldBoards()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Old Boards" then
            obj:Destroy()
        end
    end
end

removeAllOldBoards()

SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Library:Notify{
    Title = "AmethystHub",
    Content = "Loaded, Enjoy!", 
    Duration = 8
}
SaveManager:LoadAutoloadConfig()
