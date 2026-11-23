-- InstanceETA: holder styr paa dine instances. Hvor mange du har vaeret i denne time og i dag,
-- hvornaar den naeste er fri, og en log over hver run med tid, XP, guld og kills.
-- Samme stil som LevelETA, GoldETA, LayerETA, TrackETA og CraftETA.
--
-- Saadan virker det:
--  * Gaar du ind i en dungeon eller raid, starter en ny run. Gaar du ud, slutter den, og du faar en kort opsummering.
--  * Er det den samme instance som sidst (fx efter et doedsfald eller en tur ud for at saelge), laegges de to sammen.
--    Det ser vi paa mobbenes GUID: alle mobs i en instance deler et zone-id, og det skifter, naar instancen nulstilles.
--  * Forever skjuler nogle vaerdier for addons ("secret values"). Dem roerer vi ikke, og combat-loggen bruges ikke.
--    Kills taelles derfor ud fra XP-beskederne ("X dies, you gain N experience").
local ADDON = "InstanceETA"
local NAME = "InstanceETA"
local PATH = "Interface\\AddOns\\InstanceETA\\"
local TEX = PATH .. "Textures\\"
local LOGO = TEX .. "Logo"
local F_SEMI = PATH .. "Fonts\\Inter-SemiBold.ttf"
local F_BOLD = PATH .. "Fonts\\Inter-Bold.ttf"

local HOUR, DAY = 3600, 86400
local MAX_RUNS = 300     -- saa mange runs gemmes i alt
local MAX_TRADES = 200
local DB

