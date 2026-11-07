-- Protótipo local de coleta de ovos. No Studio, use como ModuleScript no cliente.
-- As áreas de demonstração são posicionadas em relação ao ponto de início.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
assert(player, "Execute em um contexto de cliente.")

local api = {}
local areas = {}
local unlocked = {}
local collected = {}
local health = 100
local currentArea
local base
local egg
local movement
local fleeing = false
local round = 0
local allUnlocked = false

local function rootPart()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function removeEgg()
    if egg then
        egg:Destroy()
        egg = nil
    end
end

local function cancelMovement()
    if movement then
        movement:Cancel()
        movement = nil
    end
end

local function moveTo(position)
    local root = rootPart()
    if not root then
        return false, "Personagem indisponível."
    end

    cancelMovement()
    movement = TweenService:Create(
        root,
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        { Position = position }
    )
    movement:Play()
    return true
end

function api.onAllAreasUnlocked()
    print("Todas as áreas desbloqueadas!")
end

function api.syncUnlockedAreas()
    local count = 0
    for id, area in ipairs(areas) do
        if health >= area.requiredStrength then
            unlocked[id] = true
        end
        if unlocked[id] then
            count = count + 1
        end
    end
    if count > 0 and count == #areas and not allUnlocked then
        allUnlocked = true
        api.onAllAreasUnlocked()
    end
end

function api.onGameStart()
    local root = rootPart()
    if not root then
        return false, "Aguarde o personagem aparecer e chame onGameStart() novamente."
    end

    round = round + 1
    cancelMovement()
    removeEgg()
    base = root.Position
    health = 100
    currentArea = nil
    fleeing = false
    unlocked = {}
    collected = {}
    allUnlocked = false
    areas = {}

    for id = 1, 11 do
        local offset = Vector3.new(id * 24, 0, 0)
        areas[id] = {
