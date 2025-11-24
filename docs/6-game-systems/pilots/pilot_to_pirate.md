## Как пилот становится пиратом - размышления и гейм-дизайн

Цель: собрать выводы из материалов в `Assets/Design` и предложить игровые механики, сюжетные триггеры и характеристики, которые ведут от "обычного пилота" к пиратству. Материал основан на `planetary_economy.md`, `quest_system.md`, `pilots.md`, `planets.md`, `bible.md`, `lore/black_market_eden5.md` и примерах в `QuestSamples`.

---

**Краткая идея**: переход пилота в пиратство - это не одномоментный выбор, а кривая решений и накопленных обстоятельств: экономическое давление, возможности подполья, личностные черты, события (потеря, предательство, отчаяние), а также доступность инфраструктуры контрабанды и пиратских братств.

**Источники и сигналы в мире**:
- **Экономика**: пилоты зависят от торговли, маржи и доставки (`planetary_economy.md`). Низкие доходы, большая волатильность, отсутствие контрактов стимулируют рискованные действия.
- **Потребности и планировщик пилота**: потребности (Hunger, Entertainment, кредиты) и ShipNeeds (топливо, ремонт) заставляют вставлять EarnMoney/Refuel цели; отсутствие денег → поиски нелегальных заработков (`needs_and_goals_architecture.md`, `pilots.md`).
- **Квесты/_hooks**: Composer/Director выдаёт hooks (см. `QuestSamples`) - smuggling, convoy, informant - они естественно предоставляют легальный/нелегальный выбор.
- **Подполье**: Noir-Triada, Helios Clinics, Kern Logistics и pirate brotherhoods - рынки и контакты, дающие опции для преступлений (`SettingBible/factions`, `lore/black_market_eden5.md`).

---

1) Пути и ключевые триггеры превращения
- **Экономический крах / долг**: пилот теряет сбережения (провал миссии, штрафы, личные долги). Нужда в больших суммах создаёт мотивацию принять смелое, высокооплачиваемое, но нелегальное задание (smuggling, contraband missions).
- **Столкновение с системой**: жёсткие правила Федерации, конфискации, несправедливые наказания - пилот теряет веру в систему и начинает искать альтернативные сети (ноар-триада, подпольные клиники).
- **Социальная связка / вербовка**: знакомство с информантом, контрабандистом или бывшим пиратом (hook → talk_informant_planetA, hook_smuggling) открывает контакты и постоянный доход.
- **Крушение / потеря работы**: например, крушение при миссии (см. Eden-5) - потеря фрахта, изоляция, доступ к тёмным рынкам.
- **Моральный компромисс шаг за шагом**: сначала мелкая контрабанда, затем саботаж охраны, нападение на конвои; каждое действие увеличивает wanted-level / репутацию у подполья.

2) Игровые действия и решения, которые ведут в пиратство
- **Судоходная контрабанда** (smuggling): брать запрещённые грузы, выбирать рискованные маршруты; успешные рейсы повышают доверие подполья и доступ к лучшим заданиям.
- **Отказ помогать законам / саботаж**: игрок может саботировать маяки или порубить каналы связи (повышает шанс успешного ограбления/контрабанды).
- **Вооружённые налёты**: атаки на маленькие торговые флоты; переход от скрытной к открытой преступной активности.
- **Организация сети**: найм пилотов-наёмников, обустройство тайников и тайных баз (игровой шаг к капитализации преступного бизнеса).

3) Характеристики и параметры, способствующие пиратству
- **Личностные черты**: высокая Greed, низкая Caution, низкая Loyalty/High Independence, высокая Aggression - увеличивают склонность к принятию рискованных контрактов (`planetary_economy.md`, `pilots.md`).
- **Навыки**: высокий TradingSkill (для оценки маржи), высокий CombatSkill и Pilot Skill (для угона/погони), Engineering для быстрых правок/модернизаций корабля.
- **Корабль**: большая CargoCapacity (для контрабанды), модификации для уклонения от сканеров, усиленное вооружение и быстрые двигатели - техническая предпосылка.
- **Социальные связи**: контакты в Noir-Triada / Kern / Helios - дают доступ к заданиям и апгрейдам.

