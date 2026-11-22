local addon = ...
local pack = "shendralas"
if not Polestar.RegisterPack({
    addon = addon,
    id = pack,
    title = "辛德拉",
    author = "Codex",
    version = "0.1.3",
    format = 5,
    license = "MIT",
    source = "WoW Forever quest observations and QuestieDB 1.1.1. See SOURCES.txt.",
}) then return end

local zone, desolace, barrens = 2652, 1443, 1413
local western = {zone, 43.66, 34.36}
local eastern = {zone, 73.27, 23.13}
local temple = {zone, 47, 78}
local sieve = {zone, 46.09, 78.14}
local garden = {zone, 69.66, 71.78}
local retreat = {zone, 72.73, 31.17}
local maraudon = {desolace, 29.2, 62.5}
local razorfen = {barrens, 50.9, 92.9}
local gelkisVillage = {desolace, 36.22, 79.25}

-- NPC records are ID, fallback name, UiMapID, x, y. Positional values use 0–100.
local mordent = {253471, "Mordent Evenshade", zone, 35.17, 46.61}
local kirandis = {254656, "Magister Kirandis", zone, 47.37, 76.46}
local vindael = {254717, "Vindael", zone, 42, 79.02}
local biraxas = {255486, "Historian Biraxas", zone, 46, 78.22}
local mithera = {254578, "Mithera", zone, 53.32, 76.02}
local woodwyrd = {254674, "Woodwyrd", zone, 69.66, 71.78}
local kogthug = {253527, "Kog'thug the Brave", zone, 72.73, 31.17}
local quolga = {255678, "Quolga the Wise", zone, 58.15, 14.78}
local liranne = {255385, "Liranne", zone, 47.46, 65.63}
local warug = {5398, "Warug", desolace, 74.97, 68.16}
local orgrul = {253136, "Orgrul", zone, 35.71, 12.66}
local hagiak = {253851, "Hagiak", zone, 59.27, 53.93}
local restoredKhan = {254357, "Khan Jehn", desolace, 73.83, 73.89}
local uthek = {5397, "Uthek the Wise", desolace, 36.22, 79.25}
local nerlokh = {253177, "Nerlokh", zone, 20.93, 22.68}
local rokren = {254040, "Rokren", zone, 34.13, 77.94}

-- English fallback labels preserve the journal's names where the client has
-- yet to supply a localized name. Step titles and instructions are in zhCN.
-- Prerequisite arrays contain immediate all-of requirements.
local quests = {
    [92914] = {"Strange Pylons", 43},
    [96010] = {"Fragments of the Pylons", 41, {92914}},
    [96018] = {"Powering the Pylons", 43, {96010}},
    [93016] = {"A Brief History Lesson", 43, {96018}},
    [93394] = {"Meeting the Magister", 43, {93016}},
    [93450] = {"Phantasmal Problems", 42, {93394}},
    [93546] = {"Spectral Iron Ore", 42, {93450}},
    [96060] = {"Tempered Expectations", 42, {93546}},
    [99257] = {"A Heart of Crystal", 43, {93394}},
    [99258] = {"Mana Mania", 43, {99257}},
    [93341] = {"Forlorn Gardens", 43, {93394}},
    [93362] = {"What They've Done to My Peonies", 43, {93341}},
    [93594] = {"Word of the Woods", 43, {93341}},
    [93568] = {"Partially Digested Collar", 45},
    [93574] = {"Corpsefeeder's Carapace", 45},
    [93609] = {"Forlorn Necklace", 45},
    [93644] = {"Tattered Journal", 45},
    [93404] = {"Rot and Regret", 49, {93594}},
    [93601] = {"Passing the Blame", 45, {93404}},
    [93604] = {"Agamaggan's Blood", 45, {93601}},
    [93606] = {"Not on Squealing Terms", 45, {93604}},
    [93034] = {"Valley of Bones", 38, {1373}},
    [93035] = {"Ravaging Ravagers", 38, {93034}},
    [93037] = {"Outing Outcasts", 40, {93034}},
    [93041] = {"Facing the Truth", 38, {93035, 93037}},
    [93044] = {"A Cleansing Cry", 38, {93041}},
    [93045] = {"Test Your Theory", 38, {93044}},
    [93058] = {"Saving Our Own", 42, {93045}},
    [93062] = {"Bone Burying", 42, {93045}},
    [93122] = {"Checking Things Out", 43, {93058, 93062}},
    [93125] = {"Going Home", 43},
    [93128] = {"Khan Jehn", 42, {93122}},
    [92841] = {"Valley of Bones", 40, {92743}},
    [92844] = {"Mountain of Bones", 42, {92841}},
    [92846] = {"Outcast Necromancers", 40, {92841}},
    [92847] = {"Corrupting Tears", 42, {92844, 92846}},
    [92873] = {"Proof of Concept", 41, {92847}},
    [92893] = {"No Mercy for the Weak", 42, {92873}},
    [92894] = {"Bone Raising", 40, {92873}},
    [93066] = {"Bristleback Retreat", 43, {92893, 92894}},
    [93072] = {"Long-Term Solutions", 43, {93066}},
    [93129] = {"Threat of Starvation", 43, {93066}},
    [93188] = {"Return to Orgrul", 43, {93072, 93129}},
    [93196] = {"Khan Jehn", 42, {93188}},
}

