getgenv().scripttitle = "SilentHook.cc"
getgenv().FolderName = "ChadreyBest"
loadstring(game:HttpGet('https://raw.githubusercontent.com/Awakenchan/jan/main/JanModifiedSource'))()

local LegitTab = library:AddTab("Combat")
local LegitColumn1 = LegitTab:AddColumn()

local LegitColumn2 = LegitTab:AddColumn()
local GunModsSection = LegitColumn2:AddSection("Gun Mods")

local ReplicatedFirst = cloneref(game:GetService("ReplicatedFirst"))
local Bullets = require(ReplicatedFirst:WaitForChild("Framework")).Libraries.Bullets

local GetFireImpulse = getupvalue(Bullets.Fire, 6)


local noRecoilEnabled = false
local recoilScale = 0.1


setupvalue(Bullets.Fire, 6, function(...)
    local impulse = {GetFireImpulse(...)}

    if noRecoilEnabled then
        for i = 1, #impulse do
            impulse[i] = impulse[i] * recoilScale
        end
    end

    return unpack(impulse)
end)

GunModsSection:AddToggle({
    text = "No Recoil",
    flag = "No Recoil",
    value = false,
    callback = function(state)
        noRecoilEnabled = state
    end
})

GunModsSection:AddSlider({
    text = "Recoil Control",
    flag = "Recoil",
    min = 0,
    max = 100,
    value = 100,
    suffix = "%",
    callback = function(value)
        recoilScale = value / 100
    end
})

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FrameworkModule = require(ReplicatedFirst:WaitForChild("Framework"))
FrameworkModule:WaitForLoaded()

local Interface = FrameworkModule.Libraries.Interface
local Network = FrameworkModule.Libraries.Network
local Bullets = FrameworkModule.Libraries.Bullets

local GetSpreadAngle = getupvalue(Bullets.Fire, 1)
local originalFire = Bullets.Fire

local noSpreadEnabled = false
local spreadScale = 0

GunModsSection:AddToggle({
    text = "No Spread",
    flag = "No Spread",
    value = false,
    callback = function(state)
        noSpreadEnabled = state
    end
})

GunModsSection:AddSlider({
    name = "Spread Amount",
    flag = "SpreadAmount",
    min = 0,
    max = 100,
    value = 0,
    suffix = "%",
    callback = function(value)
        spreadScale = value / 100
    end
})

setupvalue(Bullets.Fire, 1, function(Character, CCamera, Weapon, ...)
    if noSpreadEnabled then
        local OldMoveState = Character.MoveState
        local OldZooming = Character.Zooming
        local OldFirstPerson = CCamera.FirstPerson

        Character.MoveState = "Walking"
        Character.Zooming = true
        CCamera.FirstPerson = true

        local ReturnArgs = {GetSpreadAngle(Character, CCamera, Weapon, ...)}

        Character.MoveState = OldMoveState
        Character.Zooming = OldZooming
        CCamera.FirstPerson = OldFirstPerson

        return unpack(ReturnArgs)
    end

    return GetSpreadAngle(Character, CCamera, Weapon, ...)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Firearm = nil
task.spawn(function()
    setthreadidentity(2)
    Firearm = require(ReplicatedStorage.Client.Abstracts.ItemInitializers.Firearm)
end)

repeat task.wait() until Firearm

local Framework = require(ReplicatedFirst:WaitForChild("Framework"))
Framework:WaitForLoaded()

local Animators = Framework.Classes.Animators
local Firearms = Framework.Classes.Firearm

local AnimatedReload = getupvalue(Firearm, 7)

setupvalue(Firearm, 7, function(...)
    if Window.Flags["AR2/InstantReload"] then
        local Args = {...}
        for Index = 0, Args[3].LoopCount do
            Args[4]("Commit", "Load")
        end
        Args[4]("Commit", "End")
        return true
    end

    return AnimatedReload(...)
end)

GunModsSection:AddToggle({
    text = "Instant Reload",
    flag = "AR2/InstantReload",
    value = false,
    callback = function(state)
    end
})

local LocalPlayerSection = LegitColumn2:AddSection("Local Player")

getgenv().Speed = 45

local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

local framework = require(ReplicatedFirst.Framework)

local network = framework.require("Libraries", "Network")
local players = framework.require("Classes", "Players")

local localPlayer = players.get()

local flying = false
local oldState = nil
local oldRealState = nil

local originalSend = clonefunction(network.Send)

UserInputService.InputBegan:Connect(function(input : InputObject, gameProcessedEvent : boolean)
    if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Space and flying then
        local character = localPlayer.Character
        if not character then
            return
        end
        local rootPart = character.RootPart
        if not rootPart then
            return
        end
        while flying and UserInputService:IsKeyDown(Enum.KeyCode.Space) do
            local deltaTime = RunService.Heartbeat:Wait()
            rootPart.Position = rootPart.Position + Vector3.yAxis * (deltaTime * getgenv().Speed)
            rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input : InputObject, gameProcessedEvent : boolean)
    if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Space then
        if flying then
            flying = false
        end
    end
end)

hookfunction(network.Send, newcclosure(function(self : {[any] : any}, name : string, ... : any)
    local arguments = table.pack(...)
    if name == "Character State Report" then
        if arguments[4] == "Falling" and flying then
            arguments[4] = (oldState and oldState == "Climbing") and "Running" or "Climbing"
            oldState = arguments[4]
        else
            oldRealState = arguments[4]
        end
    end
    return originalSend(self, name, table.unpack(arguments))
end))

LocalPlayerSection:AddToggle({
    text = "Fly",
    flag = "Fly",
    callback = function(state)
        flying = state
    end
})

