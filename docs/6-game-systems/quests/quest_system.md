## Дизайн системы бесконечной генерации квестов

Ниже — подробные мысли и предложения по реализации процедурной, бесконечной и смыслово-целостной системы квестов для игры.

---

### Короткая цель
Система должна уметь генерировать неограниченное количество интересных, «сюжетно содержательных» квестов из набора небольших «ходов» (moves). Каждый квест — это собрание ходов, согласованных между собой по тематике, целям и конфликтам, создающее цепочку значимых ситуаций и гарантирующее ощущение прогресса и последствий.

### Основные контрактные пункты (inputs / outputs / success)
- Вход: seed (случай или игрок-статус), начальные теги/темы (набор дизайнерских параметров), начальное состояние мира (NPC, фракции, ресурсы, карты). 
- Выход: сериализуемый квест (структура: метаданные + последовательность сцени/ходов + условия успеха/провала + награды/следствия).
- Успех: квест логически корректен (нет внутренних противоречий), имеет ясную цель, несколько точек выбора/напряжения, и даёт награды/последствия, которые могут быть применены к миру.

### Предположения (из недосказанного)
- Игра — с открытым миром, есть система мирового состояния (NPC, фракции, ресурсы).
- Unity-проект, можно использовать ScriptableObject/JSON для контента.
- Дизайнеры готовят пул ходов и метаданных; система отвечает за компоновку и согласование.

---

## Компоненты системы
1. Редактор контента — набор ходов (moves) в виде ScriptableObject или JSON-файлов.
2. Move Pool — коллекция ходов, размеченная тегами: тема, тон, требуемые предпосылки, последствия, сложность, роли участников.
3. Composer (композитор) — алгоритм, собирающий цепочку ходов в квест по правилам согласования.
4. Validator — проверяет квест на логические конфликты и переставляет/заменяет ходы при необходимости.
5. World Simulator / State Interface — API для чтения/модификации мира (проверки предусловий и применения последствий).
6. Director / Tuning Layer — отвечает за тон (комедия/трагедия), скорость эскалации, длину и плотность интеракций.

---

## Формат одного хода (move)
Каждый move — это минимальный сюжетный строительный блок с метаданными и шаблоном исполнения.

Пример полей (структура):
- id: уникальный идентификатор
- title / brief: короткое описание для дизайнеров и логики
- description: развёрнутая формулировка для локализации / инструментов
- tags: ["theft", "faction:Kern", "tone:dark", "scale:small"]
- prereqs: набор предусловий (world state predicates), пример: `{"faction.reputation.Kern > 30", "planet == Valen"}`
- consumes: ресурсы/объекты/персонажи, которые используются и могут исчезнуть
- produces: эффекты на мир (репутация, слоты миссий, предметы, NPC-state)
- roles: какие агенты участвуют (giver, target, companion, antagonist)
- complexity / weight: относительная сложность для отбора
- branchingPoints: набор точек выбора/вариантов (если есть)
- beats: внутренняя последовательность под-действий (опционально)
- narrativeMoves: маленькие повествовательные элементы, которые могут вставляться внутрь (flavor)

Важно: предусловия и эффекты должны быть выражены через небольшое безопасное DSL или последовательность предикатов, совместимых с World State API.

---

## Типы ходов (примерный пул)
- Hook / Hook-Start: создаёт начальный интерес (например, "постоянные кражи на рынке").
- Fetch / Delivery: простая цель и награда.
- Investigation: собирает факты, создаёт новые теги/локи.
- Confrontation: прямой конфликт с NPC/фракцией.
- MoralChoice: выбор, влияющий на репутацию и дальнейшие пути.
- Twist / Complication: меняет условия (внезапная атака, раскрытие предателя).
- Climax: разрешение конфликта — победа/поражение/уступка.
- Aftermath: последствия, усиление мира и новые hooks.

Каждый тип имеет шаблон, набор обязательных полей и вероятностные веса появления.

---

## Теги и семантика
Теги — ключ к согласованию ходов. Разделяем теги на группы:
- Тематические ("smuggling", "espionage", "rescue")
- Фракционные ("faction:Kern")
- Локальные ("planet:Valen-1")
- Эмоциональные/тона ("tone:tragic", "tone:comic")
- Геймплейные ("stealth", "combat", "social")
- Сложность/масштаб ("scale:small","scale:epic")

Composer использует пересечение тегов для выбора совместимых ходов и для тематического согласования.

---

