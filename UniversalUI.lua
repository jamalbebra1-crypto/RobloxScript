-// Universal- UI + Funktionen
--// F2 = Menü öffnen / schließen
--// Roblox Studio Schulprojekt

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------
-- EINSTELLUNGEN
--------------------------------------------------

local BACKGROUND = Color3.fromRGB(5, 5, 5)
local SIDEBAR = Color3.fromRGB(8, 8, 8)
local TEXT = Color3.fromRGB(190, 190, 190)
local BORDER = Color3.fromRGB(90, 90, 90)
local GREEN = Color3.fromRGB(0, 255, 0)

local FLY_SPEED = 60
local AIM_MAX_DISTANCE = 1000

--------------------------------------------------
-- ZENTRALE KEYBINDS
--------------------------------------------------

local Keybinds = {
	aim = Enum.KeyCode.Q,
	esp = Enum.KeyCode.E,
	noclip = Enum.KeyCode.N,
	fly = Enum.KeyCode.P
}

--------------------------------------------------
-- STATUS
--------------------------------------------------

local flying = false
local noclipEnabled = false
local espEnabled = false
local aimEnabled = false

local flyVelocity
local flyConnection
local noclipConnection
local aimConnection

local currentTarget = nil
local espObjects = {}

local waitingForKey = nil
local keybindButtons = {}
local keybindDisplays = {}

--------------------------------------------------
-- ALTES GUI ENTFERNEN
--------------------------------------------------

for _, guiName in ipairs({
	"UniversalUI",
	"ProjectKeybindUI"
}) do

	local old = PlayerGui:FindFirstChild(guiName)

	if old then
		old:Destroy()
	end

end

--------------------------------------------------
-- HILFSFUNKTIONEN
--------------------------------------------------

local function getKeyName(key)
	return key and key.Name or "NONE"
end

--------------------------------------------------
-- TEAM
--------------------------------------------------

local function getTeamColor(player)

	if LocalPlayer.Team and player.Team then

		if LocalPlayer.Team == player.Team then
			return Color3.fromRGB(0, 100, 255)
		else
			return Color3.fromRGB(255, 0, 0)
		end

	end

	return Color3.fromRGB(255, 255, 255)

end

local function isEnemy(player)

	if player == LocalPlayer then
		return false
	end

	if LocalPlayer.Team and player.Team then
		return LocalPlayer.Team ~= player.Team
	end

	return true

end

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local function startNoclip()

	if noclipEnabled then
		return
	end

	noclipEnabled = true

	noclipConnection = RunService.Stepped:Connect(function()

		if not noclipEnabled then
			return
		end

		local character = LocalPlayer.Character

		if not character then
			return
		end

		for _, part in ipairs(character:GetDescendants()) do

			if part:IsA("BasePart") then
				part.CanCollide = false
			end

		end

	end)

end

local function stopNoclip()

	if not noclipEnabled then
		return
	end

	noclipEnabled = false

	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end

	local character = LocalPlayer.Character

	if character then

		for _, part in ipairs(character:GetDescendants()) do

			if part:IsA("BasePart") then
				part.CanCollide = true
			end

		end

	end

end

local function toggleNoclip()

	if noclipEnabled then
		stopNoclip()
	else
		startNoclip()
	end

end

--------------------------------------------------
-- FLY
--------------------------------------------------

local function startFly()

	if flying then
		return
	end

	local character = LocalPlayer.Character

	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return
	end

	flying = true
	humanoid.PlatformStand = true

	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.Name = "SchoolProjectFly"
	flyVelocity.MaxForce = Vector3.new(
		math.huge,
		math.huge,
		math.huge
	)

	flyVelocity.Velocity = Vector3.zero
	flyVelocity.Parent = root

	flyConnection = RunService.RenderStepped:Connect(function()

		if not flying or not root.Parent then
			return
		end

		local camera = workspace.CurrentCamera
		local direction = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			direction += camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			direction -= camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			direction -= camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			direction += camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.new(0, 1, 0)
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			direction -= Vector3.new(0, 1, 0)
		end

		if direction.Magnitude > 0 then
			flyVelocity.Velocity =
				direction.Unit * FLY_SPEED
		else
			flyVelocity.Velocity = Vector3.zero
		end

	end)

end

local function stopFly()

	if not flying then
		return
	end

	flying = false

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end

	local character = LocalPlayer.Character

	if character then

		local humanoid =
			character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.PlatformStand = false
		end

	end

end

local function toggleFly()

	if flying then
		stopFly()
	else
		startFly()
	end

end

--------------------------------------------------
-- ESP
--------------------------------------------------

local function removeESP(player)

	local data = espObjects[player]

	if not data then
		return
	end

	if data.connection then
		data.connection:Disconnect()
	end

	for _, object in pairs(data) do

		if typeof(object) == "Instance" then
			object:Destroy()
		end

	end

	espObjects[player] = nil

