--[[
  ✦ AuraX Visuals v1.0 ✦
  Только визуальные эффекты (видны только тебе, на стороне клиента).
  Меню на русском, работает на ПК и телефоне (Delta и др.).
  ПК: RightShift - открыть/закрыть меню. Телефон: плавающая кнопка AX.
]]

local env = (getgenv and getgenv()) or _G
if env.AuraX_Unload then pcall(env.AuraX_Unload) end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer
repeat task.wait() until Workspace.CurrentCamera

local rad, sin, cos, pi, rnd = math.rad, math.sin, math.cos, math.pi, math.random
local function CAM() return Workspace.CurrentCamera end
local function CP() return CAM().CFrame.Position end
local function v3(x) return Vector3.new(x, x, x) end

------------------------------------------------------------------
-- ЯДРО: хранилище объектов, утилиты
------------------------------------------------------------------
local Bag = {}
local function bag(key, obj)
	Bag[key] = Bag[key] or {}
	table.insert(Bag[key], obj)
	return obj
end
local function clear(key)
	local t = Bag[key]
	if not t then return end
	Bag[key] = nil
	for i = #t, 1, -1 do
		local o = t[i]
		local ty = typeof(o)
		if ty == "Instance" then pcall(o.Destroy, o)
		elseif ty == "RBXScriptConnection" then pcall(o.Disconnect, o)
		elseif ty == "function" then pcall(o)
		elseif ty == "thread" then pcall(task.cancel, o) end
	end