## Алгоритм сборки квеста (высокоуровневый)
1. Инициализация: получают seed + дизайнерские параметры (темы, длина, тон, фракция).
2. Выбор hook: из пула выбрать стартовый ход, подходящий по тэгам и предусловиям.
3. Расстановка целей: определить основные цели (primary objective) и альтернативные (secondary).
4. Генерация цепочки: итеративно добавлять ход по правилам:
   - для текущего состояния выбрать совместимые moves по тегам и предусловиям;
   - учитывать желаемую эскалацию сложности и длину;
   - не допускать конфликтов (например, один ход не должен требовать и одновременно уничтожать один и тот же ресурс до его использования);
   - добавлять twists с заданной частотой.
5. Валидация: проверить целостность, устранить прямые противоречия, попытаться заменить или перетянуть ходы.
6. Финализация: вставить Climax + Aftermath, упаковать метаданные и сгенерировать эффекты мира в виде patch-а.

---

## Согласование и предотвращение конфликтов
- Использовать ограниченную логику предусловий и эффектов (predicate + effect pattern), суммируемую и симулируемую на этапе сборки.
- При добавлении нового хода композитор применяет эффект в копии world-state и проверяет, не делает ли это невозможным ранее добавленные ходы.
- Если конфликт — попытаться найти альтернативу из пула с тем же тегом; если не найдено — откат на N шагов и выбрать другой путь.

---

## Эскалация и «качели» интереса
- Директор (Director) контролирует кривую интереса: hook -> complication -> escalation -> climax.
- Параметры: плотность взаимодействий (moves per minute/segment), шанс твиста, сила последствий.
- Для сохранения вариативности можно добавлять «flavor»-подмисьюсы в каждом ходе (короткие вероятностные вставки).

---

## Примеры генерации (скелет)
Пример 1 (кратко):
- Hook: "Контрабанда на станции Эден-5"
- Investigation: игрок узнаёт перевозчика и его маршрут
- MoralChoice: выбрать выдать перевозчика или помочь
- Twist: перевозчик — агент фракции X
- Confrontation: погоня/штурм
- Climax: выбор — арестовать/пустить/убить
- Aftermath: изменение репутации и новые hook-и

Пример 2: мини-цепочка без твистов
- Hook: запрос на доставку
- Fetch: захват/перевоз
- Delivery: награда
- Aftermath: небольшая репутация

---

## Псевдокод компоновщика (упрощённо)

1. composer(seed, params, worldState):
   - rng = init_rng(seed)
   - theme = choose_theme(params)
   - hook = select_move(pool, predicates: matches(theme, params))
   - sequence = [hook]
   - while not done:
       candidates = filter(pool, matches_tags, prereqsSatisfied(sequence, worldState))
       candidate = pick_weighted(candidates, rng, director_weights)
       if validator.canAppend(sequence, candidate):
           append(sequence, candidate); simulateEffects(worldState, candidate)
       else:
           tryAlternativeOrRollback()
   - finalize(sequence)
   - return sequence

---

## Integration notes (Unity)
- Контент: ScriptableObject-derived assets для moves. Плюс экспорт/импорт в JSON для удобства инструментов.
- Composer: MonoBehaviour/Service (можно сделать как singleton manager), с возможностью вызова на сервере/локально.
- Validator/Simulator: лёгкая копия WorldState (deep copy of relevant slices) или применение reversible patch логики.
- Designer tools: EditorWindow для просмотра пула ходов, генерации примера квеста и ручной донастройки.

---

## Метрики и тестирование
- Разнообразие: процент уникальных тэг-сочетаний за N проигрышей.
- Связность: доля квестов, прошедших валидацию без откатов.
- Интересность: (экспериментально) ранжирование игроков / internal heuristics (кол-во принятых твистов, среднемин. длина цепочки).

Написать unit тесты на: validator (простые конфликтные сценарии), composer (детерминированность при фиксированном seed), и базовый end-to-end с небольшим pool.

---

## Edge cases и как их обрабатывать
- Пустой пул: fallbacks/hardcoded hooks.
- Циклические зависимости (move A требует эффект B, B требует A): детектор циклов и ограничение глубины.
- Невыполнимые предусловия: garbage collection таких moves или пометка как "designer-only".

---

## Маленькие шаги для быстрой проверки идеи
1. Создать 20-30 moves разного типа (в JSON/ScriptableObject).
2. Реализовать composer с простым predicate-checker и возможностью симуляции эффектов.
3. Написать EditorWindow, который генерирует квест по нажатию и показывает sequence + world patches.
4. Собрать обратную связь от дизайнера и итеративно расширять пул и правила.

---

## Диалоги и взаимодействия с персонажами (Dialogues & Interaction Trees)