LocalPlayerSection:AddButton({
    text = "Noclip",
    callback = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()

        local noclip = true

        RunService.Stepped:Connect(function()
            if noclip and character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide == true then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
})

local SelfChamsEnabled = false
local SelfChamsColor = Color3.fromRGB(255, 255, 255)
local RainbowChamsEnabled = false
local originalProperties = {}

local function HSVToRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0

    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end

    return Color3.new(r + m, g + m, b + m)
end

local function applyChams(char)
    task.wait(0)
    originalProperties = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            originalProperties[part] = {
                Color = part.Color,
                Material = part.Material
            }
            part.Material = Enum.Material.ForceField
        end
    end
end

local function removeChams(char)
    if not char then return end
    for part, props in pairs(originalProperties) do
        if part and part.Parent then
            part.Color = props.Color
            part.Material = props.Material
        end
    end
    originalProperties = {}
end

local function updateChams()
    if not SelfChamsEnabled or not LocalPlayer.Character then return end
    for part, _ in pairs(originalProperties) do
        if part and part.Parent then
            if RainbowChamsEnabled then
                local hue = (tick() * 120) % 360
                part.Color = HSVToRGB(hue, 1, 1)
            else
                part.Color = SelfChamsColor
            end
        end
    end
end

LocalPlayerSection:AddToggle({
    text = "Self Chams",
    flag = "SelfChams",
    value = false,
    callback = function(state)
        SelfChamsEnabled = state
        if LocalPlayer.Character then
            if SelfChamsEnabled then
                applyChams(LocalPlayer.Character)
            else
                removeChams(LocalPlayer.Character)
            end
        end
    end
})

LocalPlayerSection:AddToggle({
    text = "Rainbow Chams",
    dlag = "RainbowChams",
    value = false,
    callback = function(state)
        RainbowChamsEnabled = state
        if SelfChamsEnabled and LocalPlayer.Character then
            if not RainbowChamsEnabled then
                for part, _ in pairs(originalProperties) do
                    if part and part.Parent then
                        part.Color = SelfChamsColor
                    end
                end
            end
        end
    end
})

:AddColor({
    text = "Chams Color",
    dlag = "ChamsColor",
    value = SelfChamsColor,
    callback = function(color)
        SelfChamsColor = color
        if SelfChamsEnabled and not RainbowChamsEnabled and LocalPlayer.Character then
            for part, _ in pairs(originalProperties) do
                if part and part.Parent then
                    part.Color = SelfChamsColor
                end
            end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    if SelfChamsEnabled then
        applyChams(char)
    else
        removeChams(char)
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    updateChams()
end)

local VisualsTab = library:AddTab("Visuals")
local VisualsColumn1 = VisualsTab:AddColumn()
local VisualsMain = VisualsColumn1:AddSection("Humans")

local Settings = {
    BoxEnabled = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    NameEnabled = false,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameFont = 2,
    NameSize = 13,
    DistanceEnabled = false,
    DistanceColor = Color3.fromRGB(255, 255, 255),
    DistanceFont = 2,
    DistanceSize = 13,
    HealthBarEnabled = false,
    MaxDistance = 1000,
}

VisualsMain:AddToggle({
    text = "Box",
    flag = "Box",
    value = false,
    callback = function(val) Settings.BoxEnabled = val end
}):AddColor({
    value = Settings.BoxColor,
    flag = "BoxColor",
    callback = function(col)
        Settings.BoxColor = col
    end
})
VisualsMain:AddToggle({
    text = "Health",
    flag = "HealthToggle",
    value = false,
    callback = function(val) Settings.HealthBarEnabled = val end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer


local ESPConnections = {}


local function DrawESP(plr)
    repeat wait() until plr.Character and plr.Character:FindFirstChild("Humanoid")
    
    local limbs = {}
    local isR15 = (plr.Character.Humanoid.RigType == Enum.HumanoidRigType.R15)

    local function DrawLine()
        local line = Drawing.new("Line")
        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(1, 1)
        line.Color = Color3.fromRGB(255, 0, 0)
        line.Thickness = 1
        line.Transparency = 1
        return line
    end

    if isR15 then
        limbs = {
            Head_UpperTorso = DrawLine(),
            UpperTorso_LowerTorso = DrawLine(),
            UpperTorso_LeftUpperArm = DrawLine(),
            LeftUpperArm_LeftLowerArm = DrawLine(),
            LeftLowerArm_LeftHand = DrawLine(),
            UpperTorso_RightUpperArm = DrawLine(),
            RightUpperArm_RightLowerArm = DrawLine(),
            RightLowerArm_RightHand = DrawLine(),
            LowerTorso_LeftUpperLeg = DrawLine(),
            LeftUpperLeg_LeftLowerLeg = DrawLine(),
            LeftLowerLeg_LeftFoot = DrawLine(),
            LowerTorso_RightUpperLeg = DrawLine(),
            RightUpperLeg_RightLowerLeg = DrawLine(),
            RightLowerLeg_RightFoot = DrawLine(),
        }
    else
        limbs = {
            Head_Spine = DrawLine(),
            Spine = DrawLine(),
            LeftArm = DrawLine(),
            LeftArm_UpperTorso = DrawLine(),
            RightArm = DrawLine(),
            RightArm_UpperTorso = DrawLine(),
            LeftLeg = DrawLine(),
            LeftLeg_LowerTorso = DrawLine(),
            RightLeg = DrawLine(),
            RightLeg_LowerTorso = DrawLine()
        }
    end

    local function SetVisibility(state)
        for _, line in pairs(limbs) do
            line.Visible = state
        end
    end

    local function RemoveLines()
        for _, line in pairs(limbs) do
            line:Remove()
        end
    end

    local connection
    if isR15 then
        connection = RunService.RenderStepped:Connect(function()
            local char = plr.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 then
                local _, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                if onScreen then
                    local H = Camera:WorldToViewportPoint(char.Head.Position)
                    local UT = Camera:WorldToViewportPoint(char.UpperTorso.Position)
                    local LT = Camera:WorldToViewportPoint(char.LowerTorso.Position)
                    local LUA = Camera:WorldToViewportPoint(char.LeftUpperArm.Position)
                    local LLA = Camera:WorldToViewportPoint(char.LeftLowerArm.Position)
                    local LH = Camera:WorldToViewportPoint(char.LeftHand.Position)
                    local RUA = Camera:WorldToViewportPoint(char.RightUpperArm.Position)
                    local RLA = Camera:WorldToViewportPoint(char.RightLowerArm.Position)
                    local RH = Camera:WorldToViewportPoint(char.RightHand.Position)
                    local LUL = Camera:WorldToViewportPoint(char.LeftUpperLeg.Position)
                    local LLL = Camera:WorldToViewportPoint(char.LeftLowerLeg.Position)
                    local LF = Camera:WorldToViewportPoint(char.LeftFoot.Position)
                    local RUL = Camera:WorldToViewportPoint(char.RightUpperLeg.Position)
                    local RLL = Camera:WorldToViewportPoint(char.RightLowerLeg.Position)
                    local RF = Camera:WorldToViewportPoint(char.RightFoot.Position)

                    limbs.Head_UpperTorso.From = Vector2.new(H.X, H.Y)
                    limbs.Head_UpperTorso.To = Vector2.new(UT.X, UT.Y)

                    limbs.UpperTorso_LowerTorso.From = Vector2.new(UT.X, UT.Y)
                    limbs.UpperTorso_LowerTorso.To = Vector2.new(LT.X, LT.Y)

                    limbs.UpperTorso_LeftUpperArm.From = Vector2.new(UT.X, UT.Y)
                    limbs.UpperTorso_LeftUpperArm.To = Vector2.new(LUA.X, LUA.Y)

                    limbs.LeftUpperArm_LeftLowerArm.From = Vector2.new(LUA.X, LUA.Y)
                    limbs.LeftUpperArm_LeftLowerArm.To = Vector2.new(LLA.X, LLA.Y)

                    limbs.LeftLowerArm_LeftHand.From = Vector2.new(LLA.X, LLA.Y)
                    limbs.LeftLowerArm_LeftHand.To = Vector2.new(LH.X, LH.Y)

                    limbs.UpperTorso_RightUpperArm.From = Vector2.new(UT.X, UT.Y)
                    limbs.UpperTorso_RightUpperArm.To = Vector2.new(RUA.X, RUA.Y)

                    limbs.RightUpperArm_RightLowerArm.From = Vector2.new(RUA.X, RUA.Y)
                    limbs.RightUpperArm_RightLowerArm.To = Vector2.new(RLA.X, RLA.Y)

                    limbs.RightLowerArm_RightHand.From = Vector2.new(RLA.X, RLA.Y)
                    limbs.RightLowerArm_RightHand.To = Vector2.new(RH.X, RH.Y)

                    limbs.LowerTorso_LeftUpperLeg.From = Vector2.new(LT.X, LT.Y)
                    limbs.LowerTorso_LeftUpperLeg.To = Vector2.new(LUL.X, LUL.Y)

                    limbs.LeftUpperLeg_LeftLowerLeg.From = Vector2.new(LUL.X, LUL.Y)
                    limbs.LeftUpperLeg_LeftLowerLeg.To = Vector2.new(LLL.X, LLL.Y)

                    limbs.LeftLowerLeg_LeftFoot.From = Vector2.new(LLL.X, LLL.Y)
                    limbs.LeftLowerLeg_LeftFoot.To = Vector2.new(LF.X, LF.Y)

                    limbs.LowerTorso_RightUpperLeg.From = Vector2.new(LT.X, LT.Y)
                    limbs.LowerTorso_RightUpperLeg.To = Vector2.new(RUL.X, RUL.Y)

                    limbs.RightUpperLeg_RightLowerLeg.From = Vector2.new(RUL.X, RUL.Y)
                    limbs.RightUpperLeg_RightLowerLeg.To = Vector2.new(RLL.X, RLL.Y)

                    limbs.RightLowerLeg_RightFoot.From = Vector2.new(RLL.X, RLL.Y)
                    limbs.RightLowerLeg_RightFoot.To = Vector2.new(RF.X, RF.Y)

                    if not limbs.Head_UpperTorso.Visible then
                        SetVisibility(true)
                    end
                else
                    if limbs.Head_UpperTorso.Visible then
                        SetVisibility(false)
                    end
                end
            else
                if limbs.Head_UpperTorso.Visible then
                    SetVisibility(false)
                end
                if not Players:FindFirstChild(plr.Name) then
                    RemoveLines()
                    connection:Disconnect()
                end
            end
        end)
    else
        connection = RunService.RenderStepped:Connect(function()
            local char = plr.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 then
                local _, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                if onScreen then
                    local H = Camera:WorldToViewportPoint(char.Head.Position)
                    local torso = char.Torso or char.UpperTorso
                    local T_Height = torso.Size.Y/2 - 0.2
                    local UT = Camera:WorldToViewportPoint((torso.CFrame * CFrame.new(0, T_Height, 0)).p)
                    local LT = Camera:WorldToViewportPoint((torso.CFrame * CFrame.new(0, -T_Height, 0)).p)

                    local LA = char["Left Arm"]
                    local LA_Height = LA.Size.Y/2 - 0.2
                    local LUA = Camera:WorldToViewportPoint((LA.CFrame * CFrame.new(0, LA_Height, 0)).p)
                    local LLA = Camera:WorldToViewportPoint((LA.CFrame * CFrame.new(0, -LA_Height, 0)).p)

                    local RA = char["Right Arm"]
                    local RA_Height = RA.Size.Y/2 - 0.2
                    local RUA = Camera:WorldToViewportPoint((RA.CFrame * CFrame.new(0, RA_Height, 0)).p)
                    local RLA = Camera:WorldToViewportPoint((RA.CFrame * CFrame.new(0, -RA_Height, 0)).p)

                    local LL = char["Left Leg"]
                    local LL_Height = LL.Size.Y/2 - 0.2
                    local LUL = Camera:WorldToViewportPoint((LL.CFrame * CFrame.new(0, LL_Height, 0)).p)
                    local LLL = Camera:WorldToViewportPoint((LL.CFrame * CFrame.new(0, -LL_Height, 0)).p)

                    local RL = char["Right Leg"]
                    local RL_Height = RL.Size.Y/2 - 0.2
                    local RUL = Camera:WorldToViewportPoint((RL.CFrame * CFrame.new(0, RL_Height, 0)).p)
                    local RLL = Camera:WorldToViewportPoint((RL.CFrame * CFrame.new(0, -RL_Height, 0)).p)

                    limbs.Head_Spine.From = Vector2.new(H.X, H.Y)
                    limbs.Head_Spine.To = Vector2.new(UT.X, UT.Y)

                    limbs.Spine.From = Vector2.new(UT.X, UT.Y)
                    limbs.Spine.To = Vector2.new(LT.X, LT.Y)

                    limbs.LeftArm.From = Vector2.new(LUA.X, LUA.Y)
                    limbs.LeftArm.To = Vector2.new(LLA.X, LLA.Y)

                    limbs.LeftArm_UpperTorso.From = Vector2.new(UT.X, UT.Y)
                    limbs.LeftArm_UpperTorso.To = Vector2.new(LUA.X, LUA.Y)

                    limbs.RightArm.From = Vector2.new(RUA.X, RUA.Y)
                    limbs.RightArm.To = Vector2.new(RLA.X, RLA.Y)

                    limbs.RightArm_UpperTorso.From = Vector2.new(UT.X, UT.Y)
                    limbs.RightArm_UpperTorso.To = Vector2.new(RUA.X, RUA.Y)

                    limbs.LeftLeg.From = Vector2.new(LUL.X, LUL.Y)
                    limbs.LeftLeg.To = Vector2.new(LLL.X, LLL.Y)

                    limbs.LeftLeg_LowerTorso.From = Vector2.new(LT.X, LT.Y)
                    limbs.LeftLeg_LowerTorso.To = Vector2.new(LUL.X, LUL.Y)

                    limbs.RightLeg.From = Vector2.new(RUL.X, RUL.Y)
                    limbs.RightLeg.To = Vector2.new(RLL.X, RLL.Y)

                    limbs.RightLeg_LowerTorso.From = Vector2.new(LT.X, LT.Y)
                    limbs.RightLeg_LowerTorso.To = Vector2.new(RUL.X, RUL.Y)

                    if not limbs.Head_Spine.Visible then
                        SetVisibility(true)
                    end
                else
                    if limbs.Head_Spine.Visible then
                        SetVisibility(false)
                    end
                end
            else
                if limbs.Head_Spine.Visible then
                    SetVisibility(false)
                end
                if not Players:FindFirstChild(plr.Name) then
                    RemoveLines()
                    connection:Disconnect()
                end
            end
        end)
    end

    
    return function()
        connection:Disconnect()
        RemoveLines()
    end
end

local skeletonColor = Color3.fromRGB(255, 255, 255)

VisualsMain:AddToggle({
    text = "Skeleton",
    flag = "SkeletonToggle",
    value = false,
    callback = function(enabled)
        skeletonEnabled = enabled

        if enabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    if not ESPConnections[player.Name] then
                        ESPConnections[player.Name] = DrawESP(player, skeletonColor)
                    end
                end
            end

            if not PlayerAddedConn then
                PlayerAddedConn = Players.PlayerAdded:Connect(function(newPlayer)
                    if newPlayer ~= LocalPlayer and skeletonEnabled then
                        if not ESPConnections[newPlayer.Name] then
                            ESPConnections[newPlayer.Name] = DrawESP(newPlayer, skeletonColor)
                        end
                    end
                end)
            end

            if not PlayerRemovingConn then
                PlayerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
                    if ESPConnections[leavingPlayer.Name] then
                        ESPConnections[leavingPlayer.Name]()
                        ESPConnections[leavingPlayer.Name] = nil
                    end
                end)
            end
        else
            for playerName, cleanupFunc in pairs(ESPConnections) do
                cleanupFunc()
                ESPConnections[playerName] = nil
            end

            if PlayerAddedConn then
                PlayerAddedConn:Disconnect()
                PlayerAddedConn = nil
            end

            if PlayerRemovingConn then
                PlayerRemovingConn:Disconnect()
                PlayerRemovingConn = nil
            end
        end
    end
})

VisualsMain:AddToggle({
    text = "Name Player",
    flag = "NameESP",
    default = false,
    callback = function(val) Settings.NameEnabled = val end
}):AddColor({
    value = Settings.NameColor,
    flag = "NameColor",
    callback = function(col)
        Settings.NameColor = col
    end
})

VisualsMain:AddToggle({
    text = "Distance",
    flag = "DistanceESP",
    value = false,
    callback = function(val) Settings.DistanceEnabled = val end
}):AddColor({
    value = Settings.DistanceColor,
    flag = "DistanceColor",
    callback = function(col)
        Settings.DistanceColor = col
    end
})

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local highlights = {}
local HighlightsEnabled = false
local HighlightColor = Color3.fromRGB(255, 255, 0)

local function addHighlightToCharacter(character, player)
	if not HighlightsEnabled then return end
	if player == localPlayer then return end
	if highlights[player] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PlayerHighlight"
	highlight.FillColor = HighlightColor
	highlight.OutlineColor = HighlightColor
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Adornee = character
	highlight.Parent = character

	highlights[player] = highlight
end

local function removeHighlight(player)
	if highlights[player] then
		highlights[player]:Destroy()
		highlights[player] = nil
	end
end

local function onCharacterAdded(character, player)
	if player == localPlayer then return end
	if character:IsDescendantOf(game) then
		addHighlightToCharacter(character, player)
	else
		character.AncestryChanged:Wait()
		addHighlightToCharacter(character, player)
	end
end

local function onPlayerAdded(player)
	if player == localPlayer then return end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)
	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

local function onPlayerRemoving(player)
	removeHighlight(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

VisualsMain:AddToggle({
	text = "Chams",
	flag = "Highlight",
	value = false,
	callback = function(val)
		HighlightsEnabled = val
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= localPlayer then
				if val then
					if player.Character then
						addHighlightToCharacter(player.Character, player)
					end
				else
					removeHighlight(player)
				end
			end
		end
	end
}):AddColor({
	value = HighlightColor,
	flag = "HighlightColor",
	callback = function(color)
		HighlightColor = color
		for _, highlight in pairs(highlights) do
			highlight.FillColor = HighlightColor
			highlight.OutlineColor = HighlightColor
		end
	end
})

VisualsMain:AddSlider({
    text = "Max Distance",
    flag = "MaxDistance",
    min = 1000,
    max = 10000,
    value = Settings.MaxDistance,
    suffix = " studs",
    callback = function(value)
        Settings.MaxDistance = value
    end
})

VisualsMain:AddButton({
    text = "Map Esp",
    callback = function()
        local interfaceMap = require(game:GetService("ReplicatedFirst").Framework).Interface.Map
        interfaceMap:EnableGodview()
    end
})

local boxDrawings = {}
local outlineDrawings = {}

local function createBoxESP(player)
    if boxDrawings[player] or outlineDrawings[player] then return end

    local box = Drawing.new("Square")
    local outline = Drawing.new("Square")

    box.Thickness, box.ZIndex, box.Visible = 1, 2, false
    outline.Thickness, outline.ZIndex, outline.Visible = 1, 1, false

    boxDrawings[player] = box
    outlineDrawings[player] = outline

    game:GetService("RunService").RenderStepped:Connect(function()
        local char = player.Character
        if not char then
            box.Visible = false
            outline.Visible = false
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if hrp and hum then
            local camera = workspace.CurrentCamera
            local charPos = hrp.Position
            local cameraPos = camera.CFrame.Position
            local distance = (cameraPos - charPos).Magnitude
            local pos, onScreen = camera:WorldToViewportPoint(charPos)

            if Settings.BoxEnabled and hum.Health > 0 and onScreen and distance <= Settings.MaxDistance then
                local scale = 1 / (pos.Z * math.tan(math.rad(camera.FieldOfView / 2)) * 2) * 100
                local w, h = 40 * scale, 60 * scale
                local x, y = pos.X - w / 2, pos.Y - h / 2

                box.Size = Vector2.new(w, h)
                box.Position = Vector2.new(x, y)
                box.Color = Settings.BoxColor
                box.Visible = true

                outline.Size = Vector2.new(w + 2, h + 2)
                outline.Position = Vector2.new(x - 1, y - 1)
                outline.Color = Settings.OutlineColor
                outline.Visible = true
            else
                box.Visible = false
                outline.Visible = false
            end
        else
            box.Visible = false
            outline.Visible = false
        end
    end)
end

local function CreateHealthESP(player)
    local segments, bars = 10, {}
    local outline = Drawing.new("Square")
    outline.Thickness = 1
    outline.Color = Color3.new(0, 0, 0)
    outline.Filled = false
    outline.Visible = false

    for i = 1, segments do
        local seg = Drawing.new("Square")
        seg.Filled = true
        seg.Visible = false
        table.insert(bars, seg)
    end

    game:GetService("RunService").RenderStepped:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            for _, s in ipairs(bars) do s.Visible = false end
            outline.Visible = false
            return
        end

        local hum = player.Character:FindFirstChild("Humanoid")
        if not hum or not Settings.HealthBarEnabled then
            for _, s in ipairs(bars) do s.Visible = false end
            outline.Visible = false
            return
        end

        local camera = workspace.CurrentCamera
        local pos, vis = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
        local distance = (camera.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude

        if vis and hum.Health > 0 and distance <= Settings.MaxDistance then
            local scale = 1 / (pos.Z * math.tan(math.rad(camera.FieldOfView / 2)) * 2) * 100
            local h = math.floor(60 * scale)
            local x, y = math.floor(pos.X - 20 * scale - 8), math.floor(pos.Y - h / 2)

            outline.Size = Vector2.new(4, h)
            outline.Position = Vector2.new(x - 1, y - 1)
            outline.Visible = true

            local hpPerc = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barFill = math.floor(h * hpPerc)
            local segH = barFill / segments

            for i = 1, segments do
                local seg = bars[i]
                local t = i / segments
                local r = t < 0.5 and 42 + (255 - 42) * (t / 0.5) or 255 + (232 - 255) * ((t - 0.5) / 0.5)
                local g = t < 0.5 and 227 + (218 - 227) * (t / 0.5) or 218 + (27 - 218) * ((t - 0.5) / 0.5)
                seg.Color = Color3.fromRGB(r, g, 5)
                seg.Size = Vector2.new(2, segH)
                seg.Position = Vector2.new(x, y + h - segH * (segments - i + 1))
                seg.Visible = true
            end
        else
            for _, s in ipairs(bars) do s.Visible = false end
            outline.Visible = false
        end
    end)
end

local function CreateNameESP(player)
    local name = Drawing.new("Text")
    name.Center, name.Outline, name.Visible = true, true, false
    name.Font, name.Size, name.Color = Settings.NameFont, Settings.NameSize, Settings.NameColor

    game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.NameEnabled and player.Character and player.Character:FindFirstChild("Head") then
            local camera = workspace.CurrentCamera
            local pos, visible = camera:WorldToViewportPoint(player.Character.Head.Position + Vector3.new(0, 2, 0))
            local distance = (camera.CFrame.Position - player.Character.Head.Position).Magnitude
            if visible and distance <= Settings.MaxDistance then
                name.Text = player.Name
                name.Position = Vector2.new(pos.X, pos.Y)
                name.Visible = true
            else
                name.Visible = false
            end
        else
            name.Visible = false
        end
    end)
end

local function CreateDistanceESP(player)
    local dist = Drawing.new("Text")
    dist.Center, dist.Outline, dist.Visible = true, true, false
    dist.Font, dist.Size, dist.Color = Settings.DistanceFont, Settings.DistanceSize, Settings.DistanceColor

    game:GetService("RunService").RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and Settings.DistanceEnabled then
            local camera = workspace.CurrentCamera
            local pos, visible = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            local distanceValue = (camera.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if visible and distanceValue <= Settings.MaxDistance then
                dist.Text = tostring(math.floor(distanceValue)) .. "m"
                dist.Position = Vector2.new(pos.X, pos.Y + 30)
                dist.Visible = true
            else
                dist.Visible = false
            end
        else
            dist.Visible = false
        end
    end)
end

local function CreateFullESP(player)
    if player == game.Players.LocalPlayer then return end
    createBoxESP(player)
    CreateHealthESP(player)
    CreateNameESP(player)
    CreateDistanceESP(player)
end

for _, player in ipairs(game.Players:GetPlayers()) do
    CreateFullESP(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        CreateFullESP(player)
    end)
end

game.Players.PlayerAdded:Connect(function(player)
    if player ~= game.Players.LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(1)
            CreateFullESP(player)
        end)
        if player.Character then
            wait(1)
            CreateFullESP(player)
        end
    end
end)

local VisualsColumn2 = VisualsTab:AddColumn()

local WorldSection = VisualsColumn2:AddSection("World")

WorldSection:AddToggle({
    text = "Full Bright",
    flag = "FullBrightToggle",
    callback = function(enabled)
        local Lighting = game:GetService("Lighting")
        _G.FullBrightEnabled = enabled

        if not _G.FullBrightExecuted then
            _G.FullBrightExecuted = true

            _G.NormalLightingSettings = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                ColorShift_Bottom = Lighting.ColorShift_Bottom,
                ColorShift_Top = Lighting.ColorShift_Top
            }

            local function applyFullBright()
                Lighting.Brightness = 2
                Lighting.ClockTime = 12
                Lighting.FogEnd = 1e6
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                Lighting.ColorShift_Top = Color3.new(0, 0, 0)
                Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
            end

            local function restoreLighting()
                for prop, value in pairs(_G.NormalLightingSettings) do
                    Lighting[prop] = value
                end
            end

            for _, prop in ipairs({
                "Brightness", "ClockTime", "FogEnd", "GlobalShadows", "Ambient",
                "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom"
            }) do
                Lighting:GetPropertyChangedSignal(prop):Connect(function()
                    if _G.FullBrightEnabled then
                        applyFullBright()
                    end
                end)
            end

            task.spawn(function()
                while true do
                    task.wait(1)
                    if _G.FullBrightEnabled then
                        applyFullBright()
                    end
                end
            end)
        end

        if _G.FullBrightEnabled then
            Lighting.Brightness = 2
            Lighting.ClockTime = 12
            Lighting.FogEnd = 1e6
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.ColorShift_Top = Color3.new(0, 0, 0)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        else
            for prop, value in pairs(_G.NormalLightingSettings) do
                Lighting[prop] = value
            end
        end
    end
})