end

local function createESP(player)

	if player == LocalPlayer then
		return
	end

	removeESP(player)

	local character = player.Character

	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not head or not root then
		return
	end

	local color = getTeamColor(player)

	--------------------------------------------------
	-- HIGHLIGHT
	--------------------------------------------------

	local highlight = Instance.new("Highlight")

	highlight.Name = "ESPBox"
	highlight.Adornee = character
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.85
	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	highlight.Parent = character

	--------------------------------------------------
	-- HEAD MARKER
	--------------------------------------------------

	local headGui = Instance.new("BillboardGui")

	headGui.Name = "HeadMarker"
	headGui.Adornee = head
	headGui.Size = UDim2.fromOffset(45, 45)
	headGui.AlwaysOnTop = true
	headGui.Parent = head

	local headBox = Instance.new("Frame")

	headBox.Size = UDim2.fromScale(1, 1)
	headBox.BackgroundTransparency = 1
	headBox.BorderSizePixel = 2
	headBox.BorderColor3 = color
	headBox.Parent = headGui

	--------------------------------------------------
	-- NAME
	--------------------------------------------------

	local nameGui = Instance.new("BillboardGui")

	nameGui.Name = "PlayerName"
	nameGui.Adornee = head
	nameGui.Size = UDim2.fromOffset(200, 40)
	nameGui.StudsOffset = Vector3.new(0, 2.5, 0)
	nameGui.AlwaysOnTop = true
	nameGui.Parent = head

	local nameLabel = Instance.new("TextLabel")

	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = color
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = nameGui

	--------------------------------------------------
	-- TRACER
	--------------------------------------------------

	local startPart = Instance.new("Part")

	startPart.Name = "ESPTracerStart"
	startPart.Size = Vector3.new(0.1, 0.1, 0.1)
	startPart.Transparency = 1
	startPart.Anchored = true
	startPart.CanCollide = false
	startPart.CanTouch = false
	startPart.CanQuery = false
	startPart.Parent = workspace

	local startAttachment = Instance.new("Attachment")
	startAttachment.Parent = startPart

	local endAttachment = Instance.new("Attachment")
	endAttachment.Parent = root

	local beam = Instance.new("Beam")

	beam.Name = "ESPTracer"
	beam.Attachment0 = startAttachment
	beam.Attachment1 = endAttachment
	beam.Width0 = 0.08
	beam.Width1 = 0.08
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Color = ColorSequence.new(color)
	beam.Parent = startPart

	--------------------------------------------------
	-- UPDATE
	--------------------------------------------------

	local connection = RunService.RenderStepped:Connect(function()

		if not espEnabled then
			return
		end

		local myCharacter = LocalPlayer.Character

		local myRoot =
			myCharacter
			and myCharacter:FindFirstChild("HumanoidRootPart")

		if myRoot and root.Parent then
			startPart.Position = myRoot.Position
		end

		if player.Parent then

			local newColor =
				getTeamColor(player)

			highlight.FillColor = newColor
			highlight.OutlineColor = newColor
			headBox.BorderColor3 = newColor
			nameLabel.TextColor3 = newColor
			beam.Color = ColorSequence.new(newColor)

		end

	end)

	espObjects[player] = {
		highlight = highlight,
		headGui = headGui,
		headBox = headBox,
		nameGui = nameGui,
		startPart = startPart,
		startAttachment = startAttachment,
		endAttachment = endAttachment,
		beam = beam,
		connection = connection
	}

end

local function enableESP()

	if espEnabled then
		return
	end

	espEnabled = true

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then
			createESP(player)
		end

	end

end

local function disableESP()

	if not espEnabled then
		return
	end

	espEnabled = false

	for player in pairs(espObjects) do
		removeESP(player)
	end

end

local function toggleESP()

	if espEnabled then
		disableESP()
	else
		enableESP()
	end

end

--------------------------------------------------
-- AIM
--------------------------------------------------

local function getClosestEnemy()

	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local closestPlayer
	local closestDistance = AIM_MAX_DISTANCE

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	for _, player in ipairs(Players:GetPlayers()) do

		if isEnemy(player) then

			local character = player.Character

			if character then

				local head = character:FindFirstChild("Head")
				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				if head and humanoid and humanoid.Health > 0 then

					local position, onScreen =
						camera:WorldToViewportPoint(
							head.Position
						)

					if onScreen then

						local distance =
							(
								Vector2.new(
									position.X,
									position.Y
								) - center
							).Magnitude

						if distance < closestDistance then
							closestDistance = distance
							closestPlayer = player
						end

					end

				end

			end

		end

	end

	return closestPlayer

end