4) Система репутации и wanted-уровень (гейм-механика)
- **Два измерения репутации**: (1) официальная - отношение к Федерациям/станциям; (2) подпольная - рейтинг у пиратских братств/брокеров.
- **Wanted score**: увеличивается при нападениях/перехватах/невыплатах. Высокий wanted → усиленные патрули / награды на голову → меняет доступные варианты (скрытые точки, более рискованные маршруты).
- **Экономический профиль**: игроку становится выгоднее действовать вне закона, когда свободный доход легальных путей меньше ожидаемой прибыли от пиратства с учётом риска.

5) Прогрессия превращения (пример стадий)
- **Stage 0 - Курьер/наёмник**: выполняет легальные доставки и мелкие поручения. Параметры: низкая репутация у подполья, нормальный доход.
- **Stage 1 - Участник контрабанды**: принимает smuggling hooks (hook_smuggling, fetch_delivery). Получает доступ к подпольным магазинам/Helios услугам; начинают появляться первые moral choice точки.
- **Stage 2 - Опасный контрабандист / рейдер**: совершает нападения на малые грузы, участвует в confrontations; wanted ↑; открываются бродячие задания от pirate brotherhoods.
- **Stage 3 - Организатор/капитан банды**: владеет сетью тайников, нанимает NPC, ведёт крупные налёты и контроль участков трафика; отношения с фракциями становятся стратегическими.

6) Примеры квест-цепочек, подтягивающие игрока к пиратству
- Hook: `hook_smuggling` → Choice: accept (smuggling route) or refuse. Accept → `investigation_market` → `confrontation_pursuit` (escalation) → `climax_standoff` → `aftermath_reputation_shift`. Последние шаги могут дать либо укрепление подполья (если player sides with smugglers), либо официальное преследование.
- Convoy hooks: `hook_convoy_notice` → watch_convoy → choice: attack convoy (gain loot/rep with pirates) or warn convoy (gain Federation rep). Такие выборы прямо двигают игрока в противоположные направления.

7) Баланс и контрмеры (рекомендации)
- **Баланс риска/дохода**: подсчитать expected_value = profit * (1 - loss_prob) - expected_costs (fines, ship loss). Должен быть точечный момент, где нелегальные задания кажутся рациональными.
- **Инструменты правосудия**: bounty systems, patrol escalation, возможность сдаться/сдать доказательства (redemption paths). Возможность амнистии или перехода в частично легальные схемы (партнёрство с TransGate) - даёт игровые ветви.
- **Ограничение доступности**: доступ к серьёзным пиратским операциям требует сетей, тайников, и доверия (trust thresholds в QuestSamples). Это предотвращает мгновенное "фармилово".

8) Реализация в системах проекта (имплементация)
- **WorldState/Director**: выдаёт hooks, следит за глобальной wanted статистикой и spawn патрулей (см. `quest_system.md`).
- **PilotModel**: добавить поле `Lawfulness` / `WantedScore` и decision modifiers (Greed/Caution) для торговых/преступных выборов.
- **MarketModule**: подпольные рынки (Helios/Noir) как отдельные MarketModule с риском транзакций и premium на препараты/модули.
- **Simulated consequences**: Composer должен симулировать последствия выбора (ex: open_hooks, reputation patches). Использовать существующий Validator/Simulator.

9) Игровые сцены и драматические моменты (для сценаристов)
- Утечка директивы Валена → моральный выбор: продать информацию подполью или передать Федерации.
- Потеря конвоя/крушение (Eden-5) → пилот остаётся без средств и вынужден идти в подполье.
- Сцена вербовки: доверенный информант предлагает крупный рейд с высоким риском/наградой.

10) Краткие next steps для реализации
- Добавить `pilot.WantedScore` и `pilot.Lawfulness` в `PilotModel`.
- Реализовать подпольные MarketModules (Helios/Noir) с методами `OfferBlackMarketTrade()` и риском detection.
- Прописать новые QuestSamples/branches, где эскалация идёт от smuggling → violent → gang leadership.
- Ввести telemetry: track number of illegal jobs completed, current wanted score, pirate-faction rep.

---

Файл подготовлен как дизайн-обзор и план для программистов и сценаристов. Могу доработать: 1) конкретные числовые пороги (wanted thresholds, payouts), 2) карточки NPC-вербовщиков, 3) диалоговые узлы для `hook_smuggling` и `talk_informant_planetA` под пиратские ветки.

---

## Технический план: как `PilotModel.cs` может эволюционировать в пиратство (для программистов)

Ниже - подробный, практически ориентированный план изменений в кодовой базе, данных и интеграции. Цель - чтобы NPC-пилоты могли автономно переходить от законопослушного поведения к криминальному через симуляционную логику, без ручного скриптинга.

