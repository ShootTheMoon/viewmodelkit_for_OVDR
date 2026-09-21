local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FIRST_PERSON_ZOOM = 0.5
local FIELD_OF_VIEW = 100

-- 카메라 높이 보정 (cm). 엔진의 1인칭 시점은 리그 머리뼈 안의 FirstPersonCamera 본이고,
-- 이 값은 거기서 더 올리거나 내리는 양이다.
-- ★ 2026-09-20 : 40 -> 0. 40 이면 눈이 머리 위 40cm 에 있어서, 같은 키의 상대를 봐도
--   정수리가 내려다보였다 (킬캠 AIM_UP 70 = 몸 중심에서 머리까지 높이. 그보다 더 위였다).
--   0 = 머리뼈 = 눈높이. 더 올리고 싶으면 Y 만 키운다.
-- ★ 2026-09-20 : 0 -> 20. 0 이면 뷰모델(월드에 놓인 실제 물체)이 같이 내려가서
--   maxico 칼 손잡이(눈 밑 181cm)가 바닥을 뚫었다. 20 은 그 타협값이다.
-- ★ 2026-09-20 : 20 -> 0. 시점이 전체적으로 높다는 피드백.
--   바닥 뚫림은 이제 ViewmodelConfig 의 SHRINK 가 잡는다 (뷰모델을 눈앞에 붙여 작게).
--   투사체는 Camera.CFrame 에서 나가므로, 이 값이 0 이면 조준점과의 높이 오차도 0 이다.
local CAMERA_HEIGHT_OFFSET = Vector3.new(0, 0, 0)

-- OVERDARE 업데이트 후 캐릭터 의상/손목 메시가 늦게 붙거나 다시 보이는 경우가 있어,
-- 1인칭에서는 로컬 캐릭터의 모든 외형 메시를 반복해서 숨긴다.
local hiddenParts: {[any]: boolean} = {}
local currentCharacter = nil
local rescanTimer = 0
local RESCAN_INTERVAL = 0.2

-- 킬캠이 도는 동안은 1인칭 숨김을 쉰다 (파일 끝 "킬캠" 절 참고).
-- 여기서 매 프레임 다시 숨기면 내가 쓰러지는 걸 볼 수 없다.
local kcOn = false

-- 로비에서 몸을 되돌려놨는지. 로비를 나가면 다시 숨김이 돈다.
local lobbyShown = false

local function applyFirstPersonLock()
	LocalPlayer.CameraMinZoomDistance = FIRST_PERSON_ZOOM
	LocalPlayer.CameraMaxZoomDistance = FIRST_PERSON_ZOOM
	if Camera then
		Camera.FieldOfView = FIELD_OF_VIEW
		pcall(function()
			Camera.CameraOffset = CAMERA_HEIGHT_OFFSET
		end)
	end
end

local function _canHideVisual(instance): boolean
	if instance:IsA("BasePart") then
		return true
	end

	local className = ""
	pcall(function()
		className = instance.ClassName
	end)

	return className == "MeshPart" or className == "Part"
end

local function isLegOrFoot(partName: string): boolean
	if not partName then return false end
	local lower = string.lower(partName)
	return lower:find("leg") ~= nil or lower:find("foot") ~= nil or lower:find("shin") ~= nil or lower:find("thigh") ~= nil or lower:find("knee") ~= nil or lower:find("shoe") ~= nil
end

-- 3인칭용으로 아바타 손에 붙여둔 칼인지. (MovementSpeedServer 가 만든다)
-- 1인칭에서는 뷰모델 칼이 따로 있으므로 이건 보이면 안 된다.
-- 뷰모델은 캐릭터 밑에 있지 않으니 여기에 걸리지 않는다.
local function isWorldHandWeapon(instance): boolean
	local parent = instance.Parent
	if not parent then
		return false
	end
	return parent.Name == "Wakizashi_Right_Hand_Weapon"
		or parent.Name == "Wakizashi_Left_Hand_Weapon"
end