-- ---------- sprog ----------
local LOC = {
  en = {
    hm = "%dh %02dm", dh = "%dd %dh",
    thisHour = "This hour", today = "Last 24 hours", nextFree = "Next instance", freeNow = "Free now",
    noLimit = "no limit", inside = "Inside", recent = "Recent runs", noRuns = "No runs yet. Enter a dungeon.",
    xp = "XP", gold = "Gold", kills = "Kills", time = "Time", perHr = "/h", ago = "%s ago", stillIn = "inside now",
    log = "Log", logTitle = "Instance log", thisChar = "This character", allChars = "All characters",
    colInst = "Instance", colWhen = "Entered", colTime = "Time", colXP = "XP", colGold = "Gold", colKills = "Kills", colLock = "Lockout",
    logHint = "Hover a run for details  ·  Shift right-click to delete it", logEmpty = "No runs in the log yet.",
    entered = "Entered", left = "Left", levels = "Level", group = "Group", rep = "Reputation", trades = "Gold traded",
    xpHr = "XP per hour", perKill = "XP per kill", runsLevel = "Runs to next level", avgLevel = "Average group level",
    merged = "Same instance as your last run, merged.", hourLeft = "counts this hour for %s", dayLeft = "counts today for %s",
    newRun = "New instance: %s.  %s this hour, %s today.", raidRun = "New raid: %s (raids do not count to the hourly limit).",
    undoHint = "Not a new instance? Type /ieta undo", undone = "Removed your last run (%s).", nothingUndo = "No run to remove.",
    deleted = "Deleted %s.", runDone = "%s done: %s", locked = "You are at the limit", lockedSub = "Next instance %s",
    lastOne = "Last instance this hour", lastOneSub = "%s of %s used", freeToast = "A new instance is free",
    freeToastSub = "%s of %s used this hour", resetSeen = "%s has been reset.",
    gave = "Gave %s to %s", got = "Received %s from %s",
    raidLocks = "Raid lockouts", resetsIn = "resets in %s", alts = "Your characters",
    settings = "InstanceETA settings", sWindow = "Window", sChat = "Chat", sLimit = "Lockout",
    showWin = "Show window", lockWin = "Lock window", minimap = "Minimap button", language = "Language",
    recentN = "Recent runs in window", enterMsg = "Message when you enter", leaveMsg = "Stats when you leave",
    groupMsg = "Post stats to party", tradeMsg = "Gold traded in chat", freeMsg = "Tell me when one is free",
    countRaids = "Raids count to the limit", accountWide = "Count all characters", hourLimit = "Instances per hour",
    dayLimit = "Instances per 24 hours", off = "Off",
    tipLeft = "Left-click: show or hide", tipRight = "Right-click: settings", tipShift = "Shift-click: log",
    help = "/ieta: window  ·  /ieta log  ·  /ieta config  ·  /ieta undo  ·  /ieta trades  ·  /ieta reset  ·  /ieta da|en",
    tradesHead = "InstanceETA gold trades, newest first", noTrades = "No gold trades yet.",
    posReset = "Windows moved back to the middle.", runWord = "run", runsWord = "runs",
    statsLine = "%s in %s: %s XP, %s, %d kills",
  },
  da = {
    hm = "%dt %02dm", dh = "%dd %dt",
    thisHour = "Denne time", today = "Sidste 24 timer", nextFree = "Næste instance", freeNow = "Fri nu",
    noLimit = "ingen grænse", inside = "Inde i", recent = "Seneste runs", noRuns = "Ingen runs endnu. Gå ind i en dungeon.",
    xp = "XP", gold = "Guld", kills = "Kills", time = "Tid", perHr = "/t", ago = "%s siden", stillIn = "inde nu",
    log = "Log", logTitle = "Instance log", thisChar = "Denne karakter", allChars = "Alle karakterer",
    colInst = "Instance", colWhen = "Gik ind", colTime = "Tid", colXP = "XP", colGold = "Guld", colKills = "Kills", colLock = "Lockout",
    logHint = "Hold musen over en run for detaljer  ·  Shift højreklik for at slette",  logEmpty = "Ingen runs i loggen endnu.",
    entered = "Gik ind", left = "Gik ud", levels = "Level", group = "Gruppe", rep = "Omdømme", trades = "Guld handlet",
    xpHr = "XP i timen", perKill = "XP pr. kill", runsLevel = "Runs til næste level", avgLevel = "Gruppens gns. level",
    merged = "Samme instance som sidst, lagt sammen.", hourLeft = "tæller i denne time i %s", dayLeft = "tæller i dag i %s",
    newRun = "Ny instance: %s.  %s denne time, %s i dag.", raidRun = "Ny raid: %s (raids tæller ikke med i timegrænsen).",
    undoHint = "Ikke en ny instance? Skriv /ieta undo", undone = "Fjernede din sidste run (%s).", nothingUndo = "Ingen run at fjerne.",
    deleted = "Slettede %s.", runDone = "%s færdig: %s", locked = "Du har nået grænsen", lockedSub = "Næste instance %s",
    lastOne = "Sidste instance i denne time", lastOneSub = "%s af %s brugt", freeToast = "En ny instance er fri",
    freeToastSub = "%s af %s brugt i denne time", resetSeen = "%s er nulstillet.",
    gave = "Gav %s til %s", got = "Fik %s fra %s",
    raidLocks = "Raid lockouts", resetsIn = "nulstilles om %s", alts = "Dine karakterer",
    settings = "InstanceETA indstillinger", sWindow = "Vindue", sChat = "Chat", sLimit = "Lockout",
    showWin = "Vis vindue", lockWin = "Lås vindue", minimap = "Minimap knap", language = "Sprog",
    recentN = "Seneste runs i vinduet", enterMsg = "Besked når du går ind", leaveMsg = "Opsummering når du går ud",
    groupMsg = "Send opsummering til party", tradeMsg = "Handlet guld i chatten", freeMsg = "Sig til når en er fri",
    countRaids = "Raids tæller med", accountWide = "Tæl alle karakterer", hourLimit = "Instances pr. time",
    dayLimit = "Instances pr. 24 timer", off = "Fra",
    tipLeft = "Venstreklik: vis eller skjul", tipRight = "Højreklik: indstillinger", tipShift = "Shift klik: log",
    help = "/ieta: vindue  ·  /ieta log  ·  /ieta config  ·  /ieta undo  ·  /ieta trades  ·  /ieta reset  ·  /ieta da|en",
    tradesHead = "InstanceETA guld handler, nyeste først", noTrades = "Ingen guld handler endnu.",
    posReset = "Vinduerne er flyttet tilbage til midten.", runWord = "run", runsWord = "runs",
    statsLine = "%s på %s: %s XP, %s, %d kills",
  },
}
local function T(k) return (LOC[(DB and DB.lang) or "en"] or LOC.en)[k] or LOC.en[k] or k end
local labels = {}
local function label(f, key) labels[#labels + 1] = {f, key}; f:SetText(T(key)) end
local function updateLabels() for _, x in ipairs(labels) do x[1]:SetText(T(x[2])) end end

-- GAET: Forever har en graense paa 5 instances i timen og ingen graense pr. doegn. Begge kan aendres i indstillingerne.
local defaults = {
  lang = "en", hidden = false, locked = false, showMinimap = true, mmAngle = 200, recentN = 5,
  enterMsg = true, leaveMsg = true, groupMsg = false, tradeMsg = true, freeMsg = true,
  countRaids = false, accountWide = false, hourLimit = 5, dayLimit = 0,
}

-- ---------- smaa hjaelpere ----------
local function secret(v) return type(issecretvalue) == "function" and issecretvalue(v) or false end
local function now() return time() end
local function clock() return (GetTime and GetTime()) or 0 end

local GI = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SI = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local CI = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
local function money(c, plain)
  c = math.floor((c or 0) + 0.5)
  local g, s, k = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  local gi, si, ci = GI, SI, CI
  if plain then gi, si, ci = "g", "s", "c" end
  if g > 0 then return g .. gi .. (s > 0 and (" " .. s .. si) or "") end
  if s > 0 then return s .. si .. (k > 0 and (" " .. k .. ci) or "") end
  return k .. ci
end

local function num(n)  -- 8100 -> "8,100" (en) eller "8.100" (da)
  n = math.floor((n or 0) + 0.5)
  local s = tostring(math.abs(n))
  local sep = (DB and DB.lang == "da") and "." or ","
  s = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse():gsub("^%" .. sep, "")
  return (n < 0 and "-" or "") .. s
end

local function dur(sec)
  sec = math.floor((sec or 0) + 0.5)
  if sec < 60 then return sec .. "s" end
  local m = math.floor(sec / 60)
  if m < 60 then return m .. "m" end
  local h = math.floor(m / 60)
  if h < 24 then return string.format(T("hm"), h, m % 60) end
  return string.format(T("dh"), math.floor(h / 24), h % 24)
end

local function stopwatch(sec)
  sec = math.floor(sec or 0)
  local h, m, s = math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%02d:%02d", m, s)
end

local function hhmm(t) return date("%H:%M", math.floor(t)) end

local function charKey()
  local n = UnitName and UnitName("player") or "?"
  local r = GetRealmName and GetRealmName() or "?"
  return n .. "-" .. r
end

-- moenstre ud fra spillets egne tekster, saa det virker paa alle sprog
local function makePat(g, anchored)
  if type(g) ~= "string" then return nil end
  local p = g:gsub("%%%d?%$?s", "\1"):gsub("%%%d?%$?d", "\2")
  p = p:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  p = p:gsub("\1", "(.+)"):gsub("\2", "(%%d+)")
  return anchored == false and p or ("^" .. p .. "$")
end

-- ---------- data ----------
local cur            -- den run du er i lige nu (en tabel i DB.runs)
local seenZone = {}  -- zone-id'er vi har set i den nuvaerende instance

local function newId() DB.nextId = (DB.nextId or 0) + 1; return DB.nextId end

local function charRuns(all)
  local me, list = charKey(), {}
  for _, r in ipairs(DB.runs) do
    if all or r.char == me then list[#list + 1] = r end
  end
  return list
end

local function counts(r)
  if r.kind == "party" then return true end
  if r.kind == "raid" then return DB.countRaids end
  return false
end

-- hvor mange instances i den sidste time og det sidste doegn, og hvornaar den naeste er fri
local function lockout()
  local t, me = now(), charKey()
  local hour, day = {}, {}
  for _, r in ipairs(DB.runs) do
    if counts(r) and (DB.accountWide or r.char == me) then
      local age = t - r.enter
      if age < HOUR then hour[#hour + 1] = r.enter end
      if age < DAY then day[#day + 1] = r.enter end
    end
  end
  table.sort(hour); table.sort(day)
  local nextAt
  local hl, dl = DB.hourLimit or 5, DB.dayLimit or 0
  if hl > 0 and #hour >= hl then nextAt = hour[#hour - hl + 1] + HOUR end
  if dl > 0 and #day >= dl then
    local d = day[#day - dl + 1] + DAY
    if not nextAt or d > nextAt then nextAt = d end
  end
  return #hour, #day, nextAt
end

-- hvor laenge en run stadig taeller med i graensen
local function lockLeft(r)
  if not counts(r) then return nil end
  local age = now() - r.enter
  if age < HOUR then return HOUR - age, "h" end
  if (DB.dayLimit or 0) > 0 and age < DAY then return DAY - age, "d" end
end

local function runTime(r) return r.t or 0 end
local function xpRate(r) local t = runTime(r); return t >= 60 and (r.xp or 0) / t * 3600 or nil end

local function groupAvg(r)
  if not r.group then return nil end
  local sum, n = 0, 0
  for _, g in pairs(r.group) do if g.lvl and g.lvl > 0 then sum = sum + g.lvl; n = n + 1 end end
  if r.lvlIn then sum = sum + r.lvlIn; n = n + 1 end
  return n > 0 and sum / n or nil
end

local function runsToLevel(r)
  local x = r.xp or 0
  if x <= 0 or not UnitXP then return nil end
  local need = (UnitXPMax("player") or 0) - (UnitXP("player") or 0)
  if need <= 0 then return nil end
  return math.ceil(need / x)
end

local function removeRun(r)
  for i, x in ipairs(DB.runs) do
    if x == r then table.remove(DB.runs, i); return true end
  end
end

-- ---------- byggeklodser (som i de andre ETA addons) ----------
local function fs(parent, font, size)
  local t = parent:CreateFontString(nil, "OVERLAY")
  t:SetFont(font, size, "")
  t:SetShadowOffset(0, 0)
  if t.SetWordWrap then t:SetWordWrap(false) end
  return t
end

local function skin(frame, prefix, texW, canvasW)
  local function part(name)
    local t = frame:CreateTexture(nil, "BACKGROUND")
    t:SetTexture(TEX .. prefix .. name); t:SetTexCoord(0, texW / canvasW, 0, 40 / 64)
    return t
  end
  local top = part("Top"); top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(20)
  local bot = part("Bottom"); bot:SetPoint("BOTTOMLEFT"); bot:SetPoint("BOTTOMRIGHT"); bot:SetHeight(20)
  local mid = part("Mid"); mid:SetPoint("TOPLEFT", top, "BOTTOMLEFT"); mid:SetPoint("BOTTOMRIGHT", bot, "TOPRIGHT")
end

local function header(frame, titleText)
  local title = fs(frame, F_BOLD, 15)
  title:SetPoint("LEFT", frame, "TOPLEFT", 14, -20)
  if titleText then title:SetText(titleText) end
  local line = frame:CreateTexture(nil, "ARTWORK")
  line:SetSize(22, 2); line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
  line:SetColorTexture(1, 0.8, 0.35, 0.9)
  return title
end

local function movable(frame, canMove, onStop)
  frame:SetMovable(true); frame:EnableMouse(true); frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) if canMove() then self:StartMoving() end end)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); if onStop then onStop(self) end end)
end

local function pill(parent, text, w, h)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h or 24)
  local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetTexture(TEX .. "Pill"); bg:SetTexCoord(0, 240 / 256, 0, 48 / 64)
  b.bg = bg
  b.text = fs(b, F_SEMI, (h and h < 22) and 11 or 12); b.text:SetPoint("CENTER"); b.text:SetTextColor(0.85, 0.87, 0.92)
  if text then b.text:SetText(text) end
  b.r, b.g, b.b = 0.85, 0.87, 0.92
  b.paint = function(self, r, g, bl) self.r, self.g, self.b = r, g, bl; self.text:SetTextColor(r, g, bl) end
  b:SetScript("OnEnter", function() b.text:SetTextColor(1, 0.82, 0.4) end)
  b:SetScript("OnLeave", function() b.text:SetTextColor(b.r, b.g, b.b) end)
  return b
end