### 1) Перенос данных отношений/репутации в систему `Faction`

Важно: вместо хранения всех полей репутации/wanted/trust в каждом `PilotModel` мы централизуем это в универсальном классе/сервисе `Faction`/`FactionManager`. `PilotModel` хранит только ссылку/ID на связанные фракции и краткие derived-поля (кэшированные) - а вся политическая/криминальная статистика по каждому пилоту хранится в `Faction`.

Причины:
- Унификация (репутация - концепт фракций, не отдельных пилотов).
- Удобство баланса и репликации: фракция контролирует свои параметры (включая PirateFaction как частный случай).
- Лёгкость для Director/Composer - все запросы по репутации идут к Faction API.

Что переносится в `Faction`:
- `WantedScorePerPilot` (map pilotId -> float) - текущий уровень розыска против данного пилота у этой фракции/юрисдикции.
- `ReputationPerPilot` (map pilotId -> float) - модель репутации/лояльности.
- `TrustPerPilot` (map pilotId -> float) - доверие подполья/контактов (CriminalNetworkTrust теперь per-faction or per-network).
- `IllegalJobHistoryPerPilot` (map pilotId -> JobStats) - счетчики успешных/проваленных illegal jobs связаны с фракцией.

Что остаётся в `PilotModel`:
- Поля, относящиеся к способности и личности (Greed, Caution, Skills, ShipModel refs).
- Короткоживущие кэши (например, lastKnownWantedEstimate) - для оптимизации; всё изменяемое фактическое состояние за репутацией идёт в `Faction`.

Требования: добавить persistence для `Faction` (ScriptableObject + runtime state), и защищать все изменения под общей синхронизацией в WorldState / FactionManager (thread-safe).

### Дизайн `Faction` (кратко)
- Базовый класс `Faction`:
	- id, name, type (enum: LegalAuthority, PirateNetwork, Broker, Corp)
	- methods:
		- `float GetReputation(Guid pilotId)`
		- `void AdjustReputation(Guid pilotId, float delta)`
		- `float GetTrust(Guid pilotId)`
		- `void AdjustTrust(Guid pilotId, float delta)`
		- `float GetWanted(Guid pilotId)`
		- `void AdjustWanted(Guid pilotId, float delta, DetectionContext ctx)`
		- `List<IllegalOffer> GetOffersForPilot(Guid pilotId, PilotSnapshot snapshot)` (for pirate networks)
	- internal storages: maps for per-pilot values, persisted in world save.

- `PirateFaction : Faction` (specialization)
	- extra API: `RegisterIllegalOffer(...)`, `GetNetworkMultiplier()`, `IssueSafehouse(pilotId)`, policy for when to reduce detection risk for trusted pilots.
	- policy fields: `minTrustForMajorJobs`, `trustGainOnSuccess`, `trustLossOnFailure`.

Интеграция: все вызовы к репутации/wanted идут через `FactionManager` (singleton/service) и только он модифицирует maps; `PilotModel` делает `FactionManager.Query(...)` при принятии решений.

### 2) Новые типы целей (Goals)
- `SmuggleRunGoal` - stealth delivery, использует BlackMarketModule и route concealment.
- `FenceGoodsGoal` - продажа украденного/контрабандного груза через `BlackMarketModule`.
- `RaidConvoyGoal` - open combat raid on convoy (requires CombatSkill checks and appropriate ship capabilities).
- `EstablishSafehouseGoal` - инвентарь/тайник creation (долгосрочная цель, требует капитал).

Каждый illegalGoal реализуется как GoalChain: [EnsureSupportGoals (refuel/hide) → ExecuteIllegalAction → Escape/Dispose].

### 3) `BlackMarketModule` (MarketModule variant)
- Функции:
	- `GetIllegalOffer(itemId, qty)` → returns `{price, baseDetectionRisk, minTrust}`
	- `TryBlackBuy(pilotId, itemId, qty)` / `TryBlackSell(...)` → атомарно изменяют стоки и возвращают success + detectionOutcome
- Параметры: `illegalPricePremium`, `liquidity`, `detectionBase`.
- Реализация: как `MarketModule` с дополнительными полями для `detectionRisk` и `isIllegal=true`.