local function startAimLock()

	if aimEnabled then
		return
	end

	aimEnabled = true

	aimConnection =
		RunService.RenderStepped:Connect(function()

			if not aimEnabled then
				return
			end

			local camera = workspace.CurrentCamera

			if not camera then
				return
			end

			if not currentTarget
				or not currentTarget.Parent
				or not isEnemy(currentTarget) then

				currentTarget = getClosestEnemy()

			end

			if currentTarget then

				local character =
					currentTarget.Character

				if character then

					local head =
						character:FindFirstChild("Head")

					local humanoid =
						character:FindFirstChildOfClass("Humanoid")

					if head and humanoid and humanoid.Health > 0 then

						camera.CFrame =
							CFrame.lookAt(
								camera.CFrame.Position,
								head.Position
							)

					else
						currentTarget = nil
					end

				else
					currentTarget = nil
				end

			end

		end)

end

local function stopAimLock()

	aimEnabled = false
	currentTarget = nil

	if aimConnection then
		aimConnection:Disconnect()
		aimConnection = nil
	end

end

local function toggleAimLock()

	if aimEnabled then
		stopAimLock()
	else
		startAimLock()
	end

end

--------------------------------------------------
-- GUI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "UniversalUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")

Main.Size = UDim2.fromOffset(570, 400)

Main.Position = UDim2.new(
	0.5,
	-285,
	0.5,
	-200
)

Main.BackgroundColor3 = BACKGROUND
Main.BorderColor3 = BORDER
Main.BorderSizePixel = 2
Main.Visible = false
Main.Parent = ScreenGui

--------------------------------------------------
-- TITLE
--------------------------------------------------

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1, -20, 0, 55)
Title.Position = UDim2.fromOffset(10, 0)

Title.BackgroundTransparency = 1
Title.Text = "Universal Menu"
Title.TextColor3 = TEXT
Title.TextSize = 30
Title.Font = Enum.Font.Code
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Line = Instance.new("Frame")

Line.Size = UDim2.new(1, -20, 0, 2)
Line.Position = UDim2.fromOffset(10, 55)

Line.BackgroundColor3 = BORDER
Line.BorderSizePixel = 0
Line.Parent = Main

--------------------------------------------------
-- SIDEBAR
--------------------------------------------------

local Sidebar = Instance.new("Frame")

Sidebar.Size = UDim2.new(0, 125, 1, -57)
Sidebar.Position = UDim2.fromOffset(0, 57)

Sidebar.BackgroundColor3 = SIDEBAR
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideLine = Instance.new("Frame")

SideLine.Size = UDim2.new(0, 2, 1, 0)
SideLine.Position = UDim2.new(1, -2, 0, 0)

SideLine.BackgroundColor3 =
	Color3.fromRGB(70, 70, 70)

SideLine.BorderSizePixel = 0
SideLine.Parent = Sidebar

--------------------------------------------------
-- CONTENT
--------------------------------------------------

local Content = Instance.new("Frame")

Content.Size = UDim2.new(1, -125, 1, -57)
Content.Position = UDim2.fromOffset(125, 57)

Content.BackgroundTransparency = 1
Content.Parent = Main

--------------------------------------------------
-- TABS
--------------------------------------------------

local Tabs = {}
local Buttons = {}

local function CreateTab(name, order)

	local Button = Instance.new("TextButton")

	Button.Size = UDim2.new(1, -10, 0, 55)
	Button.Position =
		UDim2.fromOffset(5, (order - 1) * 60)

	Button.BackgroundColor3 = SIDEBAR
	Button.BorderSizePixel = 0
	Button.Text = name
	Button.TextColor3 = TEXT
	Button.TextSize = 24
	Button.Font = Enum.Font.Code
	Button.Parent = Sidebar

	local Selection = Instance.new("Frame")

	Selection.Size = UDim2.new(0, 4, 1, 0)

	Selection.BackgroundColor3 = GREEN
	Selection.BorderSizePixel = 0
	Selection.Visible = false
	Selection.Parent = Button

	local Page = Instance.new("Frame")

	Page.Name = name .. "Page"
	Page.Size = UDim2.new(1, -20, 1, -20)
	Page.Position = UDim2.fromOffset(10, 10)

	Page.BackgroundTransparency = 1
	Page.Visible = false
	Page.Parent = Content

	Tabs[name] = Page

	Buttons[name] = {
		Button = Button,
		Selection = Selection
	}

	Button.MouseButton1Click:Connect(function()

		for tabName, page in pairs(Tabs) do

			page.Visible = false
			Buttons[tabName].Selection.Visible = false
			Buttons[tabName].Button.TextColor3 = TEXT

		end

		Page.Visible = true
		Selection.Visible = true
		Button.TextColor3 =
			Color3.fromRGB(230, 230, 230)

	end)

	return Page

end

local MenuPage = CreateTab("Menu", 1)
local CombatPage = CreateTab("Combat", 2)
local PlayerPage = CreateTab("Player", 3)

