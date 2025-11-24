## Система Faction - дизайн и API

Цель: описать общую сущность `Faction` - какие данные фракция хранит, какие API предоставляет и как интегрируется с игровыми подсистемами (Director, Patrols, MarketModules, PilotModel и т.д.).

Документ даёт конкретику для реализации `Faction`/`FactionManager` как универсального механизма отношений и влияния в мире. Частные кейсы (например, `PirateFaction` или `LegalAuthority`) описаны в разделе "Примеры специализаций".

---

1) Основная идея
- `Faction` - сущность, ответственная за хранение отношений между миром и акторами (пилотами, корпорациями, NPC). Репутация, wanted-баллы, доверие к криминальным сетям и история  взаимодействий централются в `Faction`, а не разбрасываются по пилотам.

2) Почему централизовать в `Faction`
- Репутация - свойство межсубъектных отношений (pilot↔faction).
- Управление эскалацией (патрули, bounty) проще, когда источник - фракция/юрисдикция.
- Director и WorldState оперируют фракциями - проще для правил и генераторов квестов.

3) Данные, которые хранит `Faction` (runtime + persisted)
- `id` (GUID), `name`, `type` (enum: `LegalAuthority`, `PirateNetwork`, `Broker`, `Corp`, `Neutral`)
- `Dictionary<Guid, float> ReputationPerPilot` - лояльность/репутация.
- `Dictionary<Guid, float> WantedPerPilot` - текущий уровень розыска против пилота в этой юрисдикции.
- `Dictionary<Guid, float> TrustPerPilot` - универсальная мера доверия/взаимоотношений между пилотом и фракцией. Семантика зависит от типа фракции: для pirate-network это доверие подполья, для корпорации - лояльность/служебное доверие, для брокера - коммерческое доверие.
- `Dictionary<Guid, JobStats> JobHistoryPerPilot` - история успешных/проваленных заданий (как легальных, так и нелегальных). Структура `JobStats` может включать: `successfulCount`, `failedCount`, `totalProfit`, `lastJobType`, `lastResultTimestamp`.
- Конфигурация фракции (ScriptableObject или data asset): параметры поведения (patrolIntensity, bountyPolicy, trustGainOnSuccess и т.д.).

3.1) Членство и аффилиации пилотов
- `HashSet<Guid> Members` - список pilotId, которые официально принадлежат фракции (members). Это главные субъекты, от которых фракция может требовать налоги, службы или предоставлять защиту.
- `Dictionary<Guid, AffiliationInfo> AffiliationsPerPilot` - пилоты могут иметь множественные аффилиации/роли (affiliate, contractor, blackmarket_contact, outlaw). `AffiliationInfo` хранит `role`, `sinceTimestamp`, `privileges`.
- Модель принадлежности:
  - `PrimaryFaction` (у пилота) - одна фракция, считающаяся "главной" (например, работодатель/гражданство).
  - `Affiliations` - список дополнительных фракций/сетей (например, pirate network, broker), которые дают доступ к услугам, но не делают пилота полноценным членом.
  - Права и привилегии зависят от `role` и `TrustPerPilot`.

3.2) Отношения между фракциями
- `FactionRelations` - модель отношений между двумя фракциями: `enum RelationType { Allied, Neutral, Hostile, TradePartner, Rival, Vassal }` + `float Influence` и `DateTime lastChanged`.
- Хранение: каждая `Faction` содержит `Dictionary<Guid, FactionRelation> Relations` (factionId -> relation).
- Семантика и эффекты:
  - `Allied` - фракции обмениваются информацией о преступлениях, снижают вероятность преследования при пересечении границ; возможность совместных операций.
  - `Hostile` - юрисдикционные силы одной фракции охотятся на членов другой; торговые маршруты закрыты; black market may favor attacks.
  - `TradePartner` - сниженные tariffs, совместные рынки (включая полу-легальные каналы).
  - `Vassal` - одна фракция платит дань другой; это влияет на распределение bounty и на кто реагирует на преступления.
- Последствия для игровых систем:
  - Director учитывает `FactionRelations` при спауне патрулей и при определении, какой юрисдикции выставлять bounty.
  - BlackMarket/IllegalOffers могут быть изолированы внутри сети дружественных фракций - предложение от pirate network часто "перескакивает" по отношениям.
  - При вычислении detectionRisk учитывается влияние соседних фракций (патрули дружественной фракции снижают риск, враждебной - повышают).


