# Архитектура системы потребностей и целей пилотов

## Обзор

Документ описывает архитектуру системы принятия решений для NPC-пилотов, основанную на потребностях (needs), мотивациях (motivations) и целях (goals). Система интегрируется с существующим PilotModel, ShipModel и GenericSimulationManager.

Важно: помимо потребностей пилота, симуляция теперь учитывает потребности корабля (топливо, состояние/ремонт и т.п.). Планировщик пилота должен уметь ставить цели для удовлетворения как потребностей пилота (еда, отдых, развлечения, самореализация), так и потребностей корабля (заправка, ремонт).

---

## 1. Архитектурная схема

```
┌─────────────────────────────────────────────────────────────┐
│                      PilotModel                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              PilotNeeds (компонент)                  │   │
│  │  - Hunger: 0..100                                    │   │
│  │  - Comfort: 0..100                                   │   │
│  │  - Entertainment: 0..100                             │   │
│  │  - SelfActualization: 0..100                         │   │
│  │  + UpdateNeeds(dt): обновление с течением времени   │   │
│  │  + GetUrgentNeed(): возвращает самую срочную         │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            PilotGoalPlanner (компонент)              │   │
│  │  + EvaluateNeeds(): анализ потребностей              │   │
│  │  + CreateGoalForNeed(): генерация цели               │   │
│  │  + EnsureShipNeeds(): вставляет Refuel/Repair когда нужно││
│  └──────────────────────────────────────────────────────┘   │
│                           ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              GoalQueue (компонент)                   │   │
│  │  - Queue<Goal> goals                                 │   │
│  │  - Goal CurrentGoal                                  │   │
│  │  + PushGoal(goal)                                    │   │
│  │  + ExecuteCurrentGoal(dt, ship): выполнение          │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │        Goal (абстрактный базовый класс)              │   │
│  │  + Execute(dt, pilot, ship): bool                    │   │
│  │  + IsComplete: bool                                  │   │
│  │  + IsFailed: bool                                    │   │
│  │  ────────────────────────────────────                │   │
│  │  Наследники:                                         │   │
│  │  - TravelToLocationGoal                              │   │
│  │  - BuyItemGoal                                       │   │
│  │  - EarnMoneyGoal                                     │   │
│  │  - RefuelShipGoal                                    │   │
│  │  - RepairShipGoal                                    │   │
│  │  - DockAtStationGoal                                 │   │
│  │  - VisitBarGoal                                      │   │
│  │  - RestGoal                                          │   │
│  │  - TradeRouteGoal                                    │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│           GenericSimulationManager                          │
│  - GetModelsOfType<CelestialModel>()                       │
│  - GetById(Guid): ISimulatable                              │
│  - FindNearestPlanetWithService(pos, serviceType)           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    CelestialModel                              │
│  - Services: List<ServiceType>                              │
│  - MarketModule: цены, стоки                                 │
│  - DockCapacity, ReservedDocks                              │
│  + HasService(ServiceType): bool                            │
│  + RequestDock(shipId): bool                                │
│  + TryPurchase(item, qty, cost): bool                       │
│  + ProvideRefuel(shipId, amount) -> cost, success           │
│  + ProvideRepair(shipId) -> cost, success                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Компоненты системы

### 2.1 PilotNeeds — Система потребностей

(См. оригинал — без изменений по базовым полям, оставляем Hunger/Comfort/Entertainment/SelfActualization и методы UpdateNeeds, GetMostUrgentNeed, SatisfyNeed)

### 2.2 ShipNeeds — новый компонент (потребности корабля)

Ответственность:
- Хранение состояний корабля, которые влияют на поведение пилота (топливо, состояние/повреждения, необходимость ремонта).
- Предоставление простых предикатов/оценок: NeedsRefuel(), NeedsRepair(), EstimateRefuelCost(), EstimateRepairCost().
- Планировщик пилота должен проверять эти предикаты при формировании целей: если кораблю нужна заправка или ремонт до безопасного выполнения путешествия/покупки, вставлять соответствующие цели перед TravelToLocationGoal.

Поля (пример для ShipModel + ShipNeeds-обёртки):
```csharp
// В ShipModel уже есть:
public float MaxFuel;
public float CurrentFuel;
public float FuelPerUnit;