--------------------------------------------------
-- BUTTON
--------------------------------------------------

local function CreateBox(parent, text, y, width)

	local button = Instance.new("TextButton")

	button.Name = text

	button.Size =
		UDim2.fromOffset(width or 300, 55)

	button.Position =
		UDim2.fromOffset(25, y)

	button.BackgroundColor3 =
		Color3.fromRGB(5, 5, 5)

	button.BorderColor3 = BORDER
	button.BorderSizePixel = 2

	button.Text = text
	button.TextColor3 = TEXT
	button.TextSize = 24
	button.Font = Enum.Font.Code
	button.Parent = parent

	return button

end

--------------------------------------------------
-- MENU
--------------------------------------------------

local Welcome = Instance.new("TextLabel")

Welcome.Size = UDim2.new(1, 0, 0, 80)
Welcome.Position = UDim2.fromOffset(20, 50)

Welcome.BackgroundTransparency = 1
Welcome.Text = "Welcome to Universal"
Welcome.TextColor3 = TEXT
Welcome.TextSize = 27
Welcome.Font = Enum.Font.Code
Welcome.TextXAlignment = Enum.TextXAlignment.Left
Welcome.Parent = MenuPage

local Info = Instance.new("TextLabel")

Info.Size = UDim2.new(1, -40, 0, 100)
Info.Position = UDim2.fromOffset(20, 130)

Info.BackgroundTransparency = 1
Info.Text = "F2 = Menü öffnen / schließen"
Info.TextColor3 =
	Color3.fromRGB(130, 130, 130)

Info.TextSize = 20
Info.Font = Enum.Font.Code
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.Parent = MenuPage

--------------------------------------------------
-- KEYBIND BUTTON
--------------------------------------------------

local function CreateKeybind(parent, name, y)

	local button = Instance.new("TextButton")

	button.Size = UDim2.fromOffset(130, 55)
	button.Position = UDim2.fromOffset(335, y)

	button.BackgroundColor3 =
		Color3.fromRGB(5, 5, 5)

	button.BorderColor3 = BORDER
	button.BorderSizePixel = 2

	button.Text =
		"⌨  " .. getKeyName(Keybinds[name])

	button.TextColor3 = TEXT
	button.TextSize = 18
	button.Font = Enum.Font.Code
	button.Parent = parent

	keybindButtons[name] = button

	button.MouseButton1Click:Connect(function()

		if waitingForKey then
			return
		end

		waitingForKey = name

		button.Text = "PRESS KEY"
		button.TextColor3 = GREEN

	end)

	return button

end

--------------------------------------------------
-- COMBAT
--------------------------------------------------

local AimButton =
	CreateBox(CombatPage, "aim: OFF", 25, 300)

CreateKeybind(CombatPage, "aim", 25)

local ESPButton =
	CreateBox(CombatPage, "esp: OFF", 100, 300)

CreateKeybind(CombatPage, "esp", 100)

local NoclipButton =
	CreateBox(CombatPage, "noclip: OFF", 175, 300)

CreateKeybind(CombatPage, "noclip", 175)

--------------------------------------------------
-- PLAYER
--------------------------------------------------

local FlyButton =
	CreateBox(PlayerPage, "fly: OFF", 20, 300)

CreateKeybind(PlayerPage, "fly", 20)

--------------------------------------------------
-- SLIDER
--------------------------------------------------