WorldSection:AddToggle({
    text = "No Clouds",
    flag = "NoClouds",
    callback = function(state)
        if state then
            for i, v in pairs(workspace.Terrain:GetChildren()) do
                if v:IsA("Clouds") then
                    v:Destroy()
                end
            end
        end
    end
})

WorldSection:AddToggle({
    text = "No Leaves", 
    flag = "NoLeavesToggle", 
    callback = function(enabled)
        if enabled then
            for i, v in ipairs(workspace:GetDescendants()) do
                if v.Name == "Leaves" then
                    v:Destroy()
                end
            end
        end
    end
})

local Lighting = game:GetService("Lighting")
local selectedTheme = "Default"


Library = Library or {}
Library.Flags = Library.Flags or {}

local Socolo = {}

function applySkybox(theme)
    if theme == "Default" then
        local oldSky = Lighting:FindFirstChildOfClass("Sky")
        if oldSky then
            oldSky:Destroy()
        end
        return
    end

    
    Socolo.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
    Socolo.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
    Socolo.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
    Socolo.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
    Socolo.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
    Socolo.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
    Socolo.StarCount = nil

    if theme == "Sponge Bob" then
        Socolo.SkyboxBk = "http://www.roblox.com/asset/?id=7633178166"
        Socolo.SkyboxDn = "http://www.roblox.com/asset/?id=7633178166"
        Socolo.SkyboxFt = "http://www.roblox.com/asset/?id=7633178166"
        Socolo.SkyboxLf = "http://www.roblox.com/asset/?id=7633178166"
        Socolo.SkyboxRt = "http://www.roblox.com/asset/?id=7633178166"
        Socolo.SkyboxUp = "http://www.roblox.com/asset/?id=7633178166"

    elseif theme == "Vaporwave" then
        Socolo.SkyboxBk = "rbxassetid://1417494030"
        Socolo.SkyboxDn = "rbxassetid://1417494146"
        Socolo.SkyboxFt = "rbxassetid://1417494253"
        Socolo.SkyboxLf = "rbxassetid://1417494402"
        Socolo.SkyboxRt = "rbxassetid://1417494499"
        Socolo.SkyboxUp = "rbxassetid://1417494643"

    elseif theme == "Clouds" then
        Socolo.SkyboxBk = "rbxassetid://570557514"
        Socolo.SkyboxDn = "rbxassetid://570557775"
        Socolo.SkyboxFt = "rbxassetid://570557559"
        Socolo.SkyboxLf = "rbxassetid://570557620"
        Socolo.SkyboxRt = "rbxassetid://570557672"
        Socolo.SkyboxUp = "rbxassetid://570557727"

    elseif theme == "Twilight" then
        Socolo.SkyboxBk = "rbxassetid://264908339"
        Socolo.SkyboxDn = "rbxassetid://264907909"
        Socolo.SkyboxFt = "rbxassetid://264909420"
        Socolo.SkyboxLf = "rbxassetid://264909758"
        Socolo.SkyboxRt = "rbxassetid://264908886"
        Socolo.SkyboxUp = "rbxassetid://264907379"

    elseif theme == "Chill" then
        Socolo.SkyboxBk = "rbxassetid://5084575798"
        Socolo.SkyboxDn = "rbxassetid://5084575916"
        Socolo.SkyboxFt = "rbxassetid://5103949679"
        Socolo.SkyboxLf = "rbxassetid://5103948542"
        Socolo.SkyboxRt = "rbxassetid://5103948784"
        Socolo.SkyboxUp = "rbxassetid://5084576400"

    elseif theme == "Minecraft" then
        Socolo.SkyboxBk = "rbxassetid://1876545003"
        Socolo.SkyboxDn = "rbxassetid://1876544331"
        Socolo.SkyboxFt = "rbxassetid://1876542941"
        Socolo.SkyboxLf = "rbxassetid://1876543392"
        Socolo.SkyboxRt = "rbxassetid://1876543764"
        Socolo.SkyboxUp = "rbxassetid://1876544642"

    elseif theme == "Among Us" then
        Socolo.SkyboxBk = "rbxassetid://5752463190"
        Socolo.SkyboxDn = "rbxassetid://5872485020"
        Socolo.SkyboxFt = "rbxassetid://5752463190"
        Socolo.SkyboxLf = "rbxassetid://5752463190"
        Socolo.SkyboxRt = "rbxassetid://5752463190"
        Socolo.SkyboxUp = "rbxassetid://5752463190"

    elseif theme == "Redshift" then
        Socolo.SkyboxBk = "rbxassetid://401664839"
        Socolo.SkyboxDn = "rbxassetid://401664862"
        Socolo.SkyboxFt = "rbxassetid://401664960"
        Socolo.SkyboxLf = "rbxassetid://401664881"
        Socolo.SkyboxRt = "rbxassetid://401664901"
        Socolo.SkyboxUp = "rbxassetid://401664936"

    elseif theme == "Aesthetic Night" then
        Socolo.SkyboxBk = "rbxassetid://1045964490"
        Socolo.SkyboxDn = "rbxassetid://1045964368"
        Socolo.SkyboxFt = "rbxassetid://1045964655"
        Socolo.SkyboxLf = "rbxassetid://1045964655"
        Socolo.SkyboxRt = "rbxassetid://1045964655"
        Socolo.SkyboxUp = "rbxassetid://1045962969"

    elseif theme == "Neptune" then
        Socolo.SkyboxBk = "rbxassetid://218955819"
        Socolo.SkyboxDn = "rbxassetid://218953419"
        Socolo.SkyboxFt = "rbxassetid://218954524"
        Socolo.SkyboxLf = "rbxassetid://218958493"
        Socolo.SkyboxRt = "rbxassetid://218957134"
        Socolo.SkyboxUp = "rbxassetid://218950090"
        Socolo.StarCount = 5000

    elseif theme == "Galaxy" then
        Socolo.SkyboxBk = "http://www.roblox.com/asset/?id=159454299"
        Socolo.SkyboxDn = "http://www.roblox.com/asset/?id=159454296"
        Socolo.SkyboxFt = "http://www.roblox.com/asset/?id=159454293"
        Socolo.SkyboxLf = "http://www.roblox.com/asset/?id=159454286"
        Socolo.SkyboxRt = "http://www.roblox.com/asset/?id=159454300"
        Socolo.SkyboxUp = "http://www.roblox.com/asset/?id=159454288"
        Socolo.StarCount = 5000
    end

    
    local oldSky = Lighting:FindFirstChildOfClass("Sky")
    if oldSky then
        oldSky:Destroy()
    end

    
    local sky = Instance.new("Sky")
    sky.Name = "CustomSkybox"
    sky.SkyboxBk = Socolo.SkyboxBk
    sky.SkyboxDn = Socolo.SkyboxDn
    sky.SkyboxFt = Socolo.SkyboxFt
    sky.SkyboxLf = Socolo.SkyboxLf
    sky.SkyboxRt = Socolo.SkyboxRt
    sky.SkyboxUp = Socolo.SkyboxUp
    sky.Parent = Lighting