// Добавить/описать:
public float MaxHealth;
public float CurrentHealth;
public float RepairCostMultiplier = 1.0f; // множитель цены ремонта на станциях
```

Методы/логика:
- bool NeedsRefuel(float safeMargin) => CurrentFuel < safeMargin
- float EstimateDistanceTo(Vector3 target) -> distance (используется с FuelPerUnit)
- float EstimateFuelNeeded(distance) => distance * FuelPerUnit
- bool NeedsRepair(float threshold) => CurrentHealth < threshold

Интеграция:
- Planner перед созданием целей для пилота вызывает EnsureShipOperational(pilot, ship, plannedDistanceEstimate).
- Если топлива не хватает, вставляется цепочка: FindNearestPlanetWithService(Repair|Dock|Fuel) → TravelTo → Dock → Refuel (RefuelShipGoal).
- Если ремонт нужен — аналогично: вставить RepairShipGoal.
- Refuel и Repair — цель, которая вызывает у CelestialModel соответствующие сервисы (Fuel/Repair/Shop).

### 2.3 PilotGoalPlanner — Планировщик целей (обновлённый)

Ответственность:
- Анализ потребностей пилота и состояния корабля.
- Генерация целей, которые могут включать как удовлетворение пилота, так и обслуживание корабля.
- Вставка сервисных целей (Refuel/Repair) как предусловий для целевых действий (например, поездки к магазину).

Основной метод (псевдокод):
```csharp
public Goal PlanNextGoal(PilotModel pilot, PilotNeeds needs)
{
    // 1. получить самую срочную потребность
    var (needType, urgency) = needs.GetMostUrgentNeed(pilot);

    // 2. если срочность низкая -> wander
    if (urgency < 30f) return new WanderGoal(...);

    // 3. сформировать основную цель в зависимости от needType
    Goal mainGoal = needType switch {
        NeedType.Hunger => PlanHungerGoal(pilot, needs),
        NeedType.Comfort => PlanComfortGoal(pilot, needs),
        NeedType.Entertainment => PlanEntertainmentGoal(pilot, needs),
        NeedType.SelfActualization => PlanSelfActualizationGoal(pilot, needs),
    };

    // 4. Получить оценку расстояний/времени для mainGoal (например, target planet position)
    // 5. Проверить состояние корабля: нужен ли Refuel/Repair перед выполнением mainGoal?
    // 6. Если нужен Refuel/Repair — обернуть mainGoal в GoalChain: [Refuel/Repair, mainGoal]
    return EnsureShipSupportGoals(pilot, mainGoal);
}
```

Пример: hunger flow с учётом корабля
- Hunger критичен -> найти ближайший бар/магазин
- Оценить расстояние и fuelNeeded
- Если Credits >= foodCost и ship.CurrentFuel >= fuelNeeded:
  - Travel -> Dock -> Buy
- Если ship.CurrentFuel < fuelNeeded:
  - EarnMoney не нужен только ради топлива если есть Credits >= refuelCost
  - Вставить RefuelGoal (или EarnMoneyGoal -> Refuel -> Travel -> Buy)
- Если пилоту нужен Entertainment -> VisitBarGoal (Bar тратит Credits и удовлетворяет Entertainment). Если Credits недостаточно — EarnMoneyGoal inserted.

### 2.4 GoalQueue — Очередь целей

(Как в оригинале — без изменений; важно: GoalChain теперь может содержать сервисные цели: RefuelShipGoal, RepairShipGoal, VisitBarGoal)

---

## 3. Новые Goal-типы (MVP)

Ниже описаны минимальные цели, необходимые для обслуживания корабля и взаимодействия с барами.

### 3.1 RefuelShipGoal
- Цель: получить топливо на станции/планете с сервисом Repair/Market/Dock/Fuel (ServiceType.Fuel или Repair/Shop если Fuel не выделен).
- Логика:
  1. При старте ищет ближайшую станцию с сервисом Fuel/Shop/Dock.
  2. TravelToLocationGoal -> DockAtStationGoal -> попытка Refuel через CelestialModel.Station.ProvideRefuel(shipId, desiredAmount) → возвращает cost и success.
  3. Если успех: списать Credits, увеличить CurrentFuel на amount, IsComplete = true.
  4. В противном случае: IsFailed (и возможен fallback: EarnMoneyGoal -> повтор).

- Оценки: EstimatedCost = amount * stationFuelPrice, EstimatedTime = travelTime + dockTime + serviceTime.

### 3.2 RepairShipGoal
- Цель: привести CurrentHealth к приемлемому уровню.
- Логика:
  1. Найти ближайшую станцию с сервисом Repair (или Shop с Repair).
  2. TravelTo -> Dock -> вызов CelestialModel.ProvideRepair(shipId) -> возвращает cost и success.
  3. Если успех: списать Credits, повысить CurrentHealth, IsComplete.

### 3.3 VisitBarGoal
- Цель: посещение бара для снижения Entertainment и повышения Morale.
- Логика:
  1. Найти ближайшую планету/станцию с сервисом Bar.
  2. TravelTo -> Dock -> RestGoal(внутри бара) или отдельная операция VisitBar, которая списывает Credits за время/услугу и снижает Entertainment.
  3. Если Credits недостаточно: вставить EarnMoneyGoal перед VisitBarGoal.

Примечание: бар — платная услуга. Для простоты: VisitBarGoal вызывает `TryPurchase("Drink", qty=1)` через API планеты, который делегирует вызов к `MarketModule` планеты; если не хватает денег или товара, цель провалена и планировщик ставит `EarnMoneyGoal`.

---

## 4. Интеграция ShipModel ↔ Planner

ShipModel (существующий) уже содержит базовые поля: CurrentFuel, MaxFuel, FuelPerUnit, CurrentHealth, MaxHealth. Планировщик использует их:

- Перед назначением TravelToLocationGoal вычислить requiredFuel = EstimateFuelNeeded(distance).
- Если CurrentFuel < requiredFuel + safetyReserve:
  - Найти ближайшую планету с ServiceType.Repair или ServiceType.Dock или ServiceType.Fuel
  - Вставить RefuelShipGoal перед TravelTo
- Если CurrentHealth < repairThreshold:
  - Вставить RepairShipGoal перед TravelTo

Safety rules:
- safetyReserve рассчитывается как минимальное количество топлива, чтобы добраться до ближайшей заправки + небольшой запас.
- Если нет доступных заправок в радиусе — планировщик должен выбирать EarnMoney/TradeGoal чтобы накопить и/или избегать дальних поездок.

---

## 5. Обновления CelestialModel / PlanetModel (требования)

CelestialModel должен объявлять сервисы:
- ServiceType.Fuel (или использовать Repair/Shop с флагом canRefuel)
- ServiceType.Repair
- ServiceType.Bar

API дополнения:
- bool CanRefuel => HasService(ServiceType.Fuel) || HasService(ServiceType.Shop)
- bool ProvideRefuel(Guid shipId, float amount, out float cost)
- bool ProvideRepair(Guid shipId, out float cost)
- TryPurchase должен учитывать, что покупка в Bar уменьшает Credits и удовлетворяет Entertainment (или создает RestGoal)

Требования дизайна (см. planets.md): CelestialBodyData должен позволять задавать, какие сервиса доступны (включая Fuel/Repair/Bar) и цену топлива/ремонта/услуг.

---

## 6. Примеры деревьев решений с учётом корабля

### Hunger (расширенный)
1. Hunger > threshold?
2. Найти ближайший Shop/Bar с Food
3. Оценить travel distance -> requiredFuel
4. Если ship.CurrentFuel >= requiredFuel + reserve:
   a. Если Credits >= foodCost:
      - [Travel -> Dock -> BuyItem(Food)]
   b. Иначе:
      - [EarnMoney -> Travel -> Dock -> BuyItem(Food)]
5. Иначе (нехватка топлива):
   a. Если Credits >= refuelCostNearby:
      - [Refuel -> Travel -> Dock -> BuyItem(Food)]
   b. Иначе:
      - [EarnMoney -> Refuel -> Travel -> BuyItem(Food)]

### Entertainment (бар)
1. Entertainment > threshold?
2. Найти nearest Bar
3. Оценить travel fuel
4. Если Credits >= barCost и ship fuel sufficient:
   - [Travel -> Dock -> VisitBarGoal]
5. Иначе:
   - [EarnMoney -> (Refuel if needed) -> VisitBarGoal]

---

## 7. Реализация оценок затрат и предусловий

Planner использует методы:
- float EstimateTravelFuel(Vector3 from, Vector3 to, ShipModel ship) => distance * ship.FuelPerUnit
- float EstimateRefuelCost(CelestialModel station, float amount) => station.Market.GetPrice("Fuel") * amount * stationPriceMultiplier
- float EstimateRepairCost(CelestialModel station) => function of (MaxHealth - CurrentHealth) * stationRepairRate * RepairCostMultiplier

Эти оценки используются для вычисления MoneyFactor в формуле приоритета: если пилоту/кораблю не хватает денег, urgency уменьшается и ростёт приоритет EarnMoneyGoal.

---

## 8. Изменения в Goal.Execute для сервисных целей

- RefuelShipGoal.Execute:
  - при достижении дока вызывает station.ProvideRefuel(ship.Id, neededAmount)
  - если station возвращает cost и success -> deduct Credits, increase CurrentFuel
  - IsComplete при успехе

- RepairShipGoal.Execute:
  - аналогично: station.ProvideRepair(ship.Id) -> deduct Credits, increase CurrentHealth

- VisitBarGoal.Execute:
  - at dock calls station.TryPurchase(buyerId, "Drink", 1, out cost)
  - if success -> pilot.Needs.SatisfyNeed(NeedType.Entertainment, amount) and pilot.Credits -= cost

Все вызовы, изменяющие стоки или резервацию доков, должны быть атомарными и защищены lock'ами на стороне CelestialModel.

---

## 9. Точки внедрения в кодовую базу

1. ShipModel: документировать/убедиться что CurrentFuel/MaxFuel/FuelPerUnit и CurrentHealth/MaxHealth присутствуют и доступны планировщику.
2. GenericSimulationManager: добавить helper FindNearestPlanetWithService(position, service) и FindNearestWithAnyServices(position, services[])
3. CelestialModel: реализовать ProvideRefuel/ProvideRepair, добавить ServiceType.Fuel, ServiceType.Repair, ServiceType.Bar
4. PilotGoalPlanner: при планировании целей вызывать EnsureShipSupportGoals(pilot, ship, mainGoal) и вставлять Refuel/Repair/EarnMoney при необходимости
5. Новые Goal-классы: RefuelShipGoal, RepairShipGoal, VisitBarGoal
6. MarketModule: добавить позицию "Fuel" и "RepairService" или относиться к ним как к услугам со своими ценами (сохранить через `MarketModule.Stacks`)

---

## 10. Пример псевдо-кода: EnsureShipSupportGoals

```csharp
private Goal EnsureShipSupportGoals(PilotModel pilot, Goal mainGoal)
{
    var ship = GenericSimulationManager.Instance.GetById(pilot.AssignedShipId) as ShipModel;
    if (ship == null) return mainGoal;

    // estimate total travel distance required by mainGoal (simplified)
    float requiredFuel = Planner.EstimateFuelForGoal(mainGoal, ship);

    // check repair need
    if (ship.CurrentHealth < ship.MaxHealth * 0.5f)
    {
        var repairGoal = new RepairShipGoal(FindNearestRepairStation(pilot.Position));
        return new GoalChain(new []{ repairGoal, mainGoal });
    }

    // check fuel need
    if (ship.CurrentFuel < requiredFuel + Planner.SafetyFuelReserve)
    {
        var refuelGoal = new RefuelShipGoal(FindNearestFuelStation(pilot.Position), requiredFuel + Planner.SafetyFuelReserve - ship.CurrentFuel);
        return new GoalChain(new []{ refuelGoal, mainGoal });
    }

    return mainGoal;
}
```

---

## 11. Баланс и тюнинг

- Настройте price/stock для Fuel и RepairService в defaultMarket для планет.
- SafetyFuelReserve — величина в литрах/единицах топлива, необходимая, чтобы добраться до ближайшей станции.
- Refuel/Repair должны иметь временные лимиты и таймауты резерва дока.
- VisitBar прибавляет Entertainment и Morale, но расходует Credits.

---

## 12. Тесты и проверка

MVP тесты:
1. Создать пилота и корабль с малым запасом топлива -> убедиться, что при возникновении потребности пилот сначала вставляет RefuelGoal перед TravelTo.
2. Пилот без денег, но с высоким Entertainment -> должен поставить EarnMoneyGoal перед VisitBarGoal.
3. Пилоты, посещающие BusyStation: RequestDock возвращает отказ и планировщик ищет альтернативу.

Логирование:
- Логировать создание RefuelShipGoal/RepairShipGoal/VisitBarGoal и решения EarnMoneyGoal.
- Логировать покупки в Bar и списание Credits.

---

## 13. Заключение

Добавление потребностей корабля и платных баров существенно повышает реализм поведения NPC. Пилотский планировщик обязан учитывать не только внутренние потребности пилота, но и состояние корабля — иначе пилоты будут застревать в невозможных задачах (поездки без топлива и т.д.). Внедрение описанных целей и сервисов в планетные ассеты (CelestialBodyData) позволит дизайнерам гибко настраивать, где доступны заправки, ремонт и бары.

*Файлы и кодовые изменения — следующие шаги: обновить планировщик (PilotGoalPlanner), добавить новые Goal-типы (RefuelShipGoal, RepairShipGoal, VisitBarGoal), расширить `CelestialModel` API и использовать `MarketModule`. После подтверждения приступаю к реализации.*