local function CreateSlider(parent, title, y, defaultValue)

	local Label = Instance.new("TextLabel")

	Label.Size = UDim2.fromOffset(150, 25)
	Label.Position = UDim2.fromOffset(25, y)

	Label.BackgroundTransparency = 1
	Label.Text = title
	Label.TextColor3 = TEXT
	Label.TextSize = 20
	Label.Font = Enum.Font.Code
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = parent

	local ValueLabel = Instance.new("TextLabel")

	ValueLabel.Size = UDim2.fromOffset(50, 25)
	ValueLabel.Position = UDim2.fromOffset(330, y)

	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Text = tostring(defaultValue)
	ValueLabel.TextColor3 = TEXT
	ValueLabel.TextSize = 20
	ValueLabel.Font = Enum.Font.Code
	ValueLabel.Parent = parent

	local Bar = Instance.new("Frame")

	Bar.Size = UDim2.fromOffset(300, 8)
	Bar.Position = UDim2.fromOffset(25, y + 35)

	Bar.BackgroundColor3 =
		Color3.fromRGB(45, 45, 45)

	Bar.BorderSizePixel = 0
	Bar.Parent = parent

	local percent = defaultValue / 100

	local Fill = Instance.new("Frame")

	Fill.Size = UDim2.new(percent, 0, 1, 0)
	Fill.BackgroundColor3 = GREEN
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	local Knob = Instance.new("Frame")

	Knob.Size = UDim2.fromOffset(12, 18)
	Knob.AnchorPoint = Vector2.new(0.5, 0.5)

	Knob.Position =
		UDim2.new(percent, 0, 0.5, 0)

	Knob.BackgroundColor3 =
		Color3.fromRGB(220, 220, 220)

	Knob.BorderSizePixel = 0
	Knob.Parent = Bar

	local ClickArea = Instance.new("TextButton")

	ClickArea.Size = UDim2.new(1, 20, 0, 30)
	ClickArea.Position =
		UDim2.new(0, -10, 0.5, -15)

	ClickArea.BackgroundTransparency = 1
	ClickArea.Text = ""
	ClickArea.Parent = Bar

	local dragging = false

	local function UpdateSlider(mouseX)

		local barX = Bar.AbsolutePosition.X
		local barWidth = Bar.AbsoluteSize.X

		local newPercent =
			math.clamp(
				(mouseX - barX) / barWidth,
				0,
				1
			)

		local value =
			math.floor(newPercent * 100)

		Fill.Size =
			UDim2.new(newPercent, 0, 1, 0)

		Knob.Position =
			UDim2.new(
				newPercent,
				0,
				0.5,
				0
			)

		ValueLabel.Text = tostring(value)

	end

	ClickArea.MouseButton1Down:Connect(function()

		dragging = true

		UpdateSlider(
			UserInputService:GetMouseLocation().X
		)

	end)

	UserInputService.InputChanged:Connect(function(input)

		if dragging and
			input.UserInputType ==
			Enum.UserInputType.MouseMovement then

			UpdateSlider(input.Position.X)

		end

	end)

	UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = false

		end

	end)

end

CreateSlider(PlayerPage, "walkspeed", 95, 16)
CreateSlider(PlayerPage, "jumppower", 180, 50)

--------------------------------------------------
-- STATUS BUTTON UPDATE
--------------------------------------------------

local function UpdateButtons()

	if aimEnabled then
		AimButton.Text = "aim: ON"
		AimButton.TextColor3 = GREEN
	else
		AimButton.Text = "aim: OFF"
		AimButton.TextColor3 = TEXT
	end

	if espEnabled then
		ESPButton.Text = "esp: ON"
		ESPButton.TextColor3 = GREEN
	else
		ESPButton.Text = "esp: OFF"
		ESPButton.TextColor3 = TEXT
	end

	if noclipEnabled then
		NoclipButton.Text = "noclip: ON"
		NoclipButton.TextColor3 = GREEN
	else
		NoclipButton.Text = "noclip: OFF"
		NoclipButton.TextColor3 = TEXT
	end

	if flying then
		FlyButton.Text = "fly: ON"
		FlyButton.TextColor3 = GREEN
	else
		FlyButton.Text = "fly: OFF"
		FlyButton.TextColor3 = TEXT
	end

end

--------------------------------------------------
-- BUTTON FUNCTIONS
--------------------------------------------------

AimButton.MouseButton1Click:Connect(function()

	toggleAimLock()
	UpdateButtons()

end)

ESPButton.MouseButton1Click:Connect(function()

	toggleESP()
	UpdateButtons()

end)

NoclipButton.MouseButton1Click:Connect(function()

	toggleNoclip()
	UpdateButtons()

end)

FlyButton.MouseButton1Click:Connect(function()

	toggleFly()
	UpdateButtons()

end)

--------------------------------------------------
-- KEYBINDS UI
--------------------------------------------------

local KeybindGui = Instance.new("ScreenGui")

KeybindGui.Name = "ProjectKeybindUI"
KeybindGui.ResetOnSpawn = false
KeybindGui.IgnoreGuiInset = true
KeybindGui.Parent = PlayerGui

local KeybindFrame = Instance.new("Frame")

KeybindFrame.Size = UDim2.fromOffset(300, 235)

KeybindFrame.Position =
	UDim2.new(
		1,
		-325,
		1,
		-260
	)

KeybindFrame.BackgroundColor3 =
	Color3.fromRGB(10, 10, 10)

KeybindFrame.BorderSizePixel = 0
KeybindFrame.Active = true
KeybindFrame.Parent = KeybindGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 12)
FrameCorner.Parent = KeybindFrame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = BORDER
FrameStroke.Thickness = 1
FrameStroke.Parent = KeybindFrame

--------------------------------------------------
-- HEADER
--------------------------------------------------

local Header = Instance.new("Frame")

Header.Size = UDim2.new(1, 0, 0, 42)

Header.BackgroundColor3 =
	Color3.fromRGB(15, 15, 15)

Header.BorderSizePixel = 0
Header.Active = true
Header.Parent = KeybindFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderTitle = Instance.new("TextLabel")

HeaderTitle.Size =
	UDim2.new(1, -50, 1, 0)