local function closeButton(parent, onClick)
  local x = CreateFrame("Button", nil, parent)
  x:SetSize(20, 20); x:SetPoint("TOPRIGHT", -10, -10)
  local t = fs(x, F_BOLD, 16); t:SetPoint("CENTER"); t:SetText("×"); t:SetTextColor(0.55, 0.58, 0.64)
  x:SetScript("OnEnter", function() t:SetTextColor(1, 1, 1) end)
  x:SetScript("OnLeave", function() t:SetTextColor(0.55, 0.58, 0.64) end)
  x:SetScript("OnClick", onClick)
  return x
end

local GREY, WHITE, BLUE, GOLD, ORANGE, RED, GREEN, HEADC =
  {0.55, 0.58, 0.64}, {0.91, 0.92, 0.94}, {0.62, 0.82, 1}, {1, 0.82, 0.29}, {1, 0.6, 0.35}, {1, 0.38, 0.35}, {0.36, 1, 0.48}, {1, 0.82, 0.4}
local function col(fsObj, c) fsObj:SetTextColor(c[1], c[2], c[3]) end
local function hex(c) return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255) end

local function say(msg) print("|cffffd24aInstanceETA|r " .. msg) end

-- ---------- toast (som i de andre ETA addons) ----------
local toast = CreateFrame("Button", "InstanceETAToast", UIParent)
toast:SetSize(280, 48); toast:SetPoint("TOP", UIParent, "TOP", 0, -150); toast:SetFrameStrata("HIGH"); toast:Hide()
skin(toast, "Panel", 520, 1024)
do
  local icon = toast:CreateTexture(nil, "ARTWORK"); icon:SetSize(26, 26); icon:SetPoint("LEFT", 12, 0); icon:SetTexture(LOGO)
  local title = fs(toast, F_BOLD, 13); title:SetPoint("TOPLEFT", 48, -9); title:SetTextColor(1, 0.82, 0.29)
  local sub = fs(toast, F_SEMI, 11); sub:SetPoint("TOPLEFT", 48, -27); sub:SetTextColor(0.75, 0.78, 0.84)
  local t = 0
  toast:SetScript("OnClick", function() toast:Hide() end)
  toast:SetScript("OnUpdate", function(self, dt)
    t = t + dt
    self:SetAlpha(t < 0.25 and t / 0.25 or (t > 7 and math.max(0, 1 - (t - 7)) or 1))
    if t > 8 then self:Hide() end
  end)
  toast.show = function(head, text)
    title:SetText(head); sub:SetText(text or "")
    local w = math.max(title:GetStringWidth() or 0, sub:GetStringWidth() or 0) + 64
    toast:SetWidth(math.max(240, math.min(420, w)))
    t = 0; toast:SetAlpha(0); toast:Show()
    if PlaySound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.TELL_MESSAGE) or 3081) end
  end
end

-- ---------- tooltip med alle detaljer om en run ----------
local function runTip(owner, r, anchor)
  GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
  GameTooltip:AddLine(r.name or "?", 1, 0.82, 0.3)
  if r.char ~= charKey() then GameTooltip:AddLine(r.char, 0.62, 0.82, 1) end
  local function line(a, b, c) GameTooltip:AddDoubleLine(a, b, 0.75, 0.78, 0.84, (c or WHITE)[1], (c or WHITE)[2], (c or WHITE)[3]) end
  line(T("entered"), date("%d/%m %H:%M", r.enter) .. "  (" .. string.format(T("ago"), dur(now() - r.enter)) .. ")")
  if r.leave then line(T("left"), date("%H:%M", r.leave)) else line(T("left"), T("stillIn"), GREEN) end
  line(T("time"), dur(runTime(r)))
  if r.lvlIn then line(T("levels"), r.lvlIn .. ((r.lvlOut and r.lvlOut ~= r.lvlIn) and (" > " .. r.lvlOut) or "")) end
  line(T("xp"), num(r.xp), BLUE)
  local xr = xpRate(r)
  if xr then line(T("xpHr"), num(xr), BLUE) end
  if (r.kills or 0) > 0 then
    line(T("kills"), tostring(r.kills))
    if (r.xp or 0) > 0 then line(T("perKill"), num((r.xp or 0) / r.kills)) end
  end
  if r.char == charKey() then
    local n = runsToLevel(r)
    if n then line(T("runsLevel"), tostring(n), GOLD) end
  end
  line(T("gold"), money(r.money), GOLD)
  local ga = groupAvg(r)
  if ga then line(T("avgLevel"), string.format("%.1f", ga)) end
  if r.rep and next(r.rep) then
    GameTooltip:AddLine(" "); GameTooltip:AddLine(T("rep"), 1, 0.82, 0.4)
    for fac, v in pairs(r.rep) do line(fac, (v >= 0 and "+" or "") .. num(v), v >= 0 and GREEN or RED) end
  end
  if r.group and next(r.group) then
    GameTooltip:AddLine(" "); GameTooltip:AddLine(T("group"), 1, 0.82, 0.4)
    for n, g in pairs(r.group) do
      local cc = RAID_CLASS_COLORS and g.class and RAID_CLASS_COLORS[g.class]
      GameTooltip:AddDoubleLine(n, g.lvl and tostring(g.lvl) or "", cc and cc.r or 0.85, cc and cc.g or 0.85, cc and cc.b or 0.85, 0.55, 0.58, 0.64)
    end
  end
  if r.trades and #r.trades > 0 then
    GameTooltip:AddLine(" "); GameTooltip:AddLine(T("trades"), 1, 0.82, 0.4)
    for _, x in ipairs(r.trades) do
      if (x.give or 0) > 0 then GameTooltip:AddLine(string.format(T("gave"), money(x.give), x.who), 1, 0.6, 0.35) end
      if (x.get or 0) > 0 then GameTooltip:AddLine(string.format(T("got"), money(x.get), x.who), 0.36, 1, 0.48) end
    end
  end
  local left, kind = lockLeft(r)
  if left then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(string.format(T(kind == "h" and "hourLeft" or "dayLeft"), dur(left)), 1, 0.6, 0.35)
  end
  GameTooltip:Show()
end

-- ---------- hovedvindue ----------
local W = 260
local IW = W - 28
local f = CreateFrame("Frame", "InstanceETAFrame", UIParent)
f:SetSize(W, 120)
skin(f, "Panel", 520, 1024)
if f.SetToplevel then f:SetToplevel(true) end
local function pinTop()
  local l, t = f:GetLeft(), f:GetTop()
  if not (l and t) then return end
  f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
  DB.point = {l, t}
end
movable(f, function() return not DB.locked end, pinTop)
header(f, "|cffffffffInstance|r|cffffd24aETA|r")

local logBtn = pill(f, nil, 52, 20)
logBtn:SetPoint("TOPRIGHT", -12, -10); label(logBtn.text, "log")

local rowPool, rowN = {}, 0
local function getRow()
  rowN = rowN + 1
  local c = rowPool[rowN]
  if c then return c end
  c = CreateFrame("Frame", nil, f)
  -- raekkerne kan holdes musen over (tooltip), men vinduet kan stadig traekkes i dem
  c:RegisterForDrag("LeftButton")
  c:SetScript("OnDragStart", function() if not DB.locked then f:StartMoving() end end)
  c:SetScript("OnDragStop", function() f:StopMovingOrSizing(); pinTop() end)
  c:SetScript("OnEnter", function(self) if self.run then runTip(self, self.run) end end)
  c:SetScript("OnLeave", function() GameTooltip:Hide() end)
  c.line = c:CreateTexture(nil, "ARTWORK")
  c.line:SetPoint("BOTTOMLEFT"); c.line:SetPoint("BOTTOMRIGHT"); c.line:SetHeight(1)
  c.line:SetColorTexture(1, 1, 1, 0.06)
  c.track = c:CreateTexture(nil, "ARTWORK"); c.track:SetHeight(3); c.track:SetColorTexture(1, 1, 1, 0.08)
  c.track:SetPoint("BOTTOMLEFT", 0, 1); c.track:SetPoint("BOTTOMRIGHT", 0, 1)
  c.fill = c:CreateTexture(nil, "OVERLAY"); c.fill:SetHeight(3); c.fill:SetPoint("LEFT", c.track, "LEFT")
  c.value = fs(c, F_BOLD, 13); c.value:SetJustifyH("RIGHT")
  c.title = fs(c, F_SEMI, 12); c.title:SetJustifyH("LEFT")
  c.dot = c:CreateTexture(nil, "ARTWORK"); c.dot:SetSize(7, 7); c.dot:SetTexture(TEX .. "Dot")
  rowPool[rowN] = c
  return c
