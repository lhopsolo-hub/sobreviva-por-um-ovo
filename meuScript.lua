--[[
  Egg Collection Game Script - Carregado via BFLoader (Delta Executor)
  Compatível com Delta Android e Roblox Studio
  Funções disponíveis para o executor Delta: onGameStart, onEnterArea, onEggCollected, onFleeing, onReturnToBase, onAllAreasUnlocked, die
]]

-- Carrega o BFLoader de uma URL externa
local BFLoader = require(game:HttpGet("https://raw.githubusercontent.com/hanniii1/Loader/refs/heads/main/BFLoader.lua"))

-- Carrega o script de jogo (contém todas as funções)
local gameScript = BFLoader.load()()

-- Funções globais para serem chamadas pelo executor Delta
gameStart = onGameStart
onEnterArea = onEnterArea
onEggCollected = onEggCollected
onFleeing = onFleeing
onReturnToBase = onReturnToBase
onAllAreasUnlocked = onAllAreasUnlocked
die = die

--[[
  Estado do Jogo
  Todas as funções estão no escopo global para serem acessadas pelo executor Delta
]]

local gameState = {
    unlockedAreas = {},      -- Áreas desbloqueadas
    playerHealth = 100,     -- Vida do jogador
    isFleeing = false,      -- Se o jogador está em modo de fuga
    fleeTimer = 0,          -- Temporizador de fuga (30 segundos)
    currentArea = nil,      -- Área atual
    eggSpawned = false      -- Se o ovo já foi coletado
}

--[[
  Funções Principais - Acessíveis via executor Delta
]]

-- Inicializa o jogo
function onGameStart()
    print("Jogo iniciado!")
    syncUnlockedAreas()
end

-- Sincroniza áreas desbloqueadas com a força do jogador
function syncUnlockedAreas()
    for _, area in pairs(CONFIG.Areas) do
        if area.requiredStrength <= gameState.playerHealth then
            gameState.unlockedAreas[area.id] = true
        end
    end
end

-- Cria um ovo em uma área
function spawnEgg(areaId)
    local area = CONFIG.Areas[areaId]
    if not area then return end
    local eggData = CONFIG.EggData[area.id]
    if not eggData then return end
    
    local egg = Instance.new("Part")
    egg.Name = "Egg"
    egg.Anchored = true
    egg.CanCollide = false
    egg.Transparency = 0.5
    egg.BrickColor = BrickColor.new("Lime Green")
    egg.Position = area.eggPosition
    egg.Parent = workspace
    gameState.eggSpawned = true
    print("Ovo spawnado em " .. area.name .. " (Raridade: " .. eggData.rarity .. ")")
end

-- Verifica se o jogador pode entrar na área
function canEnterArea(areaId)
    local area = CONFIG.Areas[areaId]
    if not area then return false end
    if not gameState.unlockedAreas[areaId] then return false end
    if gameState.playerHealth < area.requiredStrength then return false end
    return true
end

-- Ataca o jogador no bosse
function bossAttack(playerPosition)
    local areaId = gameState.currentArea
    if not areaId then return end
    local area = CONFIG.Areas[areaId]
    local boss = area.boss
    
    local attackType = "basic"
    if area.boss == "Boss_01" then attackType = "charge" end
    elseif area.boss == "Boss_02" then attackType = "sweep" end
    elseif area.boss == "Boss_03" then attackType = "burst" end
    elseif area.boss == "Boss_04" then attackType = "slam" end
    elseif area.boss == "Boss_05" then attackType = "pierce" end
    elseif area.boss == "Boss_06" then attackType = "spiral" end
    elseif area.boss == "Boss_07" then attackType = "wave" end
    elseif area.boss == "Boss_08" then attackType = "rush" end
    elseif area.boss == "Boss_09" then attackType = "spike" end
    elseif area.boss == "Boss_10" then attackType = "sweep2" end
    elseif area.boss == "Boss_11" then attackType = "combo" end
    
    local damage = 10 + (math.random(0, 5))
    gameState.playerHealth = math.max(1, gameState.playerHealth - damage)
    
    local particle = Instance.new("ParticleEmitter")
    particle.EmissionRate = 20
    particle.ParticleType = ParticleEmitterType.Fire
    particle.Position = playerPosition
    particle.Parent = workspace
    print("Boss " .. area.boss .. " atacou! Vida: " .. gameState.playerHealth)