HeaderTitle.Position =
	UDim2.fromOffset(15, 0)

HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "KEYBINDS"
HeaderTitle.TextColor3 =
	Color3.fromRGB(235, 235, 235)

HeaderTitle.TextSize = 18
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextXAlignment =
	Enum.TextXAlignment.Left

HeaderTitle.Parent = Header

local DragIcon = Instance.new("TextLabel")

DragIcon.Size = UDim2.fromOffset(30, 30)

DragIcon.Position =
	UDim2.new(1, -40, 0, 6)

DragIcon.BackgroundTransparency = 1
DragIcon.Text = "⠿"
DragIcon.TextColor3 =
	Color3.fromRGB(100, 100, 100)

DragIcon.TextSize = 20
DragIcon.Font = Enum.Font.GothamBold
DragIcon.Parent = Header

--------------------------------------------------
-- KEY ROW
--------------------------------------------------

local function CreateKeyRow(name, displayName, y)

	local Row = Instance.new("Frame")

	Row.Size =
		UDim2.new(1, -20, 0, 40)

	Row.Position =
		UDim2.fromOffset(10, y)

	Row.BackgroundColor3 =
		Color3.fromRGB(18, 18, 18)

	Row.BorderSizePixel = 0
	Row.Parent = KeybindFrame

	local RowCorner = Instance.new("UICorner")
	RowCorner.CornerRadius = UDim.new(0, 7)
	RowCorner.Parent = Row

	local NameLabel = Instance.new("TextLabel")

	NameLabel.Size =
		UDim2.new(1, -100, 1, 0)

	NameLabel.Position =
		UDim2.fromOffset(12, 0)

	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = displayName

	NameLabel.TextColor3 =
		Color3.fromRGB(180, 180, 180)

	NameLabel.TextSize = 15
	NameLabel.Font = Enum.Font.GothamMedium
	NameLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	NameLabel.Parent = Row

	local KeyLabel = Instance.new("TextLabel")

	KeyLabel.Size =
		UDim2.fromOffset(75, 28)

	KeyLabel.Position =
		UDim2.new(1, -85, 0.5, -14)

	KeyLabel.BackgroundColor3 =
		Color3.fromRGB(30, 30, 30)

	KeyLabel.BorderSizePixel = 0

	KeyLabel.Text =
		getKeyName(Keybinds[name])

	KeyLabel.TextColor3 =
		Color3.fromRGB(230, 230, 230)

	KeyLabel.TextSize = 14
	KeyLabel.Font = Enum.Font.GothamBold

	KeyLabel.Parent = Row

	local KeyCorner = Instance.new("UICorner")
	KeyCorner.CornerRadius = UDim.new(0, 6)
	KeyCorner.Parent = KeyLabel

	keybindDisplays[name] = KeyLabel

	return KeyLabel

end

CreateKeyRow("fly", "Fly", 52)
CreateKeyRow("esp", "ESP", 98)
CreateKeyRow("aim", "Aim Lock", 144)
CreateKeyRow("noclip", "NoClip", 190)

--------------------------------------------------
-- ZENTRALES UPDATE
--------------------------------------------------

local function UpdateAllKeybindDisplays()

	for name, button in pairs(keybindButtons) do

		button.Text =
			"⌨  " .. getKeyName(Keybinds[name])

		button.TextColor3 = TEXT

	end

	for name, label in pairs(keybindDisplays) do

		label.Text =
			getKeyName(Keybinds[name])

	end

end

--------------------------------------------------
-- KEY INPUT
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)

	--------------------------------------------------
	-- KEYBIND ÄNDERN
	--------------------------------------------------

	if waitingForKey then

		if input.UserInputType ~=
			Enum.UserInputType.Keyboard then
			return
		end

		local name = waitingForKey

		--------------------------------------------------
		-- F2 RESERVIERT
		--------------------------------------------------

		if input.KeyCode == Enum.KeyCode.F2 then

			waitingForKey = nil

			UpdateAllKeybindDisplays()

			return

		end

		--------------------------------------------------
		-- ESC ABBRECHEN
		--------------------------------------------------

		if input.KeyCode == Enum.KeyCode.Escape then

			waitingForKey = nil

			UpdateAllKeybindDisplays()

			return

		end

		--------------------------------------------------
		-- NEUEN KEY SPEICHERN
		--------------------------------------------------

		Keybinds[name] = input.KeyCode

		waitingForKey = nil

		--------------------------------------------------
		-- SOFORT ALLE UI AKTUALISIEREN
		--------------------------------------------------

		UpdateAllKeybindDisplays()

		return

	end

	--------------------------------------------------
	-- F2
	--------------------------------------------------

	if input.KeyCode == Enum.KeyCode.F2 then

		Main.Visible = not Main.Visible

		return

	end

	if gameProcessed then
		return
	end

	--------------------------------------------------
	-- FLY
	--------------------------------------------------

	if input.KeyCode == Keybinds.fly then

		toggleFly()
		UpdateButtons()

	end

	--------------------------------------------------
	-- ESP
	--------------------------------------------------

	if input.KeyCode == Keybinds.esp then

		toggleESP()
		UpdateButtons()

	end

	--------------------------------------------------
	-- AIM
	--------------------------------------------------

	if input.KeyCode == Keybinds.aim then

		toggleAimLock()
		UpdateButtons()

	end

	--------------------------------------------------
	-- NOCLIP
	--------------------------------------------------

	if input.KeyCode == Keybinds.noclip then

		toggleNoclip()
		UpdateButtons()

	end