end

-- kind: "main" (stor raekke, evt. med bjaelke), "small", "head", "run" (prik, navn og tid), "info" (graa tekst)
local function row(y, o)
  local c = getRow()
  local kind = o.kind
  c.title:ClearAllPoints(); c.value:ClearAllPoints()
  c.dot:Hide(); c.line:Hide(); c.track:Hide(); c.fill:Hide(); c.value:Show()
  c.run = o.run; c:EnableMouse(o.run ~= nil)
  local h
  if kind == "main" then
    c.title:SetFont(F_SEMI, 12); c.value:SetFont(F_BOLD, 13)
    c.value:SetPoint("RIGHT", 0, 2); c.title:SetPoint("LEFT", 0, 2); c.title:SetPoint("RIGHT", c.value, "LEFT", -8, 0)
    local bar = type(o.frac) == "number"
    c.track:SetShown(bar); c.fill:SetShown(bar)
    if bar then
      local fc = o.fc or BLUE
      c.fill:SetColorTexture(fc[1], fc[2], fc[3], 0.9)
      c.fill:SetWidth(IW * math.max(0.02, math.min(1, o.frac)))
    end
    c.line:SetShown(not bar)
    h = bar and 28 or 24
  elseif kind == "small" then
    c.title:SetFont(F_SEMI, 11); c.value:SetFont(F_BOLD, 12)
    c.value:SetPoint("RIGHT"); c.title:SetPoint("LEFT"); c.title:SetPoint("RIGHT", c.value, "LEFT", -8, 0)
    h = 17
  elseif kind == "head" then
    c.title:SetFont(F_BOLD, 11); c.value:SetFont(F_BOLD, 12)
    c.title:SetPoint("LEFT"); c.value:SetPoint("RIGHT")
    h = 22
  elseif kind == "run" then
    c.title:SetFont(F_SEMI, 11); c.value:SetFont(F_BOLD, 11)
    c.dot:Show(); c.dot:ClearAllPoints(); c.dot:SetPoint("LEFT", 1, 0)
    local dc = o.dotc or GREY; c.dot:SetVertexColor(dc[1], dc[2], dc[3])
    c.value:SetPoint("RIGHT"); c.title:SetPoint("LEFT", 13, 0); c.title:SetPoint("RIGHT", c.value, "LEFT", -8, 0)
    h = 18
  else -- info
    c.title:SetFont(F_SEMI, 11); c.value:Hide()
    c.title:SetPoint("LEFT"); c.title:SetPoint("RIGHT")
    h = 18
  end
  c.title:SetText(o.title or ""); c.value:SetText(o.value or "")
  col(c.title, o.tc or (kind == "head" and HEADC or GREY))
  col(c.value, o.vc or WHITE)
  c:SetHeight(h); c:ClearAllPoints()
  c:SetPoint("TOPLEFT", 14, y); c:SetPoint("TOPRIGHT", -14, y)
  c:Show()
  return y - h
end

local function limitColor(n, lim)
  if lim <= 0 then return BLUE end
  if n >= lim then return RED end
  if n >= lim - 1 then return ORANGE end
  return BLUE
end

local function nextFreeText(nextAt)
  if not nextAt or nextAt <= now() then return T("freeNow"), GREEN end
  return hhmm(nextAt) .. "  ·  " .. dur(nextAt - now()), ORANGE
end

local function refresh()
  if not DB or not f:IsShown() then return end
  rowN = 0
  local y = -44
  local hN, dN, nextAt = lockout()
  local hl, dl = DB.hourLimit or 5, DB.dayLimit or 0
  y = row(y, {kind = "main", title = T("thisHour"), value = hl > 0 and (hN .. " / " .. hl) or tostring(hN),
    vc = limitColor(hN, hl), frac = hl > 0 and hN / hl or nil, fc = limitColor(hN, hl)})
  y = row(y, {kind = "main", title = T("today"), value = dl > 0 and (dN .. " / " .. dl) or (dN .. "  ·  " .. T("noLimit")),
    vc = dl > 0 and limitColor(dN, dl) or WHITE, frac = dl > 0 and dN / dl or nil, fc = limitColor(dN, dl)})
  local nt, nc = nextFreeText(nextAt)
  y = row(y, {kind = "main", title = T("nextFree"), value = nt, vc = nc})

  if cur then
    y = y - 6
    y = row(y, {kind = "head", title = T("inside") .. " " .. (cur.name or "?"), value = stopwatch(runTime(cur)), vc = WHITE, run = cur})
    local xr = xpRate(cur)
    y = row(y, {kind = "small", title = T("xp"), value = num(cur.xp) .. (xr and ("  ·  " .. num(xr) .. T("perHr")) or ""), vc = BLUE})
    y = row(y, {kind = "small", title = T("gold"), value = money(cur.money), vc = GOLD})
    y = row(y, {kind = "small", title = T("kills"), value = tostring(cur.kills or 0)})
  end

  if (DB.recentN or 0) > 0 then
    y = y - 6
    y = row(y, {kind = "head", title = T("recent")})
    local shown = 0
    for _, r in ipairs(DB.runs) do
      if r ~= cur and (DB.accountWide or r.char == charKey()) then
        local left, kind = lockLeft(r)
        local dc = left and (kind == "h" and ORANGE or BLUE) or GREY
        local who = (r.char ~= charKey()) and ("|cff8c94a3" .. (r.char:match("^[^-]+") or "") .. "|r  ") or ""
        y = row(y, {kind = "run", run = r, dotc = dc,
          title = who .. (r.name or "?") .. "  |cff6b7280" .. string.format(T("ago"), dur(now() - r.enter)) .. "|r",
          value = dur(runTime(r)), vc = WHITE, tc = {0.85, 0.87, 0.92}})
        shown = shown + 1
        if shown >= DB.recentN then break end
      end
    end
    if shown == 0 then y = row(y, {kind = "info", title = T("noRuns")}) end
  end
  for i = rowN + 1, #rowPool do rowPool[i]:Hide() end
  f:SetHeight(-y + 14)
end

-- ---------- log vindue ----------
local L = CreateFrame("Frame", "InstanceETALog", UIParent)
local LW, LH, ROWS = 560, 470, 16
L:SetSize(LW, LH); L:SetPoint("CENTER"); L:SetFrameStrata("DIALOG"); L:Hide()
skin(L, "Wide", 1040, 2048)
movable(L, function() return true end)
tinsert(UISpecialFrames, "InstanceETALog")
label(header(L), "logTitle")
closeButton(L, function() L:Hide() end)

local logAll = false
local logOffset = 0
local tabB = pill(L, nil, 120, 20); tabB:SetPoint("TOPRIGHT", -40, -10); label(tabB.text, "allChars")
local tabA = pill(L, nil, 120, 20); tabA:SetPoint("RIGHT", tabB, "LEFT", -6, 0); label(tabA.text, "thisChar")

local COLS = { {"colInst", 18, 150, "LEFT"}, {"colWhen", 172, 70, "RIGHT"}, {"colTime", 246, 58, "RIGHT"}, {"colXP", 308, 62, "RIGHT"},
  {"colGold", 374, 76, "RIGHT"}, {"colKills", 454, 36, "RIGHT"}, {"colLock", 494, 50, "RIGHT"} }
for _, c in ipairs(COLS) do
  local t = fs(L, F_BOLD, 10); t:SetPoint("TOPLEFT", c[2], -50); t:SetWidth(c[3]); t:SetJustifyH(c[4]); t:SetTextColor(1, 0.82, 0.4)
  label(t, c[1])