local function forceHideVisual(instance)
	if not instance then
		return
	end

	local className = ""
	pcall(function()
		className = instance.ClassName
	end)

	if className == "Shirt" or className == "Pants" or className == "ShirtGraphic" or className == "Accessory" or instance:IsA("Shirt") or instance:IsA("Pants") then
		pcall(function()
			instance:Destroy()
		end)
		return
	end

	-- 1인칭에서 자기 아바타는 안 보여야 한다. 보여도 되는 건 다리/발뿐이다
	-- (내려다보면 자기 다리가 보이는 게 자연스럽다).
	-- 나머지 팔/몸통/머리는 전부 숨긴다. 3인칭 모션이 팔을 얼굴 앞으로 올리면 바로 보인다.
	-- 뷰모델은 캐릭터 밑에 있지 않아 애초에 여기 안 걸린다.
	--
	-- ※ MeshPart 에서 IsA("BasePart") 가 안 먹는 경우가 있어 ClassName 검사를 겸한다.
	if _canHideVisual(instance) then
		if isWorldHandWeapon(instance) then
			-- 3인칭용 칼. 아래 Wakizashi 예외보다 먼저 걸러야 한다. 순서를 바꾸면 다시 보인다.
			hiddenParts[instance] = true
			pcall(function()
				instance.Transparency = 1
			end)
			pcall(function()
				instance.CastShadow = false
			end)
		elseif instance.Name:find("Wakizashi") or (instance.Parent and instance.Parent.Name:find("Wakizashi")) or isLegOrFoot(instance.Name) then
			hiddenParts[instance] = nil
			pcall(function()
				instance.Transparency = 0
			end)
		else
			hiddenParts[instance] = true
			pcall(function()
				instance.Transparency = 1
			end)
			pcall(function()
				instance.CastShadow = false
			end)
		end
	end
end

local function scanCharacter(character)
	forceHideVisual(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		forceHideVisual(descendant)
	end
end

local function setupCharacter(character)
	currentCharacter = character
	hiddenParts = {}
	scanCharacter(character)
	character.DescendantAdded:Connect(function(descendant)
		forceHideVisual(descendant)
		for _, child in ipairs(descendant:GetDescendants()) do
			forceHideVisual(child)
		end
	end)
	-- 스폰할 때마다 찍히면 지저분해서 뺐다. 문제 생기면 여기 다시 넣어라.
end

applyFirstPersonLock()

LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(applyFirstPersonLock)
LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(applyFirstPersonLock)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
	applyFirstPersonLock()
end)

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
	applyFirstPersonLock()
	setupCharacter(character)
end)

local function enforceFirstPersonHide(dt)
	dt = dt or (1 / 60)

	if kcOn then
		return
	end

	-- ★ 로비(격납고)에서는 아바타가 아예 안 보여야 한다. 진열장 무기만 보여주는 화면이다.
	--   평소엔 다리·발은 남겨두지만 여기서는 그것까지 전부 숨긴다.
	--   (처음엔 반대로 몸을 되돌렸는데, 아바타를 보여주지 않기로 바뀌었다)
	if _G.InLobby then
		if not lobbyShown then
			lobbyShown = true
			if currentCharacter then
				for _, d in ipairs(currentCharacter:GetDescendants()) do
					if _canHideVisual(d) then
						pcall(function()
							d.Transparency = 1
						end)
					end
				end
			end
		end
		return
	elseif lobbyShown then
		lobbyShown = false
		-- 로비를 나가면 다리·발은 다시 보여야 한다. 다음 스캔이 알아서 정리하도록 목록을 비운다
		hiddenParts = {}
		if currentCharacter then
			scanCharacter(currentCharacter)
		end
	end

	if Camera then
		if Camera.FieldOfView ~= FIELD_OF_VIEW then
			Camera.FieldOfView = FIELD_OF_VIEW
		end
		pcall(function()
			if Camera.CameraOffset ~= CAMERA_HEIGHT_OFFSET then
				Camera.CameraOffset = CAMERA_HEIGHT_OFFSET
			end
		end)
	end

	rescanTimer = rescanTimer + dt
	if currentCharacter and currentCharacter.Parent and rescanTimer >= RESCAN_INTERVAL then
		rescanTimer = 0
		scanCharacter(currentCharacter)
	end

	for part in pairs(hiddenParts) do
		if isnil(part) then
			hiddenParts[part] = nil
		else
			-- ★ 매 프레임 값을 다시 써 넣던 것을 "이미 숨겨져 있으면 건너뛴다" 로 바꿨다.
			--   속성 쓰기는 읽기보다 훨씬 비싸다. 이 루프가 프레임의 약 9% 를 먹고 있었다
			--   (실측 2026-08-19 : 이 함수를 통째로 끄면 39.5 -> 43.2 FPS).
			--   읽기 자체가 실패하면 파츠가 지워진 것이므로 목록에서 뺀다.
			local ok, t = pcall(function() return part.Transparency end)
			if not ok then
				hiddenParts[part] = nil
			elseif t ~= 1 then
				pcall(function()
					part.Transparency = 1
				end)
				pcall(function()
					part.CastShadow = false
				end)
			end
		end
	end
end

