local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local radius = 25

-- Кэш для хранения исходных значений
local originalProperties = {}

local function applyEffect(player, hide)
    local char = player.Character
    if not char then return end
    
    if hide then
        -- Сохраняем оригинальные свойства и скрываем
        if not originalProperties[player] then
            originalProperties[player] = {}
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BasePart") then
                    originalProperties[player][obj] = {
                        Transparency = obj.Transparency,
                        CanCollide = obj.CanCollide
                    }
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
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = props.Transparency
                    end
                end
            end
            originalProperties[player] = nil
        end
    end
end

-- Проверка расстояния
task.spawn(function()
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
end)