end
local logRows = {}
for i = 1, ROWS do
  local b = CreateFrame("Button", nil, L)
  b:SetSize(LW - 28, 22); b:SetPoint("TOPLEFT", 14, -66 - (i - 1) * 22)
  b:RegisterForClicks("RightButtonUp")
  local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.025 or 0)
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 0.82, 0.3, 0.08)
  b.dot = b:CreateTexture(nil, "ARTWORK"); b.dot:SetSize(7, 7); b.dot:SetTexture(TEX .. "Dot"); b.dot:SetPoint("LEFT", 0, 0)
  b.cells = {}
  for k, c in ipairs(COLS) do
    local t = fs(b, k == 1 and F_SEMI or F_BOLD, 11)
    t:SetPoint("LEFT", b, "LEFT", c[2] - 14 + (k == 1 and 12 or 0), 0); t:SetWidth(c[3] - (k == 1 and 12 or 0)); t:SetJustifyH(c[4])
    b.cells[k] = t
  end
  b:SetScript("OnEnter", function(self) if self.run then runTip(self, self.run) end end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self, btn)
    if btn == "RightButton" and IsShiftKeyDown() and self.run then
      local r = self.run
      if r == cur then cur = nil; DB.charCur[charKey()] = nil end
      removeRun(r); say(string.format(T("deleted"), (r.name or "?") .. " (" .. date("%d/%m %H:%M", r.enter) .. ")"))
      GameTooltip:Hide(); L.refresh(); refresh()
    end
  end)
  logRows[i] = b
end
local logEmpty = fs(L, F_SEMI, 12); logEmpty:SetPoint("TOP", 0, -120); logEmpty:SetTextColor(0.55, 0.58, 0.64); label(logEmpty, "logEmpty")
local logFoot = fs(L, F_SEMI, 10); logFoot:SetPoint("BOTTOMLEFT", 18, 16); logFoot:SetTextColor(0.45, 0.48, 0.54); label(logFoot, "logHint")
local logCount = fs(L, F_SEMI, 10); logCount:SetPoint("BOTTOMRIGHT", -18, 16); logCount:SetTextColor(0.45, 0.48, 0.54)