### 4) `PiracyDecisionModule` - модуль принятия решений (новый класс)
- Задача: оценивать доступные illegalOffers и решать, брать ли их (enqueue illegal goals).
- Входы: Pilot state (Credits, ship, Greed/Caution/Lawfulness, PirateStage, CriminalNetworkTrust), WorldState (nearby offers, patrolDensity, director hooks), Offer metadata.
- Вычисления:
	- `expectedProfit = offer.EstimateProfit(pilot)`
	- `expectedLoss = offer.EstimateLoss(pilot)` (включая вероятность потери ship/cargo)
	- `detectionRisk = offer.baseDetection + world.PatrolDensity(route) - pilot.StealthModifiers`
	- `trustBenefit = pilot.CriminalNetworkTrust * offer.NetworkMultiplier`
	- `moralityPenalty = pilot.Lawfulness * moralWeight`
- Utility (пример):
	`utility = expectedProfit*(1+Greed) - expectedLoss*(1-Caution) - detectionRisk*riskWeight + trustBenefit - moralityPenalty`
- Решение: если `utility >= threshold(stage, offer.complexity)` И `CriminalNetworkTrust >= offer.minTrust` → accept job → `Planner.PushGoal(offer.ToGoalChain())`.
- Дополнительно: при успешном выполнении `IllegalJobsCompleted++`, `CriminalNetworkTrust += deltaTrust`, возможный апгрейт `PirateStage`.

### 5) Интеграция с `PilotGoalPlanner`
- В `PlanNextGoal()` вызывать `PiracyDecisionModule.Evaluate()` перед генерацией стандартных lawful goals.
- Illegal goals вставляются в очередь как GoalChains с support goals (Refuel, Repair, Hide). Планировщик должен уметь резервировать safehouse/dock через `CelestialModel` API.

### 6) Wanted system и реакция правоохранительных органов
- Логика:
	- `WantedScore += baseWantedForCrime * detectionSeverity` при detection
	- Если `WantedScore >= bountyThreshold` → Director создаёт bounty + увеличивает patrolDensity в секторах, где пилот активен
	- WantedScore естественно снижается (decay) при отсутствии новых преступлений
- Patrol AI подписан на WorldState и target'ит ships с высоким WantedScore (probabilistic targeting).

### 7) PirateStage progression и trust механика
- Примеры порогов:
	- Stage1: `IllegalJobsCompleted >= 1`
	- Stage2: `IllegalJobsCompleted >= 5 && CriminalNetworkTrust >= 0.4`
	- Stage3: `IllegalJobsCompleted >= 15 && CriminalNetworkTrust >= 0.75`
- Consequence: Stage unlocks larger illegalOffers, lowers some internal thresholds, но повышает внимание law enforcement.

### 8) Конфигурация и тюнинг (ScriptableObject)
- Создать `PiracyConfig` ScriptableObject с параметрами: `piracyThresholdBase`, `stageMultipliers[]`, `trustDecayRate`, `wantedDecayRate`, `detectionBase`, `illegalPricePremium`, `patrolInfluence`.
- Дизайнеры меняют значения в инспекторе для балансировки.

### 9) Telemetry, Debug и тесты
- Telemetry: log events (pilotId, offerId, utilityValue, decision, result, wantedDelta).
- Debug UI: показать utility-breakdown, currentOffers, pilot trust/wanted/stage, force values.
- Unit tests:
	- utility calculation with deterministic inputs
	- progression of PirateStage after sequence of successes/failures
	- WantedScore increase/decay
- Integration tests:
	- pilot with low credits accepts illegalOffer and planner enqueues `SmuggleRunGoal`.
	- detection triggers bounty and Director spawns patrol.

### 10) Безопасность и edge cases
- Не допускать мгновенной массовой конверсии: require `minTrust` и staged unlocks.
- При уничтожении/удалении BlackMarket node - пилоты ищут альтернативы или возвращаются к lawful routes.
- Thread safety: все изменения полей пилота под `model.Sync`.

### 11) Roadmap (задачи/приоритеты)
1. Implement `Faction` system + migrate reputation/wanted/trust storage (high priority)
2. Implement basic `BlackMarketModule` + seed illegal offers (data)
3. Implement `IllegalJobOffer` DTO and Director hook to spawn offers
4. Implement `PiracyDecisionModule` and integrate with `PilotGoalPlanner`
5. Add `SmuggleRunGoal` and `FenceGoodsGoal` (MVP illegal goals)
6. Wanted system integration with Director/Patrols (uses Faction.Wanted maps)
7. Telemetry, Debug UI and Tuning

---

**См. также**: подробный дизайн системы фракций - `Assets/Design/faction_system.md` (репутация, wanted, trust, API и интеграция для PirateFaction).