Диалоги — ключ к созданию заинтересованности и контролируемой вариативности веток. В нашей системе диалог рассматривается как вложенный объект внутри move (или как отдельный move типа "interaction"). Диалог состоит из узлов (dialog nodes) и ответов (choices). Каждый ответ может:
- изменять локальное отношение/доверие к NPC (trust/relationship value),
- добавлять/удалять теги и флаги во временном world snapshot,
- порождать немедленные последствия (patches) или открывать новые moves (hooks),
- вести к следующему узлу диалога или завершать interaction с выбранным исходом.

Основные элементы диалога:
- dialogNode: `{ id, speaker (actor id), textKey, choices: [choiceId...] }`
- choice: `{ id, textKey, prerequisites (minTrust, requiredTag), effects (patches, trustDelta), nextNodeId, outcomeTag }`

Механика доверия (Trust / Relationship)
- У каждого NPC хранится relationship map: relationship[playerId] или просто numeric trust (0..100). Диалог-choices могут менять trust на значение (+/-). Composer и runtime используют trust для определения доступных веток (например, "войти в доверие" доступно при trust >= 40).
- Trust влияет не только на диалог — он может влиять на вероятность того, что NPC выполнит обещание или предаст игрока.

Пример поведения "найти информанта и войти в доверие":
1) Move "find_informant" содержит interaction с root node "greeting".
2) Игрок выбирает: "предложить плату" (+trust +10, produces known_route), "угрожать" (-trust -20, может вызвать conflict_seed), "дружелюбно пообщаться" (+trust +5, открывает дополнительную информацию при trust>=15).
3) Накопив trust выше порога, игрок может разблокировать специальный ответ "довериться/попросить о личной встрече", который откроет событие "follow_up" (новый move) с более высокой наградой.

Интеграция диалогов с Composer и WorldState
- При генерации квеста Composer учитывает interaction узлы как потенциальные точки ветвления. Он может симулировать типичные ответы (например, наиболее вероятные варианты по текущему игрок-профилю) чтобы предсказать последствия и выбрать последовательность ходов, которые дают желаемую кривую интереса.
- Каждый choice содержит effects в том же формате, что и produces в moves — т.е. декларативные патчи, которые Composer симулирует на копии WorldState и которые будут применены при реальном выполнении.
- Для offline-валидации Composer должен прогонять несколько сценариев ответов (например, честный путь / агрессивный путь) чтобы убедиться, что ни одна ветка не делает квест полностью невыполнимым.

Пример JSON-узла (сокращённо):

```json
"dialog": {
    "root": "node_greet",
    "nodes": {
        "node_greet": {
            "id": "node_greet",
            "speaker": "npc_informant_02",
            "textKey": "greet_informant",
            "choices": ["c_pay","c_threat","c_befriend"]
        }
    },
    "choices": {
        "c_pay": {"id":"c_pay","textKey":"offer_money","effects":{"reputation":{"BlackMarket":2},"open_hooks":["share_route"]},"trustDelta":10,"nextNodeId":"node_share"},
        "c_threat": {"id":"c_threat","textKey":"threaten","effects":{"open_hooks":["alert_pursuit"]},"trustDelta":-20,"nextNodeId":"node_run"}
    }
}
```

Небольшое практическое правило для дизайнеров: держите диалоги компактными (3-5 узлов на interaction) для простоты тестирования и минимизации combinatorial explosion. Используйте trust-пороговые ответы для создания "испытываемых" ветвей.

---

Теперь, когда в дизайне прописаны диалоги и доверие, можно расширять sample-moves диалоговыми деревьями и прописывать ожидаемые patch-эффекты для каждой опции.

---

## Пример сценария: конвой (end-to-end example)

Ниже — конкретный сценарий, иллюстрирующий как все части системы работают вместе: hooks, places, actors, диалоги, trust и временные события (scheduled convoy).

1) Hook: Игрок заходит на рынок на планете X — система генерирует hook "convoy_notice" и создаёт запись в журнале: "Ожидается конвой с планеты A на планету B; пора поговорить с информатором на планете A". Этот hook создаёт open_hook "talk_informant_planetA" и запланированное событие "convoy_XXX" со свойствами `{from: planet_A, to: planet_B, window: [t0, t1]}`.

2) Игрок может отправиться на планету A и найти информанта в любом баре (каждая локация типа "bar" имеет связанный actor с role=informant). Move "talk_informant_planetA" содержит interaction/dialogue с несколькими вариантами:
    - если `trust >= HIGH_THRESHOLD`: информатор даёт дату бесплатно (effects: open_hooks: ["watch_convoy"]);
    - если `trust >= MID_THRESHOLD`: игроку достаточно заплатить небольшую сумму (effects: reputation/credits change + open_hooks: ["watch_convoy"]);
    - если `trust < MID_THRESHOLD`: требуется либо выполнить серию favour-тасков (move "raise_trust_task") либо заплатить высокую цену (effects: large credits transfer + open_hooks: ["watch_convoy"]).