end
local function clearAll()
	local keys = {}
	for k in pairs(Bag) do keys[#keys + 1] = k end
	for _, k in ipairs(keys) do clear(k) end
end
local function loop(key, fn) return bag(key, RunService.RenderStepped:Connect(fn)) end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function H(hex)
	if hex == "rainbow" then return Color3.new(1, 1, 1) end
	hex = hex:gsub("#", "")
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end
local function tw(o, p, t, st)
	pcall(function() TweenService:Create(o, TweenInfo.new(t or 1, st or Enum.EasingStyle.Sine), p):Play() end)
end
local function rainbowSeq()
	local k = {}
	for i = 0, 6 do k[#k + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 0.8, 1)) end
	return ColorSequence.new(k)
end
local function colorSeq(a, b)
	if a == "rainbow" then return rainbowSeq() end
	return ColorSequence.new(H(a), H(b or a))
end
local function ulower(s)
	local ok, res = pcall(function()
		local out = {}
		for _, c in utf8.codes(s) do
			if c >= 0x410 and c <= 0x42F then c = c + 32
			elseif c == 0x401 then c = 0x451
			elseif c < 128 then c = string.byte(string.lower(string.char(c))) end
			out[#out + 1] = utf8.char(c)
		end
		return table.concat(out)
	end)
	return ok and res or s
end

local World = mk("Folder", { Name = "AuraX_" .. rnd(1000, 9999) }, Workspace)
bag("world", World)

local function P(o, parent)
	o.Anchored = true; o.CanCollide = false; o.CanQuery = false; o.CanTouch = false; o.CastShadow = false
	if o.Material == nil then o.Material = Enum.Material.Neon end
	local p = Instance.new("Part")
	for k, v in pairs(o) do p[k] = v end
	p.Parent = parent or World
	return p
end

local function guiParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	ok, h = pcall(function() return game:GetService("CoreGui") end)
	if ok and h then
		local t = Instance.new("Folder")
		local ok2 = pcall(function() t.Parent = h end)
		t:Destroy()
		if ok2 then return h end
	end
	return LP:WaitForChild("PlayerGui")
end
local GP = guiParent()
local Gui = mk("ScreenGui", { Name = "AX" .. rnd(1000, 9999), ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, GP)
local Overlay = mk("ScreenGui", { Name = "AXO" .. rnd(1000, 9999), ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 990, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, GP)
bag("gui", Gui); bag("gui", Overlay)

local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function torso() local c = LP.Character return c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")) end
local function head() local c = LP.Character return c and c:FindFirstChild("Head") end

local TEX = {
	s = "rbxasset://textures/particles/sparkles_main.dds",
	m = "rbxasset://textures/particles/smoke_main.dds",
	f = "rbxasset://textures/particles/fire_main.dds",
}
local function emitter(parent, o)
	local sz = o.size or 1
	local e = mk("ParticleEmitter", {
		Texture = TEX[o.tex or "s"], Color = colorSeq(o.c1 or "ffffff", o.c2),
		Rate = o.rate or 20, Speed = NumberRange.new(o.s1 or 1, o.s2 or o.s1 or 2),
		Lifetime = NumberRange.new((o.life or 1) * 0.8, (o.life or 1) * 1.2),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, sz), NumberSequenceKeypoint.new(1, sz * (o.shrink or 0.2)) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, o.tr or 0.2), NumberSequenceKeypoint.new(0.8, o.tr or 0.2), NumberSequenceKeypoint.new(1, 1) }),
		LightEmission = o.em or 0.5, Acceleration = Vector3.new(0, o.acc or 0, 0),
		SpreadAngle = Vector2.new(o.spread or 30, o.spread or 30), RotSpeed = NumberRange.new(-80, 80),
		Rotation = NumberRange.new(0, 360), LockedToPart = o.lock or false,
		EmissionDirection = o.dir or Enum.NormalId.Top, Drag = o.drag or 0,
	}, parent)
	return e
end

------------------------------------------------------------------
-- Освещение: снимок и эффекты
------------------------------------------------------------------
local LightProps = { "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "FogColor", "FogEnd", "FogStart", "ClockTime", "ExposureCompensation", "GlobalShadows" }
local OrigLight = {}
for _, p in ipairs(LightProps) do pcall(function() OrigLight[p] = Lighting[p] end) end
local AtmOrig
local function restoreLighting()
	for p, v in pairs(OrigLight) do pcall(function() Lighting[p] = v end) end
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if a and AtmOrig then for k, v in pairs(AtmOrig) do pcall(function() a[k] = v end) end end
end
local function fx(class, name)
	local o = Lighting:FindFirstChild(name)
	if not o then o = Instance.new(class); o.Name = name; o.Parent = Lighting; bag("fx", o) end
	return o
end
local function getAtm()
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if not a then a = fx("Atmosphere", "AuraAtm") end
	if not AtmOrig then AtmOrig = { Density = a.Density, Offset = a.Offset, Color = a.Color, Decay = a.Decay, Glare = a.Glare, Haze = a.Haze } end
	return a
end
local function getSky()
	local s = Lighting:FindFirstChildOfClass("Sky")
	if not s then s = fx("Sky", "AuraSky") end
	return s
end
local function getCC() return fx("ColorCorrectionEffect", "AuraCC") end
local function tempLight(key, props)
	local old = {}
	for k in pairs(props) do old[k] = Lighting[k] end
	for k, v in pairs(props) do
		if type(v) == "string" then v = H(v) end
		tw(Lighting, { [k] = v }, 2)
	end
	bag(key, function() for k, v in pairs(old) do pcall(function() Lighting[k] = v end) end end)
end

------------------------------------------------------------------
-- РЕЕСТР ФУНКЦИЙ И ГРУППЫ
------------------------------------------------------------------
local Cfg = { weatherInt = 1, cycle = 0.25, wingScale = 1, flap = 1, orbitSpeed = 1, auraRate = 1, fov = 70, meteorEvery = 3, vig = 0.5 }
local Cats, AllItems, Groups, ByID = {}, {}, {}, {}
local function newCat(name) local c = { name = name, items = {} }; table.insert(Cats, c); return c end
local function addItem(c, it)
	table.insert(c.items, it)
	if it.kind ~= "label" then it.lname = ulower(it.name); table.insert(AllItems, it) end
	if it.id then ByID[it.id] = it end
	return it
end
local function Label(c, t) addItem(c, { kind = "label", name = t }) end
local function Button(c, name, fn, id) return addItem(c, { kind = "button", name = name, fn = fn, id = id }) end
local function Slider(c, name, mn, mx, def, fn, step)
	return addItem(c, { kind = "slider", name = name, min = mn, max = mx, value = def, fn = fn, step = step or 0 })
end
local function Toggle(c, name, key, on, off, o)
	o = o or {}
	local it = { kind = "toggle", name = name, key = key, on = on, off = off or function() clear(key) end, group = o.group, char = o.char, id = o.id, state = false }
	if it.group then Groups[it.group] = Groups[it.group] or {}; table.insert(Groups[it.group], it) end
	return addItem(c, it)
end
local function setOn(it, state)
	if it.group and state then
		for _, o in ipairs(Groups[it.group]) do
			if o ~= it and o.state then o.state = false; pcall(o.off) end
		end
	end
	if it.state == state then return end
	it.state = state
	local ok, e = pcall(state and it.on or it.off)
	if not ok then warn("[AuraX] " .. tostring(it.name) .. ": " .. tostring(e)); it.state = false; pcall(it.off) end
end
local function reapplyGroup(g)
	for _, o in ipairs(Groups[g] or {}) do if o.state then pcall(o.off); pcall(o.on) end end
end
local function Press(id)
	local it = ByID[id]
	if not it then return end
	if it.kind == "button" then pcall(it.fn) else setOn(it, true) end
end
local RefreshUI = function() end

------------------------------------------------------------------
-- 🌅 ВРЕМЯ
------------------------------------------------------------------
local tc = newCat("🌅 Время")
local HN = { [0] = "Полночь", "Глубокая ночь", "Ночь", "Поздняя ночь", "Предрассвет", "Рассвет", "Раннее утро", "Утро", "Ясное утро", "Позднее утро", "Почти полдень", "Солнечный день", "Полдень", "После полудня", "Жаркий день", "Послеобеденное", "Вечер близко", "Золотой час", "Закат", "Сумерки", "Вечер", "Поздний вечер", "Ночь настаёт", "Почти полночь" }
Label(tc, "Время суток")
for h = 0, 23 do
	Button(tc, string.format("🕒 %02d:00 — %s", h, HN[h]), function() Lighting.ClockTime = h end)
end
Label(tc, "Быстрые")
Button(tc, "🌅 Рассвет 5:30", function() Lighting.ClockTime = 5.5 end)
Button(tc, "🌇 Закат 18:15", function() Lighting.ClockTime = 18.25 end)
Button(tc, "☀ Яркий полдень", function() Lighting.ClockTime = 12 end)
Button(tc, "🌙 Глубокая полночь", function() Lighting.ClockTime = 0 end)
Button(tc, "🌆 Синий час 19:30", function() Lighting.ClockTime = 19.5 end)
Button(tc, "🌄 Золотой час 17:00", function() Lighting.ClockTime = 17 end)
Label(tc, "Режимы")
Toggle(tc, "🔄 Авто-смена дня и ночи", "cycle", function()
	loop("cycle", function(dt) Lighting.ClockTime = (Lighting.ClockTime + dt * Cfg.cycle) % 24 end)
end)
Toggle(tc, "⏸ Заморозить время", "freeze", function()
	local t0 = Lighting.ClockTime
	loop("freeze", function() Lighting.ClockTime = t0 end)
end)
Toggle(tc, "🕰 Реальное время устройства", "realtime", function()
	loop("realtime", function() local d = os.date("*t"); Lighting.ClockTime = d.hour + d.min / 60 + d.sec / 3600 end)
end)
Slider(tc, "Скорость смены дня", 0.05, 3, 0.25, function(v) Cfg.cycle = v end)
Slider(tc, "Точное время (час)", 0, 24, 12, function(v) Lighting.ClockTime = v end)

------------------------------------------------------------------
-- 💡 ОСВЕЩЕНИЕ
------------------------------------------------------------------
local lc = newCat("💡 Освещение")
local LROWS = {
	{ "Золотой закат", 17.8, "7a4a2a", "ffb066", 900, 2.2, "ffb27a", 0.35, 0.1 },
	{ "Розовый рассвет", 5.9, "7a4a66", "ff9ac8", 900, 2, "ffb3d1", 0.38, 0.1 },
	{ "Киберпанк", 1, "3a1a6a", "ff2bd6", 600, 1.5, "ff2bd6", 0.45, 0.3 },
	{ "Вейпорвейв", 18.3, "6a2a8a", "ff71ce", 700, 2, "01cdfe", 0.4, 0.2 },
	{ "Тропики", 12, "7a9a6a", "bfffe6", 2500, 3, "9fe8ff", 0.15, 0 },
	{ "Зимнее утро", 8, "8aa0c0", "dfeaff", 500, 2.5, "e8f1ff", 0.5, 0.1 },
	{ "Адский мир", 0, "5a1000", "ff3a00", 350, 1, "ff4400", 0.6, 0.2 },
	{ "Сказочный лес", 14, "4a7a4a", "b7ffb0", 800, 2.5, "c9ffcf", 0.3, 0 },
	{ "Глубины океана", 12, "0a3a6a", "0a6aa8", 200, 1.5, "0a7ab8", 0.7, 0 },
	{ "Сакура", 16.5, "9a6a7a", "ffd1e6", 1200, 2.5, "ffd9ec", 0.3, 0.1 },
	{ "Пустыня", 13, "8a6a3a", "ffd9a0", 2000, 3, "ffdca8", 0.25, 0.2 },
	{ "Космическая ночь", 0, "1a1a4a", "05051a", 100000, 0.5, "0a0a3a", 0.1, 0 },
	{ "Лунная ночь", 0.3, "2a3a6a", "1a2a5a", 1500, 1, "2a3a7a", 0.3, 0 },
	{ "Ретро 80-х", 19, "5a2a7a", "ff6ac1", 800, 2, "ff9e7a", 0.4, 0.2 },
	{ "Мрачный туман", 10, "3a3a3a", "6a6a6a", 150, 0.8, "7a7a7a", 0.8, -0.2 },
	{ "Фиолетовые сумерки", 18.8, "4a2a7a", "8a4aff", 900, 1.5, "9a6aff", 0.4, 0 },
	{ "Изумрудный мир", 12, "1a6a4a", "3affb0", 900, 2, "3affb0", 0.35, 0 },
	{ "Кровавая луна", 0, "4a0a0a", "8a0a0a", 700, 0.8, "aa1010", 0.45, 0 },
	{ "Золотой час", 17, "8a6a2a", "ffd27a", 1500, 2.6, "ffd98a", 0.3, 0.2 },
	{ "Синий час", 19, "2a3a6a", "5a7aff", 1200, 1.6, "6a8aff", 0.35, 0 },
	{ "Радужный день", 12, "8a8aff", "ffffff", 3000, 3, "ffffff", 0.1, 0 },
	{ "Ледяной мир", 11, "6a9aca", "bfe8ff", 400, 2.5, "cff0ff", 0.5, 0.1 },
	{ "Токсичный мир", 15, "3a6a1a", "9aff3a", 350, 1.4, "8aff2a", 0.6, 0 },
	{ "Туманная долина", 7, "6a7a8a", "c0cad8", 250, 2, "cfd8e4", 0.75, 0 },
	{ "Закат Мальдив", 18, "6a4a5a", "ff8a5a", 1800, 2.4, "ffa07a", 0.3, 0.2 },
	{ "Матрица", 0, "003a10", "00ff55", 300, 1, "00ff55", 0.5, 0 },
	{ "Аврора-ночь", 1, "1a4a5a", "0a2a3a", 3000, 0.8, "1a5a6a", 0.3, 0 },
	{ "Осень", 16, "7a4a1a", "ffa040", 1000, 2.2, "ffb060", 0.35, 0.1 },
	{ "Весна", 11, "6a9a6a", "e8ffd8", 2500, 3, "e8ffe8", 0.2, 0 },
	{ "Закат на Марсе", 17.5, "7a3a1a", "d86a3a", 800, 2, "e8864a", 0.5, 0 },
	{ "Неон Токио", 23, "3a1a5a", "00e5ff", 700, 1.2, "ff2bd6", 0.4, 0.3 },
	{ "Ясный полдень", 13, "9aa0a8", "ffffff", 100000, 3, "ffffff", 0, 0 },
	{ "Штормовое небо", 14, "3a4a5a", "5a6a7a", 400, 1.2, "6a7a8a", 0.7, -0.1 },
	{ "Тёплая ночь", 21, "3a2a4a", "3a2a5a", 1500, 1, "5a3a7a", 0.3, 0 },
	{ "Сумрак леса", 20, "1a3a2a", "1a3a2a", 300, 0.9, "2a5a3a", 0.6, 0 },
	{ "Белая комната", 12, "ffffff", "ffffff", 100000, 3, "ffffff", 0, 0.3 },
}
local function applyPreset(r)
	Lighting.ClockTime = r[2]
	Lighting.FogStart = 0
	tw(Lighting, { Ambient = H(r[3]), OutdoorAmbient = H(r[3]), FogColor = H(r[4]), FogEnd = r[5], Brightness = r[6], ExposureCompensation = r[9] }, 2)
	local a = getAtm()
	tw(a, { Color = H(r[7]), Decay = H(r[4]), Density = r[8] }, 2)
end
Label(lc, "Пресеты освещения")
for i, r in ipairs(LROWS) do
	Button(lc, "🎨 " .. r[1], function() applyPreset(r) end, "L" .. i)
end
Label(lc, "Настройки")
Button(lc, "♻ Сбросить освещение", restoreLighting)
Slider(lc, "Яркость", 0, 10, 2, function(v) Lighting.Brightness = v end)
Slider(lc, "Экспозиция", -3, 3, 0, function(v) Lighting.ExposureCompensation = v end)
Slider(lc, "Дальность тумана", 50, 5000, 2000, function(v) Lighting.FogEnd = v end, 50)
Slider(lc, "Плотность атмосферы", 0, 1, 0.3, function(v) getAtm().Density = v end)
Slider(lc, "Дымка (Haze)", 0, 10, 1, function(v) getAtm().Haze = v end)
Toggle(lc, "🌑 Выключить тени", "noshadow", function()
	local o = Lighting.GlobalShadows; Lighting.GlobalShadows = false
	bag("noshadow", function() Lighting.GlobalShadows = o end)
end)
Toggle(lc, "🌈 Радужное освещение мира", "rbamb", function()
	local t = 0
	loop("rbamb", function(dt) t = t + dt * 0.1; local c = Color3.fromHSV(t % 1, 0.5, 0.9); Lighting.Ambient = c; Lighting.OutdoorAmbient = c end)
	bag("rbamb", function() Lighting.Ambient = OrigLight.Ambient; Lighting.OutdoorAmbient = OrigLight.OutdoorAmbient end)
end)
Toggle(lc, "💓 Пульсация яркости", "pulse", function()
	local b = Lighting.Brightness
	loop("pulse", function() Lighting.Brightness = b + 0.8 * sin(os.clock() * 2) end)
	bag("pulse", function() Lighting.Brightness = b end)
end)
local SKYT = { "ff5a5a", "ffa05a", "ffe05a", "9aff5a", "5aff9a", "5affee", "5aaaff", "7a5aff", "c05aff", "ff5ac8", "ffffff", "202030" }
local SKYN = { "Красный", "Оранжевый", "Жёлтый", "Лаймовый", "Зелёный", "Бирюзовый", "Голубой", "Синий", "Фиолетовый", "Розовый", "Белый", "Тёмный" }
Label(lc, "Оттенок неба")
for i, hx in ipairs(SKYT) do
	Button(lc, "🎈 Небо: " .. SKYN[i], function() tw(Lighting, { ColorShift_Top = H(hx) }, 1.5) end)
end

------------------------------------------------------------------
-- 🎬 ЦВЕТ И ЭФФЕКТЫ
------------------------------------------------------------------
local cc = newCat("🎬 Цвет и эффекты")
local function mkFx(key, class, props) local e = mk(class, props, Lighting); bag(key, e); return e end
local TINTS = {
	{ "Красный", "ff8a8a" }, { "Оранжевый", "ffb88a" }, { "Жёлтый", "fff08a" }, { "Лайм", "c8ff8a" }, { "Зелёный", "8aff9a" },
	{ "Мятный", "8affd8" }, { "Бирюзовый", "8afff0" }, { "Голубой", "8ad0ff" }, { "Синий", "8a9aff" }, { "Индиго", "a08aff" },
	{ "Фиолетовый", "c08aff" }, { "Пурпурный", "e88aff" }, { "Розовый", "ff8ac8" }, { "Малиновый", "ff6a9a" }, { "Золотой", "ffe0a0" },
	{ "Серебряный", "dfe4ee" }, { "Тёплый", "ffe8d0" }, { "Холодный", "d0e8ff" }, { "Винтаж", "ffe0b0" }, { "Лунный", "a0b0ff" },
	{ "Закатный", "ff9a70" }, { "Кислотный", "b0ff30" }, { "Кровавый", "ff6060" }, { "Океанский", "60b0ff" }, { "Лесной", "90e090" },
	{ "Сакура", "ffc0e0" }, { "Лавандовый", "c8a0ff" }, { "Персиковый", "ffcaa0" }, { "Футуризм", "80fff0" }, { "Без оттенка", "ffffff" },
}
Label(cc, "Цветовые фильтры")
for _, t in ipairs(TINTS) do
	Button(cc, "🎨 Фильтр: " .. t[1], function() tw(getCC(), { TintColor = H(t[2]) }, 1) end)
end
Label(cc, "Режимы изображения")
Button(cc, "⚫ Чёрно-белое", function() getCC().Saturation = -1 end)
Button(cc, "🟤 Сепия", function() local c = getCC(); c.TintColor = H("d8b890"); c.Saturation = -0.4 end)
Button(cc, "🟢 Ночное видение", function() local c = getCC(); c.TintColor = H("40ff60"); c.Brightness = 0.1; c.Contrast = 0.2 end)
Button(cc, "📽 Ретро-плёнка", function() local c = getCC(); c.TintColor = H("ffe0a0"); c.Contrast = 0.1; c.Saturation = -0.2 end)
Button(cc, "🌈 Гипер-насыщенность", function() getCC().Saturation = 1.5 end)
Button(cc, "🧪 Кислотный трип", function() local c = getCC(); c.Saturation = 2; c.Contrast = 0.3 end)
Button(cc, "♻ Сбросить цвет", function() local c = getCC(); c.TintColor = Color3.new(1, 1, 1); c.Saturation = 0; c.Contrast = 0; c.Brightness = 0 end)
Slider(cc, "Насыщенность", -1, 3, 0, function(v) getCC().Saturation = v end)
Slider(cc, "Контраст", -0.5, 1, 0, function(v) getCC().Contrast = v end)
Slider(cc, "Яркость фильтра", -0.3, 0.5, 0, function(v) getCC().Brightness = v end)
Label(cc, "Свечение (Bloom)")
local BL = { { "Мягкое свечение", 0.6, 24, 1 }, { "Сильное свечение", 1.5, 40, 0.8 }, { "Мечта", 2, 56, 0.6 }, { "Неоновое", 3, 30, 0.5 }, { "Кинематограф", 0.8, 18, 1.1 }, { "Взрыв света", 5, 56, 0.3 } }
for i, b in ipairs(BL) do
	Toggle(cc, "✨ " .. b[1], "bl" .. i, function() mkFx("bl" .. i, "BloomEffect", { Intensity = b[2], Size = b[3], Threshold = b[4] }) end, nil, { group = "bloom" })
end
Label(cc, "Солнечные лучи")
local SR = { { "Лёгкие лучи", 0.1, 0.2 }, { "Средние лучи", 0.25, 0.5 }, { "Сильные лучи", 0.5, 0.8 }, { "Божественные лучи", 1, 1 } }
for i, b in ipairs(SR) do
	Toggle(cc, "☀ " .. b[1], "sr" .. i, function() mkFx("sr" .. i, "SunRaysEffect", { Intensity = b[2], Spread = b[3] }) end, nil, { group = "rays" })
end
Label(cc, "Глубина резкости и размытие")
local DF = { { "Ближний фокус", 0.6, 10, 15 }, { "Средний фокус", 0.5, 30, 25 }, { "Дальний фокус", 0.4, 80, 40 }, { "Тилт-шифт", 0.9, 20, 8 } }
for i, b in ipairs(DF) do
	Toggle(cc, "📷 " .. b[1], "df" .. i, function() mkFx("df" .. i, "DepthOfFieldEffect", { FarIntensity = b[2], FocusDistance = b[3], InFocusRadius = b[4], NearIntensity = 0 }) end, nil, { group = "dof" })
end
for i, s in ipairs({ 4, 8, 16, 24 }) do
	Toggle(cc, "🌫 Размытие " .. s, "bk" .. i, function() mkFx("bk" .. i, "BlurEffect", { Size = s }) end, nil, { group = "blur" })
end

------------------------------------------------------------------
-- 🌧 ПОГОДА
------------------------------------------------------------------
local wc = newCat("🌧 Погода")
local function W(n, tex, c1, c2, rate, s1, s2, size, life, acc, em, spread, h, fxn, boxY, bx)
	return { n = n, tex = tex, c1 = c1, c2 = c2, rate = rate, s1 = s1, s2 = s2, size = size, life = life, acc = acc, em = em, spread = spread, h = h, fx = fxn, boxY = boxY or 1, bx = bx or 110 }
end
local WEATHER = {
	W("Лёгкий дождь", "s", "9ec8ff", "cfe3ff", 250, 60, 80, 0.18, 1, 0, 0.3, 3, 45, "rain"),
	W("Дождь", "s", "9ec8ff", "cfe3ff", 600, 70, 95, 0.2, 1, 0, 0.3, 3, 45, "rain"),
	W("Ливень", "s", "8ab8ff", "cfe3ff", 1400, 90, 120, 0.22, 0.9, 0, 0.4, 3, 45, "rain"),
	W("Гроза с молниями", "s", "8ab8ff", "cfe3ff", 1200, 90, 120, 0.22, 0.9, 0, 0.4, 3, 45, "storm"),
	W("Морось", "s", "b8d4ff", "e0eeff", 300, 25, 35, 0.12, 2, 0, 0.3, 5, 45, "rain"),
	W("Снег", "s", "ffffff", "e8f2ff", 150, 5, 9, 0.35, 9, 0, 0.6, 15, 45, "snow"),
	W("Снегопад", "s", "ffffff", "d8e8ff", 450, 6, 12, 0.4, 8, 0, 0.6, 20, 45, "snow"),
	W("Метель", "s", "ffffff", "cfe0ff", 1200, 20, 35, 0.45, 4, 0, 0.6, 25, 45, "blizzard"),
	W("Град", "s", "e6f4ff", "ffffff", 300, 70, 100, 0.35, 1, 0, 0.2, 2, 45, "rain"),
	W("Лёгкая дымка", "m", "cfd6e0", "ffffff", 12, 1, 3, 25, 10, 0, 0, 180, 6, "fog", 20),
	W("Густой туман", "m", "aab2bc", "d6dce4", 25, 1, 3, 35, 10, 0, 0, 180, 6, "thick", 20),
	W("Песчаная буря", "m", "d9b36a", "c99a4a", 100, 30, 50, 12, 4, 0, 0, 15, 8, "sand", 20),
	W("Вулканический пепел", "m", "6a6a6a", "2a2a2a", 200, 3, 6, 0.9, 10, 0, 0, 20, 45, "ash"),
	W("Лепестки сакуры", "s", "ffc0d8", "ffe0ee", 80, 3, 6, 0.7, 10, 0, 0.3, 30, 45),
	W("Осенние листья", "s", "e08a2a", "b04a1a", 70, 3, 6, 0.8, 10, 0, 0, 30, 45),
	W("Зелёные листья", "s", "6ac04a", "3a8a2a", 70, 3, 6, 0.8, 10, 0, 0, 30, 45),
	W("Светлячки", "s", "d8ff6a", "ffff9a", 14, 0.5, 2, 0.6, 8, 0, 1, 180, 4, nil, 25, 80),
	W("Пузыри", "s", "bfe8ff", "ffffff", 30, 1, 3, 1.2, 8, 0.4, 0.3, 60, 3, nil, 10, 80),
	W("Конфетти", "s", "rainbow", "rainbow", 120, 4, 8, 0.6, 8, 0, 0.5, 40, 45),
	W("Сердечки", "s", "ff5a8a", "ff9ab8", 60, 3, 6, 0.9, 9, 0, 0.5, 30, 45),
	W("Звёздный дождь", "s", "fff3a0", "ffffff", 150, 15, 25, 0.8, 3, 0, 1, 10, 45),
	W("Золотой дождь", "s", "ffd24a", "ffb000", 300, 40, 60, 0.4, 1.4, 0, 1, 4, 45),
	W("Неоновый дождь", "s", "ff2bd6", "00e5ff", 600, 70, 95, 0.25, 1, 0, 1, 3, 45),
	W("Кровавый дождь", "s", "a00000", "e02020", 600, 70, 95, 0.22, 1, 0, 0.2, 3, 45),
	W("Радужный дождь", "s", "rainbow", "rainbow", 600, 70, 95, 0.25, 1, 0, 0.6, 3, 45),
	W("Искры", "s", "ff9a2a", "ffd24a", 100, 6, 14, 0.4, 3, 8, 1, 60, 3, nil, 10, 70),
	W("Огненный дождь", "s", "ff5a00", "ffc000", 300, 50, 70, 0.5, 1.2, 0, 1, 5, 45),
	W("Космическая пыль", "s", "b08aff", "6aa8ff", 50, 0.5, 2, 0.6, 9, 0, 1, 180, 5, nil, 30, 90),
	W("Магические руны", "s", "a06aff", "ff6aff", 40, 1, 3, 1.3, 6, 1, 1, 180, 4, nil, 15, 70),
	W("Пух одуванчиков", "s", "ffffff", "ffffff", 40, 1, 3, 0.5, 10, 0, 0.4, 60, 25),
	W("Кислотный дождь", "s", "7aff2a", "c8ff6a", 600, 70, 95, 0.22, 1, 0, 0.6, 3, 45, "rain"),
	W("Золотая пыльца", "s", "ffe08a", "fff3c0", 60, 0.5, 2, 0.4, 8, 0, 1, 180, 4, nil, 20, 80),
	W("Фиолетовый туман", "m", "8a4aff", "c08aff", 20, 1, 3, 30, 10, 0, 0.2, 180, 6, nil, 20),
	W("Розовые облака", "m", "ff9ad0", "ffc8e6", 20, 1, 3, 30, 10, 0, 0.2, 180, 6, nil, 20),
	W("Чёрный снег", "s", "1a1a1a", "3a3a3a", 200, 5, 9, 0.5, 9, 0, 0, 15, 45),
	W("Серебряные искры", "s", "e0e0ff", "ffffff", 60, 0.5, 2, 0.4, 8, 0, 1, 180, 4, nil, 20, 80),
	W("Лавовые искры", "s", "ff3a00", "ffaa00", 100, 6, 14, 0.5, 3, 10, 1, 60, 3, nil, 10, 70),
	W("Изумрудный дождь", "s", "3affb0", "8affd8", 500, 70, 95, 0.22, 1, 0, 0.8, 3, 45),
	W("Синие снежинки", "s", "6ab0ff", "cfe6ff", 200, 5, 9, 0.4, 9, 0, 0.8, 15, 45),
	W("Голубые светлячки", "s", "6af0ff", "a8ffff", 14, 0.5, 2, 0.6, 8, 0, 1, 180, 4, nil, 25, 80),
	W("Тёплый ливень", "s", "ffb08a", "ffd0b0", 1000, 80, 110, 0.22, 0.9, 0, 0.4, 3, 45, "rain"),
	W("Радужные пузыри", "s", "rainbow", "rainbow", 30, 1, 3, 1.4, 8, 0.4, 0.5, 60, 3, nil, 10, 80),
	W("Дымка заката", "m", "ff9a6a", "ffc8a0", 20, 1, 3, 30, 10, 0, 0.2, 180, 6, nil, 20),
	W("Электрические искры", "s", "6ae0ff", "ffffff", 120, 15, 30, 0.3, 2, 0, 1, 180, 4, nil, 20, 70),
}
local FXL = {
	rain = { FogEnd = 700, FogColor = "6b7480", Brightness = 1.3 }, storm = { FogEnd = 450, FogColor = "39414a", Brightness = 0.8 },
	snow = { FogEnd = 600, FogColor = "dfe8f2" }, blizzard = { FogEnd = 140, FogColor = "e8f0fa" },
	fog = { FogEnd = 380, FogColor = "c8ced6" }, thick = { FogEnd = 90, FogColor = "b0b6be" },
	sand = { FogEnd = 130, FogColor = "c8a460" }, ash = { FogEnd = 450, FogColor = "3a3a3a" },
}
local Fields = {}
local function startField(key, d)
	local holder = P({ Size = Vector3.new(d.bx, d.boxY, d.bx), Transparency = 1, Material = Enum.Material.SmoothPlastic })
	bag(key, holder)
	local e = emitter(holder, { tex = d.tex, c1 = d.c1, c2 = d.c2, rate = d.rate, s1 = d.s1, s2 = d.s2, size = d.size, life = d.life, acc = d.acc, em = d.em, spread = d.spread, dir = Enum.NormalId.Bottom, tr = 0.1, shrink = 1 })
	e.Rate = d.rate * Cfg.weatherInt
	Fields[key] = { e = e, base = d.rate }
	bag(key, function() Fields[key] = nil end)
	loop(key, function() holder.CFrame = CFrame.new(CP() + Vector3.new(0, d.h, 0)) end)
	if d.fx and FXL[d.fx] then tempLight(key, FXL[d.fx]) end
	if d.fx == "storm" then
		bag(key, task.spawn(function()
			while true do
				task.wait(rnd(30, 90) / 10)
				local b = Lighting.Brightness
				Lighting.Brightness = b + 6; task.wait(0.07)
				Lighting.Brightness = b; task.wait(0.1)
				Lighting.Brightness = b + 4; task.wait(0.05)
				Lighting.Brightness = b
			end
		end))
	end
end
Label(wc, "Осадки и атмосфера (одна погода за раз)")
for i, d in ipairs(WEATHER) do
	Toggle(wc, "🌦 " .. d.n, "w" .. i, function() startField("w" .. i, d) end, nil, { group = "weather", id = "w" .. i })
end
Slider(wc, "Интенсивность погоды", 0.2, 3, 1, function(v)
	Cfg.weatherInt = v
	for _, f in pairs(Fields) do f.e.Rate = f.base * v end
end)
Button(wc, "⛔ Выключить погоду", function()
	for _, o in ipairs(Groups.weather) do if o.state then setOn(o, false) end end
	RefreshUI()
end)

local ac = newCat("✨ Частицы мира")
local function A(n, tex, c1, c2, rate, s1, s2, size, life, acc, em)
	return W(n, tex, c1, c2, rate, s1, s2, size, life, acc, em, 180, 0, nil, 50, 70)
end
local AMB = {
	A("Пыль в воздухе", "m", "d8d0c0", "ffffff", 15, 0.2, 1, 0.8, 8, 0, 0.1),
	A("Светлячки вокруг", "s", "d8ff6a", "ffff9a", 14, 0.5, 2, 0.6, 8, 0, 1),
	A("Плавающие огни", "s", "c8a0ff", "ffffff", 20, 0.5, 2, 0.9, 8, 0, 1),
	A("Парящие лепестки", "s", "ffc0d8", "ffe0ee", 25, 0.5, 2, 0.7, 9, 0, 0.3),
	A("Магические споры", "s", "6affb0", "a0ffd8", 25, 0.5, 2, 0.6, 8, 0.3, 1),
	A("Звёздная пыль вокруг", "s", "ffffff", "a0d0ff", 40, 0.3, 1.5, 0.35, 8, 0, 1),
	A("Лёгкие пузырьки", "s", "bfe8ff", "ffffff", 15, 0.5, 2, 1.1, 8, 0.6, 0.3),
	A("Искры огня", "s", "ff9a2a", "ffd24a", 30, 1, 3, 0.4, 5, 2, 1),
	A("Висящие снежинки", "s", "ffffff", "d8e8ff", 30, 0.3, 1.5, 0.4, 9, 0, 0.6),
	A("Золотая пыльца вокруг", "s", "ffe08a", "fff3c0", 30, 0.3, 1.5, 0.4, 8, 0, 1),
	A("Розовые огоньки", "s", "ff7ac8", "ffb0e0", 20, 0.5, 2, 0.8, 8, 0, 1),
	A("Синие огоньки", "s", "5aaaff", "a8d8ff", 20, 0.5, 2, 0.8, 8, 0, 1),
	A("Ледяная пыль", "s", "b8e8ff", "ffffff", 35, 0.3, 1.5, 0.35, 8, 0, 0.8),
	A("Тёмные души", "m", "4a2a6a", "8a5aaa", 12, 0.5, 2, 3, 8, 0.4, 0.2),
}
Label(ac, "Частицы вокруг камеры")
for i, d in ipairs(AMB) do
	Toggle(ac, "💫 " .. d.n, "a" .. i, function() startField("a" .. i, d) end, nil, { id = "a" .. i })
end

------------------------------------------------------------------
-- 🪐 КОСМОС
------------------------------------------------------------------
local sc = newCat("🪐 Космос")
local function sph(az, el, dist)
	local a, e = rad(az), rad(el)
	return Vector3.new(cos(e) * sin(a), sin(e), -cos(e) * cos(a)) * dist
end
local function group(key, off, spin, static)
	if not Bag.sp_fog then tempLight("sp_fog", { FogEnd = 1e5 }) end
	local m = Instance.new("Model"); m.Name = key; m.Parent = World; bag(key, m)
	m.WorldPivot = CFrame.new()
	local last
	bag(key, RunService.RenderStepped:Connect(function()
		local pos = CP()
		if static then
			if last and (pos - last).Magnitude < 12 then return end
			last = pos
		end
		m:PivotTo(CFrame.new(pos + off) * (spin and spin(os.clock()) or CFrame.new()))
	end))
	return m
end
local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder

Label(sc, "Звёзды и небо")
Toggle(sc, "🌑 Чёрное небо (убрать скайбокс)", "blacksky", function()
	local s = getSky(); local old = {}
	for _, f in ipairs({ "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }) do old[f] = s[f]; s[f] = "" end
	bag("blacksky", function() for f, v in pairs(old) do s[f] = v end end)
end, nil, { id = "sky_black" })
Slider(sc, "Количество звёзд неба", 0, 5000, 3000, function(v) getSky().StarCount = v end, 100)
Slider(sc, "Размер солнца", 0, 60, 21, function(v) getSky().SunAngularSize = v end)
Slider(sc, "Размер луны", 0, 60, 11, function(v) getSky().MoonAngularSize = v end)
Toggle(sc, "🙈 Скрыть солнце и луну", "hidebodies", function()
	local s = getSky(); local o = s.CelestialBodiesShown; s.CelestialBodiesShown = false
	bag("hidebodies", function() s.CelestialBodiesShown = o end)
end)
local STARC = { Color3.new(1, 1, 1), Color3.fromRGB(190, 215, 255), Color3.fromRGB(255, 240, 190), Color3.fromRGB(255, 205, 160) }
local STARS = { { "Звёзды: редкое небо (150)", 150, false }, { "Звёзды: обычное небо (350)", 350, false }, { "Звёзды: густое небо (700)", 700, false }, { "Звёзды: цветные (350)", 350, true } }
for i, d in ipairs(STARS) do
	Toggle(sc, "⭐ " .. d[1], "stars" .. i, function()
		local g = group("stars" .. i, Vector3.zero, nil, true)
		for _ = 1, d[2] do
			local v = Vector3.new(rnd() * 2 - 1, rnd() * 2 - 0.3, rnd() * 2 - 1)
			if v.Magnitude < 0.1 then v = Vector3.new(0, 1, 0) end
			local s = rnd(6, 16) * (rnd() < 0.05 and 2 or 1)
			P({ Size = v3(s), Color = d[3] and Color3.fromHSV(rnd(), 0.5, 1) or STARC[rnd(1, #STARC)], CFrame = CFrame.new(v.Unit * 1800) }, g)
		end
	end, nil, { group = "stars", id = "stars" .. i })
end

-- Планеты
Label(sc, "Планеты")
local PL = {
	{ "Луна", "c8c8c8", 420, 20, 25, "Slate" }, { "Земля", "2a6ad8", 700, -35, 18, "SmoothPlastic", "6ab8ff", nil, true },
	{ "Марс", "c8502a", 380, 60, 12, "Sand" }, { "Юпитер", "d8a878", 1100, -70, 22, "SmoothPlastic" },
	{ "Сатурн (с кольцами)", "e8d49a", 900, 100, 20, "SmoothPlastic", nil, "e0c890" }, { "Венера", "e8c888", 650, 140, 10, "Sand", "ffe0a0" },
	{ "Меркурий", "9a8a7a", 300, -110, 15, "Slate" }, { "Нептун", "2a4ad8", 800, 170, 25, "SmoothPlastic", "6a8aff" },
	{ "Уран (с кольцом)", "7ae8e8", 780, -150, 14, "SmoothPlastic", "b0ffff", "a0f0f0" }, { "Плутон", "b8a898", 250, -10, 30, "Slate" },
	{ "Лавовая планета", "ff3a00", 700, 45, 8, "Neon", "ff8a00" }, { "Ледяная планета", "cfeaff", 650, -60, 8, "Ice", "e0f4ff" },
	{ "Кристальная планета", "3affea", 600, 85, 28, "Neon", "9affff" }, { "Розовый гигант (с кольцом)", "ff8ad0", 1000, -125, 18, "SmoothPlastic", nil, "ffc0e8" },
	{ "Планета-океан", "1a8aff", 700, 120, -5, "SmoothPlastic", "6ad0ff", nil, true }, { "Токсичная планета", "8aff2a", 600, -20, 12, "SmoothPlastic", "b0ff60" },
}
for i, d in ipairs(PL) do
	Toggle(sc, "🪐 " .. d[1], "pl" .. i, function()
		local key = "pl" .. i
		local sz = d[3]
		local g = group(key, sph(d[4], d[5], 1700), (not d[8]) and function(t) return CFrame.Angles(0, t * 0.03, 0) end or nil, d[8] ~= nil)
		P({ Shape = BALL, Size = v3(sz), Color = H(d[2]), Material = Enum.Material[d[6]] }, g)
		if d[7] then P({ Shape = BALL, Size = v3(sz * 1.05), Color = H(d[7]), Transparency = 0.8 }, g) end
		if d[9] then P({ Shape = BALL, Size = v3(sz * 1.015), Color = Color3.new(1, 1, 1), Transparency = 0.6, Material = Enum.Material.SmoothPlastic }, g) end
		if d[8] then
			local tilt = CFrame.Angles(rad(70), 0, rad(15))
			P({ Shape = CYL, Size = Vector3.new(2.5, sz * 2.3, sz * 2.3), Color = H(d[8]), Transparency = 0.35, Material = Enum.Material.SmoothPlastic, CFrame = tilt * CFrame.Angles(0, 0, pi / 2) }, g)
			P({ Shape = CYL, Size = Vector3.new(2, sz * 1.8, sz * 1.8), Color = H(d[2]), Transparency = 0.15, Material = Enum.Material.SmoothPlastic, CFrame = tilt * CFrame.Angles(0, 0, pi / 2) }, g)
		end
	end, nil, { id = "pl" .. i })
end

-- Гигантские звёзды
Label(sc, "Звёзды-гиганты")
local BIG = {
	{ "Стивенсон 2-18 (самая большая звезда)", "ff5a1a", "ff3a10", 1500, 0, 15 }, { "UY Щита (гипергигант)", "ff7a3a", "ff4a1a", 1300, 40, 10 },
	{ "VY Большого Пса", "ff4a1a", "ff2a0a", 1100, -40, 12 }, { "Бетельгейзе", "ff6a3a", "ff3a1a", 800, 80, 18 },
	{ "Антарес", "ff5a3a", "ff2a1a", 700, -80, 20 }, { "Ригель (синий)", "b0d0ff", "6a9aff", 500, 120, 14 },
	{ "R136a1 (самая массивная)", "8ab0ff", "4a7aff", 450, -120, 16 }, { "Сириус A", "e8f4ff", "a8c8ff", 300, 150, 10 },
	{ "Солнце (для сравнения)", "ffe08a", "ffb030", 150, -150, 12 }, { "Полярная звезда", "fffbd0", "ffe890", 350, 170, 22 },
	{ "Красный карлик", "ff4a2a", "aa1a0a", 120, -170, 8 }, { "Белый карлик", "ffffff", "c8e0ff", 60, 25, 30 },
	{ "Голубой гигант", "4aa0ff", "1a60ff", 600, -25, 24 }, { "Пурпурная звезда", "c04aff", "8a1aff", 500, 65, 26 },
	{ "Зелёная звезда", "4aff8a", "1aff5a", 500, -65, 26 },
}
for i, d in ipairs(BIG) do
	Toggle(sc, "🌟 " .. d[1], "big" .. i, function()
		local key = "big" .. i
		local sz = d[4]
		local g = group(key, sph(d[5], d[6], math.max(2200, sz * 1.8)), nil, true)
		local core = P({ Shape = BALL, Size = v3(sz), Color = H(d[2]) }, g)
		local s1 = P({ Shape = BALL, Size = v3(sz * 1.08), Color = H(d[3]), Transparency = 0.7 }, g)
		local s2 = P({ Shape = BALL, Size = v3(sz * 1.25), Color = H(d[3]), Transparency = 0.88 }, g)
		emitter(core, { tex = "f", c1 = d[3], c2 = d[2], rate = 12, s1 = sz * 0.02, s2 = sz * 0.05, size = sz * 0.25, life = 6, spread = 180, em = 1, tr = 0.6, lock = true })
		loop(key, function()
			local k = 1 + 0.03 * sin(os.clock() * 1.5)
			s1.Size = v3(sz * 1.08 * k); s2.Size = v3(sz * 1.25 * (2 - k))
		end)
	end, nil, { id = "big" .. i })
end
Toggle(sc, "💫 Пульсар (вращающиеся лучи)", "pulsar", function()
	local g = group("pulsar", sph(-100, 20, 2000), function(t) return CFrame.Angles(0, t * 4, 0) end)
	P({ Shape = BALL, Size = v3(60), Color = H("bfe8ff") }, g)
	P({ Shape = CYL, Size = Vector3.new(2000, 16, 16), Color = H("6ae0ff"), Transparency = 0.5, CFrame = CFrame.Angles(0, 0, rad(65)) }, g)
	P({ Shape = CYL, Size = Vector3.new(2000, 6, 6), Color = H("ffffff"), Transparency = 0.2, CFrame = CFrame.Angles(0, 0, rad(65)) }, g)
end)
Toggle(sc, "🔆 Двойная звёздная система", "binary", function()
	local g = group("binary", sph(110, 22, 2300), function(t) return CFrame.Angles(0, t * 0.3, 0) end)
	P({ Shape = BALL, Size = v3(500), Color = H("ff8a2a"), CFrame = CFrame.new(-380, 0, 0) }, g)
	P({ Shape = BALL, Size = v3(560), Color = H("ff6a1a"), Transparency = 0.8, CFrame = CFrame.new(-380, 0, 0) }, g)
	P({ Shape = BALL, Size = v3(350), Color = H("8ab8ff"), CFrame = CFrame.new(380, 0, 0) }, g)
	P({ Shape = BALL, Size = v3(400), Color = H("6a9aff"), Transparency = 0.8, CFrame = CFrame.new(380, 0, 0) }, g)
end)

-- Чёрные дыры
Label(sc, "Чёрные дыры и квазары")
local BH = {
	{ "Чёрная дыра TON 618", "ff5a00", "ffaa30", "ffffff", "6ab0ff", 700, -20, 12 },
	{ "Гаргантюа (Интерстеллар)", "ffb040", "ffe0a0", "ffffff", nil, 500, 30, 8 },
	{ "Стрелец A*", "ff3a3a", "ff9a5a", "ffe0c0", nil, 450, -90, 15 },
	{ "Синяя чёрная дыра", "1a5aff", "4aaaff", "e0f4ff", "8ac8ff", 550, 90, 10 },
	{ "Фиолетовая чёрная дыра", "8a2aff", "c06aff", "ffe0ff", "d08aff", 550, -140, 20 },
	{ "Изумрудный квазар", "2aff6a", "8affb0", "eaffef", "6affa8", 650, 150, 14 },
	{ "Розовая чёрная дыра", "ff2a8a", "ff7ac0", "ffe6f4", nil, 500, 180, 12 },
	{ "Белый квазар", "ffffff", "c8e0ff", "8ac0ff", "ffffff", 700, -45, 20 },
}
for i, d in ipairs(BH) do
	Toggle(sc, "⚫ " .. d[1], "bh" .. i, function()
		local key = "bh" .. i
		local s = d[6]
		local tilt = CFrame.Angles(rad(-18), 0, rad(8))
		local g = group(key, sph(d[7], d[8], 2300), function(t) return tilt * CFrame.Angles(0, t * 0.25, 0) end)
		local c1, c2, c3 = H(d[2]), H(d[3]), H(d[4])
		local cols = { c1, c1:Lerp(c2, 0.5), c2, c2:Lerp(c3, 0.5), c3 }
		for k, m in ipairs({ 3.2, 2.7, 2.25, 1.85, 1.5 }) do
			local dia = math.min(2040, s * m)
			P({ Shape = CYL, Size = Vector3.new(3, dia, dia), Color = cols[k], Transparency = 0.35 - 0.05 * k, CFrame = CFrame.new(0, k * 1.2, 0) * CFrame.Angles(0, 0, pi / 2) }, g)
		end
		P({ Shape = BALL, Size = v3(s * 1.06), Color = c3, Transparency = 0.85 }, g)
		P({ Shape = BALL, Size = v3(s), Color = Color3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic }, g)
		if d[5] then
			local len, w = math.min(2000, s * 3), s * 0.09
			P({ Shape = CYL, Size = Vector3.new(len, w, w), Color = H(d[5]), Transparency = 0.55, CFrame = CFrame.Angles(0, 0, pi / 2) }, g)
			P({ Shape = CYL, Size = Vector3.new(len, w * 0.4, w * 0.4), Color = Color3.new(1, 1, 1), Transparency = 0.2, CFrame = CFrame.Angles(0, 0, pi / 2) }, g)
		end
		local ep = P({ Size = Vector3.new(s * 2.4, 2, s * 2.4), Transparency = 1, Material = Enum.Material.SmoothPlastic, CFrame = CFrame.new(0, 2, 0) }, g)
		local e = emitter(ep, { tex = "s", c1 = d[3], c2 = d[4], rate = 120, s1 = 0, s2 = 0.5, size = s * 0.03, life = 5, em = 1, tr = 0.1, spread = 0, lock = true })
		pcall(function() e.Shape = Enum.ParticleEmitterShape.Disc end)
	end, nil, { id = "bh" .. i })
end

-- Галактики
Label(sc, "Галактики")
local GAL = {
	{ "Млечный Путь", "ffe8b0", "8ab0ff", 3, 900, 20, 30 }, { "Андромеда", "ffc8a0", "c08aff", 2, 1000, -60, 35 },
	{ "Галактика Вихрь", "c0a0ff", "6a8aff", 2, 800, 100, 28 }, { "Золотая галактика", "ffd24a", "ff8a2a", 4, 900, -120, 32 },
	{ "Алая галактика", "ff8a8a", "ff2a4a", 3, 900, 150, 26 }, { "Изумрудная галактика", "a0ffd0", "2a9a8a", 3, 900, -20, 38 },
}
for i, d in ipairs(GAL) do
	Toggle(sc, "🌌 " .. d[1], "gal" .. i, function()
		local R = d[5]
		local tilt = CFrame.Angles(rad(65), 0, rad(15))
		local g = group("gal" .. i, sph(d[6], d[7], 2000), function(t) return tilt * CFrame.Angles(0, t * 0.05, 0) end)
		local c1, c2 = H(d[2]), H(d[3])
		for k = 1, 240 do
			local r = (rnd() ^ 0.7) * R
			local a = r / R * 5 + ((k % d[4]) * (2 * pi / d[4])) + (rnd() - 0.5) * 0.5
			local s = rnd(8, 20)
			P({ Size = v3(s), Color = c1:Lerp(c2, r / R), CFrame = CFrame.new(cos(a) * r, (rnd() - 0.5) * R * 0.04, sin(a) * r) }, g)
		end
		P({ Shape = BALL, Size = v3(R * 0.2), Color = c1, Transparency = 0.35 }, g)
		P({ Shape = BALL, Size = v3(R * 0.45), Color = c1, Transparency = 0.85 }, g)
	end, nil, { id = "gal" .. i })
end

-- Астероиды, метеоры, аврора, радуга
Label(sc, "Астероиды и метеоры")
local AST = { { "Каменный пояс астероидов", "8a8a8a", "Slate" }, { "Ледяной пояс астероидов", "9ae0ff", "Ice" }, { "Золотой пояс астероидов", "ffd24a", "Neon" } }
for i, d in ipairs(AST) do
	Toggle(sc, "☄ " .. d[1], "ast" .. i, function()
		local g = group("ast" .. i, Vector3.zero, function(t) return CFrame.Angles(0, t * 0.02, 0) end)
		for _ = 1, 160 do
			local a, r, s = rnd() * 2 * pi, rnd(500, 800), rnd(8, 26)
			P({ Size = Vector3.new(s, s * 0.7, s * 1.2), Color = H(d[2]), Material = Enum.Material[d[3]], CFrame = CFrame.new(cos(a) * r, rnd(-40, 40), sin(a) * r) * CFrame.Angles(rnd() * 6, rnd() * 6, 0) }, g)
		end
	end, nil, { id = "ast" .. i })
end
local function meteor(col)
	local cp = CP()
	local az = rnd() * 2 * pi
	local start = cp + Vector3.new(cos(az) * 900, rnd(350, 800), sin(az) * 900)
	local dir = Vector3.new(-cos(az) + (rnd() - 0.5) * 0.6, -0.35, -sin(az) + (rnd() - 0.5) * 0.6).Unit
	local s = 7
	local p = P({ Shape = BALL, Size = v3(s), Color = col or Color3.new(1, 1, 1), CFrame = CFrame.new(start) })
	local a0 = mk("Attachment", { Position = Vector3.new(0, s / 2, 0) }, p)
	local a1 = mk("Attachment", { Position = Vector3.new(0, -s / 2, 0) }, p)
	mk("Trail", { Attachment0 = a0, Attachment1 = a1, Lifetime = 1.2, Color = ColorSequence.new(col or Color3.new(1, 1, 1), Color3.new(1, 1, 1)), LightEmission = 1, Transparency = NumberSequence.new(0, 1), WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, p)
	local dur = rnd(25, 45) / 10
	tw(p, { Position = start + dir * 1400 }, dur, Enum.EasingStyle.Linear)
	Debris:AddItem(p, dur + 1.5)
end
local MET = { { "Падающие звёзды (белые)", "ffffff" }, { "Золотые метеоры", "ffd24a" }, { "Голубые метеоры", "6ac8ff" }, { "Розовые метеоры", "ff6ac8" }, { "Радужные метеоры", "rainbow" } }
for i, d in ipairs(MET) do
	Toggle(sc, "🌠 " .. d[1], "met" .. i, function()
		bag("met" .. i, task.spawn(function()
			while true do
				task.wait(Cfg.meteorEvery * (0.5 + rnd()))
				meteor(d[2] == "rainbow" and Color3.fromHSV(rnd(), 0.7, 1) or H(d[2]))
			end
		end))
	end, nil, { id = "met" .. i })
end
Slider(sc, "Пауза между метеорами (сек)", 0.3, 10, 3, function(v) Cfg.meteorEvery = v end)
Button(sc, "☄ Метеоритный дождь (залп)", function()
	task.spawn(function() for _ = 1, 25 do meteor(Color3.fromHSV(rnd(), 0.4, 1)); task.wait(0.15) end end)
end)
Button(sc, "🌠 Один метеор", function() meteor() end)

Label(sc, "Северное сияние и радуга")
local AUR = { { "Зелёное северное сияние", 0.38, 0.05 }, { "Фиолетовое северное сияние", 0.76, 0.05 }, { "Красное северное сияние", 0.0, 0.03 }, { "Радужное северное сияние", -1, 0 } }
for i, d in ipairs(AUR) do
	Toggle(sc, "🌌 " .. d[1], "aur" .. i, function()
		local key = "aur" .. i
		local g = group(key, Vector3.new(0, 350, -1100), nil, true)
		local segs = {}
		for rb = 1, 3 do
			for k = 1, 36 do
				local p = P({ Size = Vector3.new(52, 260, 2), Transparency = 0.6, CFrame = CFrame.new((k - 18.5) * 50, 0, (rb - 2) * 120 + sin(k * 0.35) * 80) }, g)
				segs[#segs + 1] = { p, k, rb }
			end
		end
		loop(key, function()
			local t = os.clock()
			for _, s in ipairs(segs) do
				local p, k, rb = s[1], s[2], s[3]
				p.Size = Vector3.new(52, 220 + 90 * sin(t * 0.8 + k * 0.3 + rb), 2)
				p.Transparency = 0.55 + 0.25 * sin(t * 1.3 + k * 0.5)
				local hue = d[2] < 0 and ((k / 36 + t * 0.05) % 1) or (d[2] + d[3] * sin(k * 0.2 + t * 0.3)) % 1
				p.Color = Color3.fromHSV(hue, 0.7, 1)
			end
		end)
	end, nil, { id = "aur" .. i })
end
for i, dbl in ipairs({ false, true }) do
	Toggle(sc, dbl and "🌈 Двойная радуга" or "🌈 Радуга", "rbw" .. i, function()
		local g = group("rbw" .. i, Vector3.new(0, 0, -1500), nil, true)
		for band = 1, (dbl and 14 or 7) do
			local R = 1300 - band * 22 + (band > 7 and 250 or 0)
			local hue = ((band - 1) % 7) / 7 * 0.8
			if band > 7 then hue = 0.8 - ((band - 8) / 7 * 0.8) end
			for k = 0, 47 do
				local a = k / 47 * pi
				P({ Size = Vector3.new(40, 20, 4), Color = Color3.fromHSV(hue, 0.8, 1), Transparency = 0.35, CFrame = CFrame.new(cos(a) * R, sin(a) * R - 200, 0) * CFrame.Angles(0, 0, a + pi / 2) }, g)
			end
		end
	end, nil, { id = "rbw" .. i })
end
Button(sc, "♻ Убрать весь космос", function()
	for _, it in ipairs(AllItems) do
		if it.key and (it.key:match("^pl%d") or it.key:match("^big") or it.key:match("^bh") or it.key:match("^gal") or it.key:match("^ast") or it.key:match("^aur") or it.key:match("^rbw") or it.key:match("^stars") or it.key:match("^met") or it.key == "pulsar" or it.key == "binary") and it.state then setOn(it, false) end
	end
	clear("sp_fog"); RefreshUI()
end)

Label(sc, "Облака и вода")
local function getClouds()
	local t = Workspace.Terrain
	local c = t:FindFirstChildOfClass("Clouds")
	if not c then c = Instance.new("Clouds"); c.Parent = t; bag("clouds", c) end
	return c
end
local CLD = { { "Лёгкие облака", 0.3, 0.4, "ffffff" }, { "Обычные облака", 0.5, 0.6, "ffffff" }, { "Плотные облака", 0.8, 0.9, "ffffff" }, { "Закатные облака", 0.6, 0.6, "ffb090" }, { "Грозовые облака", 0.9, 1, "505560" }, { "Розовые облака", 0.6, 0.6, "ffc0e0" }, { "Золотые облака", 0.6, 0.6, "ffd870" }, { "Фиолетовые облака", 0.6, 0.7, "b090ff" } }
for _, d in ipairs(CLD) do
	Button(sc, "☁ " .. d[1], function() local c = getClouds(); c.Enabled = true; c.Cover = d[2]; c.Density = d[3]; c.Color = H(d[4]) end)
end
local TR = Workspace.Terrain
local WOrig = { WaterColor = TR.WaterColor, WaterTransparency = TR.WaterTransparency, WaterWaveSize = TR.WaterWaveSize, WaterWaveSpeed = TR.WaterWaveSpeed, WaterReflectance = TR.WaterReflectance }
local WAT = { { "Бирюзовая вода", "3acfd0", 0.8 }, { "Голубая лагуна", "3aa8ff", 0.7 }, { "Тёмная бездна", "0a1a3a", 0.3 }, { "Кровавое море", "a01010", 0.4 }, { "Лавовое море", "ff4a00", 0.2 }, { "Токсичная вода", "a0ff30", 0.4 }, { "Розовое озеро", "ff8ac8", 0.6 }, { "Молочная вода", "f0f0f0", 0.3 }, { "Чёрная нефть", "050505", 0 }, { "Золотая вода", "ffd24a", 0.4 } }
for _, d in ipairs(WAT) do
	Button(sc, "🌊 " .. d[1], function() TR.WaterColor = H(d[2]); TR.WaterTransparency = d[3]; TR.WaterReflectance = 0.6 end)
end
Button(sc, "♻ Вернуть воду и облака", function()
	for k, v in pairs(WOrig) do pcall(function() TR[k] = v end) end
	local c = TR:FindFirstChildOfClass("Clouds"); if c then c.Cover = 0.5; c.Density = 0.5; c.Color = Color3.new(1, 1, 1) end
end)

------------------------------------------------------------------
-- 🪽 КРЫЛЬЯ
------------------------------------------------------------------
local wgc = newCat("🪽 Крылья")
local SH = { feather = {}, bat = {}, butterfly = {}, crystal = {} }
for i = 1, 9 do
	local t = (i - 1) / 8
	table.insert(SH.feather, { ang = 75 - 120 * t, len = 5.2 - 3 * math.abs(t - 0.35), w = 1, th = 0.1, z = 0 })
end
for i = 1, 9 do
	local t = (i - 1) / 8
	table.insert(SH.feather, { ang = 75 - 120 * t, len = (5.2 - 3 * math.abs(t - 0.35)) * 0.55, w = 0.9, th = 0.1, z = 0.12 })
end
SH.bat = { { ang = 62, len = 7, w = 0.3, th = 0.3, z = 0 }, { ang = 28, len = 8, w = 0.3, th = 0.3, z = 0 }, { ang = -8, len = 7.5, w = 0.3, th = 0.3, z = 0 }, { ang = -42, len = 5.5, w = 0.3, th = 0.3, z = 0 },
	{ ang = 45, len = 6, w = 2.4, th = 0.05, z = 0.05, tr = 0.35 }, { ang = 10, len = 6.5, w = 2.4, th = 0.05, z = 0.05, tr = 0.35 }, { ang = -25, len = 5, w = 2.2, th = 0.05, z = 0.05, tr = 0.35 } }
SH.butterfly = { { ang = 38, len = 5.6, w = 4, th = 0.08, z = 0 }, { ang = -32, len = 4.2, w = 3, th = 0.08, z = 0 }, { ang = 38, len = 3, w = 2, th = 0.08, z = 0.1 }, { ang = -32, len = 2.3, w = 1.6, th = 0.08, z = 0.1 } }
SH.crystal = { { ang = 80, len = 3.5, w = 0.7, th = 0.5, z = 0 }, { ang = 52, len = 5, w = 0.8, th = 0.5, z = 0 }, { ang = 22, len = 6, w = 0.9, th = 0.5, z = 0 }, { ang = -8, len = 5.5, w = 0.8, th = 0.5, z = 0 }, { ang = -38, len = 4.2, w = 0.7, th = 0.5, z = 0 }, { ang = -65, len = 3, w = 0.6, th = 0.5, z = 0 } }
local WS = {
	{ "Ангельские белые", "ffffff", "dfe8ff", "SmoothPlastic", "feather", 0 }, { "Золотые ангельские", "ffd24a", "fff0a0", "Neon", "feather", 0 },
	{ "Серафим (сияющие)", "ffffff", "ffd24a", "Neon", "feather", 0.2 }, { "Демонические красные", "a01010", "ff2a2a", "SmoothPlastic", "bat", 0 },
	{ "Падший ангел", "1a1a1a", "4a4a4a", "SmoothPlastic", "feather", 0 }, { "Огненные", "ff3a00", "ffd000", "Neon", "feather", 0.15 },
	{ "Ледяные", "9ae0ff", "e0f8ff", "Ice", "feather", 0.1 }, { "Кристальные", "6affea", "c0fff6", "Glass", "crystal", 0.2 },
	{ "Галактические", "3a1a8a", "ff6aff", "Neon", "feather", 0.1 }, { "Неоновые синие", "00aaff", "00ffee", "Neon", "feather", 0 },
	{ "Радужные", "rainbow", "rainbow", "Neon", "feather", 0 }, { "Электрические", "6ae0ff", "ffffff", "Neon", "crystal", 0 },
	{ "Сакура", "ffb0d0", "ffe0f0", "SmoothPlastic", "feather", 0.1 }, { "Изумрудные", "1aaa6a", "6affb0", "Glass", "feather", 0.2 },
	{ "Тёмные фиолетовые", "3a0a5a", "8a2aff", "Neon", "bat", 0.1 }, { "Бабочка розовая", "ff7ac8", "ffc0e8", "Neon", "butterfly", 0.2 },
	{ "Бабочка голубая", "5aaaff", "a0e0ff", "Neon", "butterfly", 0.2 }, { "Бабочка-монарх", "ff8a1a", "1a1a1a", "SmoothPlastic", "butterfly", 0 },
	{ "Крылья летучей мыши", "2a2a2a", "5a1a5a", "SmoothPlastic", "bat", 0 }, { "Дракон зелёный", "1a8a2a", "6aff6a", "SmoothPlastic", "bat", 0 },
	{ "Дракон красный", "8a1a1a", "ff6a2a", "SmoothPlastic", "bat", 0 }, { "Призрачные", "e0f0ff", "a0c0ff", "Neon", "feather", 0.6 },
	{ "Чёрно-золотые", "111111", "ffd24a", "Neon", "feather", 0 }, { "Токсичные", "7aff1a", "2a8a0a", "Neon", "bat", 0.1 },
}
for i, st in ipairs(WS) do
	Toggle(wgc, "🪽 " .. st[1], "wing" .. i, function()
		local key = "wing" .. i
		local defs, mat, sc2 = SH[st[5]], Enum.Material[st[4]], Cfg.wingScale
		local c1, c2, rb = H(st[2]), H(st[3]), st[2] == "rainbow"
		local wp = {}
		for _, side in ipairs({ -1, 1 }) do
			for k, f in ipairs(defs) do
				local t = (k - 1) / math.max(1, #defs - 1)
				local p = P({ Size = Vector3.new(f.len * sc2, f.w * sc2, f.th * sc2), Material = mat, Color = c1:Lerp(c2, t), Transparency = f.tr or st[6] })
				wp[#wp + 1] = { p = p, side = side, f = f, t = t }
			end
		end
		local tt = 0
		loop(key, function(dt)
			tt = tt + dt
			local T = torso()
			if not T then return end
			local R = hrp()
			local moving = R and R.AssemblyLinearVelocity.Magnitude > 4
			local sweep = 0.85 + 0.4 * sin(tt * Cfg.flap * (moving and 5 or 2))
			local base = T.CFrame
			for _, w in ipairs(wp) do
				local f, s = w.f, w.side
				w.p.CFrame = base * CFrame.new(s * 0.5, 0.5, 0.55) * CFrame.Angles(0, -s * sweep, 0) * CFrame.new(0, 0, f.z) * CFrame.Angles(0, 0, s * rad(f.ang)) * CFrame.new(s * f.len * sc2 / 2, 0, 0)
				if rb then w.p.Color = Color3.fromHSV((w.t + tt * 0.2) % 1, 0.7, 1) end
			end
		end)
	end, nil, { group = "wings", char = true, id = "wing" .. i })
end
Slider(wgc, "Размер крыльев", 0.5, 3, 1, function(v) Cfg.wingScale = v; reapplyGroup("wings") end)
Slider(wgc, "Скорость взмаха", 0.2, 4, 1, function(v) Cfg.flap = v end)

------------------------------------------------------------------
-- 👑 АКСЕССУАРЫ
------------------------------------------------------------------
local axc = newCat("👑 Аксессуары")
local function ringCF(a, r) return CFrame.new(cos(a) * r, 0, sin(a) * r) * CFrame.Angles(0, -(a + pi / 2), 0) end
Label(axc, "Нимбы")
local HALO = { { "Золотой нимб", "ffd24a" }, { "Белый нимб", "ffffff" }, { "Красный нимб", "ff2a2a" }, { "Голубой нимб", "5aaaff" }, { "Розовый нимб", "ff7ac8" }, { "Радужный нимб", "rainbow" }, { "Двойной золотой нимб", "ffd24a", true } }
for i, d in ipairs(HALO) do
	Toggle(axc, "😇 " .. d[1], "halo" .. i, function()
		local key, n, r = "halo" .. i, 20, 1.1
		local rings = d[3] and 2 or 1
		local ps = {}
		for rr = 1, rings do
			for k = 1, n do ps[#ps + 1] = { P({ Size = Vector3.new(2 * pi * r * rr / n * 1.1, 0.14, 0.14), Color = H(d[2]) }), k, rr } end
		end
		loop(key, function()
			local h = head()
			if not h then return end
			local t = os.clock()
			for _, e in ipairs(ps) do
				local a = e[2] / n * 2 * pi + t * 0.5 * (e[3] == 2 and -1 or 1)
				e[1].CFrame = CFrame.new(h.Position + Vector3.new(0, 1.25 + 0.08 * sin(t * 2) + (e[3] - 1) * 0.25, 0)) * ringCF(a, r * (1 + (e[3] - 1) * 0.3))
				if d[2] == "rainbow" then e[1].Color = Color3.fromHSV((e[2] / n + t * 0.2) % 1, 0.7, 1) end
			end
		end)
	end, nil, { group = "halo", char = true, id = "halo" .. i })
end
Label(axc, "Короны")
local CRN = { { "Золотая корона", "ffd24a", "Neon" }, { "Серебряная корона", "dfe4ee", "Metal" }, { "Алмазная корона", "8afff0", "Neon" }, { "Огненная корона", "ff5a00", "Neon" }, { "Тёмная королевская корона", "8a2aff", "Neon" }, { "Радужная корона", "rainbow", "Neon" } }
for i, d in ipairs(CRN) do
	Toggle(axc, "👑 " .. d[1], "crown" .. i, function()
		local key, ps = "crown" .. i, {}
		for k = 1, 12 do ps[#ps + 1] = { P({ Size = Vector3.new(0.65, 0.3, 0.2), Color = H(d[2]), Material = Enum.Material[d[3]] }), k, false } end
		for k = 1, 6 do ps[#ps + 1] = { P({ Size = Vector3.new(0.22, 0.75, 0.22), Color = H(d[2]), Material = Enum.Material[d[3]] }), k, true } end
		loop(key, function()
			local h = head()
			if not h then return end
			local t = os.clock()
			for _, e in ipairs(ps) do
				local a = e[2] / (e[3] and 6 or 12) * 2 * pi
				e[1].CFrame = h.CFrame * CFrame.new(0, e[3] and 0.95 or 0.7, 0) * ringCF(a, 0.75)
				if d[2] == "rainbow" then e[1].Color = Color3.fromHSV((e[2] / 12 + t * 0.2) % 1, 0.7, 1) end
			end
		end)
	end, nil, { group = "crown", char = true, id = "crown" .. i })
end
Label(axc, "Рога")
local HORN = { { "Чёрные рога", "1a1a1a", "SmoothPlastic" }, { "Красные рога демона", "c01010", "Neon" }, { "Золотые рога", "ffd24a", "Neon" }, { "Ледяные рога", "9ae0ff", "Ice" }, { "Кристальные рога", "ff4aff", "Neon" }, { "Костяные рога", "e8e0c8", "SmoothPlastic" } }
for i, d in ipairs(HORN) do
	Toggle(axc, "😈 " .. d[1], "horn" .. i, function()
		local key, ps = "horn" .. i, {}
		for _, s in ipairs({ -1, 1 }) do
			for k = 1, 4 do ps[#ps + 1] = { P({ Size = Vector3.new(0.34 - 0.06 * k, 0.4, 0.34 - 0.06 * k), Color = H(d[2]), Material = Enum.Material[d[3]] }), s, k } end
		end
		loop(key, function()
			local h = head()
			if not h then return end
			for _, e in ipairs(ps) do
				local s, k = e[2], e[3]
				e[1].CFrame = h.CFrame * CFrame.new(s * (0.4 + 0.18 * k), 0.55 + 0.3 * k, -0.15 - 0.05 * k) * CFrame.Angles(0, 0, -s * 0.25 * k)
			end
		end)
	end, nil, { group = "horn", char = true, id = "horn" .. i })
end
Label(axc, "Хвосты")
local TAIL = { { "Лисий хвост", "ff8a2a", "ffffff", 10, 0.9 }, { "Кошачий хвост", "1a1a1a", "3a3a3a", 10, 0.6 }, { "Демонический хвост", "a01010", "ff2a2a", 10, 0.6 }, { "Драконий хвост", "1a8a2a", "6aff6a", 12, 0.8 }, { "Радужный хвост", "ff3a3a", "3a3aff", 12, 0.7 }, { "Кроличий хвост", "ffffff", "ffffff", 1, 1.3 }, { "Звёздный хвост", "ffffff", "6a8aff", 12, 0.6 } }
for i, d in ipairs(TAIL) do
	Toggle(axc, "🦊 " .. d[1], "tail" .. i, function()
		local key, n, segs, pos = "tail" .. i, d[4], {}, {}
		for k = 1, n do
			local s = d[5] * (1 - (k - 1) / (n + 2) * 0.7)
			segs[k] = P({ Shape = BALL, Size = v3(s), Color = H(d[2]):Lerp(H(d[3]), (k - 1) / math.max(1, n - 1)), Material = (i >= 5 and i ~= 6) and Enum.Material.Neon or Enum.Material.SmoothPlastic })
		end
		loop(key, function()
			local T = torso()
			if not T then return end
			local t = os.clock()
			local anchor = (T.CFrame * CFrame.new(0, -0.9, 0.6)).Position
			for k = 1, n do
				local prev = (k == 1) and anchor or pos[k - 1]
				local cur = pos[k] or prev
				local dir = cur - prev
				if dir.Magnitude < 0.001 then dir = T.CFrame.LookVector * -1 + Vector3.new(0, -0.2, 0) end
				local tgt = prev + dir.Unit * 0.6 + Vector3.new(0, -0.03, 0) + T.CFrame.RightVector * sin(t * 3 + k * 0.6) * 0.04
				pos[k] = tgt
				segs[k].Position = tgt
				if i == 5 then segs[k].Color = Color3.fromHSV((k / n + t * 0.2) % 1, 0.8, 1) end
			end
		end)
	end, nil, { group = "tail", char = true, id = "tail" .. i })
end
Label(axc, "Светящиеся глаза")
local EYES = { { "Красные глаза", "ff1a1a" }, { "Синие глаза", "1a8aff" }, { "Зелёные глаза", "1aff4a" }, { "Золотые глаза", "ffd24a" }, { "Фиолетовые глаза", "a02aff" }, { "Белые глаза", "ffffff" } }
for i, d in ipairs(EYES) do
	Toggle(axc, "👁 " .. d[1], "eye" .. i, function()
		local key = "eye" .. i
		local l = P({ Size = Vector3.new(0.25, 0.12, 0.06), Color = H(d[2]) })
		local r = P({ Size = Vector3.new(0.25, 0.12, 0.06), Color = H(d[2]) })
		mk("PointLight", { Color = H(d[2]), Range = 6, Brightness = 2 }, l)
		loop(key, function()
			local h = head()
			if not h then return end
			l.CFrame = h.CFrame * CFrame.new(-0.2, 0.1, -0.52)
			r.CFrame = h.CFrame * CFrame.new(0.2, 0.1, -0.52)
		end)
	end, nil, { group = "eyes", char = true, id = "eye" .. i })
end

------------------------------------------------------------------
-- 🔥 АУРЫ
------------------------------------------------------------------
local auc = newCat("🔥 Ауры")
local function AU(n, tex, c1, c2, rate, s1, s2, size, life, acc, em) return { n = n, tex = tex, c1 = c1, c2 = c2, rate = rate, s1 = s1, s2 = s2, size = size, life = life, acc = acc, em = em } end
local AURA = {
	AU("Огненная аура", "f", "ff6a00", "ffd000", 60, 2, 5, 2.5, 1, 6, 0.5), AU("Ледяная аура", "s", "9ae0ff", "e0f8ff", 40, 1, 3, 0.6, 2, 1, 0.8),
	AU("Электрическая аура", "s", "6ae0ff", "ffffff", 80, 8, 14, 0.5, 0.3, 0, 1), AU("Тёмная аура", "m", "1a0030", "6a00aa", 30, 1, 3, 3, 1.2, 2, 0),
	AU("Святая аура", "s", "fff4b0", "ffffff", 50, 1, 3, 0.8, 2, 4, 1), AU("Токсичная аура", "m", "7aff1a", "3a8a0a", 30, 1, 3, 3, 1.2, 2, 0.3),
	AU("Кровавая аура", "s", "ff1a1a", "7a0000", 50, 1, 4, 0.8, 1.5, 3, 0.4), AU("Космическая аура", "s", "a06aff", "6ac8ff", 70, 3, 8, 0.7, 1.5, 0, 1),
	AU("Неоновая розовая", "s", "ff2bd6", "ff9aee", 60, 2, 5, 0.7, 1.5, 3, 1), AU("Золотая аура", "s", "ffd24a", "fff0a0", 60, 2, 5, 0.7, 1.5, 3, 1),
	AU("Радужная аура", "s", "rainbow", "rainbow", 70, 2, 5, 0.8, 1.5, 3, 1), AU("Ночная аура", "s", "2a2aaa", "6a6aff", 50, 1, 4, 0.8, 1.5, 2, 0.8),
	AU("Водная аура", "s", "2a8aff", "8ad0ff", 60, 3, 6, 0.5, 1.2, -15, 0.5), AU("Земляная аура", "m", "6a4a2a", "a08a5a", 30, 1, 3, 2, 1.2, 1, 0),
	AU("Ветряная аура", "m", "ffffff", "d0e0f0", 40, 8, 12, 2, 0.8, 0, 0), AU("Аура сакуры", "s", "ffb0d0", "ffe0f0", 40, 1, 3, 0.8, 3, -1, 0.3),
	AU("Звёздная пыль", "s", "ffffff", "a0d0ff", 90, 1, 4, 0.3, 2, 0, 1), AU("Аура духа", "m", "a0ffe0", "ffffff", 25, 1, 2, 3, 1.5, 3, 0.5),
	AU("Плазменная аура", "s", "ff2aff", "2affff", 70, 6, 10, 0.6, 0.8, 0, 1), AU("Магическая аура", "s", "c06aff", "6aa0ff", 60, 2, 5, 0.8, 1.5, 2, 1),
	AU("Кристальная аура", "s", "6affea", "c0fff6", 50, 2, 4, 0.7, 1.5, 1, 0.9), AU("Лавовая аура", "f", "ff3a00", "ff9a00", 50, 2, 4, 2, 1, 3, 0.8),
	AU("Аура рассвета", "s", "ff9a6a", "ffd08a", 50, 2, 4, 0.8, 1.5, 3, 1), AU("Мятная аура", "s", "8affc8", "d0ffe8", 50, 2, 4, 0.7, 1.5, 3, 1),
	AU("Вампирская аура", "m", "8a0020", "1a0008", 30, 1, 3, 3, 1.2, 2, 0), AU("Аура искр", "s", "ffcc40", "ff6a00", 80, 10, 18, 0.35, 0.5, -20, 1),
	AU("Дымная аура", "m", "808080", "404040", 30, 1, 3, 3, 1.5, 3, 0), AU("Лунная аура", "s", "d0d8ff", "ffffff", 50, 1, 3, 0.7, 2, 2, 1),
	AU("Солнечная аура", "f", "ffe040", "ff8a00", 60, 2, 5, 3, 1, 4, 1), AU("Метелица", "s", "ffffff", "c8e8ff", 80, 6, 10, 0.5, 1.2, 0, 0.6),
	AU("Пиксельная аура", "s", "00ff55", "00ffaa", 50, 2, 4, 0.4, 1.5, 3, 1), AU("Бабл-гам аура", "s", "ff7ac8", "ffb0e0", 40, 1, 3, 1, 2, 3, 0.4),
}
Label(auc, "Ауры (одна за раз)")
for i, d in ipairs(AURA) do
	Toggle(auc, "🔥 " .. d.n, "au" .. i, function()
		local R = hrp()
		if not R then return end
		bag("au" .. i, emitter(R, { tex = d.tex, c1 = d.c1, c2 = d.c2, rate = d.rate * Cfg.auraRate, s1 = d.s1, s2 = d.s2, size = d.size, life = d.life, acc = d.acc, em = d.em, spread = 180 }))
		bag("au" .. i, mk("PointLight", { Color = H(d.c1 == "rainbow" and "ff5ca8" or d.c1), Range = 14, Brightness = 2 }, R))
	end, nil, { group = "aura", char = true, id = "au" .. i })
end
Slider(auc, "Плотность частиц ауры", 0.2, 3, 1, function(v) Cfg.auraRate = v; reapplyGroup("aura") end)
Label(auc, "Контур вокруг тела")
local OUT = { { "Красный", "ff2a2a" }, { "Оранжевый", "ff8a1a" }, { "Золотой", "ffd24a" }, { "Зелёный", "2aff6a" }, { "Голубой", "2ad0ff" }, { "Синий", "2a5aff" }, { "Фиолетовый", "a02aff" }, { "Белый", "ffffff" } }
for i, d in ipairs(OUT) do
	Toggle(auc, "🔲 Контур: " .. d[1], "out" .. i, function()
		local C = LP.Character
		if C then bag("out" .. i, mk("Highlight", { FillColor = H(d[2]), OutlineColor = H(d[2]), FillTransparency = 0.75, OutlineTransparency = 0, Adornee = C }, C)) end
	end, nil, { group = "outline", char = true })
end
Label(auc, "Свет вокруг тела")
for i, d in ipairs(OUT) do
	Toggle(auc, "💡 Свет: " .. d[1], "pl_" .. i, function()
		local R = hrp()
		if R then bag("pl_" .. i, mk("PointLight", { Color = H(d[2]), Range = 18, Brightness = 3 }, R)) end
	end, nil, { group = "plight", char = true })
end

------------------------------------------------------------------
-- 🔮 ПОД НОГАМИ
------------------------------------------------------------------
local gc = newCat("🔮 Под ногами")
local function groundPos()
	local R = hrp()
	if not R then return end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { LP.Character, World }
	local hit = Workspace:Raycast(R.Position, Vector3.new(0, -15, 0), rp)
	return hit and (hit.Position + Vector3.new(0, 0.08, 0)) or (R.Position - Vector3.new(0, 3, 0))
end
local function mkRing(n, th, col) local t = {}; for k = 1, n do t[k] = P({ Size = Vector3.new(0.7, 0.12, th), Color = col }) end return t end
local function setRing(parts, c, r, a0, resize)
	local n = #parts
	local len = 2 * pi * r / n * 1.08
	for k, p in ipairs(parts) do
		if resize then p.Size = Vector3.new(len, 0.12, p.Size.Z) end
		p.CFrame = CFrame.new(c) * ringCF(a0 + (k - 1) / n * 2 * pi, r)
	end
end
local function mkTri(col) local t = {}; for k = 1, 6 do t[k] = P({ Size = Vector3.new(0.2, 0.12, 5), Color = col }) end return t end
local function setTri(parts, c, r, a0)
	local idx = 0
	for k = 0, 1 do
		for j = 0, 2 do
			idx = idx + 1
			local a = a0 + k * pi / 3 + j * 2 * pi / 3
			local b = a + 2 * pi / 3
			local A_ = c + Vector3.new(cos(a) * r, 0, sin(a) * r)
			local B_ = c + Vector3.new(cos(b) * r, 0, sin(b) * r)
			parts[idx].Size = Vector3.new(0.2, 0.12, (A_ - B_).Magnitude)
			parts[idx].CFrame = CFrame.lookAt((A_ + B_) / 2, B_)
		end
	end
end
local GR = {}
for i, n in ipairs({ "Синий", "Красный", "Золотой", "Фиолетовый", "Зелёный", "Розовый", "Бирюзовый", "Белый", "Радужный" }) do
	local cs = { "2a8aff", "ff2a2a", "ffd24a", "a02aff", "2aff6a", "ff5ca8", "2affee", "ffffff", "rainbow" }
	GR[#GR + 1] = { "Магический круг: " .. n, cs[i], cs[i] == "rainbow" and "rainbow" or "ffffff", "circle", "s" }
end
for i, n in ipairs({ "Синяя", "Красная", "Золотая", "Фиолетовая", "Зелёная", "Розовая" }) do
	local cs = { "2a8aff", "ff2a2a", "ffd24a", "a02aff", "2aff6a", "ff5ca8" }
	GR[#GR + 1] = { "Печать-гексаграмма: " .. n, cs[i], "ffffff", "seal", "s" }
end
for i, n in ipairs({ "Голубой", "Красный", "Зелёный", "Золотой", "Фиолетовый" }) do
	local cs = { "2ad0ff", "ff2a2a", "2aff6a", "ffd24a", "a02aff" }
	GR[#GR + 1] = { "Радар-пульс: " .. n, cs[i], "ffffff", "radar", "s" }
end
for i, n in ipairs({ "Розовый", "Белый", "Золотой", "Голубой" }) do
	local cs = { "ff7ac8", "ffffff", "ffd24a", "5aaaff" }
	GR[#GR + 1] = { "Цветок-лотос: " .. n, cs[i], "ffffff", "lotus", "s" }
end
GR[#GR + 1] = { "Огненная печать", "ff5a00", "ffd000", "seal", "f" }
GR[#GR + 1] = { "Ледяной круг", "9ae0ff", "ffffff", "circle", "s" }
GR[#GR + 1] = { "Электро-круг", "6ae0ff", "ffffff", "circle", "s" }
GR[#GR + 1] = { "Круг тьмы", "8a2aff", "1a0030", "circle", "m" }
for i, d in ipairs(GR) do
	Toggle(gc, "🔮 " .. d[1], "gr" .. i, function()
		local key = "gr" .. i
		local c1, c2 = H(d[2]), H(d[3])
		local rb = d[2] == "rainbow"
		local A_, B_, C_
		if d[4] == "circle" then A_ = mkRing(28, 0.2, c1); B_ = mkRing(18, 0.2, c2); C_ = mkRing(8, 0.5, c1)
		elseif d[4] == "seal" then A_ = mkRing(28, 0.2, c1); B_ = mkTri(c2)
		elseif d[4] == "radar" then A_ = mkRing(28, 0.2, c1); B_ = mkRing(28, 0.2, c2); C_ = mkRing(28, 0.2, c1)
		else A_ = mkRing(20, 0.2, c1); B_ = mkRing(8, 0.7, c2) end
		local ep = P({ Size = Vector3.new(4, 0.2, 4), Transparency = 1, Material = Enum.Material.SmoothPlastic })
		bag(key, ep)
		emitter(ep, { tex = d[5], c1 = d[2], c2 = d[3], rate = 14, s1 = 1, s2 = 3, size = 0.7, life = 1.5, acc = 2, spread = 30 })
		loop(key, function()
			local c = groundPos()
			if not c then return end
			local t = os.clock()
			ep.CFrame = CFrame.new(c)
			if d[4] == "circle" then
				setRing(A_, c, 3.2, t * 0.6); setRing(B_, c, 2, -t * 0.9); setRing(C_, c, 2.6, t * 1.3)
			elseif d[4] == "seal" then
				setRing(A_, c, 3.2, t * 0.5); setTri(B_, c, 2.9, t * 0.8)
			elseif d[4] == "radar" then
				for k, ring in ipairs({ A_, B_, C_ }) do
					local f = ((t * 0.6) + (k - 1) / 3) % 1
					setRing(ring, c, 0.5 + f * 4.5, 0, true)
					for _, p in ipairs(ring) do p.Transparency = f end
				end
			else
				setRing(A_, c, 2.6, t * 0.4)
				for k, p in ipairs(B_) do
					local a = t * 0.7 + (k - 1) / 8 * 2 * pi
					p.Size = Vector3.new(0.5, 0.12, 2.4)
					p.CFrame = CFrame.new(c) * CFrame.Angles(0, -a + pi / 2, 0) * CFrame.new(0, 0, -1.6)
				end
			end
			if rb then
				local col = Color3.fromHSV((t * 0.2) % 1, 0.8, 1)
				for _, set in ipairs({ A_, B_, C_ }) do for _, p in ipairs(set) do p.Color = col end end
			end
		end)
	end, nil, { group = "ground", char = true, id = "gr" .. i })
end

------------------------------------------------------------------
-- 🌠 СЛЕДЫ
------------------------------------------------------------------
local trc = newCat("🌠 Следы")
local TRL = {
	{ "Радужный след", "rainbow", "rainbow", 1 }, { "Огненный след", "ff5a00", "ffd000", 0.8 }, { "Ледяной след", "9ae0ff", "ffffff", 1 },
	{ "Неоновый розовый след", "ff2bd6", "00e5ff", 1 }, { "Электрический след", "6ae0ff", "ffffff", 0.5 }, { "Золотой след", "ffd24a", "fff0a0", 1.2 },
	{ "Тёмный след", "1a0030", "8a2aff", 1.2 }, { "Звёздный след", "ffffff", "a0d0ff", 1.5 }, { "Кровавый след", "7a0000", "ff2a2a", 1 },
	{ "Токсичный след", "7aff1a", "3a8a0a", 1 }, { "Сакура-след", "ffb0d0", "ffe0f0", 1.5 }, { "Космический след", "3a1a8a", "ff6aff", 1.5 },
	{ "Плазменный след", "ff2aff", "2affff", 0.8 }, { "Светлячковый след", "d8ff6a", "ffff9a", 1.5 }, { "Лавовый след", "ff3a00", "ffaa00", 1 },
	{ "Призрачный след", "e0f0ff", "a0c0ff", 2 },
}
for i, d in ipairs(TRL) do
	Toggle(trc, "〰 " .. d[1], "tr" .. i, function()
		local C, key = LP.Character, "tr" .. i
		if not C then return end
		local function add(part, o0, o1)
			if not part then return end
			local a0 = mk("Attachment", { Position = o0 }, part)
			local a1 = mk("Attachment", { Position = o1 }, part)
			local t = mk("Trail", { Attachment0 = a0, Attachment1 = a1, Color = colorSeq(d[2], d[3]), Lifetime = d[4], LightEmission = 1, MinLength = 0.05, FaceCamera = true,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
				WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, part)
			bag(key, a0); bag(key, a1); bag(key, t)
		end
		add(hrp(), Vector3.new(0, 0.8, 0), Vector3.new(0, -2.4, 0))
		for _, n in ipairs({ "LeftHand", "RightHand", "Left Arm", "Right Arm" }) do add(C:FindFirstChild(n), Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0)) end
	end, nil, { group = "trail", char = true, id = "tr" .. i })
end

------------------------------------------------------------------
-- 🪐 ОРБИТЫ
------------------------------------------------------------------
local oc = newCat("💎 Орбиты")
local ORB = {
	{ "Золотые шары", 5, 3.5, 1.2, "ffd24a", 0.7, 0 }, { "Голубые огни", 8, 3.5, 1.5, "5ac8ff", 0.5, 0 }, { "Розовые сферы", 6, 3.2, 1.3, "ff7ac8", 0.6, 0 },
	{ "Радужный хоровод", 10, 3.8, 1.2, "rainbow", 0.5, 0 }, { "Огненные шары", 4, 3.3, 2, "ff5a00", 0.8, 0 }, { "Ледяные кристаллы", 6, 3.3, 1.2, "9ae0ff", 0.7, 0, true },
	{ "Звёзды-спутники", 7, 3.6, 1.4, "ffe84a", 0.6, 0, true }, { "Тёмные сферы", 3, 3.2, 1.5, "6a00aa", 0.9, 0 }, { "Зелёные огоньки", 12, 3.6, 1.8, "5aff8a", 0.35, 0 },
	{ "Быстрый вихрь", 14, 2.5, 4, "ffffff", 0.3, 0 }, { "Наклонная орбита", 6, 3.8, 1.5, "a06aff", 0.6, 0.8 }, { "Большое кольцо огней", 18, 5, 0.8, "ffb04a", 0.4, 0 },
}
for i, d in ipairs(ORB) do
	Toggle(oc, "💎 " .. d[1], "orb" .. i, function()
		local key, ps = "orb" .. i, {}
		for k = 1, d[2] do
			ps[k] = P({ Shape = d[8] and Enum.PartType.Block or BALL, Size = v3(d[6]), Color = d[5] == "rainbow" and Color3.fromHSV(k / d[2], 0.8, 1) or H(d[5]) })
		end
		loop(key, function()
			local R = hrp()
			if not R then return end
			local t = os.clock()
			for k, p in ipairs(ps) do
				local a = t * d[4] * Cfg.orbitSpeed + k / d[2] * 2 * pi
				local off = CFrame.Angles(d[7], 0, 0) * Vector3.new(cos(a) * d[3], sin(t * 2 + k) * 0.3, sin(a) * d[3])
				p.CFrame = CFrame.new(R.Position + off) * CFrame.Angles(t, t, 0)
			end
		end)
	end, nil, { group = "orbit", char = true })
end
Toggle(oc, "☀ Мини-солнечная система", "minisys", function()
	local sun = P({ Shape = BALL, Size = v3(0.9), Color = H("ffd24a") })
	local cols = { "9a8a7a", "e8c888", "2a6ad8", "c8502a", "d8a878", "e8d49a", "7ae8e8", "2a4ad8" }
	local pl = {}
	for k = 1, 8 do pl[k] = P({ Shape = BALL, Size = v3(0.3 + (k == 5 and 0.2 or 0)), Color = H(cols[k]) }) end
	loop("minisys", function()
		local R = hrp()
		if not R then return end
		local t = os.clock()
		local c = R.Position + Vector3.new(0, 4.5, 0)
		sun.Position = c
		for k, p in ipairs(pl) do
			local a = t * (2.2 - k * 0.2) * Cfg.orbitSpeed + k
			p.Position = c + Vector3.new(cos(a) * (1 + k * 0.5), 0, sin(a) * (1 + k * 0.5))
		end
	end)
end, nil, { char = true })
Toggle(oc, "🧬 Спираль ДНК", "dna", function()
	local ps = {}
	for k = 1, 48 do ps[k] = P({ Shape = BALL, Size = v3(0.35), Color = k % 2 == 0 and H("5ac8ff") or H("ff7ac8") }) end
	loop("dna", function()
		local R = hrp()
		if not R then return end
		local t = os.clock()
		for k, p in ipairs(ps) do
			local i = math.ceil(k / 2)
			local ph = (k % 2 == 0) and 0 or pi
			local a = i * 0.5 + t * 2 + ph
			p.Position = R.Position + Vector3.new(cos(a) * 2.2, -2.5 + i * 0.2, sin(a) * 2.2)
		end
	end)
end, nil, { char = true })
local RNG = { { "Гироскоп (3 кольца)", "5ac8ff", 3 }, { "Огненное кольцо", "ff5a00", 1 }, { "Золотые кольца", "ffd24a", 2 }, { "Радужные кольца", "rainbow", 3 }, { "Фиолетовое кольцо", "a02aff", 1 } }
for i, d in ipairs(RNG) do
	Toggle(oc, "⭕ " .. d[1], "ring" .. i, function()
		local sets = {}
		for k = 1, d[3] do
			local s = {}
			for j = 1, 24 do s[j] = P({ Size = Vector3.new(2 * pi * (4.2 - k * 0.6) / 24 * 1.1, 0.14, 0.14), Color = H(d[2]) }) end
			sets[k] = s
		end
		loop("ring" .. i, function()
			local R = hrp()
			if not R then return end
			local t = os.clock()
			for k, s in ipairs(sets) do
				local rot = CFrame.Angles(t * (0.5 + k * 0.4), t * 0.6 * k, (k - 1) * 0.9)
				for j, p in ipairs(s) do
					p.CFrame = CFrame.new(R.Position) * rot * ringCF(j / 24 * 2 * pi, 4.2 - k * 0.6)
					if d[2] == "rainbow" then p.Color = Color3.fromHSV((j / 24 + t * 0.2) % 1, 0.8, 1) end
				end
			end
		end)
	end, nil, { char = true })
end
Slider(oc, "Скорость орбит", 0.2, 4, 1, function(v) Cfg.orbitSpeed = v end)

------------------------------------------------------------------
-- 🧍 ТЕЛО
------------------------------------------------------------------
local bc = newCat("🧍 Тело и щиты")
local BodyOrig = {}
local function bodyParts()
	local out, C = {}, LP.Character
	if C then for _, p in ipairs(C:GetChildren()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then out[#out + 1] = p end end end
	return out
end
local function restoreBody()
	for p, o in pairs(BodyOrig) do
		if p.Parent then p.Color = o[1]; p.Material = o[2]; p.Transparency = o[3]; p.Reflectance = o[4] end
	end
	BodyOrig = {}
end
local BODY = {
	{ "Золотое тело", "ffd24a", "Metal", 0, 0.3 }, { "Серебряное тело", "c8c8d0", "Metal", 0, 0.3 }, { "Хромированное тело", "e0e0e0", "Metal", 0, 0.8 },
	{ "Стеклянное тело", "a0d8ff", "Glass", 0.4, 0.2 }, { "Призрак", "e0f0ff", "Neon", 0.65, 0 }, { "Ледяное тело", "b0e8ff", "Ice", 0, 0 },
	{ "Мраморное тело", "f0f0f0", "Marble", 0, 0 }, { "Лавовое тело", "ff3a00", "Neon", 0, 0 }, { "Неон красный", "ff1a1a", "Neon", 0, 0 },
	{ "Неон синий", "1a5aff", "Neon", 0, 0 }, { "Неон зелёный", "1aff4a", "Neon", 0, 0 }, { "Неон розовый", "ff2bd6", "Neon", 0, 0 },
	{ "Неон фиолетовый", "a02aff", "Neon", 0, 0 }, { "Неон бирюзовый", "1affee", "Neon", 0, 0 }, { "Неон оранжевый", "ff8a1a", "Neon", 0, 0 },
	{ "Неон жёлтый", "ffee1a", "Neon", 0, 0 }, { "Неон белый", "ffffff", "Neon", 0, 0 }, { "Тёмная материя", "101010", "SmoothPlastic", 0, 0 },
	{ "Галактическое тело", "3a1a8a", "Neon", 0, 0 }, { "Радужное тело", "rainbow", "Neon", 0, 0 },
}
for i, d in ipairs(BODY) do
	Toggle(bc, "🧍 " .. d[1], "body" .. i, function()
		local key = "body" .. i
		for _, p in ipairs(bodyParts()) do
			if not BodyOrig[p] then BodyOrig[p] = { p.Color, p.Material, p.Transparency, p.Reflectance } end
			p.Material = Enum.Material[d[3]]; p.Transparency = d[4]; p.Reflectance = d[5]
			if d[2] ~= "rainbow" then p.Color = H(d[2]) end
		end
		if d[2] == "rainbow" then
			loop(key, function() local c = Color3.fromHSV((os.clock() * 0.2) % 1, 0.8, 1); for _, p in ipairs(bodyParts()) do p.Color = c end end)
		end
	end, restoreBody, { group = "body", char = true })
end
Label(bc, "Энергетические щиты")
local SHD = { { "Голубой щит", "2ad0ff" }, { "Золотой щит", "ffd24a" }, { "Красный щит", "ff2a2a" }, { "Фиолетовый щит", "a02aff" }, { "Радужный щит", "rainbow" } }
for i, d in ipairs(SHD) do
	Toggle(bc, "🛡 " .. d[1], "shd" .. i, function()
		local ball = P({ Shape = BALL, Size = v3(7), Color = H(d[2]), Transparency = 0.75 })
		loop("shd" .. i, function()
			local R = hrp()
			if not R then return end
			ball.Position = R.Position
			local t = os.clock()
			ball.Transparency = 0.75 + 0.1 * sin(t * 3)
			if d[2] == "rainbow" then ball.Color = Color3.fromHSV((t * 0.2) % 1, 0.7, 1) end
		end)
	end, nil, { group = "shield", char = true })
end

------------------------------------------------------------------
-- 🎥 КАМЕРА
------------------------------------------------------------------
local cmc = newCat("🎥 Камера")
Toggle(cmc, "🔭 Свой угол обзора (FOV)", "fov", function()
	local o = CAM().FieldOfView
	loop("fov", function() CAM().FieldOfView = Cfg.fov end)
	bag("fov", function() CAM().FieldOfView = o end)
end)
Slider(cmc, "Значение FOV", 30, 120, 70, function(v) Cfg.fov = v end)
Slider(cmc, "Макс. отдаление камеры", 10, 2000, 128, function(v) LP.CameraMaxZoomDistance = v end, 10)
for i, f in ipairs({ 0.08, 0.12, 0.17 }) do
	Toggle(cmc, "🎞 Кино-полосы " .. i, "bars" .. i, function()
		for _, y in ipairs({ 0, 1 - f }) do
			bag("bars" .. i, mk("Frame", { Size = UDim2.new(1, 0, f, 0), Position = UDim2.new(0, 0, y, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, Overlay))
		end
	end, nil, { group = "bars" })
end
Toggle(cmc, "🌘 Виньетка (затемнение краёв)", "vig", function()
	local function edge(pos, size, rot)
		local f = mk("Frame", { Position = pos, Size = size, BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, Overlay)
		mk("UIGradient", { Rotation = rot, Transparency = NumberSequence.new(1 - Cfg.vig, 1) }, f)
		bag("vig", f)
	end
	edge(UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.25, 0), 90)
	edge(UDim2.new(0, 0, 0.75, 0), UDim2.new(1, 0, 0.25, 0), 270)
	edge(UDim2.new(0, 0, 0, 0), UDim2.new(0.2, 0, 1, 0), 0)
	edge(UDim2.new(0.8, 0, 0, 0), UDim2.new(0.2, 0, 1, 0), 180)
end)
Slider(cmc, "Сила виньетки (перевключи)", 0.1, 1, 0.5, function(v) Cfg.vig = v end)
Toggle(cmc, "🙈 Скрыть интерфейс игры", "hidecore", function()
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	bag("hidecore", function() pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end) end)
end)
Button(cmc, "📸 Скрыть меню на 5 секунд", function()
	Gui.Enabled = false
	task.delay(5, function() if Gui.Parent then Gui.Enabled = true end end)
end)

------------------------------------------------------------------
-- ⚙ ИНТЕРФЕЙС
------------------------------------------------------------------
local Theme = { accent = H("7a5cff"), accent2 = H("ff5ca8") }
local accents = {}
local ApplyTheme = function() end
local uic = newCat("⚙ Интерфейс")
local THEMES = { { "Фиолетовая", "7a5cff", "ff5ca8" }, { "Океан", "2a9aff", "2affd0" }, { "Закат", "ff7a3a", "ff3a8a" }, { "Мята", "2affb0", "2ab0ff" }, { "Сакура", "ff7ab8", "ffc0e0" }, { "Золото", "ffc23a", "ff7a3a" },
	{ "Неон", "00ffd0", "ff00d0" }, { "Кровь", "ff2a3a", "7a0010" }, { "Лёд", "8ae0ff", "ffffff" }, { "Изумруд", "2aff6a", "aaff2a" }, { "Космос", "5a3aff", "00c8ff" }, { "Монохром", "d0d0d0", "808080" } }
Label(uic, "Темы меню")
for _, t in ipairs(THEMES) do
	Button(uic, "🎨 Тема: " .. t[1], function() Theme.accent = H(t[2]); Theme.accent2 = H(t[3]); ApplyTheme() end)
end

------------------------------------------------------------------
-- 🏠 ГЛАВНАЯ (пресеты) - вставляем первой
------------------------------------------------------------------
local hc = { name = "🏠 Главная", items = {} }
table.insert(Cats, 1, hc)
Label(hc, "Быстрые пресеты - включают сразу много эффектов")
local function ResetAll()
	for _, it in ipairs(AllItems) do if it.kind == "toggle" and it.state then setOn(it, false) end end
	restoreLighting(); restoreBody()
	local c = Lighting:FindFirstChild("AuraCC"); if c then c.TintColor = Color3.new(1, 1, 1); c.Saturation = 0; c.Contrast = 0; c.Brightness = 0 end
	RefreshUI()
end
Button(hc, "🚀 Космос: ТОН 618, звёзды, планеты", function() Press("L12"); Press("sky_black"); Press("stars2"); Press("gal1"); Press("pl2"); Press("pl1"); Press("bh1"); Press("big1"); Press("met1"); RefreshUI() end)
Button(hc, "🌸 Сакура: лепестки и розовый закат", function() Press("L10"); Press("w14"); RefreshUI() end)
Button(hc, "❄ Зима: снегопад и мороз", function() Press("L6"); Press("w7"); RefreshUI() end)
Button(hc, "🔥 Ад: лава, огонь, демон", function() Press("L7"); Press("w37"); Press("au1"); Press("tail3"); Press("horn2"); RefreshUI() end)
Button(hc, "🌃 Киберпанк: неоновый дождь", function() Press("L31"); Press("w23"); RefreshUI() end)
Button(hc, "😇 Ангел: крылья, нимб, святая аура", function() Press("wing1"); Press("halo1"); Press("au5"); Press("gr3"); RefreshUI() end)
Button(hc, "😈 Демон: крылья, рога, тёмная аура", function() Press("wing4"); Press("horn2"); Press("au4"); Press("tail3"); RefreshUI() end)
Button(hc, "🧚 Сказочный лес: светлячки", function() Press("L8"); Press("w17"); RefreshUI() end)
Button(hc, "⛔ Выключить всё и сбросить", ResetAll)

------------------------------------------------------------------
-- Системные кнопки (в интерфейс)
------------------------------------------------------------------
local function Unload()
	for _, it in ipairs(AllItems) do if it.state then it.state = false; pcall(it.off) end end
	restoreBody()
	clearAll()
	restoreLighting()
	pcall(function() for k, v in pairs(WOrig) do TR[k] = v end end)
	env.AuraX_Unload = nil
end
env.AuraX_Unload = Unload
Button(uic, "♻ Сбросить всё", ResetAll)
Button(uic, "❌ Выгрузить AuraX полностью", Unload)

------------------------------------------------------------------
-- ИНТЕРФЕЙС МЕНЮ
------------------------------------------------------------------
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local FONT, FONTB = Enum.Font.SourceSans, Enum.Font.SourceSansBold
local TS = isMobile and 16 or 17
local ROWH = isMobile and 36 or 34
local vp = CAM().ViewportSize
local WW = isMobile and math.min(vp.X * 0.88, 620) or 660
local WH = isMobile and math.min(vp.Y * 0.82, 340) or 440
local TABW = isMobile and 104 or 150
local ROWC = Color3.fromRGB(30, 28, 50)

local function corner(o, r) return mk("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function acc(inst, prop, which) table.insert(accents, { inst, prop, which or 1 }); inst[prop] = which == 2 and Theme.accent2 or Theme.accent end

local Win = mk("Frame", { Name = "Win", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(WW, WH), BackgroundColor3 = Color3.fromRGB(14, 12, 26), ClipsDescendants = true, BorderSizePixel = 0 }, Gui)
corner(Win, 14)
local WinScale = mk("UIScale", { Scale = 1 }, Win)
local wst = mk("UIStroke", { Thickness = 2, Transparency = 0.2 }, Win); acc(wst, "Color")

-- Плавающие обои
local Wall = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 0, ClipsDescendants = true }, Win)
local wgrad = mk("UIGradient", { Rotation = 30 }, Wall)
local blobs, stars = {}, {}
for k = 1, 3 do
	local b = mk("Frame", { Size = UDim2.fromOffset(180, 180), BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 0 }, Wall)
	corner(b, 90); acc(b, "BackgroundColor3", k % 2 == 0 and 2 or 1)
	blobs[k] = { b, rnd() * 6, 0.2 + 0.3 * k }
end
for k = 1, 26 do
	local s = rnd(2, 5)
	local f = mk("Frame", { Size = UDim2.fromOffset(s, s), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 0 }, Wall)
	corner(f, 3)
	stars[k] = { f, rnd(), rnd(), 0.02 + rnd() * 0.05, rnd() * 6 }
end
local function themeWall()
	local d = Theme.accent:Lerp(Color3.new(0, 0, 0), 0.8)
	local d2 = Theme.accent2:Lerp(Color3.new(0, 0, 0), 0.85)
	wgrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 10, 24)), ColorSequenceKeypoint.new(0.5, d), ColorSequenceKeypoint.new(1, d2) })
end
ApplyTheme = function()
	for _, a in ipairs(accents) do if a[1].Parent then pcall(function() a[1][a[2]] = a[3] == 2 and Theme.accent2 or Theme.accent end) end end
	themeWall(); RefreshUI()
end
themeWall()
local wallAnim = true
loop("ui", function(dt)
	if not wallAnim or not Win.Visible then return end
	local t = os.clock()
	wgrad.Rotation = (t * 8) % 360
	for _, b in ipairs(blobs) do
		b[1].Position = UDim2.new(0.5 + 0.4 * sin(t * 0.2 * b[3] + b[2]), -90, 0.5 + 0.4 * cos(t * 0.17 * b[3] + b[2]), -90)
	end
	for _, s in ipairs(stars) do
		s[3] = s[3] - s[4] * dt
		if s[3] < -0.02 then s[3] = 1.02; s[2] = rnd() end
		s[1].Position = UDim2.new(s[2] + 0.01 * sin(t + s[5]), 0, s[3], 0)
		s[1].BackgroundTransparency = 0.3 + 0.5 * (0.5 + 0.5 * sin(t * 2 + s[5]))
	end
end)

-- Верхняя панель
local Top = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Color3.fromRGB(10, 8, 20), BackgroundTransparency = 0.35, BorderSizePixel = 0 }, Win)
local Title = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0, 160, 1, 0), Text = "✦ AuraX Visuals", Font = FONTB, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left }, Top)
acc(Title, "TextColor3")
local Info = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(isMobile and 150 or 180, 0), Size = UDim2.new(1, -250, 1, 0), Text = "", Font = FONT, TextSize = 14, TextColor3 = Color3.fromRGB(190, 190, 220), TextXAlignment = Enum.TextXAlignment.Left }, Top)
local function topBtn(txt, xoff)
	local b = mk("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xoff, 0.5, 0), Size = UDim2.fromOffset(30, 26), BackgroundColor3 = ROWC, Text = txt, Font = FONTB, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = true }, Top)
	corner(b, 8); return b
end
local CloseB, MinB = topBtn("✕", -8), topBtn("—", -44)

-- Перетаскивание
local function draggable(handle, target, onClick)
	local dragging, start, startPos, moved
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; moved = 0; start = i.Position; startPos = target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
					if onClick and moved < 8 then onClick() end
				end
			end)
		end
	end)
	bag("ui", UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			moved = math.max(moved, d.Magnitude)
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
end
draggable(Top, Win)

-- Вкладки
local TabList = mk("ScrollingFrame", { Position = UDim2.fromOffset(6, 44), Size = UDim2.new(0, TABW, 1, -50), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, Win)
mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, TabList)
local Content = mk("Frame", { Position = UDim2.fromOffset(TABW + 12, 44), Size = UDim2.new(1, -(TABW + 18), 1, -50), BackgroundTransparency = 1 }, Win)
local Search = mk("TextBox", { Size = UDim2.new(1, -4, 0, 30), BackgroundColor3 = ROWC, BackgroundTransparency = 0.2, Text = "", PlaceholderText = "🔎 Поиск по функциям...", PlaceholderColor3 = Color3.fromRGB(150, 150, 180), TextColor3 = Color3.new(1, 1, 1), Font = FONT, TextSize = TS, ClearTextOnFocus = false, BorderSizePixel = 0 }, Content)
corner(Search, 8)
local Page = mk("ScrollingFrame", { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, -2, 1, -36), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, Content)
acc(Page, "ScrollBarImageColor3")
mk("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, Page)
mk("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }, Page)

local Rows, PageConns, CurCat = {}, {}, 1
local TabBtns = {}
RefreshUI = function() for _, f in ipairs(Rows) do pcall(f) end end

local function clearPage()
	for _, c in ipairs(PageConns) do pcall(c.Disconnect, c) end
	PageConns = {}; Rows = {}
	for _, c in ipairs(Page:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	Page.CanvasPosition = Vector2.new(0, 0)
end
local function renderItems(list)
	clearPage()
	for idx, it in ipairs(list) do
		if it.kind == "label" then
			mk("TextLabel", { Size = UDim2.new(1, -6, 0, 24), BackgroundTransparency = 1, Text = "— " .. it.name .. " —", Font = FONTB, TextSize = 15, TextColor3 = Color3.fromRGB(200, 190, 255), LayoutOrder = idx }, Page)
		elseif it.kind == "toggle" then
			local b = mk("TextButton", { Size = UDim2.new(1, -6, 0, ROWH), BackgroundColor3 = ROWC, BackgroundTransparency = 0.25, AutoButtonColor = false, Text = "", LayoutOrder = idx, BorderSizePixel = 0 }, Page)
			corner(b, 8)
			mk("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -62, 1, 0), Position = UDim2.fromOffset(10, 0), Text = it.name, TextColor3 = Color3.new(1, 1, 1), Font = FONT, TextSize = TS, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, b)
			local sw = mk("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(40, 20), BackgroundColor3 = Color3.fromRGB(60, 60, 85), BorderSizePixel = 0 }, b)
			corner(sw, 10)
			local kn = mk("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, sw)
			corner(kn, 8)
			local function ref()
				local on = it.state
				tw(sw, { BackgroundColor3 = on and Theme.accent or Color3.fromRGB(60, 60, 85) }, 0.15)
				tw(kn, { Position = on and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) }, 0.15)
			end
			Rows[#Rows + 1] = ref; ref()
			b.Activated:Connect(function() setOn(it, not it.state); RefreshUI() end)
		elseif it.kind == "button" then
			local b = mk("TextButton", { Size = UDim2.new(1, -6, 0, ROWH), BackgroundColor3 = ROWC, BackgroundTransparency = 0.25, AutoButtonColor = true, Text = it.name, TextColor3 = Color3.new(1, 1, 1), Font = FONT, TextSize = TS, LayoutOrder = idx, BorderSizePixel = 0, TextTruncate = Enum.TextTruncate.AtEnd }, Page)
			corner(b, 8)
			mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, b); b.TextXAlignment = Enum.TextXAlignment.Left
			b.Activated:Connect(function()
				local ok, e = pcall(it.fn)
				if not ok then warn("[AuraX] " .. it.name .. ": " .. tostring(e)) end
				RefreshUI()
				b.BackgroundColor3 = Theme.accent; tw(b, { BackgroundColor3 = ROWC }, 0.4)
			end)
		elseif it.kind == "slider" then
			local f = mk("Frame", { Size = UDim2.new(1, -6, 0, ROWH + 16), BackgroundColor3 = ROWC, BackgroundTransparency = 0.25, LayoutOrder = idx, BorderSizePixel = 0 }, Page)
			corner(f, 8)
			mk("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -80, 0, 22), Position = UDim2.fromOffset(10, 4), Text = it.name, TextColor3 = Color3.new(1, 1, 1), Font = FONT, TextSize = TS, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, f)
			local vl = mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(70, 22), Position = UDim2.new(1, -10, 0, 4), Font = FONTB, TextSize = TS, TextColor3 = Color3.fromRGB(210, 200, 255), TextXAlignment = Enum.TextXAlignment.Right }, f)
			local track = mk("Frame", { Position = UDim2.new(0, 12, 1, -18), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = Color3.fromRGB(60, 60, 85), BorderSizePixel = 0 }, f)
			corner(track, 3)
			local fill = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0 }, track); corner(fill, 3); acc(fill, "BackgroundColor3")
			local function vis()
				local rel = (it.value - it.min) / (it.max - it.min)
				fill.Size = UDim2.new(math.clamp(rel, 0, 1), 0, 1, 0)
				vl.Text = (it.step >= 1 and tostring(math.floor(it.value + 0.5))) or string.format("%.2f", it.value)
			end
			vis()
			local hit = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, -30), BackgroundTransparency = 1, Text = "" }, f)
			local dragging = false
			local function setX(x)
				local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
				local v = it.min + (it.max - it.min) * rel
				if it.step > 0 then v = math.floor(v / it.step + 0.5) * it.step end
				it.value = v; vis(); pcall(it.fn, v)
			end
			hit.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = true; Page.ScrollingEnabled = false; setX(i.Position.X)
					i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false; Page.ScrollingEnabled = true end end)
				end
			end)
			PageConns[#PageConns + 1] = UIS.InputChanged:Connect(function(i)
				if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setX(i.Position.X) end
			end)
		end
	end
end
local function renderCat() renderItems(Cats[CurCat].items) end
local function doSearch(q)
	q = ulower(q)
	local res = {}
	for _, c in ipairs(Cats) do
		for _, it in ipairs(c.items) do
			if it.kind ~= "label" and string.find(it.lname, q, 1, true) then
				res[#res + 1] = it
				if #res >= 120 then break end
			end
		end
	end
	renderItems(res)
end
Search:GetPropertyChangedSignal("Text"):Connect(function()
	if Search.Text == "" then renderCat() else doSearch(Search.Text) end
end)
local function styleTabs()
	for i, b in ipairs(TabBtns) do
		b.BackgroundColor3 = i == CurCat and Theme.accent or ROWC
		b.BackgroundTransparency = i == CurCat and 0.15 or 0.35
	end
end
local oldRefresh = RefreshUI
RefreshUI = function() oldRefresh(); styleTabs() end
local function selectCat(i)
	CurCat = i; styleTabs()
	if Search.Text ~= "" then Search.Text = "" else renderCat() end
end
for i, c in ipairs(Cats) do
	local b = mk("TextButton", { Size = UDim2.new(1, -4, 0, ROWH), BackgroundColor3 = ROWC, BackgroundTransparency = 0.35, Text = c.name, TextColor3 = Color3.new(1, 1, 1), Font = FONTB, TextSize = isMobile and 14 or 16, AutoButtonColor = false, LayoutOrder = i, BorderSizePixel = 0, TextTruncate = Enum.TextTruncate.AtEnd }, TabList)
	corner(b, 8)
	b.Activated:Connect(function() selectCat(i) end)
	TabBtns[i] = b
end
Info.Text = "Функций: " .. #AllItems
selectCat(1)

-- Плавающая кнопка и открытие/закрытие
local Float = mk("TextButton", { Size = UDim2.fromOffset(isMobile and 50 or 54, isMobile and 50 or 54), Position = UDim2.new(0, 14, 0.4, 0), Text = "AX", Font = FONTB, TextSize = 20, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(20, 16, 40), AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 5 }, Gui)
corner(Float, 27)
local fst = mk("UIStroke", { Thickness = 2.5 }, Float); acc(fst, "Color")
local function openMenu(open)
	if open then
		Win.Visible = true; WinScale.Scale = 0.85 * Cfg.uiScale; tw(WinScale, { Scale = Cfg.uiScale }, 0.2)
	else
		tw(WinScale, { Scale = 0.85 * Cfg.uiScale }, 0.15)
		task.delay(0.15, function() if Win.Parent and WinScale.Scale < Cfg.uiScale * 0.9 then Win.Visible = false end end)
	end
end
Cfg.uiScale = 1
local function toggleMenu() openMenu(not Win.Visible or WinScale.Scale < Cfg.uiScale * 0.9) end
draggable(Float, Float, toggleMenu)
CloseB.Activated:Connect(function() openMenu(false) end)
MinB.Activated:Connect(function() openMenu(false) end)
bag("ui", UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end))
loop("ui", function() fst.Transparency = 0.2 + 0.3 * (0.5 + 0.5 * sin(os.clock() * 2)) end)

-- Настройки интерфейса (добавляем в категорию)
Slider(uic, "Масштаб меню", 0.6, 1.4, 1, function(v) Cfg.uiScale = v; WinScale.Scale = v end)
Slider(uic, "Прозрачность обоев", 0, 1, 0, function(v) Wall.BackgroundTransparency = v end)
Toggle(uic, "🌌 Анимированные обои", "wallanim", function() wallAnim = true end, function() wallAnim = false end)
Toggle(uic, "📊 Показать FPS", "fps", function()
	local n, acc2 = 0, 0
	loop("fps", function(dt)
		n = n + 1; acc2 = acc2 + dt
		if acc2 >= 0.5 then Info.Text = "Функций: " .. #AllItems .. "  |  FPS: " .. math.floor(n / acc2); n = 0; acc2 = 0 end
	end)
	bag("fps", function() Info.Text = "Функций: " .. #AllItems end)
end)
Button(uic, "📍 Центрировать окно", function() Win.Position = UDim2.new(0.5, 0, 0.5, 0) end)
Button(uic, "📍 Вернуть кнопку AX", function() Float.Position = UDim2.new(0, 14, 0.4, 0) end)
Info.Text = "Функций: " .. #AllItems

-- Повторное применение при респавне
bag("sys", LP.CharacterAdded:Connect(function()
	task.wait(1.2)
	for _, it in ipairs(AllItems) do
		if it.char and it.state then pcall(it.off); pcall(it.on) end
	end
end))

openMenu(true)
warn("[AuraX Visuals] Загружено. Функций: " .. #AllItems .. ". Кнопка AX / RightShift - меню.")
