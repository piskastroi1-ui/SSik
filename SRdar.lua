local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Таблица брайнротов с их приоритетами (10-балльная система)
local brainrotPriorities = {
    ["Garama and Madundung"] = 4,
    ["Dragon Cannelloni"] = 8,
    ["Nuclearo Dinossauro"] = 1,
    ["Esok Sekolah"] = 1,
    ["La Supreme Combinasion"] = 5,
    ["Ketupat Kepat"] = 2,
    ["Strawberry Elephant"] = 10,
    ["Spaghetti Tualetti"] = 2,
    ["Ketchuru and Musturu"] = 3,
    ["Tralaledon"] = 3,
    ["Tictac Sahur"] = 3,
    ["Los Primos"] = 3,
    ["Tang Tang Keletang"] = 2,
    ["Money Money Puggy"] = 1,
    ["Burguro And Fryuro"] = 5,
    ["Chillin Chili"] = 3,
    ["La Secret Combinasion"] = 3,
    ["Eviledon"] = 1,
    ["Spooky and Pumpky"] = 4,
    ["La Spooky Grande"] = 1,
    ["Meowl"] = 10,
    ["Chipso and Queso"] = 1,
    ["La Casa Boo"] = 6,
    ["Headless Horseman"] = 9,
    ["Los Tacoritas"] = 3,
    ["Capitano Moby"] = 7,
    ["Cooki and Milki"] = 7,
    ["Los Puggies"] = 1,
    ["Orcaledon"] = 2,
    ["Fragrama and Chocrama"] = 5,
    ["Guest 666"] = 3,
    ["Los Bros"] = 1,
    ["Lavadorito Spinito"] = 3,
    ["W or L"] = 2,
    ["Fishino Clownino"] = 2,
    ["Mieteteira Bicicleteira"] = 1,
    ["La Extinct Grande"] = 1,
    ["Los Chicleteiras"] = 1,
    ["Las Sis"] = 1,
    ["Tacorita Bicicleta"] = 1,
    ["Los Mobilis"] = 1,
}

-- Функция для получения цвета луча в зависимости от приоритета
local function getColorByPriority(priority)
    if priority >= 9 then
        return Color3.fromRGB(255, 0, 255) -- Фиолетовый (максимальный приоритет)
    elseif priority >= 7 then
        return Color3.fromRGB(255, 0, 0) -- Красный (высокий)
    elseif priority >= 5 then
        return Color3.fromRGB(255, 165, 0) -- Оранжевый (средний)
    elseif priority >= 3 then
        return Color3.fromRGB(255, 255, 0) -- Желтый (ниже среднего)
    else
        return Color3.fromRGB(0, 255, 0) -- Зеленый (низкий)
    end
end

-- Функция для проверки, есть ли у брейнрота над головой M/s
local function hasMSOverhead(obj)
    -- Проверяем, является ли объект моделью
    if not obj:IsA("Model") then
        return false
    end
    
    -- Ищем BillboardGui в потомках модели
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BillboardGui") then
            -- В BillboardGui ищем TextLabel
            for _, guiChild in ipairs(child:GetDescendants()) do
                if guiChild:IsA("TextLabel") then
                    -- Проверяем, содержит ли текст M/s
                    if string.find(guiChild.Text, "M/s") then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- Функция для получения информации о найденных брайнротах
local function findBrainrots()
    local foundBrainrots = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        local priority = brainrotPriorities[obj.Name]
        if priority then
            local targetPart = nil
            
            if obj:IsA("BasePart") then
                targetPart = obj
            elseif obj:IsA("Model") then
                targetPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
            end
            
            if targetPart then
                -- Проверяем, есть ли у брейнрота над головой M/s
                if hasMSOverhead(obj) then
                    table.insert(foundBrainrots, {
                        name = obj.Name,
                        priority = priority,
                        part = targetPart,
                        distance = nil -- будет рассчитано позже
                    })
                end
            end
        end
    end
    
    return foundBrainrots
