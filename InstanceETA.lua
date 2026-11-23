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
    logHint = "Click: post stats  ·  Hover: details  ·  Shift right-click: delete", logEmpty = "No runs in the log yet.",
    entered = "Entered", left = "Left", levels = "Level", group = "Group", rep = "Reputation", trades = "Gold traded",
    xpHr = "XP per hour", perKill = "XP per kill", runsLevel = "Runs to next level", avgLevel = "Average group level",
    merged = "Same instance as your last run, merged.", resumed = "Back in the same instance, continuing your last run.",
    hourLeft = "counts this hour for %s", dayLeft = "counts today for %s",
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
    tipLeft = "Left-click: instance log", tipRight = "Right-click: settings", tipShift = "Shift-click: compact window",
    help = "/ieta: log  ·  /ieta compact  ·  /ieta chars  ·  /ieta lockouts  ·  /ieta config  ·  /ieta undo  ·  /ieta trades  ·  /ieta reset  ·  /ieta da|en",
    tradesHead = "InstanceETA gold trades, newest first", noTrades = "No gold trades yet.",
    posReset = "Windows moved back to the middle.", runWord = "run", runsWord = "runs",
    statsLine = "%s in %s: %s XP, %s, %d kills",
    legHour = "Past hour", legDay = "Past 24 hours", legOld = "Older", legRaid = "Raid", legAlts = "Alts",
    bSettings = "Settings", bTrades = "Trades", bLocks = "Lockouts", bChars = "Characters", showAlts = "Show alts",
    leftAgo = "left %s ago", tradesTitle = "Trade log", colDate = "When", colWho = "Player", colGave = "Gave", colGot = "Received",
    colWhere = "Where", tradesFoot = "Gold you gave or got in trades, newest first", locksTitle = "Raid lockouts, all characters",
    colChar = "Character", colResets = "Resets in", noLocks = "No raid lockouts right now.", charsTitle = "Your characters",
    colLevel = "Level", colRested = "Rested", colGoldC = "Gold", colDur = "Durability", colBags = "Bags free", colSeen = "Last seen",
    restedState = "Rested state", resting = "Resting", notResting = "Not resting", profs = "Professions", totalGold = "Total gold",
    online = "Online", compact = "Compact window", posted = "Stats posted to party.",
    legBG = "Battleground", showBG = "Battlegrounds", bgRun = "Battleground: %s. Good luck!", honor = "Honor", hks = "Honorable kills",
    won = "Won", lost = "Lost", result = "Result", bgTotal = "All your %s", bgRecord = "%d won, %d lost", honorHr = "Honor per hour",
    resetMsg = "Tell the group about resets", resetSaid = "%s has been reset.", cds = "Cooldowns", cdReady = "Ready", colCD = "Cooldowns",
    charsFoot = "Shift right-click a character to remove it", removed = "Removed %s and %d runs.", cantRemove = "You can not remove the character you are playing.",
    bgLine = "%s %s in %s: %s honor, %d HKs", bgLineNoRes = "%s in %s: %s honor, %d HKs", avgHonor = "Honor per game",
  },
  da = {
    hm = "%dt %02dm", dh = "%dd %dt",
    thisHour = "Denne time", today = "Sidste 24 timer", nextFree = "Næste instance", freeNow = "Fri nu",
    noLimit = "ingen grænse", inside = "Inde i", recent = "Seneste runs", noRuns = "Ingen runs endnu. Gå ind i en dungeon.",
    xp = "XP", gold = "Guld", kills = "Kills", time = "Tid", perHr = "/t", ago = "%s siden", stillIn = "inde nu",
    log = "Log", logTitle = "Instance log", thisChar = "Denne karakter", allChars = "Alle karakterer",
    colInst = "Instance", colWhen = "Gik ind", colTime = "Tid", colXP = "XP", colGold = "Guld", colKills = "Kills", colLock = "Lockout",
    logHint = "Klik: send opsummering  ·  Hold musen over: detaljer  ·  Shift højreklik: slet",  logEmpty = "Ingen runs i loggen endnu.",
    entered = "Gik ind", left = "Gik ud", levels = "Level", group = "Gruppe", rep = "Omdømme", trades = "Guld handlet",
    xpHr = "XP i timen", perKill = "XP pr. kill", runsLevel = "Runs til næste level", avgLevel = "Gruppens gns. level",
    merged = "Samme instance som sidst, lagt sammen.", resumed = "Tilbage i samme instance, fortsætter din sidste run.",
    hourLeft = "tæller i denne time i %s", dayLeft = "tæller i dag i %s",
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
    tipLeft = "Venstreklik: instance log", tipRight = "Højreklik: indstillinger", tipShift = "Shift klik: lille vindue",
    help = "/ieta: log  ·  /ieta compact  ·  /ieta chars  ·  /ieta lockouts  ·  /ieta config  ·  /ieta undo  ·  /ieta trades  ·  /ieta reset  ·  /ieta da|en",
    tradesHead = "InstanceETA guld handler, nyeste først", noTrades = "Ingen guld handler endnu.",
    posReset = "Vinduerne er flyttet tilbage til midten.", runWord = "run", runsWord = "runs",
    statsLine = "%s på %s: %s XP, %s, %d kills",
    legHour = "Sidste time", legDay = "Sidste 24 timer", legOld = "Ældre", legRaid = "Raid", legAlts = "Alts",
    bSettings = "Indstillinger", bTrades = "Handler", bLocks = "Lockouts", bChars = "Karakterer", showAlts = "Vis alts",
    leftAgo = "gik ud for %s siden", tradesTitle = "Handelslog", colDate = "Hvornår", colWho = "Spiller", colGave = "Gav", colGot = "Fik",
    colWhere = "Hvor", tradesFoot = "Guld du har givet eller fået i handler, nyeste først", locksTitle = "Raid lockouts, alle karakterer",
    colChar = "Karakter", colResets = "Nulstilles om", noLocks = "Ingen raid lockouts lige nu.", charsTitle = "Dine karakterer",
    colLevel = "Level", colRested = "Rested", colGoldC = "Guld", colDur = "Holdbarhed", colBags = "Ledige pladser", colSeen = "Sidst set",
    restedState = "Rested", resting = "Hviler", notResting = "Hviler ikke", profs = "Erhverv", totalGold = "Guld i alt",
    online = "Online", compact = "Lille vindue", posted = "Opsummering sendt til party.",
    legBG = "Battleground", showBG = "Battlegrounds", bgRun = "Battleground: %s. Held og lykke!", honor = "Honor", hks = "Honorable kills",
    won = "Vundet", lost = "Tabt", result = "Resultat", bgTotal = "Alle dine %s", bgRecord = "%d vundet, %d tabt", honorHr = "Honor i timen",
    resetMsg = "Sig til gruppen ved nulstilling", resetSaid = "%s er nulstillet.", cds = "Cooldowns", cdReady = "Klar", colCD = "Cooldowns",
    charsFoot = "Shift højreklik en karakter for at fjerne den", removed = "Fjernede %s og %d runs.", cantRemove = "Du kan ikke fjerne den karakter du spiller.",
    bgLine = "%s %s på %s: %s honor, %d HKs", bgLineNoRes = "%s på %s: %s honor, %d HKs", avgHonor = "Honor pr. kamp",
  },
}
local function T(k) return (LOC[(DB and DB.lang) or "en"] or LOC.en)[k] or LOC.en[k] or k end
local labels = {}
local function label(f, key) labels[#labels + 1] = {f, key}; f:SetText(T(key)) end
local function updateLabels() for _, x in ipairs(labels) do x[1]:SetText(T(x[2])) end end

-- GAET: Forever har en graense paa 5 instances i timen og ingen graense pr. doegn. Begge kan aendres i indstillingerne.
local defaults = {
  lang = "en", hidden = true, logAlts = false, logBG = true, resetMsg = true, locked = false, showMinimap = true, mmAngle = 200, recentN = 5,
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
    if (all or r.char == me) and (DB.logBG or r.kind ~= "pvp") then list[#list + 1] = r end
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
  -- lag: det vindue du klikker paa eller aabner, kommer foran de andre ETA vinduer
  if frame.SetToplevel then frame:SetToplevel(true) end
  frame:SetFrameLevel(40)
  frame:HookScript("OnShow", function(self) self:Raise() end)
  frame:HookScript("OnMouseDown", function(self) self:Raise() end)
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
  if r.kind == "pvp" then
    GameTooltip:AddLine(" ")
    if r.result then line(T("result"), T(r.result), r.result == "won" and GREEN or RED) end
    line(T("honor"), num(r.honor), RED)
    if (r.honor or 0) > 0 and runTime(r) >= 60 then line(T("honorHr"), num(r.honor / runTime(r) * 3600), RED) end
    line(T("hks"), tostring(r.hks or 0))
    -- samlet for denne battleground
    local w, l, n, hon, t = 0, 0, 0, 0, 0
    for _, x in ipairs(DB.runs) do
      if x.kind == "pvp" and x.map == r.map and x.char == r.char then
        n = n + 1; hon = hon + (x.honor or 0); t = t + runTime(x)
        if x.result == "won" then w = w + 1 elseif x.result == "lost" then l = l + 1 end
      end
    end
    if n > 1 then
      GameTooltip:AddLine(" "); GameTooltip:AddLine(string.format(T("bgTotal"), r.name or "?"), 1, 0.82, 0.4)
      line(T("result"), string.format(T("bgRecord"), w, l))
      line(T("avgHonor"), num(hon / n), RED)
      if t >= 60 then line(T("honorHr"), num(hon / t * 3600), RED) end
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
    if cur.kind == "pvp" then
      y = row(y, {kind = "small", title = T("honor"), value = num(cur.honor) .. "  ·  " .. (cur.hks or 0) .. " HKs", vc = RED})
    else
      y = row(y, {kind = "small", title = T("kills"), value = tostring(cur.kills or 0)})
    end
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

-- ---------- vinduer med lister (log, handler, lockouts, karakterer) ----------
local postStats   -- saettes laengere nede
local AGE_HOUR, AGE_DAY, AGE_OLD, RAIDC, ALTC, BGC = GREEN, GOLD, RED, {0.75, 0.55, 1}, {0.62, 0.82, 1}, {1, 0.45, 0.45}

local function classHex(class)
  local cc = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
  return cc and hex({cc.r, cc.g, cc.b}) or "|cffd9dde6"
end
local function shortName(key) return (key or "?"):match("^[^-]+") or key end

-- et vindue i ETA stil med en liste. cols = { {x, bredde, "LEFT"/"RIGHT", noegle til overskrift}, ... }
local function listWindow(name, titleKey, w, h, top, nRows, cols)
  local win = CreateFrame("Frame", name, UIParent)
  win:SetSize(w, h); win:SetPoint("CENTER"); win:SetFrameStrata("HIGH"); win:Hide()
  skin(win, "Wide", 1040, 2048)
  movable(win, function() return true end)
  tinsert(UISpecialFrames, name)
  win.title = header(win); if titleKey then label(win.title, titleKey) end
  closeButton(win, function() win:Hide() end)
  win.offset = 0
  for _, c in ipairs(cols) do
    if c[4] then
      local t = fs(win, F_BOLD, 10); t:SetPoint("TOPLEFT", c[1], top); t:SetWidth(c[2]); t:SetJustifyH(c[3]); t:SetTextColor(1, 0.82, 0.4)
      label(t, c[4])
    end
  end
  win.rows = {}
  for i = 1, nRows do
    local b = CreateFrame("Button", nil, win)
    b:SetSize(w - 28, 22); b:SetPoint("TOPLEFT", 14, top - 16 - (i - 1) * 22)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.025 or 0)
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 0.82, 0.3, 0.08)
    b.dot = b:CreateTexture(nil, "ARTWORK"); b.dot:SetSize(7, 7); b.dot:SetTexture(TEX .. "Dot"); b.dot:SetPoint("LEFT", 0, 0)
    b.cells = {}
    for k, c in ipairs(cols) do
      local t = fs(b, (k == 2) and F_SEMI or F_BOLD, 11)
      t:SetPoint("LEFT", b, "LEFT", c[1] - 14, 0); t:SetWidth(c[2]); t:SetJustifyH(c[3])
      b.cells[k] = t
    end
    b:SetScript("OnEnter", function(self) if self.tip then self.tip(self) end end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function(self, btn) if self.click then self.click(self, btn) end end)
    win.rows[i] = b
  end
  win.empty = fs(win, F_SEMI, 12); win.empty:SetPoint("TOP", 0, top - 60); win.empty:SetTextColor(0.55, 0.58, 0.64)
  win.foot = fs(win, F_SEMI, 10); win.foot:SetPoint("BOTTOMLEFT", 18, 16); win.foot:SetTextColor(0.45, 0.48, 0.54)
  win.count = fs(win, F_SEMI, 10); win.count:SetPoint("BOTTOMRIGHT", -18, 16); win.count:SetTextColor(0.45, 0.48, 0.54)
  -- items: liste af { cells = {tekst...}, colors = {farve...}, dot = farve, tip = fn, click = fn }
  win.fill = function(items)
    win.offset = math.max(0, math.min(win.offset, #items - nRows))
    for i = 1, nRows do
      local b, it = win.rows[i], items[i + win.offset]
      if it then
        b.tip, b.click = it.tip, it.click
        b.dot:SetShown(it.dot ~= nil)
        if it.dot then b.dot:SetVertexColor(it.dot[1], it.dot[2], it.dot[3]) end
        for k, t in ipairs(b.cells) do t:SetText(it.cells[k] or ""); col(t, (it.colors and it.colors[k]) or WHITE) end
        b:Show()
      else
        b.tip, b.click = nil, nil
        b:Hide()
      end
    end
    win.empty:SetShown(#items == 0)
    win.count:SetText(#items > nRows and string.format("%d-%d / %d", win.offset + 1, math.min(#items, win.offset + nRows), #items) or "")
  end
  win:EnableMouseWheel(true)
  win:SetScript("OnMouseWheel", function(self, d) self.offset = self.offset - d * 3; if self.refresh then self.refresh() end end)
  win:SetScript("OnShow", function(self) self.offset = 0; if self.refresh then self.refresh() end end)
  return win
end

-- ---------- instance loggen (hovedvinduet, som i Nova) ----------
local LW, LTOP, ROWS = 680, -164, 14
local L = listWindow("InstanceETALog", nil, LW, -LTOP + 16 + ROWS * 22 + 40, LTOP, ROWS, {
  {18, 22, "RIGHT", nil}, {46, 240, "LEFT", "colInst"}, {290, 104, "RIGHT", "colWhen"}, {398, 54, "RIGHT", "colTime"},
  {456, 58, "RIGHT", "colXP"}, {518, 70, "RIGHT", "colGold"}, {592, 72, "RIGHT", "colLock"} })
L.title:SetText("|cffffffffInstance|r|cffffd24aETA|r")
label(L.empty, "logEmpty"); label(L.foot, "logHint")

-- tre tal oeverst: denne time, sidste 24 timer, naeste instance
local stats = {}
for i, key in ipairs({"thisHour", "today", "nextFree"}) do
  local x = 18 + (i - 1) * 206
  local k = fs(L, F_SEMI, 11); k:SetPoint("TOPLEFT", x, -46); k:SetTextColor(0.55, 0.58, 0.64); label(k, key)
  local v = fs(L, F_BOLD, 18); v:SetPoint("TOPLEFT", x, -62)
  local track = L:CreateTexture(nil, "ARTWORK"); track:SetPoint("TOPLEFT", x, -88); track:SetSize(190, 3); track:SetColorTexture(1, 1, 1, 0.08)
  local fill = L:CreateTexture(nil, "OVERLAY"); fill:SetPoint("TOPLEFT", track, "TOPLEFT"); fill:SetHeight(3)
  stats[i] = {v = v, track = track, fill = fill}
end
local function bar(s, frac, c)
  local on = type(frac) == "number"
  s.track:SetShown(on); s.fill:SetShown(on)
  if on then s.fill:SetColorTexture(c[1], c[2], c[3], 0.9); s.fill:SetWidth(math.max(2, 190 * math.min(1, frac))) end
end

-- knapper: indstillinger, handler, lockouts, karakterer + "vis alts"
local btnDefs = {{"bSettings", 86}, {"bTrades", 76}, {"bLocks", 82}, {"bChars", 96}}
local lbtn, bx = {}, 18
for i, d in ipairs(btnDefs) do
  local b = pill(L, nil, d[2], 22); b:SetPoint("TOPLEFT", bx, -102); label(b.text, d[1])
  bx = bx + d[2] + 6; lbtn[i] = b
end
local altsBtn = CreateFrame("CheckButton", nil, L)
altsBtn:SetSize(32, 18); altsBtn:SetPoint("TOPRIGHT", -18, -104)
local altsOff = altsBtn:CreateTexture(nil, "ARTWORK"); altsOff:SetAllPoints(); altsOff:SetTexture(TEX .. "ToggleOff"); altsOff:SetTexCoord(0, 1, 0, 36 / 64)
local altsOn = altsBtn:CreateTexture(nil, "ARTWORK"); altsOn:SetAllPoints(); altsOn:SetTexture(TEX .. "ToggleOn"); altsOn:SetTexCoord(0, 1, 0, 36 / 64)
local altsT = fs(L, F_SEMI, 12); altsT:SetPoint("RIGHT", altsBtn, "LEFT", -8, 0); altsT:SetTextColor(0.85, 0.87, 0.92); label(altsT, "showAlts")
altsBtn:SetScript("OnClick", function() DB.logAlts = not DB.logAlts; L.offset = 0; L.refresh() end)
local bgBtn = CreateFrame("CheckButton", nil, L)
bgBtn:SetSize(32, 18); bgBtn:SetPoint("RIGHT", altsT, "LEFT", -18, 0)
local bgOff = bgBtn:CreateTexture(nil, "ARTWORK"); bgOff:SetAllPoints(); bgOff:SetTexture(TEX .. "ToggleOff"); bgOff:SetTexCoord(0, 1, 0, 36 / 64)
local bgOn = bgBtn:CreateTexture(nil, "ARTWORK"); bgOn:SetAllPoints(); bgOn:SetTexture(TEX .. "ToggleOn"); bgOn:SetTexCoord(0, 1, 0, 36 / 64)
local bgT = fs(L, F_SEMI, 12); bgT:SetPoint("RIGHT", bgBtn, "LEFT", -8, 0); bgT:SetTextColor(0.85, 0.87, 0.92); label(bgT, "showBG")
bgBtn:SetScript("OnClick", function() DB.logBG = not DB.logBG; L.offset = 0; L.refresh(); refresh() end)

-- forklaring af farverne
do
  local x = 18
  for _, d in ipairs({{AGE_HOUR, "legHour"}, {AGE_DAY, "legDay"}, {AGE_OLD, "legOld"}, {RAIDC, "legRaid"}, {BGC, "legBG"}, {ALTC, "legAlts"}}) do
    local dot = L:CreateTexture(nil, "ARTWORK"); dot:SetSize(7, 7); dot:SetTexture(TEX .. "Dot"); dot:SetPoint("TOPLEFT", x, -138)
    dot:SetVertexColor(d[1][1], d[1][2], d[1][3])
    local t = fs(L, F_SEMI, 10); t:SetPoint("LEFT", dot, "RIGHT", 5, 0); t:SetTextColor(0.62, 0.65, 0.7); label(t, d[2])
    x = x + 100
  end
end
local sep = L:CreateTexture(nil, "ARTWORK"); sep:SetPoint("TOPLEFT", 14, -152); sep:SetPoint("TOPRIGHT", -14, -152); sep:SetHeight(1); sep:SetColorTexture(1, 1, 1, 0.06)

local function ageColor(r)
  if not r.leave or now() - r.enter < HOUR then return AGE_HOUR end
  if now() - r.enter < DAY then return AGE_DAY end
  return AGE_OLD
end

L.refresh = function()
  if not (DB and L:IsShown()) then return end
  -- tallene
  local hN, dN, nextAt = lockout()
  local hl, dl = DB.hourLimit or 5, DB.dayLimit or 0
  local hc = limitColor(hN, hl)
  stats[1].v:SetText(hl > 0 and (hN .. " / " .. hl) or tostring(hN)); col(stats[1].v, hc); bar(stats[1], hl > 0 and hN / hl or nil, hc)
  stats[2].v:SetText(dl > 0 and (dN .. " / " .. dl) or tostring(dN)); col(stats[2].v, dl > 0 and limitColor(dN, dl) or WHITE)
  bar(stats[2], dl > 0 and dN / dl or nil, limitColor(dN, dl))
  local nt, nc = nextFreeText(nextAt)
  stats[3].v:SetText(nt); col(stats[3].v, nc); bar(stats[3], nil)
  altsOn:SetShown(DB.logAlts and true or false); altsOff:SetShown(not DB.logAlts)
  bgOn:SetShown(DB.logBG and true or false); bgOff:SetShown(not DB.logBG)
  -- runs
  local items = {}
  for i, r in ipairs(charRuns(DB.logAlts)) do
    local mine = r.char == charKey()
    local raid = r.kind == "raid"
    local bg = r.kind == "pvp"
    local ac = ageColor(r)
    local name = (r.name or "?")
    if raid then name = name .. "  " .. hex(RAIDC) .. "R|r" end
    if bg then
      name = name .. "  " .. hex(BGC) .. "BG|r"
      if r.result then name = name .. "  " .. hex(r.result == "won" and GREEN or RED) .. T(r.result) .. "|r" end
    end
    if not mine then name = classHex(DB.chars[r.char] and DB.chars[r.char].class) .. shortName(r.char) .. "|r  " .. name end
    local when = r.leave and string.format(T("leftAgo"), dur(now() - r.leave)) or T("stillIn")
    local left, kind = lockLeft(r)
    items[#items + 1] = {
      dot = (not mine) and ALTC or (raid and RAIDC or (bg and BGC or ac)),
      cells = { tostring(i), name, when, dur(runTime(r)), bg and (num(r.honor) .. " H") or num(r.xp), money(r.money), left and dur(left) or "" },
      colors = { GREY, {0.88, 0.9, 0.94}, ac, WHITE, bg and BGC or BLUE, GOLD, left and (kind == "h" and ORANGE or GOLD) or GREY },
      tip = function(self) runTip(self, r) end,
      click = function(_, btn)
        if btn == "RightButton" and IsShiftKeyDown() then
          if r == cur then cur = nil; DB.charCur[charKey()] = nil end
          removeRun(r); say(string.format(T("deleted"), (r.name or "?") .. " (" .. date("%d/%m %H:%M", r.enter) .. ")"))
          GameTooltip:Hide(); L.refresh(); refresh()
        elseif btn == "LeftButton" and postStats then
          postStats(r)
        end
      end,
    }
  end
  L.fill(items)
end

-- ---------- handelsloggen ----------
local TWin = listWindow("InstanceETATrades", "tradesTitle", 560, 420, -50, 14, {
  {18, 92, "LEFT", "colDate"}, {114, 120, "LEFT", "colWho"}, {238, 90, "RIGHT", "colGave"}, {332, 90, "RIGHT", "colGot"}, {430, 112, "LEFT", "colWhere"} })
label(TWin.empty, "noTrades"); label(TWin.foot, "tradesFoot")
TWin.refresh = function()
  if not (DB and TWin:IsShown()) then return end
  local items = {}
  for _, x in ipairs(DB.trades) do
    items[#items + 1] = {
      dot = (x.char ~= charKey()) and ALTC or nil,
      cells = { date("%d/%m %H:%M", x.at), x.who or "?", (x.give or 0) > 0 and money(x.give) or "", (x.get or 0) > 0 and money(x.get) or "",
        (x.char ~= charKey() and (shortName(x.char) .. ", ") or "") .. (x.inst or x.zone or "") },
      colors = { GREY, WHITE, ORANGE, GREEN, GREY },
    }
  end
  TWin.fill(items)
end

-- ---------- raid lockouts for alle karakterer ----------
local KWin = listWindow("InstanceETALockouts", "locksTitle", 460, 340, -50, 10, {
  {18, 130, "LEFT", "colChar"}, {152, 170, "LEFT", "colInst"}, {326, 116, "RIGHT", "colResets"} })
label(KWin.empty, "noLocks")
KWin.refresh = function()
  if not (DB and KWin:IsShown()) then return end
  local items = {}
  local keys = {}
  for key in pairs(DB.chars) do keys[#keys + 1] = key end
  table.sort(keys)
  for _, key in ipairs(keys) do
    local c = DB.chars[key]
    for _, s in ipairs(c.saved or {}) do
      if s.resetAt and s.resetAt > now() then
        items[#items + 1] = { dot = RAIDC, cells = { classHex(c.class) .. shortName(key) .. "|r", s.name, dur(s.resetAt - now()) },
          colors = { WHITE, WHITE, GREY } }
      end
    end
  end
  KWin.fill(items)
end

-- ---------- dine karakterer: rested XP, guld, holdbarhed, tasker, erhverv ----------
local CWin = listWindow("InstanceETAChars", "charsTitle", 780, 440, -50, 14, {
  {18, 128, "LEFT", "colChar"}, {150, 40, "RIGHT", "colLevel"}, {194, 108, "RIGHT", "colRested"}, {306, 92, "RIGHT", "colGoldC"},
  {402, 70, "RIGHT", "colDur"}, {476, 60, "RIGHT", "colBags"}, {540, 84, "RIGHT", "colSeen"}, {630, 134, "RIGHT", "colCD"} })
-- den cooldown der er klar, eller den der bliver klar foerst
local function cdSummary(c)
  local best
  for _, x in ipairs(c.cds or {}) do
    if x.readyAt <= now() then return T("cdReady") .. ": " .. x.name, GREEN end
    if not best or x.readyAt < best.readyAt then best = x end
  end
  if best then return best.name .. " " .. dur(best.readyAt - now()), GREY end
  return "", GREY
end
local function restedNow(c)
  -- rested XP vokser mens du er logget ud: 5% af et level pr. 8 timer paa et kro/i en by, ellers en fjerdedel. Hoejst 150%.
  if not c.max or c.max <= 0 or (c.level or 0) >= (MAX_PLAYER_LEVEL or 60) then return nil end
  local r = c.rested or 0
  if c.key ~= charKey() and c.seen then
    local rate = 0.05 * c.max / (8 * HOUR) * (c.resting and 1 or 0.25)
    r = r + (now() - c.seen) * rate
  end
  return math.min(r, 1.5 * c.max)
end
CWin.refresh = function()
  if not (DB and CWin:IsShown()) then return end
  local keys, total = {}, 0
  for key, c in pairs(DB.chars) do c.key = key; keys[#keys + 1] = key; total = total + (c.money or 0) end
  table.sort(keys, function(a, b) return (DB.chars[a].level or 0) > (DB.chars[b].level or 0) or ((DB.chars[a].level or 0) == (DB.chars[b].level or 0) and a < b) end)
  local items = {}
  for _, key in ipairs(keys) do
    local c = DB.chars[key]
    local rn = restedNow(c)
    local rested = rn and string.format("%d%%  ·  %.1f", math.floor(rn / c.max * 100 + 0.5), rn / c.max * 20) or "-"
    local online = key == charKey()
    local cdText, cdCol = cdSummary(c)
    items[#items + 1] = {
      dot = c.resting and GREEN or GREY,
      click = function(_, btn)
        if btn ~= "RightButton" or not IsShiftKeyDown() then return end
        if online then say(T("cantRemove")); return end
        local n = 0
        for i = #DB.runs, 1, -1 do if DB.runs[i].char == key then table.remove(DB.runs, i); n = n + 1 end end
        DB.chars[key] = nil
        say(string.format(T("removed"), key, n))
        GameTooltip:Hide(); L.refresh(); CWin.refresh(); refresh()
      end,
      cells = { classHex(c.class) .. shortName(key) .. "|r", tostring(c.level or "?"), rested, money(c.money or 0),
        c.dur and (c.dur .. "%") or "", c.bags and tostring(c.bags) or "", online and T("online") or (c.seen and string.format(T("ago"), dur(now() - c.seen)) or ""), cdText },
      colors = { WHITE, WHITE, BLUE, GOLD, (c.dur and c.dur < 30) and RED or WHITE, (c.bags and c.bags < 4) and ORANGE or WHITE, online and GREEN or GREY, cdCol },
      tip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(key, 1, 0.82, 0.3)
        GameTooltip:AddDoubleLine(T("restedState"), T(c.resting and "resting" or "notResting"), 0.75, 0.78, 0.84, 1, 1, 1)
        if rn then GameTooltip:AddDoubleLine(T("colRested"), num(rn) .. " XP", 0.75, 0.78, 0.84, 0.62, 0.82, 1) end
        if c.profs and #c.profs > 0 then
          GameTooltip:AddLine(" "); GameTooltip:AddLine(T("profs"), 1, 0.82, 0.4)
          for _, p in ipairs(c.profs) do GameTooltip:AddDoubleLine(p.name, p.rank .. " / " .. p.max, 0.85, 0.87, 0.92, 1, 1, 1) end
        end
        if c.cds and #c.cds > 0 then
          GameTooltip:AddLine(" "); GameTooltip:AddLine(T("cds"), 1, 0.82, 0.4)
          for _, x in ipairs(c.cds) do
            local ready = x.readyAt <= now()
            GameTooltip:AddDoubleLine(x.name, ready and T("cdReady") or dur(x.readyAt - now()), 0.85, 0.87, 0.92, ready and 0.36 or 0.55, ready and 1 or 0.58, ready and 0.48 or 0.64)
          end
        end
        local any
        for _, s in ipairs(c.saved or {}) do
          if s.resetAt and s.resetAt > now() then
            if not any then GameTooltip:AddLine(" "); GameTooltip:AddLine(T("raidLocks"), 1, 0.82, 0.4); any = true end
            GameTooltip:AddDoubleLine(s.name, string.format(T("resetsIn"), dur(s.resetAt - now())), 0.85, 0.87, 0.92, 0.55, 0.58, 0.64)
          end
        end
        GameTooltip:Show()
      end,
    }
  end
  CWin.fill(items)
  CWin.foot:SetText(T("totalGold") .. ":  " .. money(total) .. "   |cff6b7280·   " .. T("charsFoot") .. "|r")
end

lbtn[1]:SetScript("OnClick", function() local s = _G.InstanceETASettings; s:SetShown(not s:IsShown()) end)
lbtn[2]:SetScript("OnClick", function() TWin:SetShown(not TWin:IsShown()) end)
lbtn[3]:SetScript("OnClick", function() KWin:SetShown(not KWin:IsShown()) end)
lbtn[4]:SetScript("OnClick", function() CWin:SetShown(not CWin:IsShown()) end)
logBtn:SetScript("OnClick", function() L:SetShown(not L:IsShown()) end)
local function refreshWindows() L.refresh(); TWin.refresh(); KWin.refresh(); CWin.refresh() end

-- ---------- indstillinger ----------
local S = CreateFrame("Frame", "InstanceETASettings", UIParent)
local SW, COL = 520, 260
S:SetSize(SW, 360); S:SetPoint("CENTER"); S:SetFrameStrata("HIGH"); S:Hide()
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
toggle(L0, -74, "compact", "hidden", true)  -- gemmes som DB.hidden, saa knappen viser det modsatte
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
toggle(R0, -204, "resetMsg", "resetMsg")
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
  if IsShiftKeyDown and IsShiftKeyDown() then toggleWindow()
  elseif btn == "RightButton" then S:SetShown(not S:IsShown())
  else L:SetShown(not L:IsShown()) end
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
  refresh(); refreshWindows()
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
  if r.kind == "pvp" then
    if r.result then return string.format(T("bgLine"), r.name or "?", T(r.result):lower(), dur(runTime(r)), num(r.honor), r.hks or 0) end
    return string.format(T("bgLineNoRes"), r.name or "?", dur(runTime(r)), num(r.honor), r.hks or 0)
  end
  local xr = xpRate(r)
  local s = string.format(T("statsLine"), r.name or "?", dur(runTime(r)), num(r.xp), money(r.money, plain), r.kills or 0)
  if xr then s = s .. ", " .. num(xr) .. " XP" .. T("perHr") end
  local n = r.char == charKey() and runsToLevel(r)
  if n then s = s .. ", " .. n .. " " .. (n == 1 and T("runWord") or T("runsWord")) .. " > " .. ((UnitLevel("player") or 0) + 1) end
  return s
end

postStats = function(r)
  if IsInGroup and IsInGroup() and not (IsInRaid and IsInRaid()) then
    pcall(SendChatMessage, "InstanceETA: " .. statsText(r, true), "PARTY")
  else
    say(statsText(r))
  end
end

local function closeRun(quiet)
  if not cur then return end
  local r = cur
  r.leave = now()
  r.lvlOut = UnitLevel("player")
  r.died = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") or nil
  cur = nil; DB.charCur[charKey()] = nil
  wipe(seenZone)
  local active = (r.xp or 0) > 0 or (r.money or 0) > 0 or (r.kills or 0) > 0 or (r.honor or 0) > 0 or r.result
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
    if kind == "pvp" then
      say(string.format(T("bgRun"), name))
    elseif kind == "raid" and not DB.countRaids then
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
  if not inInst or (itype ~= "party" and itype ~= "raid" and itype ~= "pvp") then return nil end
  local name, _, _, _, _, _, _, mapID = GetInstanceInfo()
  if secret(name) then name = nil end
  return name or (GetRealZoneText and GetRealZoneText()) or "?", mapID, itype
end

-- ---------- samme instance som sidst? ----------
-- Alle mobs i en instance, og alle de spells du kaster derinde, har instancens zone-id i deres GUID
-- ("Creature-0-server-kort-ZONE-npc-..." og "Cast-3-server-kort-ZONE-spell-..."). Zone-id'et skifter, naar instancen nulstilles.
-- Vi gemmer det foerste zone-id vi ser i en run. Ser vi det samme zone-id i din forrige run i samme instance, er det den samme,
-- og de to runs laegges sammen. Zone-id'et tages kun fra mobs du kan angribe (ikke kaeledyr og pets) og fra dine egne spells.

-- laeg run b (den nye) ind i run a (den gamle), og fortsaet a
local function mergeInto(a, b)
  a.t = (a.t or 0) + (b.t or 0)
  a.xp = (a.xp or 0) + (b.xp or 0)
  a.money = (a.money or 0) + (b.money or 0)
  a.kills = (a.kills or 0) + (b.kills or 0)
  for k, v in pairs(b.rep or {}) do a.rep = a.rep or {}; a.rep[k] = (a.rep[k] or 0) + v end
  for k, v in pairs(b.group or {}) do a.group = a.group or {}; a.group[k] = v end
  for _, x in ipairs(b.trades or {}) do a.trades = a.trades or {}; table.insert(a.trades, x) end
  a.zone = a.zone or b.zone
  removeRun(b)
  removeRun(a); table.insert(DB.runs, 1, a)  -- op foerst i loggen igen
  a.leave, a.died = nil, nil
  cur = a; DB.charCur[charKey()] = a.id
end

-- din forrige run i samme instance (kun den seneste, og kun hvis den ikke er nulstillet siden)
local function previousRun(r)
  for _, x in ipairs(DB.runs) do
    if x ~= r and x.char == r.char then
      if x.map == r.map and not x.reset and x.leave and now() - x.enter < DAY then return x end
      if x.map ~= r.map then return nil end  -- du har vaeret i en anden instance siden
    end
  end
end

local function setZone(zone)
  if not cur or cur.kind == "pvp" or not zone or zone == "0" or cur.zone then return end
  cur.zone = zone
  local prev = previousRun(cur)
  if prev and prev.zone == zone then
    mergeInto(prev, cur)
    say(T("merged"))
    refresh(); refreshWindows()
  end
end

local function zoneOf(guid)
  if not guid or secret(guid) or type(guid) ~= "string" then return nil end
  return guid:match("^Creature%-%d+%-%d+%-%d+%-(%d+)%-") or guid:match("^Vehicle%-%d+%-%d+%-%d+%-(%d+)%-")
    or guid:match("^Cast%-%d+%-%d+%-%d+%-(%d+)%-")
end

local function sawUnit(unit)
  if not cur or cur.zone or not unit or not UnitExists(unit) then return end
  local ok, attackable = pcall(UnitCanAttack, "player", unit)
  if not ok or secret(attackable) or not attackable then return end
  local pc = UnitPlayerControlled and UnitPlayerControlled(unit)
  if pc and not secret(pc) then return end
  setZone(zoneOf(UnitGUID(unit)))
end

local function scanPlates()
  if not cur or cur.zone then return end
  for i = 1, 40 do
    local u = "nameplate" .. i
    if UnitExists(u) then sawUnit(u); if not cur or cur.zone then return end end
  end
  sawUnit("target"); sawUnit("mouseover")
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
  -- doede du og loeb tilbage som ghost, eller gik du ud for faa minutter siden uden at vi naaede at se et zone-id,
  -- fortsaetter vi din forrige run. Zone-id'et tjekkes igen, saa snart vi ser en mob eller du kaster en spell.
  local tmp = { char = charKey(), map = mapID }
  local prev = kind ~= "pvp" and previousRun(tmp) or nil
  local ghost = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
  if prev and (ghost or prev.died or (not prev.zone and now() - prev.leave < 10 * 60)) then
    cur = prev; prev.leave, prev.died = nil, nil
    removeRun(prev); table.insert(DB.runs, 1, prev)
    DB.charCur[charKey()] = prev.id
    wipe(seenZone); lastXP = snapshotXP(); updateGroup()
    if not ghost and not prev.died then say(T("resumed")) end
    refresh(); refreshWindows()
  else
    openRun(name, mapID, kind)
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(2, scanPlates); C_Timer.After(6, scanPlates)
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
  P.hk = makePat(COMBATLOG_HONORGAIN, false)
  P.award = makePat(COMBATLOG_HONORAWARD, false)
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

-- honor: "X dies, honorable kill Rank: Y (Estimated Honor Points: 12)" og "You have been awarded 83 honor points."
local function onHonor(msg)
  if not cur or type(msg) ~= "string" or secret(msg) then return end
  local n = tonumber(msg:match("(%d+)%D*$"))
  if not n then return end
  cur.honor = (cur.honor or 0) + n
  local p = pats()
  if p.hk and msg:match(p.hk) then cur.hks = (cur.hks or 0) + 1
  elseif not p.hk and not (p.award and msg:match(p.award)) then cur.hks = (cur.hks or 0) + 1 end
end

-- hvem vandt? GetBattlefieldWinner giver 0 (Horde) eller 1 (Alliance), naar kampen er slut
local function onScore()
  if not cur or cur.kind ~= "pvp" or cur.result or not GetBattlefieldWinner then return end
  local ok, w = pcall(GetBattlefieldWinner)
  if not ok or w == nil or secret(w) then return end
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  local mine = (faction == "Horde" and 0) or (faction == "Alliance" and 1) or nil
  if mine == nil then return end
  cur.result = (w == mine) and "won" or "lost"
  refresh(); refreshWindows()
end

local resetQueue
local function onSystem(msg)
  if type(msg) ~= "string" or secret(msg) then return end
  local p = pats()
  local inst = p.reset and msg:match(p.reset)
  if inst then
    for _, r in ipairs(DB.runs) do
      if r.name == inst and r.leave then r.reset = true end
    end
    -- du nulstillede: sig det til gruppen, saa de ved at de kan gaa ind i en ny. Flere paa en gang samles i en besked.
    if DB.resetMsg and IsInGroup and IsInGroup() then
      resetQueue = resetQueue or {}
      table.insert(resetQueue, inst)
      if #resetQueue == 1 and C_Timer and C_Timer.After then
        C_Timer.After(1, function()
          local list = table.concat(resetQueue, ", ")
          resetQueue = nil
          local ch = (IsInRaid and IsInRaid()) and "RAID" or "PARTY"
          pcall(SendChatMessage, "InstanceETA: " .. string.format(T("resetSaid"), list), ch)
        end)
      end
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
        local x = { who = trade.who, give = trade.give or 0, get = trade.get or 0, at = now(), char = charKey(), inst = cur and cur.name, zone = GetRealZoneText and GetRealZoneText() }
        table.insert(DB.trades, 1, x)
        while #DB.trades > MAX_TRADES do table.remove(DB.trades) end
        if cur then cur.trades = cur.trades or {}; table.insert(cur.trades, x) end
        TWin.refresh()
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

-- ---------- dine karakterer ----------
local function updateChar()
  local key = charKey()
  DB.chars[key] = DB.chars[key] or {}
  local c = DB.chars[key]
  local _, class = UnitClass("player"); c.class = class
  c.level = UnitLevel("player"); c.seen = now()
  c.money = GetMoney and GetMoney() or c.money
  c.max = UnitXPMax("player"); c.xp = UnitXP("player")
  c.rested = GetXPExhaustion and GetXPExhaustion() or 0
  c.resting = IsResting and IsResting() and true or false
  -- holdbarhed: det laveste stykke udstyr i procent
  local low
  for slot = 1, 18 do
    local cv, mv
    if GetInventoryItemDurability then cv, mv = GetInventoryItemDurability(slot) end
    if cv and mv and mv > 0 and not secret(cv) then
      local pct = math.floor(cv / mv * 100 + 0.5)
      if not low or pct < low then low = pct end
    end
  end
  c.dur = low
  local free = 0
  for bag = 0, 4 do
    local n = (C_Container and C_Container.GetContainerNumFreeSlots and C_Container.GetContainerNumFreeSlots(bag))
      or (GetContainerNumFreeSlots and GetContainerNumFreeSlots(bag)) or 0
    free = free + (tonumber(n) or 0)
  end
  c.bags = free
end

local function spellName(id)
  local ok, n = pcall(function()
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    return GetSpellInfo and (GetSpellInfo(id))
  end)
  if ok and type(n) == "string" and not secret(n) then return n end
end

-- erhvervs cooldowns. GAET: samme spells og items som i classic (transmutes, Mooncloth, Salt Shaker).
local CD_SPELLS = {
  { key = "transmute", ids = {17187, 11479, 11480, 17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566}, label = "Transmute" },
  { key = "mooncloth", ids = {18560}, label = nil },
}
local CD_ITEMS = { { key = "salt", id = 15846, label = nil } }
local function spellCD(id)
  local start, d
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, info = pcall(C_Spell.GetSpellCooldown, id)
    if ok and type(info) == "table" then start, d = info.startTime, info.duration end
  elseif GetSpellCooldown then
    local ok, a, b = pcall(GetSpellCooldown, id); if ok then start, d = a, b end
  end
  if secret(start) or secret(d) then return nil end
  return start, d
end
local function knows(id)
  local ok, v = pcall(function() return (IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id)) end)
  return ok and v == true
end
local function updateCooldowns()
  local c = DB.chars[charKey()]
  if not c then return end
  local list = {}
  for _, def in ipairs(CD_SPELLS) do
    for _, id in ipairs(def.ids) do
      if knows(id) then
        local start, d = spellCD(id)
        local name = def.label or spellName(id) or def.key
        if start and d and d > 60 then list[#list + 1] = { name = name, readyAt = now() + (start + d - clock()) }
        else list[#list + 1] = { name = name, readyAt = 0 } end
        break  -- alle transmutes deler en cooldown
      end
    end
  end
  for _, def in ipairs(CD_ITEMS) do
    local has = GetItemCount and (GetItemCount(def.id) or 0) > 0
    if has then
      local start, d
      local getCD = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
      if getCD then local ok, a, b = pcall(getCD, def.id); if ok then start, d = a, b end end
      local name = def.label or (GetItemInfo and GetItemInfo(def.id)) or "Salt Shaker"
      if start and d and not secret(d) and d > 60 then list[#list + 1] = { name = name, readyAt = now() + (start + d - clock()) }
      else list[#list + 1] = { name = name, readyAt = 0 } end
    end
  end
  c.cds = list
end

-- erhverv fra skill-listen (GAET: overskrifterne hedder "Professions" og "Secondary Skills", eller spillets egne oversaettelser)
local function updateProfs()
  local c = DB.chars[charKey()]
  if not c or not GetNumSkillLines then return end
  local heads = { [TRADE_SKILLS or "Professions"] = true, [SECONDARY_SKILLS or "Secondary Skills"] = true, Professions = true, ["Secondary Skills"] = true }
  local list, head = {}, nil
  for i = 1, GetNumSkillLines() do
    local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
    if isHeader then head = name
    elseif name and heads[head or ""] and rank and maxRank and maxRank > 1 then
      list[#list + 1] = { name = name, rank = rank, max = maxRank }
    end
  end
  c.profs = list
end

-- ---------- haendelser ----------
local cdPending = false
local E = CreateFrame("Frame")
for _, ev in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_LOGOUT", "PLAYER_XP_UPDATE",
  "PLAYER_LEVEL_UP", "CHAT_MSG_MONEY", "CHAT_MSG_COMBAT_FACTION_CHANGE", "CHAT_MSG_COMBAT_XP_GAIN", "CHAT_MSG_SYSTEM",
  "CHAT_MSG_COMBAT_HONOR_GAIN", "UPDATE_BATTLEFIELD_SCORE", "UPDATE_BATTLEFIELD_STATUS",
  "GROUP_ROSTER_UPDATE", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "UPDATE_INSTANCE_INFO",
  "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_START",
  "PLAYER_MONEY", "SPELL_UPDATE_COOLDOWN", "BAG_UPDATE_COOLDOWN", "PLAYER_UPDATE_RESTING", "UPDATE_EXHAUSTION", "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "SKILL_LINES_CHANGED",
  "TRADE_SHOW", "TRADE_CLOSED", "TRADE_REQUEST_CANCEL", "TRADE_MONEY_CHANGED", "TRADE_ACCEPT_UPDATE", "PLAYER_TRADE_MONEY", "UI_INFO_MESSAGE"}) do
  pcall(E.RegisterEvent, E, ev)
end

E:SetScript("OnEvent", function(_, event, a1, a2)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    InstanceETADB = InstanceETADB or {}
    DB = InstanceETADB
    for k, v in pairs(defaults) do if DB[k] == nil then DB[k] = v end end
    -- 0.2: loggen er hovedvinduet som i Nova, det lille vindue er valgfrit
    if (DB.ver or 1) < 2 then DB.hidden = true; DB.ver = 2 end
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
    updateChar(); updateProfs(); updateCooldowns()
    if RequestRaidInfo then pcall(RequestRaidInfo) end
    checkZone(a1, a2)
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    checkZone(false, false)
  elseif event == "PLAYER_LOGOUT" then
    -- husk hvilken run du var i, saa et reload eller login inde i instancen fortsaetter den
    DB.charCur[charKey()] = cur and cur.id or nil
    updateChar()
  elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
    onXP()
    local c = DB.chars[charKey()]; if c then c.level = UnitLevel("player") end
  elseif event == "CHAT_MSG_MONEY" then onMoneyMsg(a1)
  elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then onRep(a1)
  elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then onXPMsg(a1)
  elseif event == "CHAT_MSG_SYSTEM" then onSystem(a1)
  elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then onHonor(a1)
  elseif event == "UPDATE_BATTLEFIELD_SCORE" or event == "UPDATE_BATTLEFIELD_STATUS" then onScore()
  elseif event == "GROUP_ROSTER_UPDATE" then updateGroup()
  elseif event == "PLAYER_TARGET_CHANGED" then sawUnit("target")
  elseif event == "UPDATE_MOUSEOVER_UNIT" then sawUnit("mouseover")
  elseif event == "NAME_PLATE_UNIT_ADDED" then sawUnit(a1)
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_START" then
    if cur and not cur.zone and a1 == "player" then setZone(zoneOf(a2)) end
  elseif event == "UPDATE_INSTANCE_INFO" then saveLockouts(); KWin.refresh()
  elseif event == "SKILL_LINES_CHANGED" then updateProfs(); updateCooldowns()
  elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
    -- kommer tit, saa vi venter lidt og opdaterer en gang
    if not cdPending and C_Timer and C_Timer.After then
      cdPending = true
      C_Timer.After(2, function() cdPending = false; updateCooldowns() end)
    end
  elseif event == "PLAYER_MONEY" or event == "PLAYER_UPDATE_RESTING" or event == "UPDATE_EXHAUSTION" or event == "BAG_UPDATE_DELAYED"
    or event == "UPDATE_INVENTORY_DURABILITY" then updateChar()
  else onTrade(event, a1, a2) end
end)

-- hvert sekund: tid i instancen, og sig til naar en ny instance er fri
local wasLocked = false
local function tick(el)
  if not DB then return end
  if cur then
    cur.t = (cur.t or 0) + el
    if not cur.zone then scanPlates() end
  end
  local _, _, nextAt = lockout()
  local locked = nextAt ~= nil
  if wasLocked and not locked and DB.freeMsg then
    local hN = lockout()
    toast.show(T("freeToast"), string.format(T("freeToastSub"), hN, DB.hourLimit or 5))
    say(T("freeToast") .. ".")
  end
  wasLocked = locked
  refresh()
  refreshWindows()
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
  elseif msg == "trades" or msg == "handler" then TWin:SetShown(not TWin:IsShown())
  elseif msg == "chars" or msg == "karakterer" then CWin:SetShown(not CWin:IsShown())
  elseif msg == "lockouts" then KWin:SetShown(not KWin:IsShown())
  elseif msg == "compact" or msg == "lille" then toggleWindow()
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
    L:SetShown(not L:IsShown())
  end
end