-- ★ 예전엔 RenderStepped 와 Heartbeat 양쪽에 붙여 프레임당 두 번 돌렸다.
--   같은 일을 두 번 하는 것이라 그대로 두 배 비용이었다. 한쪽만 남긴다.
--   새로 붙는 파츠는 위 DescendantAdded 와 0.2초마다 도는 재스캔이 잡아준다.
RunService.RenderStepped:Connect(enforceFirstPersonHide)

-- ===== 킬캠 =====
--
-- 죽으면 5초 동안 나를 죽인 상대를 비춘다. 카메라는 내 시체 뒤 위쪽에서 상대를 바라보고,
-- 상대에게는 빨간 외곽선이 붙는다. 리스폰하면 자동으로 풀린다.
--
-- ★ 기본 카메라 스크립트가 매 프레임 Camera.CFrame 을 덮어쓴다.
--   RyunochiDragon 의 카메라 흔들림과 같은 수법으로 푼다:
--   BindToRenderStep 을 기본 카메라(200) 보다 늦은 202 로 걸어 맨 마지막에 다시 쓴다.
--   BindToRenderStep 이 없는 버전을 대비해 실패하면 RenderStepped 로 대체한다.
--   (CameraType = Scriptable 은 이 엔진에서 확인된 적이 없어 쓰지 않는다)
--
-- ★ 카메라를 여기서 잡는 이유: 이 스크립트가 이미 카메라와 "내 몸 숨기기" 를 둘 다 쥐고 있다.
--   따로 스크립트를 만들면 둘이 매 프레임 서로 싸운다.

local KILLCAM = {
	TIME = 5,          -- 비추는 시간 (초). 서버가 보내주는 RESPAWN_TIME 으로 덮인다
	BACK = 260,        -- 시체 뒤로 물러나는 거리 (cm)
	UP = 170,          -- 위로 올라가는 높이 (cm)
	AIM_UP = 70,       -- 상대 몸 중심에서 위로 얼마를 겨냥하는가 (cm)
	COLOR = Color3.fromRGB(255, 90, 90),
}

-- 지역변수를 늘리지 않으려고 상태를 테이블 하나에 담았다.
local kc = { endAt = 0, killer = nil, name = nil, outline = nil, vm = {}, gui = nil, label = nil }

local function kcBodyOf(player)
	local ch = player and player.Character
	if not ch then
		return nil
	end
	return ch:FindFirstChild("HumanoidRootPart")
		or ch:FindFirstChild("Torso")
		or ch:FindFirstChild("Head")
end

-- 뷰모델은 카메라에 붙어 그려진다. 킬캠 동안에는 화면을 통째로 가리므로 숨긴다.
local function kcViewmodel(hide)
	local vm = Workspace:FindFirstChild("Wakizashi_Viewmodel_Runtime")
	if not vm then
		return
	end
	if hide then
		for _, d in ipairs(vm:GetDescendants()) do
			if _canHideVisual(d) and kc.vm[d] == nil then
				local ok, t = pcall(function()
					return d.Transparency
				end)
				if ok then
					kc.vm[d] = t
					pcall(function()
						d.Transparency = 1
					end)
				end
			end
		end
	else
		-- 원래 값으로 되돌린다. 전부 0 으로 밀면 안 된다.
		-- 쿠나이처럼 원래 숨어 있던 파츠가 튀어나온다.
		for d, t in pairs(kc.vm) do
			pcall(function()
				d.Transparency = t
			end)
		end
		kc.vm = {}
	end
end

-- 나를 죽인 상대를 강조한다. Highlight 클래스는 이 엔진에 없어서 Outline 을 쓴다
-- (FriendlyHighlight 가 적 표시에 쓰는 것과 같은 방식이다).
local function kcHighlight(on)
	if on then
		local ch = kc.killer and kc.killer.Character
		if not ch then
			return
		end
		pcall(function()
			local o = Instance.new("Outline")
			o.Name = "KillCamOutline"
			o.Color = KILLCAM.COLOR
			o.Thickness = 0.6
			o.Adornee = ch
			o.Parent = ch
			kc.outline = o
		end)
	elseif kc.outline then
		pcall(function()
			kc.outline:Destroy()
		end)
		kc.outline = nil
	end
end