end)

--------------------------------------------------
-- START TAB
--------------------------------------------------

Tabs.Menu.Visible = true
Buttons.Menu.Selection.Visible = true
Buttons.Menu.Button.TextColor3 =
	Color3.fromRGB(230, 230, 230)

--------------------------------------------------
-- DRAG KEYBINDS UI
--------------------------------------------------

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1 then

		dragging = true
		dragStart = input.Position
		startPosition = KeybindFrame.Position

	end

end)

Header.InputEnded:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1 then

		dragging = false

	end

end)

UserInputService.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement then

		local delta =
			input.Position - dragStart

		KeybindFrame.Position =
			UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,

				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)

	end

end)

--------------------------------------------------
-- PLAYER EVENTS
--------------------------------------------------

local function setupPlayer(player)

	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(function()

		task.wait(0.5)

		if espEnabled then
			createESP(player)
		end

		if currentTarget == player then
			currentTarget = nil
		end

	end)

end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)

	removeESP(player)

	if currentTarget == player then
		currentTarget = nil
	end

end)

--------------------------------------------------
-- LOCALPLAYER RESPAWN
--------------------------------------------------

LocalPlayer.CharacterAdded:Connect(function()

	if flying then
		stopFly()
	end

	if noclipEnabled then
		stopNoclip()
	end

	if aimEnabled then
		stopAimLock()
	end

	task.wait(0.5)

	if espEnabled then

		for _, player in ipairs(Players:GetPlayers()) do

			if player ~= LocalPlayer then
				createESP(player)
			end

		end

	end

	UpdateButtons()
	UpdateAllKeybindDisplays()

end)

--------------------------------------------------
-- FINAL UPDATE
--------------------------------------------------

UpdateButtons()
UpdateAllKeybindDisplays()


--------------------------------------------------
-- AIM LOCK
--------------------------------------------------

local targetDiedConnection = nil

local function clearTarget()

	if targetDiedConnection then
		targetDiedConnection:Disconnect()
		targetDiedConnection = nil
	end

	currentTarget = nil

end

local function lookDownAfterKill()

	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local position = camera.CFrame.Position

	camera.CFrame = CFrame.lookAt(
		position,
		position + Vector3.new(0, -1, 0)
	)

end

local function setTarget(player)

	clearTarget()

	if not player then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	currentTarget = player

	--------------------------------------------------
	-- ZIEL STIRBT
	--------------------------------------------------

	targetDiedConnection =
		humanoid.Died:Connect(function()

			if currentTarget == player then

				clearTarget()

				-- Kamera nach unten
				lookDownAfterKill()

				-- Kurz warten und neues Ziel suchen
				task.delay(0.15, function()

					if aimEnabled then
						currentTarget =
							getClosestEnemy()
					end

				end)

			end

		end)

end

--------------------------------------------------
-- NÄCHSTES ZIEL
--------------------------------------------------

local function getClosestEnemy()

	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local closestPlayer = nil
	local closestDistance = AIM_MAX_DISTANCE

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	for _, player in ipairs(Players:GetPlayers()) do

		if isEnemy(player) then

			local character = player.Character

			if character then

				local head =
					character:FindFirstChild("Head")

				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				if head
					and humanoid
					and humanoid.Health > 0 then

					local position, onScreen =
						camera:WorldToViewportPoint(
							head.Position
						)

					if onScreen then

						local screenDistance =
							(
								Vector2.new(
									position.X,
									position.Y
								) - center
							).Magnitude

						if screenDistance < closestDistance then

							closestDistance =
								screenDistance

							closestPlayer =
								player

						end

					end

				end

			end

		end

	end

	return closestPlayer

end

--------------------------------------------------
-- START AIM
--------------------------------------------------