end


WorldSection:AddToggle({
    text = "Custom Sky",
    flag = "CustomSkyEnabled",
    value = false,
    callback = function(enabled)
        Library.Flags["CustomSkyEnabled"] = enabled
        if enabled then
            applySkybox(selectedTheme)
        else
            applySkybox("Default")
        end
    end
})


WorldSection:AddList({
    text = "Select Sky",
    flag = "CustomSkyTheme",
    values = {
        "Default",
        "Sponge Bob",
        "Vaporwave",
        "Clouds",
        "Twilight",
        "Chill",
        "Minecraft",
        "Among Us",
        "Redshift",
        "Aesthetic Night",
        "Neptune",
        "Galaxy",
    },
    value = "Default",
    callback = function(value)
        selectedTheme = value
        Library.Flags["CustomSkyTheme"] = value
        if Library.Flags["CustomSkyEnabled"] then
            applySkybox(selectedTheme)
        end
    end
})

local SettingsTab = library:AddTab("Settings")
local SettingsColumn = SettingsTab:AddColumn()
local SettingsColumn2 = SettingsTab:AddColumn()
local SettingSection = SettingsColumn:AddSection("Menu")
local ConfigSection = SettingsColumn2:AddSection("Configs")
local Warning = library:AddWarning({type = "confirm"})