3) Composer и runtime: при создании hook-а Composer создает патч в world_state — запись о запланированном конвое. При каждом ходе времени (game tick) система проверяет активные scheduled events и, когда наступает окно отправления, запускает финальный move "watch_convoy" или помечает квест как проваленный, если игрок не присутствует в нужной локации.

4) Финальная стадия "watch_convoy": move имеет prereqs: convoy_scheduled && player_at(place=planet_B, time_in_window). Если выполнены — происходит confrontation/escort/negotiation (зависит от ветки); produces: mission_complete, rewards, последствия для фракций и NPC. Если игрок не появился — event генерирует mission_failed и применяет патч, фиксирующий успешный проход конвоя (например, BlackMarket +10).

Примечания по реализации:
- Scheduled events: хранить как часть WorldState в виде списка объектов `{id, type, from, to, windowStart, windowEnd, meta}`. Composer создает эти объекты в produces при генерации hook-а.
- Проверка присутствия игрока: runtime должен уметь верифицировать положение игрока at time t (например, `player.current_location == expected_place && abs(now - scheduled_time) <= tolerance`).
- Баланс доверия vs платёж: используйте пороги (MID/HIGH) и чёткие формулы `cost = baseCost * (1 - trust/100)` или варианты с required favour-count.

Этот пример демонстрирует, как диалоги, trust, actors и scheduled world-events объединяются в выполненный сценарий, отражающий ваши требования.

## Действующие лица, локации и последствия (Actors / Places / Consequences)

Ключевая идея: каждый ход привязан не только к тегам, но и к реальным игровым сущностям — локациям, NPC/персонажам и конкретным последствиям, которые он может наложить на мир. Это позволяет квестам "чувствовать" мир и влиять на него так, чтобы изменения были заметны и долговечны.

1) Actors (действующие лица / NPC)
 - Структура персонажа (минимум): id, name, role (merchant, smuggler, officer, informer), faction, current_location (place id), reputation (map faction->int), relationships (map npc_id->relationScore), tags.
 - Роль: у каждого move может быть список задействованных actors: giver, target, companion, antagonist. Композитор должен выбирать актёров, чьи предусловия и отношения удовлетворяют логике хода (например, информант с низкой лояльностью может предать).

2) Places (локации)
 - Структура локации: id, name, type (station, planet, outpost, alley), controlling_faction, tags (например, "lawless","market","high-security"), coordinates/region.
 - Moves привязываются к местам через поле involved_places (список id). При генерации композитор может переносить последовательность по нескольким местам, проверяя логистику (время/доступность).

3) Consequences / World Patches (последствия)
 - Каждый move определяет produces как список эффектов. Эффекты — именованные патчи, которые применяются к WorldState: изменение репутации, создание/удаление объектов, открытие новых hook-ов, изменение состояния локаций (например, "checkpoint_enabled"), перевод NPC в новое состояние.
 - Патчи должны быть атомарными и описанными декларативно: `{"reputation": {"SolarFederation": 5}, "npc_state": [{"id":"npc_042","status":"wounded"}], "open_hooks": ["smuggling_alert"]}`

4) Contract: Composer ↔ WorldState
 - Composer запрашивает у WorldState только необходимые срезы (actors by tag/id, place properties, faction reputations).
 - Перед добавлением move Composer симулирует его effects на копии WorldState. Если после симуляции будущие предусловия других already-selected moves нарушаются, Composer либо подбирает альтернативу, либо откатывает.
 - После финализации квеста Composer возвращает набор atomic patches, которые игровой код применяет через WorldState.applyPatch(patch) — функция должна быть транзакционной или поддерживать rollback.

5) Привязка moves к сущностям (пример полей в move):
 - involved_actors: ["npc_smuggler_01"]
 - involved_places: ["station_eden5_market","storage_warehouse_12"]
 - produces: ["reputation:BlackMarket:+10","npc:npc_smuggler_01:status:captured"]

---

## Пример API / JSON контрактов

Пример минимального патча:

```json
{
    "reputation": {"Kern_Logistics": -10},
    "npc_state": [{"id":"npc_illario","status":"wounded"}],
    "place_flags": [{"place_id":"station_eden5","flag":"alert_level","value":2}],
    "open_hooks": ["follow_up_smuggling"]
}
```