L.refresh = function()
  if not (DB and L:IsShown()) then return end
  local list = charRuns(logAll)
  logOffset = math.max(0, math.min(logOffset, #list - ROWS))
  for i = 1, ROWS do
    local b, r = logRows[i], list[i + logOffset]
    b.run = r
    if r then
      local left, kind = lockLeft(r)
      local dc = left and (kind == "h" and ORANGE or BLUE) or GREY
      b.dot:SetVertexColor(dc[1], dc[2], dc[3])
      local who = logAll and ("|cff8c94a3" .. (r.char:match("^[^-]+") or "") .. "|r  ") or ""
      local cells = { who .. (r.name or "?"), r.leave and dur(now() - r.enter) or T("stillIn"), dur(runTime(r)), num(r.xp),
        money(r.money), tostring(r.kills or 0), left and dur(left) or "" }
      local colors = { {0.85, 0.87, 0.92}, GREY, WHITE, BLUE, GOLD, WHITE, left and (kind == "h" and ORANGE or BLUE) or GREY }
      for k, t in ipairs(b.cells) do t:SetText(cells[k]); col(t, colors[k]) end
      b:Show()
    else
      b:Hide()
    end
  end
  logEmpty:SetShown(#list == 0)
  logCount:SetText(#list > 0 and string.format("%d-%d / %d", logOffset + 1, math.min(#list, logOffset + ROWS), #list) or "")
  local on, off = {1, 0.82, 0.4}, {0.55, 0.58, 0.64}
  local a, b2 = logAll and off or on, logAll and on or off
  tabA:paint(a[1], a[2], a[3]); tabA.bg:SetAlpha(logAll and 0.45 or 1)
  tabB:paint(b2[1], b2[2], b2[3]); tabB.bg:SetAlpha(logAll and 1 or 0.45)
end
L:EnableMouseWheel(true)
L:SetScript("OnMouseWheel", function(_, d) logOffset = logOffset - d * 3; L.refresh() end)
L:SetScript("OnShow", function() logOffset = 0; L.refresh() end)
tabA:SetScript("OnClick", function() logAll = false; logOffset = 0; L.refresh() end)
tabB:SetScript("OnClick", function() logAll = true; logOffset = 0; L.refresh() end)
logBtn:SetScript("OnClick", function() L:SetShown(not L:IsShown()) end)

-- ---------- indstillinger ----------
local S = CreateFrame("Frame", "InstanceETASettings", UIParent)
local SW, COL = 520, 260
S:SetSize(SW, 360); S:SetPoint("CENTER"); S:SetFrameStrata("DIALOG"); S:Hide()
skin(S, "Wide", 1040, 2048)
movable(S, function() return true end)
tinsert(UISpecialFrames, "InstanceETASettings")
label(header(S), "settings")
closeButton(S, function() S:Hide() end)

local controls = {}
local applyAll  -- saettes laengere nede
local function section(x, y, key)
  local t = fs(S, F_BOLD, 11); t:SetPoint("TOPLEFT", x + 18, y); t:SetTextColor(1, 0.82, 0.4); label(t, key)
end
local function toggle(x, y, lkey, dbkey, invert)
  local c = CreateFrame("CheckButton", nil, S)
  c:SetSize(32, 18); c:SetPoint("TOPRIGHT", S, "TOPLEFT", x + COL - 18, y)
  local off = c:CreateTexture(nil, "ARTWORK"); off:SetAllPoints(); off:SetTexture(TEX .. "ToggleOff"); off:SetTexCoord(0, 1, 0, 36 / 64)
  local on = c:CreateTexture(nil, "ARTWORK"); on:SetAllPoints(); on:SetTexture(TEX .. "ToggleOn"); on:SetTexCoord(0, 1, 0, 36 / 64)
  local t = fs(S, F_SEMI, 12); t:SetPoint("TOPLEFT", x + 18, y - 2); t:SetTextColor(0.85, 0.87, 0.92); label(t, lkey)
  local function show() local v = DB[dbkey] and true or false; if invert then v = not v end; on:SetShown(v); off:SetShown(not v) end
  c:SetScript("OnClick", function() DB[dbkey] = not DB[dbkey]; show(); applyAll() end)
  c.load = show
  controls[#controls + 1] = c
end
local function slider(x, y, lkey, minV, maxV, dbkey, fmt)
  local t = fs(S, F_SEMI, 12); t:SetPoint("TOPLEFT", x + 18, y); t:SetTextColor(0.85, 0.87, 0.92); label(t, lkey)
  local val = fs(S, F_BOLD, 12); val:SetPoint("TOPRIGHT", S, "TOPLEFT", x + COL - 18, y); val:SetTextColor(1, 0.82, 0.4)
  local tw = COL - 36
  local s = CreateFrame("Slider", nil, S)
  s:SetOrientation("HORIZONTAL"); s:SetSize(tw, 16); s:SetPoint("TOPLEFT", x + 18, y - 18)
  local track = s:CreateTexture(nil, "BACKGROUND"); track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(3); track:SetColorTexture(1, 1, 1, 0.12)
  local fill = s:CreateTexture(nil, "ARTWORK"); fill:SetPoint("LEFT"); fill:SetHeight(3); fill:SetColorTexture(1, 0.8, 0.35, 0.9)
  s:SetThumbTexture(TEX .. "Thumb")
  local thumb = s:GetThumbTexture(); if thumb then thumb:SetSize(16, 16) end
  s:SetMinMaxValues(minV, maxV); s:SetValueStep(1)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:EnableMouseWheel(true)
  s:SetScript("OnMouseWheel", function(self, d) self:SetValue(math.max(minV, math.min(maxV, self:GetValue() + d))) end)
  local function paint(v) val:SetText(fmt(v)); fill:SetWidth(math.max(1, tw * (v - minV) / (maxV - minV))) end
  s:SetScript("OnValueChanged", function(self, v)
    v = math.floor(v + 0.5); paint(v)
    if self.loading then return end
    DB[dbkey] = v; applyAll()
  end)
  s.load = function() s.loading = true; s:SetValue(DB[dbkey]); paint(DB[dbkey]); s.loading = false end
  controls[#controls + 1] = s
end

local mmb  -- minimap knappen, laves laengere nede
local L0, R0 = 0, COL
section(L0, -52, "sWindow")
toggle(L0, -74, "showWin", "hidden", true)  -- gemmes som DB.hidden, saa knappen viser det modsatte
toggle(L0, -100, "lockWin", "locked")
toggle(L0, -126, "minimap", "showMinimap")
slider(L0, -156, "recentN", 0, 10, "recentN", function(v) return v == 0 and T("off") or tostring(v) end)
do -- sprog: to smaa knapper
  local t = fs(S, F_SEMI, 12); t:SetPoint("TOPLEFT", L0 + 18, -206); t:SetTextColor(0.85, 0.87, 0.92); label(t, "language")
  local da = pill(S, "Dansk", 64, 20); da:SetPoint("TOPRIGHT", S, "TOPLEFT", L0 + COL - 18, -202)
  local en = pill(S, "English", 64, 20); en:SetPoint("RIGHT", da, "LEFT", -6, 0)
  local function paint()
    local isDa = DB.lang == "da"
    da:paint(isDa and 1 or 0.55, isDa and 0.82 or 0.58, isDa and 0.4 or 0.64); da.bg:SetAlpha(isDa and 1 or 0.45)
    en:paint(isDa and 0.55 or 1, isDa and 0.58 or 0.82, isDa and 0.64 or 0.4); en.bg:SetAlpha(isDa and 0.45 or 1)
  end
  da:SetScript("OnClick", function() DB.lang = "da"; paint(); updateLabels(); applyAll() end)
  en:SetScript("OnClick", function() DB.lang = "en"; paint(); updateLabels(); applyAll() end)
  controls[#controls + 1] = {load = paint}
end
section(L0, -244, "sLimit")
slider(L0, -266, "hourLimit", 0, 10, "hourLimit", function(v) return v == 0 and T("off") or tostring(v) end)
slider(L0, -310, "dayLimit", 0, 60, "dayLimit", function(v) return v == 0 and T("off") or tostring(v) end)

section(R0, -52, "sChat")
toggle(R0, -74, "enterMsg", "enterMsg")
toggle(R0, -100, "leaveMsg", "leaveMsg")
toggle(R0, -126, "groupMsg", "groupMsg")
toggle(R0, -152, "tradeMsg", "tradeMsg")
toggle(R0, -178, "freeMsg", "freeMsg")
toggle(R0, -266, "countRaids", "countRaids")
toggle(R0, -292, "accountWide", "accountWide")

S:SetScript("OnShow", function() for _, c in ipairs(controls) do c.load() end end)

-- ---------- minimap knap ----------
mmb = CreateFrame("Button", "InstanceETAMinimapButton", Minimap)
mmb:SetSize(31, 31); mmb:SetFrameStrata("MEDIUM"); mmb:SetFrameLevel(8)
mmb:RegisterForClicks("LeftButtonUp", "RightButtonUp"); mmb:RegisterForDrag("LeftButton")
mmb:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
do
  local bg = mmb:CreateTexture(nil, "BACKGROUND"); bg:SetSize(20, 20); bg:SetPoint("TOPLEFT", 7, -5); bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  local icon = mmb:CreateTexture(nil, "ARTWORK"); icon:SetSize(21, 21); icon:SetPoint("TOPLEFT", 5, -5); icon:SetTexture(LOGO)
  local border = mmb:CreateTexture(nil, "OVERLAY"); border:SetSize(53, 53); border:SetPoint("TOPLEFT"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
end
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local function placeButton()
  local a = math.rad(DB.mmAngle)
  local rad = (Minimap:GetWidth() / 2) + 5
  mmb:ClearAllPoints(); mmb:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * rad, math.sin(a) * rad)
end
mmb:SetScript("OnDragStart", function(self)
  self:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local sc = Minimap:GetEffectiveScale()
    DB.mmAngle = math.deg(atan2(py / sc - my, px / sc - mx))
    placeButton()
  end)
end)
mmb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

local function toggleWindow()
  DB.hidden = f:IsShown()
  f:SetShown(not DB.hidden)
  refresh()
end
mmb:SetScript("OnClick", function(_, btn)
  if IsShiftKeyDown and IsShiftKeyDown() then L:SetShown(not L:IsShown())
  elseif btn == "RightButton" then S:SetShown(not S:IsShown())
  else toggleWindow() end
end)
mmb:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine(NAME, 1, 0.82, 0.3)
  local hN, dN, nextAt = lockout()
  local hl, dl = DB.hourLimit or 5, DB.dayLimit or 0
  local hc = limitColor(hN, hl)
  GameTooltip:AddDoubleLine(T("thisHour"), hl > 0 and (hN .. " / " .. hl) or tostring(hN), 0.85, 0.85, 0.85, hc[1], hc[2], hc[3])
  GameTooltip:AddDoubleLine(T("today"), dl > 0 and (dN .. " / " .. dl) or tostring(dN), 0.85, 0.85, 0.85, 1, 1, 1)
  local nt, nc = nextFreeText(nextAt)
  GameTooltip:AddDoubleLine(T("nextFree"), nt, 0.85, 0.85, 0.85, nc[1], nc[2], nc[3])
  if cur then GameTooltip:AddDoubleLine(T("inside") .. " " .. (cur.name or "?"), stopwatch(runTime(cur)), 0.85, 0.85, 0.85, 1, 1, 1) end
  -- raid lockouts og dine andre karakterer
  local any = false
  for key, c in pairs(DB.chars) do
    local lines = {}
    for _, s in ipairs(c.saved or {}) do
      if s.resetAt and s.resetAt > now() then lines[#lines + 1] = s end
    end
    local hourN = 0
    for _, r in ipairs(DB.runs) do if r.char == key and counts(r) and now() - r.enter < HOUR then hourN = hourN + 1 end end
    if #lines > 0 or (key ~= charKey() and hourN > 0) then
      if not any then GameTooltip:AddLine(" "); GameTooltip:AddLine(T("alts"), 1, 0.82, 0.4); any = true end
      local cc = RAID_CLASS_COLORS and c.class and RAID_CLASS_COLORS[c.class]
      GameTooltip:AddDoubleLine(key:match("^[^-]+") .. (c.level and ("  " .. c.level) or ""), hourN > 0 and (hourN .. " " .. T("thisHour"):lower()) or "",
        cc and cc.r or 0.85, cc and cc.g or 0.85, cc and cc.b or 0.85, 1, 0.6, 0.35)
      for _, s in ipairs(lines) do
        GameTooltip:AddDoubleLine("   " .. s.name, string.format(T("resetsIn"), dur(s.resetAt - now())), 0.75, 0.78, 0.84, 0.55, 0.58, 0.64)
      end
    end
  end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(T("tipLeft"), 0.6, 0.6, 0.6)
  GameTooltip:AddLine(T("tipRight"), 0.6, 0.6, 0.6)
  GameTooltip:AddLine(T("tipShift"), 0.6, 0.6, 0.6)
  GameTooltip:Show()
end)
mmb:SetScript("OnLeave", function() GameTooltip:Hide() end)

applyAll = function()
  if not DB then return end
  f:SetShown(not DB.hidden)
  mmb:SetShown(DB.showMinimap)
  placeButton()
  refresh(); L.refresh()
end

-- ---------- runs: ind og ud af instances ----------
local function snapshotXP()
  return { xp = UnitXP("player") or 0, max = UnitXPMax("player") or 0, lvl = UnitLevel("player") or 0 }
end
local lastXP

local function updateGroup()
  if not cur then return end
  cur.group = cur.group or {}
  local n = GetNumGroupMembers and GetNumGroupMembers() or 0
  local raid = IsInRaid and IsInRaid()
  for i = 1, n do
    local unit = raid and ("raid" .. i) or ("party" .. i)
    if UnitExists(unit) and not UnitIsUnit(unit, "player") then
      local name = UnitName(unit)
      if name and not secret(name) and name ~= UNKNOWNOBJECT then
        local _, class = UnitClass(unit)
        local lvl = UnitLevel(unit)
        cur.group[name] = { class = class, lvl = (lvl and lvl > 0) and lvl or (cur.group[name] and cur.group[name].lvl) }
      end
    end
  end
end

local function statsText(r, plain)
  local xr = xpRate(r)
  local s = string.format(T("statsLine"), r.name or "?", dur(runTime(r)), num(r.xp), money(r.money, plain), r.kills or 0)
  if xr then s = s .. ", " .. num(xr) .. " XP" .. T("perHr") end
  local n = r.char == charKey() and runsToLevel(r)
  if n then s = s .. ", " .. n .. " " .. (n == 1 and T("runWord") or T("runsWord")) .. " > " .. ((UnitLevel("player") or 0) + 1) end
  return s
end

local function closeRun(quiet)
  if not cur then return end
  local r = cur
  r.leave = now()
  r.lvlOut = UnitLevel("player")
  cur = nil; DB.charCur[charKey()] = nil
  wipe(seenZone)
  local active = (r.xp or 0) > 0 or (r.money or 0) > 0 or (r.kills or 0) > 0
  if not quiet and DB.leaveMsg and active then
    say(statsText(r))
    if DB.groupMsg and IsInGroup and IsInGroup() and not (IsInRaid and IsInRaid()) then
      pcall(SendChatMessage, "InstanceETA: " .. statsText(r, true), "PARTY")
    end
  end
  refresh(); L.refresh()
end

local function openRun(name, mapID, kind)
  local r = {
    id = newId(), char = charKey(), name = name, map = mapID, kind = kind, enter = now(),
    t = 0, xp = 0, money = 0, kills = 0, lvlIn = UnitLevel("player"), rep = {}, group = {},
  }
  table.insert(DB.runs, 1, r)
  while #DB.runs > MAX_RUNS do table.remove(DB.runs) end
  cur = r; DB.charCur[charKey()] = r.id
  wipe(seenZone)
  lastXP = snapshotXP()
  updateGroup()
  local c = DB.chars[charKey()]; if c then c.level = UnitLevel("player") end
  if DB.enterMsg then
    if kind == "raid" and not DB.countRaids then
      say(string.format(T("raidRun"), name))
    else
      local hN, dN = lockout()
      local hl, dl = DB.hourLimit or 5, DB.dayLimit or 0
      local h = hex(limitColor(hN, hl)) .. hN .. (hl > 0 and ("/" .. hl) or "") .. "|r"
      local d = dN .. (dl > 0 and ("/" .. dl) or "")
      say(string.format(T("newRun"), name, h, d) .. "  |cff8c94a3" .. T("undoHint") .. "|r")
    end
  end
  if counts(r) then
    local hN, _, nextAt = lockout()
    local hl = DB.hourLimit or 5
    if nextAt then toast.show(T("locked"), string.format(T("lockedSub"), (nextFreeText(nextAt))))
    elseif hl > 0 and hN == hl then toast.show(T("lastOne"), string.format(T("lastOneSub"), hN, hl)) end
  end
  refresh(); L.refresh()
end

local function findRun(id)
  if not id then return nil end
  for _, r in ipairs(DB.runs) do if r.id == id then return r end end
end

-- er vi i en dungeon eller raid? (battlegrounds og arenaer logges ikke i denne version)
local function instanceNow()
  local inInst, itype = IsInInstance()
  if not inInst or (itype ~= "party" and itype ~= "raid") then return nil end
  local name, _, _, _, _, _, _, mapID = GetInstanceInfo()
  if secret(name) then name = nil end
  return name or (GetRealZoneText and GetRealZoneText()) or "?", mapID, itype
end

local function checkZone(isLogin, isReload)
  local name, mapID, kind = instanceNow()
  local saved = findRun(DB.charCur[charKey()])
  if saved and saved ~= cur and not saved.leave then
    -- en run der stadig var aaben fra sidst du spillede
    local same = name and (isLogin or isReload) and saved.map == mapID
    if not same then saved.leave = saved.enter + (saved.t or 0); saved.lvlOut = saved.lvlOut or UnitLevel("player"); DB.charCur[charKey()] = nil end
  end
  if not name then
    -- ude af instancen. Er du lige logget ind udenfor, men loggen tror du er inde, lukkes runnen stille.
    if cur then closeRun(isLogin or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))) end
    return
  end
  if cur then
    if cur.map == mapID and cur.char == charKey() then
      if not lastXP then lastXP = snapshotXP() end
      return  -- samme instance (reload, eller zonen skiftede inde i instancen)
    end
    closeRun(true)
  end
  -- reload eller login inde i en instance du allerede har en run for: fortsaet den
  saved = findRun(DB.charCur[charKey()])
  if (isLogin or isReload) and saved and saved.map == mapID and (not saved.leave or now() - saved.leave < 15 * 60) then
    cur = saved; cur.leave = nil; DB.charCur[charKey()] = cur.id
    lastXP = snapshotXP()
    refresh(); L.refresh()
    return
  end
  openRun(name, mapID, kind)
end

-- samme instance som sidst? Mobbenes GUID indeholder instancens zone-id.
local function sawGUID(guid)
  if not cur or not guid or secret(guid) or type(guid) ~= "string" then return end
  local zone = guid:match("^Creature%-%d+%-%d+%-%d+%-(%d+)%-") or guid:match("^Vehicle%-%d+%-%d+%-%d+%-(%d+)%-")
  if not zone or seenZone[zone] then return end
  seenZone[zone] = true
  if cur.zone then return end
  cur.zone = zone
  -- find din seneste run i den samme instance, med samme zone-id, som ikke er blevet nulstillet
  for _, r in ipairs(DB.runs) do
    if r ~= cur and r.char == cur.char and r.map == cur.map and r.zone == zone and not r.reset and now() - r.enter < DAY then
      r.t = (r.t or 0) + (cur.t or 0)
      r.xp = (r.xp or 0) + (cur.xp or 0)
      r.money = (r.money or 0) + (cur.money or 0)
      r.kills = (r.kills or 0) + (cur.kills or 0)
      for k, v in pairs(cur.rep or {}) do r.rep = r.rep or {}; r.rep[k] = (r.rep[k] or 0) + v end
      for k, v in pairs(cur.group or {}) do r.group = r.group or {}; r.group[k] = v end
      for _, x in ipairs(cur.trades or {}) do r.trades = r.trades or {}; table.insert(r.trades, x) end
      removeRun(cur)
      -- runnen flyttes op foerst i loggen igen
      removeRun(r); table.insert(DB.runs, 1, r)
      r.leave = nil
      cur = r; DB.charCur[charKey()] = r.id
      say(T("merged"))
      refresh(); L.refresh()
      return
    end
  end
end

-- ---------- XP, guld, omdoemme, kills ----------
local function onXP()
  if not cur then lastXP = nil; return end
  local s = snapshotXP()
  if lastXP then
    local d
    if s.lvl > lastXP.lvl then d = (lastXP.max - lastXP.xp) + s.xp  -- level op undervejs
    else d = s.xp - lastXP.xp end
    if d > 0 then cur.xp = (cur.xp or 0) + d end
  end
  lastXP = s
end

local P = {}
local function pats()
  if P.done then return P end
  P.done = true
  P.gold = GOLD_AMOUNT and makePat(GOLD_AMOUNT, false)
  P.silver = SILVER_AMOUNT and makePat(SILVER_AMOUNT, false)
  P.copper = COPPER_AMOUNT and makePat(COPPER_AMOUNT, false)
  P.repUp = makePat(FACTION_STANDING_INCREASED)
  P.repDown = makePat(FACTION_STANDING_DECREASED)
  P.xpNamed = makePat(COMBATLOG_XPGAIN_FIRSTPERSON, false)
  P.reset = makePat(INSTANCE_RESET_SUCCESS)
  return P
end

local function parseMoney(msg)
  local p, c = pats(), 0
  local g = p.gold and msg:match(p.gold); if g then c = c + tonumber(g) * 10000 end
  local s = p.silver and msg:match(p.silver); if s then c = c + tonumber(s) * 100 end
  local k = p.copper and msg:match(p.copper); if k then c = c + tonumber(k) end
  return c
end

local function onMoneyMsg(msg)
  if not cur or type(msg) ~= "string" or secret(msg) then return end
  local c = parseMoney(msg)
  if c > 0 then cur.money = (cur.money or 0) + c end
end

local function onRep(msg)
  if not cur or type(msg) ~= "string" or secret(msg) then return end
  local p = pats()
  local fac, n = p.repUp and msg:match(p.repUp)
  local sign = 1
  if not fac then fac, n = p.repDown and msg:match(p.repDown); sign = -1 end
  if fac and n then
    cur.rep = cur.rep or {}
    cur.rep[fac] = (cur.rep[fac] or 0) + sign * tonumber(n)
  end
end

local function onXPMsg(msg)
  if not cur or type(msg) ~= "string" or secret(msg) then return end
  local p = pats()
  if p.xpNamed and msg:match(p.xpNamed) then cur.kills = (cur.kills or 0) + 1 end
end

local function onSystem(msg)
  if type(msg) ~= "string" or secret(msg) then return end
  local p = pats()
  local inst = p.reset and msg:match(p.reset)
  if inst then
    for _, r in ipairs(DB.runs) do
      if r.name == inst and r.leave then r.reset = true end
    end
  end
end

-- ---------- handel med guld ----------
local trade = {}
local function onTrade(event, a1, a2)
  if event == "TRADE_SHOW" then
    local n = UnitName("NPC")
    trade = { who = (n and not secret(n)) and n or "?" }
  elseif event == "TRADE_MONEY_CHANGED" or event == "TRADE_ACCEPT_UPDATE" or event == "PLAYER_TRADE_MONEY" then
    if trade.who then
      local give, get = GetPlayerTradeMoney and GetPlayerTradeMoney(), GetTargetTradeMoney and GetTargetTradeMoney()
      if give and not secret(give) then trade.give = give end
      if get and not secret(get) then trade.get = get end
    end
  elseif event == "UI_INFO_MESSAGE" then
    local msg = (type(a2) == "string") and a2 or a1
    if trade.who and ERR_TRADE_COMPLETE and msg == ERR_TRADE_COMPLETE then
      if (trade.give or 0) > 0 or (trade.get or 0) > 0 then
        local x = { who = trade.who, give = trade.give or 0, get = trade.get or 0, at = now(), char = charKey(), inst = cur and cur.name }
        table.insert(DB.trades, 1, x)
        while #DB.trades > MAX_TRADES do table.remove(DB.trades) end
        if cur then cur.trades = cur.trades or {}; table.insert(cur.trades, x) end
        if DB.tradeMsg then
          if x.give > 0 then say(string.format(T("gave"), money(x.give), x.who)) end
          if x.get > 0 then say(string.format(T("got"), money(x.get), x.who)) end
        end
      end
      trade = {}
    end
  elseif event == "TRADE_CLOSED" or event == "TRADE_REQUEST_CANCEL" then
    -- TRADE_CLOSED kommer foer beskeden om at handlen er gennemfoert, saa vi rydder foerst lidt senere
    if C_Timer and C_Timer.After then C_Timer.After(1, function() trade = {} end) end
  end
end

-- ---------- raid lockouts for hver karakter ----------
local function saveLockouts()
  local c = DB.chars[charKey()]
  if not c or not GetNumSavedInstances then return end
  local list = {}
  local n = GetNumSavedInstances() or 0
  for i = 1, n do
    local name, _, reset, _, locked = GetSavedInstanceInfo(i)
    if name and not secret(name) and locked and reset and reset > 0 then
      list[#list + 1] = { name = name, resetAt = now() + reset }
    end
  end
  c.saved = list
end

-- ---------- haendelser ----------
local E = CreateFrame("Frame")
for _, ev in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_LOGOUT", "PLAYER_XP_UPDATE",
  "PLAYER_LEVEL_UP", "CHAT_MSG_MONEY", "CHAT_MSG_COMBAT_FACTION_CHANGE", "CHAT_MSG_COMBAT_XP_GAIN", "CHAT_MSG_SYSTEM",
  "GROUP_ROSTER_UPDATE", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "UPDATE_INSTANCE_INFO",
  "TRADE_SHOW", "TRADE_CLOSED", "TRADE_REQUEST_CANCEL", "TRADE_MONEY_CHANGED", "TRADE_ACCEPT_UPDATE", "PLAYER_TRADE_MONEY", "UI_INFO_MESSAGE"}) do
  pcall(E.RegisterEvent, E, ev)
end

E:SetScript("OnEvent", function(_, event, a1, a2)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    InstanceETADB = InstanceETADB or {}
    DB = InstanceETADB
    for k, v in pairs(defaults) do if DB[k] == nil then DB[k] = v end end
    DB.runs = DB.runs or {}; DB.chars = DB.chars or {}; DB.trades = DB.trades or {}; DB.charCur = DB.charCur or {}
    if not DB.langSet then
      local loc = GetLocale and GetLocale() or "enUS"
      DB.lang = (loc == "daDK") and "da" or DB.lang
      DB.langSet = true
    end
    f:ClearAllPoints()
    if DB.point then f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", DB.point[1], DB.point[2])
    else f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -220) end
    updateLabels()
    applyAll()
  elseif event == "PLAYER_ENTERING_WORLD" then
    local key = charKey()
    DB.chars[key] = DB.chars[key] or {}
    local c = DB.chars[key]
    local _, class = UnitClass("player"); c.class = class; c.level = UnitLevel("player"); c.seen = now()
    if RequestRaidInfo then pcall(RequestRaidInfo) end
    checkZone(a1, a2)
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    checkZone(false, false)
  elseif event == "PLAYER_LOGOUT" then
    -- husk hvilken run du var i, saa et reload eller login inde i instancen fortsaetter den
    DB.charCur[charKey()] = cur and cur.id or nil
  elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
    onXP()
    local c = DB.chars[charKey()]; if c then c.level = UnitLevel("player") end
  elseif event == "CHAT_MSG_MONEY" then onMoneyMsg(a1)
  elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then onRep(a1)
  elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then onXPMsg(a1)
  elseif event == "CHAT_MSG_SYSTEM" then onSystem(a1)
  elseif event == "GROUP_ROSTER_UPDATE" then updateGroup()
  elseif event == "PLAYER_TARGET_CHANGED" then if cur then sawGUID(UnitGUID("target")) end
  elseif event == "UPDATE_MOUSEOVER_UNIT" then if cur then sawGUID(UnitGUID("mouseover")) end
  elseif event == "NAME_PLATE_UNIT_ADDED" then if cur and a1 then sawGUID(UnitGUID(a1)) end
  elseif event == "UPDATE_INSTANCE_INFO" then saveLockouts()
  else onTrade(event, a1, a2) end
end)

-- hvert sekund: tid i instancen, og sig til naar en ny instance er fri
local wasLocked = false
local function tick(el)
  if not DB then return end
  if cur then cur.t = (cur.t or 0) + el end
  local _, _, nextAt = lockout()
  local locked = nextAt ~= nil
  if wasLocked and not locked and DB.freeMsg then
    local hN = lockout()
    toast.show(T("freeToast"), string.format(T("freeToastSub"), hN, DB.hourLimit or 5))
    say(T("freeToast") .. ".")
  end
  wasLocked = locked
  refresh()
  if L:IsShown() then L.refresh() end
end
if C_Timer and C_Timer.NewTicker then
  local last = clock()
  C_Timer.NewTicker(1, function() local t = clock(); tick(t - last); last = t end)
else
  local a, clockFrame = 0, CreateFrame("Frame")
  clockFrame:SetScript("OnUpdate", function(_, el) a = a + el; if a >= 1 then tick(a); a = 0 end end)
end

-- ---------- kommandoer ----------
SLASH_INSTANCEETA1 = "/instanceeta"
SLASH_INSTANCEETA2 = "/ieta"
SlashCmdList.INSTANCEETA = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "log" then L:SetShown(not L:IsShown())
  elseif msg == "config" or msg == "settings" or msg == "indstillinger" then S:SetShown(not S:IsShown())
  elseif msg == "undo" or msg == "fortryd" then
    local r
    for _, x in ipairs(DB.runs) do if x.char == charKey() then r = x; break end end
    if not r then say(T("nothingUndo")); return end
    if r == cur then cur = nil; DB.charCur[charKey()] = nil end
    removeRun(r); say(string.format(T("undone"), r.name or "?"))
    refresh(); L.refresh()
  elseif msg == "trades" or msg == "handler" then
    say(T("tradesHead"))
    if #DB.trades == 0 then print(T("noTrades")) end
    for i = 1, math.min(20, #DB.trades) do
      local x = DB.trades[i]
      local s = date("%d/%m %H:%M", x.at) .. "  "
      if x.give > 0 then s = s .. string.format(T("gave"), money(x.give), x.who) end
      if x.get > 0 then s = s .. (x.give > 0 and ",  " or "") .. string.format(T("got"), money(x.get), x.who) end
      if x.inst then s = s .. "  |cff8c94a3(" .. x.inst .. ")|r" end
      print(s)
    end
  elseif msg == "reset" then
    DB.point = nil
    f:ClearAllPoints(); f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    L:ClearAllPoints(); L:SetPoint("CENTER"); S:ClearAllPoints(); S:SetPoint("CENTER")
    say(T("posReset"))
  elseif msg == "da" or msg == "en" then
    DB.lang = msg; updateLabels(); applyAll()
  elseif msg == "help" or msg == "hjaelp" then
    say(T("help"))
  else
    toggleWindow()
  end
end