SettingSection:AddBind({text = "Open / Close", flag = "UI Toggle", nomouse = true, key = "End", callback = function()
    library:Close()
end})
SettingSection:AddButton({text = "Unload UI", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"])
    Warning.text = "<font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. 'Are you sure you wanna unload the UI?' .. "</font>"
    if Warning:Show() then
        library:Unload()
    end
end})
SettingSection:AddColor({text = "Accent Color", flag = "Menu Accent Color", color = Color3.fromRGB(88,133,198), callback = function(color)
    if library.currentTab then
        library.currentTab.button.TextColor3 = color
    end
    for i,v in pairs(library.theme) do
        v[(v.ClassName == "TextLabel" and "TextColor3") or (v.ClassName == "ImageLabel" and "ImageColor3") or "BackgroundColor3"] = color
    end
end})

local backgroundlist = {
    Floral = "rbxassetid://5553946656",
    Flowers = "rbxassetid://6071575925",
    Circles = "rbxassetid://6071579801",
    Hearts = "rbxassetid://6073763717"
}

local back = SettingSection:AddList({text = "Background", max = 5, flag = "background", values = {"Floral", "Flowers", "Circles", "Hearts",}, value = "Floral", callback = function(v)
    if library.main then
        library.main.Image = backgroundlist[v]
    end
end})