local function kcGuiSet(text)
	if not (kc.gui and kc.gui.Parent) then
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		if not pg then
			return
		end
		kc.gui = Instance.new("ScreenGui")
		kc.gui.Name = "KillCam"
		kc.gui.Parent = pg

		kc.label = Instance.new("TextLabel")
		kc.label.Name = "KilledBy"
		kc.label.AnchorPoint = Vector2.new(0.5, 0)
		kc.label.Position = UDim2.new(0.5, 0, 0.12, 0)
		kc.label.Size = UDim2.new(0, 520, 0, 34)
		kc.label.BackgroundTransparency = 1
		kc.label.TextColor3 = KILLCAM.COLOR
		kc.label.TextSize = 26
		kc.label.Text = ""
		kc.label.Visible = false
		kc.label.ZIndex = 30
		-- 테두리 속성 이름이 버전마다 달라서 둘 다 시도한다 (Crosshair 와 같다)
		pcall(function()
			kc.label.BorderPixelSize = 0
		end)
		pcall(function()
			kc.label.BorderSizePixel = 0
		end)
		-- OVERDARE 에는 Font enum 이 없다. Bold(boolean) 만 있다.
		pcall(function()
			kc.label.Bold = true
		end)
		kc.label.Parent = kc.gui
	end
	if kc.label then
		kc.label.Text = text or ""
		kc.label.Visible = text ~= nil
	end
end

local function kcStop()
	if not kcOn then
		return
	end
	kcOn = false
	kc.killer = nil
	kc.name = nil
	kcHighlight(false)
	kcViewmodel(false)
	kcGuiSet(nil)
end

local function kcStart(killer, name)
	kc.killer = killer
	kc.name = name
	kc.endAt = os.clock() + KILLCAM.TIME
	kcOn = true
	-- 1인칭이라 숨겨둔 내 몸을 다시 보이게 한다. 내가 쓰러지는 걸 봐야 한다.
	-- 위 enforceFirstPersonHide 가 kcOn 동안 쉬므로 다시 숨겨지지 않는다.
	for part in pairs(hiddenParts) do
		pcall(function()
			part.Transparency = 0
		end)
	end
	kcViewmodel(true)
	kcHighlight(true)
end

local function kcUpdate()
	if not kcOn then
		return
	end
	local left = kc.endAt - os.clock()
	if left <= 0 then
		kcStop()
		return
	end

	local cam = Workspace.CurrentCamera
	local me = kcBodyOf(LocalPlayer)
	if not (cam and me) then
		return
	end

	local him = kcBodyOf(kc.killer)
	if him then
		-- 인게임 표시는 전부 영어로 통일한다
		kcGuiSet(string.format("KILLED BY  %s     %.1f", tostring(kc.killer.Name), left))
		-- 시체에서 상대 쪽을 향하는 수평 방향. 그 반대쪽 뒤에 카메라를 놓으면
		-- 내 시체가 화면 아래에 걸리고 상대가 정면에 온다.
		local flat = Vector3.new(him.Position.X - me.Position.X, 0, him.Position.Z - me.Position.Z)
		local d = flat.Magnitude
		local dir = (d > 1) and (flat / d) or Vector3.new(0, 0, 1)
		local eye = me.Position - dir * KILLCAM.BACK + Vector3.new(0, KILLCAM.UP, 0)
		pcall(function()
			cam.CFrame = CFrame.new(eye, him.Position + Vector3.new(0, KILLCAM.AIM_UP, 0))
		end)
	else
		-- 죽인 상대가 나갔거나 벌써 리스폰했다. 내 시체만 비춘다.
		if kc.name then
			-- 경기구역 이탈처럼 가해자가 사람이 아닌 죽음. 이름만 있다
			kcGuiSet(string.format("KILLED BY  %s     %.1f", kc.name, left))
		else
			kcGuiSet(string.format("%.1f", left))
		end
		local eye = me.Position + Vector3.new(0, KILLCAM.UP + 60, KILLCAM.BACK)
		pcall(function()
			cam.CFrame = CFrame.new(eye, me.Position)
		end)
	end
end

-- 기본 카메라(200) 보다 늦게 얹어야 살아남는다.
if not pcall(function()
	RunService:BindToRenderStep("KillCam", 202, kcUpdate)
end) then
	RunService.RenderStepped:Connect(kcUpdate)
	-- BindToRenderStep 은 이 엔진에 없다. 확인 끝났으니 매번 찍지 않는다.
end

-- 리스폰하면 무조건 푼다. 시간이 남아 있어도 새 캐릭터가 생겼으면 끝난 것이다.
LocalPlayer.CharacterAdded:Connect(kcStop)

do
	local ev = game:GetService("ReplicatedStorage"):WaitForChild("CombatEvent", 10)
	if ev then
		ev.OnClientEvent:Connect(function(payload)
			if type(payload) ~= "table" or payload.phase ~= "kill" then
				return
			end
			if payload.victim ~= LocalPlayer or payload.killer == LocalPlayer then
				return
			end
			KILLCAM.TIME = tonumber(payload.respawn) or KILLCAM.TIME
			kcStart(payload.killer, payload.killerName)
		end)
	else
		print("[KillCam] CombatEvent 를 못 찾음 - 킬캠이 안 나온다")
	end
end

print("[KillCam] ready")