4) Основные API (методы)
- `float GetReputation(Guid pilotId)`
- `void AdjustReputation(Guid pilotId, float delta, ChangeContext ctx = null)`
- `float GetWanted(Guid pilotId)`
- `void AdjustWanted(Guid pilotId, float delta, DetectionContext ctx = null)`
- `float GetTrust(Guid pilotId)`
- `void AdjustTrust(Guid pilotId, float delta, ChangeContext ctx = null)`
- `IEnumerable<Offer> GetOffersForPilot(Guid pilotId, PilotSnapshot snapshot)` - возвращает возможные предложения (легальные или частично легальные). Форма и смысл Offer зависят от специализации фракции.
- `void RegisterOffer(Offer offer)` - регистрирует предложение в пуле фракции (может быть использовано в специализированных фракциях, например `PirateFaction` для `IllegalOffer`).

Примечание: все методы должны проходить через `FactionManager` для синхронизации и сохранения состояния.

5) Примеры специализаций (частные случаи `Faction`)

Ниже - примеры того, как можно расширить базовый `Faction` для конкретных ролей в мире. Эти специализации используют общий API `Faction`, но добавляют поля/политику поведения, специфичную для своей доменной логики.

- `PirateFaction : Faction` (пример криминальной/подпольной сети)
  - Доп. поля (пример): `minTrustForMajorJobs`, `trustGainOnSuccess`, `trustLossOnFailure`, `offersPool`.
  - Поведение: выдача `IllegalOffer` в зависимости от `TrustPerPilot` и `PilotSnapshot` (корабль, навыки, Stage); снижение detectionRisk для trusted pilots; предоставление safehouse/repair discounts для доверенных участников.

- `LegalAuthority : Faction` (пример юрисдикции/правоохранительных органов)
  - Доп. поля (пример): `patrolIntensity`, `bountyPolicy`, `jurisdictionSectors`.
  - Поведение: отслеживание `WantedPerPilot`, публикация bounty, координация патрулей и обмен информацией с союзными фракциями.

- `CorpFaction : Faction` (пример корпорации/работодателя)
  - Доп. поля: `payrolls`, `contracts`, `employeePrivileges`.
  - Поведение: выдача контрактов, начисление зарплаты, дисциплинарные санкции против членов.

Примечание: криминальная фракция (pirate network) - лишь частный пример специализации; базовая `Faction` должна быть независимой и гибкой для любых ролей.

6) Интеграция с подсистемами
- PilotModel / PilotGoalPlanner:
  - `PilotModel` запрашивает `FactionManager.GetOffersForPilot(pilotId)` при оценке опций;
  - `PiracyDecisionModule` использует `Faction` для чтения/модификации trust/wanted/reputation;

- BlackMarketModule (пример интеграции для криминальных/полукриминальных специализаций):
  - `BlackMarketModule` может регистрироваться как сервис или как частный MarketModule, который читает/пишет в `Faction` (например, повышает `Wanted` при detection). Для чисто легальных фракций BlackMarketModule может быть неактивен.

- Director / WorldState:
  - Director наблюдает за `Faction` и реагирует на пороги (bountyThreshold → spawn patrols);
  - WorldState вызывает `FactionManager` при загрузке/сохранении мира;

7) События и Telemetry
- `FactionEvent { type, pilotId, factionId, delta, reason }` - для трассировки изменений;
- Логи: `IllegalOfferAccepted`, `IllegalOfferFailed`, `WantedChanged`, `TrustChanged`.

8) Сценарии использования / примеры
- Пример 1 - успешный smuggling:
  - Pilot принимает `IllegalOffer` от `PirateFaction`; при success `AdjustTrust(pilotId, +0.1)`; `Faction` регистрирует history++; `PilotStage` может повышаться.

- Пример 2 - провал и поимка:
  - Detection → `AdjustWanted(pilotId, +50)` у `LegalAuthority` фракции; Director публикует bounty; PatrolDensity повышается.

9) Точки расширения (дизайнерские и технические)
- ScriptableObject профиль фракции - для быстрого конфигурирования параметров в редакторе.
- UI: Faction dashboard (инспектор) + Debug panel для просмотра per-pilot maps.

10) Performance & Persistence
- Maps могут быть большими; хранить только активные записи и lazy-load/serialize на save.
- `FactionManager` должен быть потокобезопасен и предоставлять snapshot API для симуляции в worker threads.

11) Контракты для разработчиков
- Изменять репутацию/wanted/trust только через `FactionManager` API.
- Не хранить перманентные данные репутации в `PilotModel` - только derived кеши.

---

Рекомендуемое следующее действие: создать `Faction` класс с базовым API и реализовать `PirateFaction` MVP для тестов: simple offers pool, trust adjustments on success/fail, wanted adjustments on detection. Затем интегрировать с `BlackMarketModule` и `PiracyDecisionModule`.

Ссылка: для полной игровой логики перехода пилота в пиратство см. `Assets/Design/pilot_to_pirate.md`.