end

-- Move o jogador para longe do bosse (floating/gliding)
function floatAway(playerPosition)
    local areaId = gameState.currentArea
    if not areaId then return end
    
    local area = CONFIG.Areas[areaId]
    local boss = area.boss
    
    local direction = (playerPosition - boss.Position).Unit
    direction = direction * 8
    
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.PositionEasingInOut)
    local tween = TweenService:Create(playerPosition, tweenInfo, playerPosition + direction * 50)
    tween:Play()
end

-- Inicia a coleta de ovos (fugir do bosse antes de coletar)
function startFleeing(areaId)
    gameState.isFleeing = true
    gameState.fleeTimer = 30
    gameState.currentArea = areaId
    
    local boss = CONFIG.Areas[areaId].boss
    local direction = (player.Character.HumanoidRootPart.Position - boss.Position).Unit
    direction = direction * 8
    
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.PositionEasingInOut)
    local tween = TweenService:Create(player.Character.HumanoidRootPart, tweenInfo, player.Character.HumanoidRootPart + direction * 50)
    tween:Play()
end

-- Retorna ao base (base da área)
function returnToBase()
    gameState.isFleeing = false
    gameState.fleeTimer = 0
    gameState.currentArea = nil
    
    local areaId = gameState.currentArea
    if areaId then
        local area = CONFIG.Areas[areaId]
        local boss = area.boss
        local direction = (player.Character.HumanoidRootPart.Position - boss.Position).Unit
        direction = direction * 30
        
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.PositionEasingInOut)
        local tween = TweenService:Create(player.Character.HumanoidRootPart, tweenInfo, boss.Position + direction * 30)
        tween:Play()
    end
end

-- Coleta o ovo
function collectEgg(areaId)
    local area = CONFIG.Areas[areaId]
    if not area then return end
    if gameState.eggSpawned then return end
    
    spawnEgg(areaId)
    gameState.eggSpawned = true
    
    -- O jogador flutua para longe do bosse após coletar
    startFleeing(areaId)
    
    -- Atualiza o estado
    gameState.currentArea = areaId
    print("Ovo coletado em " .. area.name)
end

-- Morte do jogador
function die()
    gameState.playerHealth = 0
    gameState.currentArea = nil
    gameState.isFleeing = false
    
    -- Retorna ao base
    returnToBase()
end

-- Notifica quando todas as áreas estão desbloqueadas
function onAllAreasUnlocked()
    print("Todas as áreas desbloqueadas!")
end

--[[
  Eventos de entrada do jogador
]]

function onEnterArea(areaId)
    if gameState.currentArea == areaId then return end
    if canEnterArea(areaId) then
        startFleeing(areaId)
    end
end

--[[
  Eventos de saída (morte)
]]

function onDeath()
    die()
end

--[[
  Eventos de coleta de ovos
]]

function onEggCollected(areaId)
    collectEgg(areaId)
end

--[[
  Inicialização
]]

-- Sincroniza as áreas desbloqueadas com a força inicial
syncUnlockedAreas()

--[[
  Funções principais disponíveis para o executor Delta
  Use estas chaves para chamar as funções no console do Delta Executor:
  delta.execute("onGameStart")
  delta.execute("onEnterArea", 1)      -- Entrar na Área 1
  delta.execute("onEggCollected", 1)   -- Coletar ovo na Área 1
  delta.execute("onFleeing", 1)        -- Iniciar fuga na Área 1
  delta.execute("onReturnToBase")      -- Retornar à base
  delta.execute("onAllAreasUnlocked")  -- Verificar se todas as áreas estão desbloqueadas
  delta.execute("die")                 -- Morte do jogador
]]