-- Include known ancestors so native skip propagation survives the engine's
-- recursive lookahead limit even at the end of the longer chains.
local function prerequisites(id, result, seen)
    local quest = quests[id]
    for _, parent in ipairs(quest and quest[3] or {}) do
        if not seen[parent] then
            seen[parent] = true
            result[#result + 1] = parent
            prerequisites(parent, result, seen)
        end
    end
end

local function point(goal, location)
    if location then
        goal.map, goal.x, goal.y = location[1], location[2], location[3]
    end
    return goal
end

local function endpoint(goal, npc)
    goal.npc, goal.npcName = npc[1], npc[2]
    goal.map, goal.x, goal.y = npc[3], npc[4], npc[5]
    return goal
end

local function accept(id, npc, optional)
    local quest = quests[id]
    local preAll = {}
    prerequisites(id, preAll, {})
    local goal = {
        t = "accept", quest = id, title = quest[1], qlvl = quest[2],
        minLevel = 35, preAll = preAll, optional = optional,
    }
    return npc and endpoint(goal, npc) or goal
end

local function turnin(id, npc)
    return endpoint({t = "turnin", quest = id, title = quests[id][1]}, npc)
end

local function complete(id, location, note)
    return point({t = "complete", quest = id, title = quests[id][1], note = note}, location)
end

local function collect(id, item, name, oi, location, note)
    return point({t = "collect", quest = id, item = item, itemName = name, oi = oi, count = 1, note = note}, location)
end

local function kill(id, npc, name, oi, count, location, note)
    return point({t = "kill", quest = id, npc = npc, target = name, oi = oi, count = count, note = note}, location)
end

local function step(title, ...)
    return {title = title, goals = {...}}
end

local function readyTurnin(title, id, npc)
    local row = step(title, turnin(id, npc))
    row.when = {{k = "complete", q = id}}
    return row
end

local function instruction(title, note, action)
    return {title = title, note = note, goals = {{t = "task", text = action or "读完后勾选，开始路线"}}}
end

local function add(steps, ...)
    for _, entry in ipairs({...}) do
        steps[#steps + 1] = entry
    end
end

-- Rebuild shared steps per registration. Polestar may attach per-guide data to
-- the goal tables. The optional journal hand-in belongs only to the outdoor run.
local repairSupplies = {}
local function crystals(index, x, y)
    local goal = point({t = "collect", item = 255667, itemName = "Coalesced Mana Crystal",
        count = 4, npc = 264149, npcName = "Unstable Mana Rift",
        note = "对道路上漂浮的不稳定法力裂隙使用法力筛，每座未修的塔消耗四枚水晶。"}, {zone, x, y})
    local row = step(index == 2 and "西塔前 · 收集四枚水晶" or "去东塔途中 · 补齐四枚水晶", goal)
    if index == 2 then
        add(row.goals, point({t = "goto", text = "西塔南侧道路", r = 10,
            note = "沿南侧道路接近。守卫挡路时逐只拉下来，从塔西侧修理，避开东侧的精英巡逻。"}, {zone, 43.9, 37.0}))
    end
    repairSupplies[row] = index
    return row
end

local function approach(outdoor)
    local start = point(accept(92914), western)
    start.object, start.objName = 577959, "Shen'dralar Pylon"
    start.note = "西塔附近的谷口和道路有巡逻精英：45级食腐者（Corpsefeeder）和43级初生的水晶塔守卫（Nascent Pylon Protector）。马格拉姆死灵可汗也是45级精英，是否主动攻击取决于你与马格拉姆的声望。等巡逻走开再靠近西塔。"
    local steps = {
        step("从凄凉之地南下，接西水晶塔任务", start),
        step("调查西塔",
            point({t = "interact", quest = 92914, oi = 1, object = 577959, objName = "Shen'dralar Pylon",
                note = "接任务后看西塔探索是否已计入。"}, western)),
        step("调查棘背营地东塔",
            point({t = "interact", quest = 92914, oi = 2, object = 577960, objName = "Shen'dralar Pylon",
                note = "从棘背营地西侧靠近东塔，沿路留意45级食腐者巡逻。营地南侧有43级精英 Kog'thug 和护卫，绕开南侧。"}, eastern)),
        step("下到主殿底层找神殿塔",
            complete(92914, temple, "从东塔向南去神殿时走在野猪人护卫西侧。主殿守卫是中立的，可以绕过。神殿塔约在 47, 78 的主殿底层，按日志确认三塔已调查。")),
        step("向莫丹特回报", turnin(92914, mordent)),
        step("接取寻找水晶塔碎片", accept(96010, mordent)),
        step("在马格拉姆村找水晶塔碎片",
            collect(96010, 255656, "Pylon Fragment", 1, {desolace, 67.9, 78.9},
                "玩家记录在凄凉之地 67.9, 78.9。马格拉姆守卫是否敌对取决于部族声望。若敌对，避开守卫，从村子外围靠近碎片。")),
        step("在吉尔吉斯村找水晶塔残片",
            collect(96010, 255657, "Pylon Shard", 2, {desolace, 36.2, 85.9},
                "玩家记录在凄凉之地 36.2, 85.9。吉尔吉斯守卫是否敌对取决于部族声望，敌对时从外围靠近。确认两项都亮起，再回辛德拉。")),
        step("回辛德拉交齐两块碎片", turnin(96010, mordent)),
        step("从莫丹特接修塔任务", accept(96018, mordent)),
        step("到神殿上层拿法力筛",
            collect(96018, 255662, "Mana Sieve", 1, sieve, "法力筛在神殿上层约 46.1, 78.1。")),
        crystals(2, 46.32, 42.94),
        step("修西水晶塔",
            point({t = "use", quest = 96018, oi = 2, item = 271882, itemName = "Pile of Pylon Parts",
                note = "从西侧贴近塔，使用背包里的修塔零件，消耗四枚水晶。沿谷道东行时再用法力筛补齐下一塔的四枚。"}, western)),
        crystals(3, 45.32, 37.82),
        step("修东水晶塔",
            point({t = "use", quest = 96018, oi = 3, item = 271882, itemName = "Pile of Pylon Parts",
                note = "到东塔旁再次使用修塔零件，耗 4 枚。水晶不足时，沿路对不稳定法力裂隙使用法力筛。"}, eastern)),
        step("返回莫丹特，交付修塔", turnin(96018, mordent)),
    }
    if outdoor then
        add(steps, step("如果已接破旧日记，在此顺手交", turnin(93644, mordent)))
    end
    add(steps,
        step("向莫丹特接取历史课", accept(93016, mordent)),
        step("听莫丹特讲完水晶塔的历史",
            endpoint(complete(93016, nil, "再与莫丹特交谈，选择对话听他讲完，等任务日志显示可以交付。"), mordent)),
        readyTurnin("向莫丹特交付历史课", 93016, mordent),
        step("接取会见魔导师", accept(93394, mordent)),
        step("进神殿找魔导师基兰迪斯", turnin(93394, kirandis)))
    return steps
end

local entryNote = "联盟从尼耶尔前哨站往南，沿凄凉之地东侧道路到马格拉姆村附近进白骨之谷。部落从葬影村沿凄凉之地南缘向东，或从菲拉斯莫沙彻营地沿路北上进凄凉之地，再由白骨之谷进图。已在辛德拉可直接去西水晶塔 43.7, 34.4。"

local manaGuideHint = "组好队后可用 /polestar guides 搜「法力狂潮」，在新标签页打开组队指南，完成后切回主线。"

local main = {instruction("辛德拉 · 野外主线",
    "建议 38–45 级。" .. entryNote .. "半人马支线可按已选部族另开，组好队后可切换玛拉顿专项。日记、项圈、项链和外壳拾到后手动右键接取。想暂缓可右键任务行跳过，之后恢复。")}
for _, entry in ipairs(approach(true)) do main[#main + 1] = entry end
add(main,
    step("在神殿接花园、水晶心脏与可选武器线",
        accept(93341, mithera), accept(99257, biraxas), accept(93450, vindael, true), {t = "note",
        text = "无法从 Vindael 接任务时，可在精英任务完成后再问。有玩家报告交精英后出现武器任务，当前资料未确认这是硬前置。硬核角色请跳过武器线。"}),
    step("带未完成的剑进入灵魂界（可选）",
        complete(93450, nil, "先确认身上有铁砧旁取得的未完成长剑。实服玩家通过角色死亡并释放灵魂完成转换，复活后回 Vindael。硬核角色跳过这项，后两件武器任务也会暂缓。")),
    step("寻找损坏的水晶塔守卫",
        complete(99257, western, "箭头指西塔搜索区域。西塔和东塔附近找 Decrepit Pylon Protector，击杀后拾取耗尽的水晶心脏。")),
    step("去花园的小神龛检查空底座",
        complete(93341, garden, "箭头指花园的 Woodwyrd 一带。找小神龛里的空底座，点完核对任务追踪。")),
    step("回神殿交底座调查，接下一轮", turnin(93341, mithera)),
    step("接植物清理与寻找 Woodwyrd", accept(93362, mithera), accept(93594, mithera)),
    step("交幽灵之刃并接矿石任务", turnin(93450, vindael), accept(93546, vindael)),
    step("交水晶心脏，可顺手接法力狂潮",
        turnin(99257, biraxas), accept(99258, biraxas, true), {t = "note",
        text = "可以现在找比拉克萨斯接任务，留在日志里继续主线。也可以以后再来接。" .. manaGuideHint}),
    step("如果已接项圈或项链，顺路交给神殿 NPC",
        turnin(93568, liranne), turnin(93609, mithera)),
    step("到花园清理三种植物",
        kill(93362, 254566, "Rowdy Rose", 1, 4, garden, "花园搜索点"),
        kill(93362, 254567, "Terrible Tulip", 2, 4, garden, "花园搜索点"),
        kill(93362, 254572, "Malevolent Marigold", 3, 20, garden, "花园搜索点")),
    step("在花园找到 Woodwyrd", turnin(93594, woodwyrd)),
    step("沿途找幽灵铁矿脉",
        complete(93546, nil, "在辛德拉找 Spectral Iron Deposit，收齐 10 份。矿脉精确分布待验证，留意游戏任务地图。")),
    step("回神殿交植物与矿石", turnin(93362, mithera), turnin(93546, vindael)),
    step("接武器试炼", accept(96060, vindael)),
    step("对辛德拉野生动物使用幽灵之刃",
        complete(96060, nil, "用任务提供的幽灵之刃完成 8 次处决。跟随任务日志提示，注意先削弱目标。")),
    step("回 Vindael 选武器", turnin(96060, vindael)),
    step("如果已接食腐者外壳，交给野猪人",
        turnin(93574, kogthug)),
    instruction("接续玛拉顿或半人马支线",
        "在指南列表搜索「辛德拉」可开玛拉顿与剃刀高地专项，或打开你已选的半人马线路。" .. manaGuideHint,
        "勾选结束野外主线")
)

local manaMania = {
    step("找比拉克萨斯接法力狂潮", accept(99258, biraxas)),
    step("组队在不稳定法力裂隙召唤并击杀精英",
        kill(99258, 276401, "Nascent Pylon Protector", 1, 1, nil,
            "组队后在不稳定法力裂隙旁使用任务给的耗尽水晶心脏，击杀召出的精英。")),
    readyTurnin("回神殿找比拉克萨斯交法力狂潮", 99258, biraxas),
}

local gelkis = {
    instruction("吉尔吉斯 · 出发前",
        "选择已支持的部族。先在凄凉之地的智者乌泰克完成「盎格库尔」(1373)。任务目标列出吉尔吉斯尊敬。进线会降低马格拉姆声望（已记录的谷口任务 −625、清理亡灵 −2500）。部分采集记录只见部落角色完成后半段，以游戏实际提供为准。两条部族线都可参考 Polestar 自带的半人马声望指南。"),
    step("在凄凉之地接白骨之谷", accept(93034, uthek)),
    step("到谷口向 Nerlokh 回报", turnin(93034, nerlokh)),
    step("接清理亡灵与搜寻法袍", accept(93035, nerlokh), accept(93037, nerlokh)),
    step("在白骨之谷清亡灵与流亡者",
        kill(93035, 11561, "Undead Ravager", 1, 6, {desolace, 59.59, 88.15}, "谷内搜索点"),
        complete(93037, nil, "在谷里打较弱的流亡者死灵法师，取一件死灵法袍。")),
    step("回谷口交两项", turnin(93035, nerlokh), turnin(93037, nerlokh)),
    step("接调查真相", accept(93041, nerlokh)),
    step("取得受诅咒的颅骨与吉尔吉斯法袍",
        complete(93041, nil, "Nerlokh 会给吉尔吉斯法袍。到谷里的巨型骨架附近找被诅咒的颅骨，带去凄凉之地交给乌泰克。")),
    step("在吉尔吉斯村交调查真相并接净化", turnin(93041, uthek), accept(93044, uthek)),
    step("进吉尔吉斯村内的洞找 Mulara",
        complete(93044, gelkisVillage, "指向村落入口区域。进村中央的洞，与 Mulara 交谈取 3 份塞拉德丝的泪水，再按日志返回。")),
    step("交泪水，接破除颅骨诅咒", turnin(93044, uthek), accept(93045, uthek)),
    step("去仪式地点破除诅咒",
        complete(93045, {desolace, 42, 82}, "去吉尔吉斯村东边池塘。拾取乌泰克的法杖，用任务给的德莱尼水晶强化，再对旁边骸骨堆上的颅骨使用法杖。坐标来自玩家记录。")),
    step("回谷口交任务，接救俘虏和安葬亡灵", turnin(93045, nerlokh),
        accept(93058, nerlokh), accept(93062, nerlokh)),
    step("沿白骨之谷解救俘虏并安葬亡灵",
        complete(93058, nil, "解救 5 名吉尔吉斯俘虏。"),
        complete(93062, nil, "使用任务道具，安葬 8 处未完成召唤的骸骨。")),
    step("回谷口交两项并接侦察", turnin(93058, nerlokh), turnin(93062, nerlokh), accept(93122, nerlokh)),
    step("调查马格拉姆前线和流亡者藏身处",
        complete(93122, {zone, 59.27, 53.93}, "箭头指马格拉姆前线；流亡者藏身处可参考 Rokren 一带，约 34.1, 77.9。到藏身处时可考虑接护送。"),
        accept(93125, rokren, true)),
    step("护送 Rokren 离开（可选）",
        complete(93125, nil, "就地接护送，跟着 Rokren，结束后回 Nerlokh 交。")),
    step("回谷口交侦察与已完成的护送", turnin(93122, nerlokh), turnin(93125, nerlokh)),
    step("接击杀可汗任务", accept(93128, nerlokh)),
    step("穿过凄凉之地，到马格拉姆村击杀可汗",
        kill(93128, 5601, "Khan Jehn", 1, 1, {desolace, 65.95, 80.41}, "查找可汗和卫兵，箭头为记录点。")),
    step("回吉尔吉斯村向乌泰克交任务", turnin(93128, uthek)),
}

local magram = {
    instruction("马格拉姆 · 出发前",
        "选择已支持的部族。先在凄凉之地完成 Warug 的 A Conqueror's Crown (92743)。任务目标列出马格拉姆尊敬。谷口任务有吉尔吉斯声望 −625 的记录。部分采集记录的马格拉姆谷口任务来自联盟角色，以游戏实际提供为准。两条部族线都可参考 Polestar 自带的半人马声望指南。"),
    step("向 Warug 接白骨之谷", accept(92841, warug)),
    step("在辛德拉北部谷口交任务", turnin(92841, orgrul)),
    step("同批接收集骸骨与击杀死灵法师", accept(92844, orgrul), accept(92846, orgrul)),
    step("刷骸骨和流亡者死灵法师",
        complete(92844, {desolace, 59.59, 88.15}, "白骨之谷搜索点。集齐 426 块 Gently Cursed Bone，可先打 Undead Ravager 并查看掉落。"),
        kill(92846, 11559, "Outcast Necromancer", 1, 6, {desolace, 63.44, 89.38}, "谷内搜索点")),
    step("交两项，接法杖材料", turnin(92844, orgrul), turnin(92846, orgrul), accept(92847, orgrul)),
    step("找石化树皮，再找 Warug 要灌注泪滴",
        complete(92847, nil, "在白骨之谷被诅咒的树附近找 3 份石化树皮；另去凄凉之地 75.0, 68.2 找 Warug 取 3 份灌注泪滴。")),
    step("交材料，接试验死灵法杖", turnin(92847, orgrul), accept(92873, orgrul)),
    step("在 Orgrul 附近山坡做召唤仪式",
        complete(92873, nil, "对坡上的拼装骸骨使用任务给的初级死灵法杖，按日志完成仪式并从结果中取得 426 块 Well Cursed Bone。")),
    step("交试验，接两项谷内后续", turnin(92873, orgrul), accept(92893, orgrul), accept(92894, orgrul)),
    step("在谷里击杀俘虏并完成复生",
        complete(92893, nil, "击杀 5 名吉尔吉斯俘虏。"),
        complete(92894, nil, "对谷中挣扎着钻出地面的亡灵用强化死灵法杖。")),
    step("交谷内两项，接野猪人营地任务", turnin(92893, orgrul), turnin(92894, orgrul), accept(93066, orgrul)),
    step("去东侧棘背营地击杀任务指定野猪人",
        complete(93066, retreat, "箭头指棘背营地参考点。核对任务日志列出的野猪人目标，做完去马格拉姆前线。")),
    step("在马格拉姆前线交任务，接两项后续", turnin(93066, hagiak),
        accept(93072, hagiak), accept(93129, hagiak)),
    step("处理流亡者并找被偷的补给",
        complete(93072, nil, "击杀 2 名流亡者斥候、6 名掠夺者、8 名死灵法师。"),
        complete(93129, {zone, 29.4, 69.9}, "与清理流亡者一起做，在流亡者藏身处找补给箱，坐标为搜索点。收齐 6 份被偷的补给。")),
    step("交两项后续，接向 Orgrul 回报", turnin(93072, hagiak), turnin(93129, hagiak), accept(93188, hagiak)),
    step("回谷口交任务并接复活可汗", turnin(93188, orgrul), accept(93196, orgrul)),
    step("去凄凉之地马格拉姆村湖中央的帐篷",
        complete(93196, {desolace, 73.83, 73.89}, "带 Orgrul 给的法杖，在湖中央帐篷的仪式处使用，复活可汗。")),
    step("与召出的可汗交谈交任务", turnin(93196, restoredKhan)),
}

local dungeon = {instruction("辛德拉 · 玛拉顿与剃刀高地",
    entryNote .. "从水晶塔开始补齐神殿与花园前置。已完成的前置会按游戏记录跳过。到 Woodwyrd 后先做玛拉顿的取水灭火，再开启剃刀高地的采血。玛拉顿要走到公主附近水池，建议组队。")}
for _, entry in ipairs(approach(false)) do dungeon[#dungeon + 1] = entry end
add(dungeon,
    step("从神殿的 Mithera 接调查花园", accept(93341, mithera)),
    step("检查花园小神龛的空底座",
        complete(93341, garden, "箭头指 Woodwyrd 一带。进入花园找小神龛，检查底座。")),
    step("交调查后接寻找 Woodwyrd", turnin(93341, mithera), accept(93594, mithera)),
    step("到花园找 Woodwyrd 并接取水",
        turnin(93594, woodwyrd), accept(93404, woodwyrd)),
    step("进玛拉顿取一瓶地歌之水",
        collect(93404, 258296, "Vial of Earth Song Water", 1, maraudon,
            "箭头指凄凉之地的玛拉顿外部入口。副本深处，瑟莱德丝公主下方的鳄鱼水池里找冒水的小泉，玩家记录在池东侧石桥下。")),
    step("回辛德拉给花园里的燃烧巨树灭火",
        complete(93404, garden, "在 Woodwyrd 身旁的燃烧巨树附近使用地歌之水，确认灭火目标也计入任务。")),
    step("交灭火任务并接追查野猪人", turnin(93404, woodwyrd), accept(93601, woodwyrd)),
    step("到棘背营地找野猪人并接采血", turnin(93601, kogthug), accept(93604, kogthug)),
    step("进剃刀高地取阿迦玛甘之血",
        collect(93604, 260237, "Virulent Blood of Agamaggan", 1, razorfen,
            "箭头指贫瘠之地南部的剃刀高地入口。玩家在副本尾段帐篷找到阿迦玛甘之血的锅；互动后击杀召出的目标并拾取。这个任务需要高地里的血。")),
    step("回棘背营地交血，查看花束后续", turnin(93604, kogthug), accept(93606, kogthug, true)),
    step("如已接后续，回花园采花并制作花束",
        complete(93606, garden, "在花园收集 5 朵 Vibrant Flower，按任务提示做成 Benevolent Bouquet，和任务要求的血一起带给 Quolga。")),
    step("把花束带给 Quolga", turnin(93606, quolga), {t = "note",
        text = "如果拿到可接任务的花园项链，在背包右键接取，再回神殿交给 Mithera。"}),
    step("如果已接花园项链，回神殿交", turnin(93609, mithera))
)

local function register(id, title, category, lower, upper, why, steps)
    local guideId = pack .. "/" .. id
    local ok = Polestar.RegisterGuide({
        id = guideId,
        pack = pack,
        title = "辛德拉 · " .. title,
        category = category,
        minLevel = lower,
        maxLevel = upper,
        zone = zone,
        zoneName = "辛德拉",
        keywords = {"辛德拉", "辛德拉斯", "Shen'dralas", title},
        version = 1,
        why = why,
        steps = steps,
    })
    if ok then
        for i, row in ipairs(steps) do
            local oi = repairSupplies[row]
            if oi then repairSupplies[row] = {guide = guideId, repair = i + 1, oi = oi} end
        end
    end
end

register("leveling", "野外主线", "Leveling", 38, 45, "从水晶塔做到神殿与花园，附武器线和可选精英接取。", main)
register("mana-mania", "法力狂潮（组队）", "Miscellaneous", 43, 52, "交完水晶心脏后，组队接取、击杀并交付法力狂潮。", manaMania)
register("gelkis", "吉尔吉斯半人马", "Miscellaneous", 38, 45, "从凄凉之地谷口前置做到击杀可汗。", gelkis)
register("magram", "马格拉姆半人马", "Miscellaneous", 40, 46, "从凄凉之地谷口前置做到复活可汗。", magram)
register("dungeons", "玛拉顿与剃刀高地", "Miscellaneous", 43, 52, "补齐水晶塔与花园前置，再做取水与采血。", dungeon)

-- Inventory is spent after each repair. The quest log identifies which tower still needs it.
local hidden = {factions = {"!Horde", "!Alliance"}}
local function refreshSupplies()
    local C = Polestar.Compat
    local state = Polestar.CharState()
    if type(state) ~= "table" then return end
    local active = C.IsOnQuest(96018) and not C.IsQuestCompleted(96018)
        and not C.IsQuestReadyForTurnIn(96018) and (C.GetItemCount(255662) or 0) > 0
        and not (state.skippedQuests and state.skippedQuests[96018])
    local objectives = active and C.GetQuestObjectives(96018)
    local changed = false
    for row, link in pairs(repairSupplies) do
        if type(link) == "table" then
            local objective = objectives and objectives[link.oi]
            local skips = state.skipped and state.skipped[link.guide]
            local visible = active and objective and not objective.finished
                and not (skips and skips[link.repair])
            local only
            if not visible then only = hidden end
            if row.only ~= only then row.only, changed = only, true end
        end
    end
    local engine = Polestar.Engine
    local current = engine and engine.GetGuide()
    if changed and current and current.pack == pack then engine.RequestUpdate() end
end
Polestar.OnLogin(refreshSupplies)
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "BAG_UPDATE_DELAYED",
    "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN"}) do
    Polestar.RegisterEvent(event, refreshSupplies)
end
Polestar.On("STEP_UPDATED", refreshSupplies)
Polestar.On("STEP_CHANGED", refreshSupplies)