local function startAimLock()

	if aimEnabled then
		return
	end

	aimEnabled = true

	aimConnection =
		RunService.RenderStepped:Connect(function()

			if not aimEnabled then
				return
			end

			local camera =
				workspace.CurrentCamera

			if not camera then
				return
			end

			--------------------------------------------------
			-- NEUES ZIEL SUCHEN
			--------------------------------------------------

			if not currentTarget
				or not currentTarget.Parent then

				local newTarget =
					getClosestEnemy()

				if newTarget then
					setTarget(newTarget)
				end

			end

			--------------------------------------------------
			-- ZIEL VERFOLGEN
			--------------------------------------------------

			if currentTarget then

				local character =
					currentTarget.Character

				if not character then

					clearTarget()
					return

				end

				local head =
					character:FindFirstChild("Head")

				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				if head
					and humanoid
					and humanoid.Health > 0 then

					camera.CFrame =
						CFrame.lookAt(
							camera.CFrame.Position,
							head.Position
						)

				else

					clearTarget()

				end

			end

		end)

end

--------------------------------------------------
-- STOP AIM
--------------------------------------------------

local function stopAimLock()

	aimEnabled = false

	clearTarget()

	if aimConnection then

		aimConnection:Disconnect()
		aimConnection = nil

	end

end

--------------------------------------------------
-- TOGGLE AIM
--------------------------------------------------

local function toggleAimLock()

	if aimEnabled then
		stopAimLock()
	else
		startAimLock()
	end

end

--------------------------------------------------
-- PLAYER SETTINGS
--------------------------------------------------

local function CreateSlider(parent, title, y, minValue, maxValue, defaultValue, callback)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.fromOffset(150, 25)
	Label.Position = UDim2.fromOffset(25, y)

	Label.BackgroundTransparency = 1
	Label.Text = title
	Label.TextColor3 = TEXT
	Label.TextSize = 20
	Label.Font = Enum.Font.Code
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = parent

	local ValueLabel = Instance.new("TextLabel")
	ValueLabel.Size = UDim2.fromOffset(60, 25)
	ValueLabel.Position = UDim2.fromOffset(330, y)

	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Text = tostring(defaultValue)
	ValueLabel.TextColor3 = TEXT
	ValueLabel.TextSize = 20
	ValueLabel.Font = Enum.Font.Code
	ValueLabel.Parent = parent

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.fromOffset(300, 8)
	Bar.Position = UDim2.fromOffset(25, y + 35)

	Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Bar.BorderSizePixel = 0
	Bar.Parent = parent

	local percent =
		(defaultValue - minValue) /
		(maxValue - minValue)

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(percent, 0, 1, 0)
	Fill.BackgroundColor3 = GREEN
	Fill.BorderSizePixel = 0
	Fill.Parent = Bar

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(12, 18)
	Knob.AnchorPoint = Vector2.new(0.5, 0.5)

	Knob.Position =
		UDim2.new(percent, 0, 0.5, 0)

	Knob.BackgroundColor3 =
		Color3.fromRGB(220, 220, 220)

	Knob.BorderSizePixel = 0
	Knob.Parent = Bar

	local ClickArea = Instance.new("TextButton")

	ClickArea.Size = UDim2.new(1, 20, 0, 30)
	ClickArea.Position =
		UDim2.new(0, -10, 0.5, -15)

	ClickArea.BackgroundTransparency = 1
	ClickArea.Text = ""
	ClickArea.Parent = Bar

	local dragging = false

	local function UpdateSlider(mouseX)

		local barX = Bar.AbsolutePosition.X
		local barWidth = Bar.AbsoluteSize.X

		local newPercent =
			math.clamp(
				(mouseX - barX) / barWidth,
				0,
				1
			)

		local value =
			math.floor(
				minValue +
				(newPercent * (maxValue - minValue))
			)

		Fill.Size =
			UDim2.new(newPercent, 0, 1, 0)

		Knob.Position =
			UDim2.new(
				newPercent,
				0,
				0.5,
				0
			)

		ValueLabel.Text = tostring(value)

		-- Wert anwenden
		callback(value)

	end

	ClickArea.MouseButton1Down:Connect(function()

		dragging = true

		UpdateSlider(
			UserInputService:GetMouseLocation().X
		)

	end)

	UserInputService.InputChanged:Connect(function(input)

		if dragging and
			input.UserInputType ==
			Enum.UserInputType.MouseMovement then

			UpdateSlider(input.Position.X)

		end

	end)

	UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = false

		end

	end)

end

--------------------------------------------------
-- WALKSPEED
--------------------------------------------------

CreateSlider(
	PlayerPage,
	"WalkSpeed",
	95,
	0,
	100,
	16,

	function(value)

		local character = LocalPlayer.Character

		if not character then
			return
		end

		local humanoid =
			character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.WalkSpeed = value
		end

	end
)

--------------------------------------------------
-- JUMPPOWER
--------------------------------------------------

CreateSlider(
	PlayerPage,
	"JumpPower",
	180,
	0,
	150,
	50,

	function(value)

		local character = LocalPlayer.Character

		if not character then
			return
		end

		local humanoid =
			character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = value
		end

	end
)
