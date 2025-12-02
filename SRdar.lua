local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Настройки первого скрипта (скрытие игроков)
local radius = 10
local originalProperties = {}

-- Настройки второго скрипта (ESP - только подсветка)
local highlightColor = Color3.fromRGB(255, 105, 180)
local espData = {}

-- Функции первого скрипта (модифицированные)
local function applyEffect(player, hide)
    local char = player.Character
    if not char then return end
    
    if hide then
        -- Сохраняем оригинальные свойства и скрываем
        if not originalProperties[player] then
            originalProperties[player] = {}
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BasePart") then
                    -- Сохраняем исходные значения
                    originalProperties[player][obj] = {
                        Transparency = obj.Transparency,
                        CanCollide = obj.CanCollide,
                        ESP_Highlight = nil
                    }
                    
                    -- Если есть ESP Highlight, сохраняем его и временно отключаем
                    local highlight = char:FindFirstChild("ESP_Highlight")
                    if highlight then
                        originalProperties[player][obj].ESP_Highlight = highlight
                        highlight.Enabled = false
                    end
                    
                    obj.Transparency = 1
                    obj.CanCollide = false
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    originalProperties[player][obj] = {
                        Transparency = obj.Transparency
                    }
                    obj.Transparency = 1
                end
            end
        end
    else
        -- Восстанавливаем оригинальные свойства
        if originalProperties[player] then
            for obj, props in pairs(originalProperties[player]) do
                if obj and obj.Parent then
                    if obj:IsA("BasePart") then
                        obj.Transparency = props.Transparency
                        obj.CanCollide = props.CanCollide
                        
                        -- Восстанавливаем ESP Highlight если он был
                        if props.ESP_Highlight and props.ESP_Highlight.Parent then
                            props.ESP_Highlight.Enabled = true
                        end
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = props.Transparency
                    end
                end
            end
            originalProperties[player] = nil
        end
    end
end

-- Функции второго скрипта (только подсветка)
local function createESP(player)
    if espData[player] then return end
    
    espData[player] = {
        Highlight = nil
    }
    
    local data = espData[player]
    
    -- Функция для создания подсветки персонажа
    local function addHighlight(character)
        if data.Highlight then
            data.Highlight:Destroy()
        end
        
        -- Проверяем, не скрыт ли игрок в данный момент
        local isHidden = originalProperties[player] ~= nil
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = highlightColor
        highlight.FillTransparency = 0.2
        highlight.OutlineColor = highlightColor
        highlight.OutlineTransparency = 0
        highlight.Adornee = character
        highlight.Parent = character
        highlight.Enabled = not isHidden -- Отключаем если игрок скрыт
        
        data.Highlight = highlight
    end
    
    -- Если персонаж уже существует
    if player.Character then
        addHighlight(player.Character)
    end
    
    -- Следим за появлением нового персонажа
    player.CharacterAdded:Connect(function(character)
        addHighlight(character)
    end)
end

local function updateESP()
    local camera = workspace.CurrentCamera
    
    for player, data in pairs(espData) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            
            -- Проверяем, не скрыт ли игрок
            local isHidden = originalProperties[player] ~= nil
            
            if character and not isHidden then
                local head = character:FindFirstChild("Head")
                
                if head then
                    local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        -- Включаем подсветку если персонаж на экране
                        if data.Highlight then
                            data.Highlight.Enabled = true
                        end
                    else
                        -- Отключаем подсветку если не на экране
                        if data.Highlight then
                            data.Highlight.Enabled = false
                        end
                    end
                end
            else
                -- Отключаем подсветку если игрок скрыт
                if data.Highlight then
                    data.Highlight.Enabled = false
                end
            end
        end
    end
end

local function removeESP(player)
    if espData[player] then
        local data = espData[player]
        
        if data.Highlight then
            data.Highlight:Destroy()
        end
        
        espData[player] = nil
    end
    
    -- Также очищаем данные о скрытии при удалении ESP
    if originalProperties[player] then
        originalProperties[player] = nil
    end
end

-- Функция проверки расстояния
local function checkDistance()
    while task.wait(0.1) do
        local myChar = LocalPlayer.Character
        if not myChar then continue end
        
        local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head")
        if not myRoot then continue end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
                if targetRoot then
                    local distance = (myRoot.Position - targetRoot.Position).Magnitude
                    applyEffect(player, distance <= radius)
                else
                    applyEffect(player, false)
                end
            else
                applyEffect(player, false)
            end
        end
    end
end

-- Инициализация ESP для всех существующих игроков
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

-- Создаем ESP для новых игроков
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

-- Удаляем ESP при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Запускаем все системы
task.spawn(checkDistance)
RunService.RenderStepped:Connect(updateESP)

print("Системы ESP (только подсветка) и скрытия игроков включены!")