end

-- Основной скрипт с плавными лучами
local function brainrotTracker()
    local lastTarget = nil
    local currentBeam = nil
    local currentGlow = nil
    local currentAttachment0 = nil
    local currentAttachment1 = nil
    
    -- Функция для создания плавного луча
    local function createSmoothBeam(startPos, endPos, thickness, color, transparency)
        -- Создаем луч с помощью Beam для плавности
        local beam = Instance.new("Beam")
        beam.Color = ColorSequence.new(color)
        beam.Transparency = NumberSequence.new(transparency)
        beam.Width0 = thickness
        beam.Width1 = thickness * 0.8
        
        -- Создаем Attachment для начала луча
        local attachment0 = Instance.new("Attachment")
        attachment0.Position = Vector3.new(0, 2, 0)
        attachment0.Parent = workspace.Terrain -- Временный родитель
        
        -- Создаем Attachment для конца луча
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = workspace.Terrain -- Временный родитель
        
        -- Назначаем Attachment луча
        beam.Attachment0 = attachment0
        beam.Attachment1 = attachment1
        beam.Parent = workspace
        
        -- Настраиваем светящийся эффект
        beam.FaceCamera = true
        beam.LightEmission = 0.8
        beam.LightInfluence = 0
        
        return beam, attachment0, attachment1
    end
    
    -- Функция для плавного движения луча
    local function updateBeamPosition(beam, attachment0, attachment1, startPos, endPos)
        if beam and attachment0 and attachment1 then
            -- Плавно обновляем позиции
            attachment0.WorldPosition = startPos
            attachment1.WorldPosition = endPos
        end
    end
    
    -- Подключение к RenderStepped для плавного обновления
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not LocalPlayer.Character then
            if currentBeam then
                currentBeam:Destroy()
                currentBeam = nil
            end
            if currentGlow then
                currentGlow:Destroy()
                currentGlow = nil
            end
            if currentAttachment0 then
                currentAttachment0:Destroy()
                currentAttachment0 = nil
            end
            if currentAttachment1 then
                currentAttachment1:Destroy()
                currentAttachment1 = nil
            end
            return
        end
        
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        
        local startPos = root.Position + Vector3.new(0, 2, 0)
        
        -- Находим всех брайнротов с M/s над головой
        local brainrots = findBrainrots()
        
        if #brainrots == 0 then
            if currentBeam then
                currentBeam:Destroy()
                currentBeam = nil
            end
            if currentGlow then
                currentGlow:Destroy()
                currentGlow = nil
            end
            if currentAttachment0 then
                currentAttachment0:Destroy()
                currentAttachment0 = nil
            end
            if currentAttachment1 then
                currentAttachment1:Destroy()
                currentAttachment1 = nil
            end
            lastTarget = nil
            return
        end
        
        -- Рассчитываем расстояния
        for _, brainrot in pairs(brainrots) do
            brainrot.distance = (startPos - brainrot.part.Position).Magnitude
        end
        
        -- Сортируем по приоритету (наибольший приоритет первый), а если приоритеты равны, то по расстоянию (ближайший первый)
        table.sort(brainrots, function(a, b)
            if a.priority == b.priority then
                return a.distance < b.distance
            end
            return a.priority > b.priority
        end)
        
        -- Берем самого приоритетного брайнрота (или ближайшего при равном приоритете)
        local bestBrainrot = brainrots[1]
        
        -- Если цель изменилась, выводим сообщение
        if lastTarget ~= bestBrainrot.name then
            print("🎯 New target: " .. bestBrainrot.name .. 
                  " (Priority: " .. bestBrainrot.priority .. 
                  ", Distance: " .. string.format("%.1f", bestBrainrot.distance) .. ")")
            lastTarget = bestBrainrot.name
            
            -- Создаем новые лучи для новой цели
            if currentBeam then
                currentBeam:Destroy()
            end
            if currentGlow then
                currentGlow:Destroy()
            end
            if currentAttachment0 then
                currentAttachment0:Destroy()
            end
            if currentAttachment1 then
                currentAttachment1:Destroy()
            end
            
            local color = getColorByPriority(bestBrainrot.priority)
            
            -- Основной луч (Beam для плавности)
            currentBeam, currentAttachment0, currentAttachment1 = createSmoothBeam(
                startPos, 
                bestBrainrot.part.Position, 
                0.1, -- Более тонкий луч
                color, 
                0.4  -- Более прозрачный
            )
            
            -- Эффект свечения (второй луч)
            currentGlow = Instance.new("Beam")
            currentGlow.Color = ColorSequence.new(Color3.new(1, 1, 1))
            currentGlow.Transparency = NumberSequence.new(0.6)
            currentGlow.Width0 = 0.05
            currentGlow.Width1 = 0.04
            
            -- Используем те же Attachment для экономии
            local glowAttachment0 = Instance.new("Attachment")
            glowAttachment0.Position = Vector3.new(0, 2, 0)
            glowAttachment0.Parent = workspace.Terrain
            
            local glowAttachment1 = Instance.new("Attachment")
            glowAttachment1.Parent = workspace.Terrain
            
            currentGlow.Attachment0 = glowAttachment0
            currentGlow.Attachment1 = glowAttachment1
            currentGlow.Parent = workspace
            currentGlow.FaceCamera = true
            currentGlow.LightEmission = 0.5
            currentGlow.LightInfluence = 0
        end
        
        -- Плавно обновляем позиции луча
        if currentBeam and currentAttachment0 and currentAttachment1 and bestBrainrot and bestBrainrot.part then
            updateBeamPosition(currentBeam, currentAttachment0, currentAttachment1, startPos, bestBrainrot.part.Position)
            
            -- Также обновляем позиции свечения
            if currentGlow and currentGlow.Attachment0 and currentGlow.Attachment1 then
                currentGlow.Attachment0.WorldPosition = startPos
                currentGlow.Attachment1.WorldPosition = bestBrainrot.part.Position
            end
        end
        
        -- Проверяем, не слишком ли близко брейнрот (чтобы луч не мешал подбирать)
        if bestBrainrot.distance < 10 then
            -- Уменьшаем прозрачность и толщину луча при близком расстоянии
            if currentBeam then
                currentBeam.Transparency = NumberSequence.new(0.7)
                currentBeam.Width0 = 0.05
                currentBeam.Width1 = 0.04
            end
            if currentGlow then
                currentGlow.Transparency = NumberSequence.new(0.8)
                currentGlow.Width0 = 0.02
                currentGlow.Width1 = 0.01
            end
        else
            -- Возвращаем нормальные настройки
            if currentBeam then
                currentBeam.Transparency = NumberSequence.new(0.4)
                currentBeam.Width0 = 0.1
                currentBeam.Width1 = 0.08
            end
            if currentGlow then
                currentGlow.Transparency = NumberSequence.new(0.6)
                currentGlow.Width0 = 0.05
                currentGlow.Width1 = 0.04
            end
        end
    end)
    
    -- Возвращаем соединение для возможности отключения
    return connection
end

-- Запуск скрипта с обработкой ошибок
local success, err = pcall(function()
    local connection = brainrotTracker()
    
    -- Очистка при выходе
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        if player == LocalPlayer and connection then
            connection:Disconnect()
        end
    end)
end)

if not success then
    print("Ошибка в скрипте: " .. err)
    warn("Убедитесь, что вы в игре и у вас есть персонаж!")
end

print("====================================")
print("Brainrot Tracker запущен!")
print("Скрипт показывает плавный луч к брайнроту с M/s над головой")
print("Луч автоматически становится тоньше при приближении к брейнроту")
print("====================================")

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