Рекомендация: реализовать небольшую библиотеку (C#) для валидации и применения патчей: Patch.Apply(WorldState) и Patch.Revert(WorldState) — это упростит откаты при ошибках.

---

Добавление этих разделов в дизайн поможет соблюсти требование, чтобы квесты опирались на реальные мирные сущности и создавали ощутимые последствия для игрового мира.

---

## Director (правила выдачи квестов) — дизайн и поведение

Director — непрерывно работающий игровой под-сервис (логика дизайна; без привязки к конкретной реализации). Его задача — наблюдать за игроком и миром и принимать решение, когда и какие квесты выдавать, чтобы сохранить интерес, не переполнить игрока заданиями и поддерживать связность повествования.

Основные обязанности Director'а:
- Слежение за событиями: посещения локаций игроком, изменения WorldState, завершения/провалы квестов, появление новых hooks.
- Решение о выдаче квеста: нужно ли подкинуть маленький/средний/крупный квест или отложить (load balancing).
- Формирование параметров для Composer'а (seed, темы, ограничения) и предзапросов к WorldState (preflight checks).
- Верификация результата Composer'а и применение начальных патчей (open hooks, scheduled events).

Decision loop (высокоуровнево):
1. Director получает событие (например, PlayerVisited(placeId)) и кладёт его в очередь анализа.
2. Периодически (Evaluate) собирает метрики: activeQuestCount, timeSinceLastMajorQuest, playerLocation, recentPlayerActions, playerState (stress/morale) и т.п.
3. Применяет правила выдачи (configurable rules):
    - Если `activeQuestCount == 0 и cooldownMajor <= 0` => шанс сгенерировать major quest.
    - Если `activeQuestCount >= maxActive` => выдать малый supportive quest с probability smallQuestChanceWhenBusy.
    - Если `PlayerVisited(place) && place.tags contains informant_spot && WorldState.hasOpenHook("talk_informant")` => приоритезировать Composer.Generate("talk_informant") для этого места.
    - Увеличивать шанс локальных hooks при частых посещениях (location stickiness).
4. Перед вызовом Composer выполнять preflight checks: есть ли требуемые actors/places/PilotModel и т.д.; если нет — модифицировать параметры или отложить задачу.
5. Вызвать Composer.Generate(params). Получив candidateQuest, прогнать validate/sanity checks; если OK — применить initial patches в WorldState (включая scheduled events); иначе попробовать alternative или отменить.

Примеры правил и порогов (должны быть настраиваемы):
- maxActiveQuestsPerPlayer = 2
- majorQuestCooldown = 72h (игровое время)
- smallQuestChanceWhenBusy = 0.35
- locationStickinessFactor = 0.1 per repeated visit

Integration notes с симуляторами (PilotModel и др.)
- Director делает preflight-запросы к WorldState/SimulationManager: FindAvailablePilot(from, to, earliestDeparture, requiredSkill). Если подходящего PilotModel нет — Composer либо предложит альтернативу (перенос окна, другой тип квеста), либо Director отложит spawn.
- Director не назначает пилотов — он лишь гарантирует, что необходимые сущности доступны в мире и Composer спроектирует квест вокруг них. Назначение PilotModel / ship происходит в runtime-logic квеста (executor), после финализации и применения стартовых патчей.

Пример псевдо-API (дизайн):
- Director.NotifyPlayerVisited(placeId)
- Director.Evaluate() -> возможно вызов Composer.Generate(params)
- `WorldState.PreflightCheckForConvoy(from,to,window) -> bool`
- Composer.GenerateQuest(params) -> `QuestCandidate { sequence, patches }`
- `Director.ValidateQuest(candidate) -> bool`

Тонкости дизайна
- Director должен быть прозрачным для дизайнеров: не скрывайте параметры; предоставьте GUI с логами решений и возможностью менять веса/пороги в рантайме.
- Для предотвращения спама используйте систему кредитов/таймеров: крупный квест даёт negative credit, который нужно погасить временем/маленькими квестами.
- Director должен симулировать "плохие ответы" (например, игрок игнорирует hook) — это помогает избегать ситуации, когда Composer создаёт квест, который полностью разваливается в рантайме.

Тесты и метрики для Director'а
- fraction_of_visits_that_spawn: доля посещений, которые приводят к созданию hook'а.
- mean_time_between_major_quests: среднее время между крупными квестами.
- active_quests_per_player: распределение активных заданий на игрока.

Заключение
Этот раздел даёт детализированное поведение Director'а в рамках проектной документации: Designer-friendly правила, API-псевдо-вызовы и интеграция с Composer/WorldState/PilotModel. Реализация прототипа отложена — пока работаем только над дизайном и настройками в Markdown-описании.