back:AddColor({flag = "backgroundcolor", color = Color3.new(), callback = function(color)
    if library.main then
        library.main.ImageColor3 = Color or Color3.fromRGB(37,38,38)
    end
end, trans = 1, calltrans = function(trans)
    if library.main then
        library.main.ImageTransparency = 1 - trans
    end
end})

SettingSection:AddSlider({text = "Tile Size", min = 50, max = 500, value = 50, callback = function(size)
    if library.main then
        library.main.TileSize = UDim2.new(0, size, 0, size)
    end
end})

SettingSection:AddButton({text = "Discord", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"])
    Warning.text = "<font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. 'Discord invite copied to clipboard!' .. "</font>"
    if Warning:Show() then
        setclipboard('discord.gg/awakenkn-gg')
    end
end})

ConfigSection:AddBox({text = "Config Name", skipflag = true})
ConfigSection:AddList({text = "Configs", skipflag = true, value = "", flag = "Config List", values = library:GetConfigs()})

ConfigSection:AddButton({text = "Create", callback = function()
    library:GetConfigs()
    writefile(library.foldername .. "/" .. library.flags["Config Name"] .. library.fileext, "{}")
    library.options["Config List"]:AddValue(library.flags["Config Name"])
end})

ConfigSection:AddButton({text = "Save", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"])
    Warning.text = "Are you sure you want to save the current settings to config <font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. library.flags["Config List"] .. "</font>?"
    if Warning:Show() then
        library:SaveConfig(library.flags["Config List"])
    end
end})

ConfigSection:AddButton({text = "Load", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"])
    Warning.text = "Are you sure you want to load config <font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. library.flags["Config List"] .. "</font>?"
    if Warning:Show() then
        library:LoadConfig(library.flags["Config List"])
    end
end})

ConfigSection:AddButton({text = "Delete", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"])
    Warning.text = "Are you sure you want to delete config <font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. library.flags["Config List"] .. "</font>?"
    if Warning:Show() then
        local config = library.flags["Config List"]
        if table.find(library:GetConfigs(), config) and isfile(library.foldername .. "/" .. config .. library.fileext) then
            library.options["Config List"]:RemoveValue(config)
            delfile(library.foldername .. "/" .. config .. library.fileext)
        end
    end
end})

library:Init()
library:selectTab(library.tabs[1])
