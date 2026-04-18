-- StarterPlayerScripts/ClassSelectUI.client.lua
-- Tutorial (3 slides) y selección de clase + guías contextuales

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClassConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClassConfig"))

local RemoteEvents      = ReplicatedStorage:WaitForChild("RemoteEvents")
local SelectClass       = RemoteEvents:WaitForChild("SelectClass")
local ClassSelected     = RemoteEvents:WaitForChild("ClassSelected")
local TutorialCompleteRE= RemoteEvents:WaitForChild("TutorialComplete")

-- ── Crear UI ──────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ClassSelectGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
backdrop.BackgroundTransparency = 0.1
backdrop.BorderSizePixel  = 0
backdrop.Parent           = screenGui

local panel = Instance.new("Frame")
panel.Size              = UDim2.new(0, 700, 0, 500)
panel.Position          = UDim2.new(0.5, -350, 0.5, -250)
panel.BackgroundColor3  = Color3.fromRGB(20, 20, 40)
panel.BorderSizePixel   = 0
panel.Parent            = backdrop
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

-- Título
local titleLabel = Instance.new("TextLabel")
titleLabel.Size   = UDim2.new(1, 0, 0, 60)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text   = "SURVIVAL RUSH"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
titleLabel.TextScaled = true
titleLabel.Font   = Enum.Font.GothamBold
titleLabel.BackgroundTransparency = 1
titleLabel.Parent = panel

-- Contenido del slide
local slideContent = Instance.new("TextLabel")
slideContent.Size   = UDim2.new(0.9, 0, 0, 200)
slideContent.Position = UDim2.new(0.05, 0, 0, 70)
slideContent.Text   = ""
slideContent.TextColor3 = Color3.fromRGB(220, 220, 220)
slideContent.TextScaled = true
slideContent.Font   = Enum.Font.Gotham
slideContent.TextWrapped = true
slideContent.BackgroundTransparency = 1
slideContent.Parent = panel

-- Contenedor de botones de clase
local classContainer = Instance.new("Frame")
classContainer.Size     = UDim2.new(1, -20, 0, 200)
classContainer.Position = UDim2.new(0, 10, 0, 250)
classContainer.BackgroundTransparency = 1
classContainer.Visible  = false
classContainer.Parent   = panel

local listLayout = Instance.new("UIGridLayout")
listLayout.CellSize     = UDim2.new(0, 100, 0, 90)
listLayout.CellPaddingX = UDim.new(0, 8)
listLayout.CellPaddingY = UDim.new(0, 8)
listLayout.Parent       = classContainer

-- Botón siguiente
local nextBtn = Instance.new("TextButton")
nextBtn.Size   = UDim2.new(0, 150, 0, 45)
nextBtn.Position = UDim2.new(0.5, -75, 1, -60)
nextBtn.Text   = "Siguiente →"
nextBtn.TextColor3 = Color3.fromRGB(255,255,255)
nextBtn.TextScaled = true
nextBtn.Font   = Enum.Font.GothamBold
nextBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
nextBtn.BorderSizePixel = 0
nextBtn.Parent = panel
Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 10)

-- ── Slides ────────────────────────────────────────────────────────────────────
local slides = {
	{
		title   = "🎯 Tu Objetivo",
		content = "Sobrevive el mayor tiempo posible.\n\nMata enemigos → Consigue XP y monedas.\nSube de nivel → Desbloquea nuevas zonas.\nMuere → Penalización de 30 segundos en el timer.",
	},
	{
		title   = "🗺️ El Mapa",
		content = "El mapa tiene 4 zonas:\n• Zona 1 (Nivel 1): Campo Abierto\n• Zona 2 (Nivel 10): Bosque Oscuro\n• Zona 3 (Nivel 30): Ruinas Volcánicas\n• Zona 4 (Nivel 60 + Rebirth): El Void\n\nCada zona tiene tiendas de armas y mejoras.",
	},
	{
		title   = "⚔️ Elige tu Clase",
		content = "Selecciona una clase para comenzar.\nCambiar de clase después cuesta 500 monedas.",
	},
}

local currentSlide = 0
local selectedClass = nil

local function showSlide(index)
	local slide = slides[index]
	if not slide then return end
	currentSlide = index

	titleLabel.Text    = slide.title
	slideContent.Text  = slide.content

	-- Mostrar botones de clase en slide 3
	classContainer.Visible = (index == 3)

	-- Cambiar texto del botón en el último slide
	if index == #slides then
		nextBtn.Text   = "Empezar →"
	else
		nextBtn.Text   = "Siguiente →"
	end
end

-- ── Crear botones de clase ─────────────────────────────────────────────────────
local function createClassButtons()
	for _, className in ipairs(ClassConfig.ORDER) do
		local cfg = ClassConfig[className]
		if not cfg then continue end

		local btn = Instance.new("TextButton")
		btn.Name  = className
		btn.Size  = UDim2.new(0, 100, 0, 90)
		btn.Text  = className .. "\n❤" .. cfg.maxHP .. " ⚡" .. cfg.speed
		btn.TextColor3 = Color3.fromRGB(255,255,255)
		btn.TextScaled = true
		btn.Font  = Enum.Font.GothamBold
		btn.BackgroundColor3 = cfg.gamepassRequired
			and Color3.fromRGB(160, 100, 0)
			or  Color3.fromRGB(40, 60, 120)
		btn.BorderSizePixel = 0
		btn.Parent = classContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

		btn.MouseButton1Click:Connect(function()
			selectedClass = className
			-- Resaltar botón seleccionado
			for _, child in ipairs(classContainer:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = child.Name == className
						and Color3.fromRGB(80, 200, 100)
						or  Color3.fromRGB(40, 60, 120)
				end
			end
		end)
	end
end

createClassButtons()

-- ── Lógica del botón siguiente ────────────────────────────────────────────────
nextBtn.MouseButton1Click:Connect(function()
	if currentSlide < #slides then
		showSlide(currentSlide + 1)
	elseif currentSlide == #slides then
		-- Confirmar selección
		if not selectedClass then
			selectedClass = "Runner" -- default
		end
		-- Cerrar UI y notificar servidor
		screenGui.Enabled = false
		SelectClass:FireServer(selectedClass)
		TutorialCompleteRE:FireServer(selectedClass)
	end
end)

-- ── Activar al recibir primer ClassSelected vacío ─────────────────────────────
ClassSelected.OnClientEvent:Connect(function(className, stats)
	if className then
		-- Actualizar label de clase en HUD si existe
		local hudGui    = playerGui:FindFirstChild("HudGui")
		local classLbl  = hudGui and hudGui:FindFirstChild("ClassLabel", true)
		if classLbl then
			classLbl.Text = "Clase: " .. tostring(className)
		end
	end
end)

-- ── Mostrar tutorial si el jugador es nuevo ────────────────────────────────────
-- El servidor triggerea esto indirectamente. Lo activamos desde el cliente
-- al detectar que tutorialComplete es false (lo sabemos si ClassSelected se
-- dispara con className=nil, o lo manejamos con un RemoteEvent adicional).
-- Para simplificar: mostrar automáticamente al cargar
task.wait(3)
-- Comprobar si ya hizo tutorial (heurística: si classLabel existe y tiene texto)
local hudGui = playerGui:FindFirstChild("HudGui")
if hudGui then
	-- Ya tiene HUD → tutorial puede estar hecho
	-- Disparar igualmente por seguridad (servidor lo ignora si ya está hecho)
end
screenGui.Enabled = true
showSlide(1)
