# Pilots - Design notes (game-design level)

Цель: описать поведение NPC-пилотов (контроллер корабля) через систему потребностей → целей → задач → действий. Документ - руководство для реализации и балансировки, не детальный код, но с ясными интеграционными точками.

## 1. Концепт
Пилоты имеют набор долгоживущих потребностей, которые меняются очень медленно и формируют высокоуровневые мотивации (глобальные цели). Из глобальной цели пилот ставит краткосрочные цели (задачи) и план действий (action sequence). Решения зависят от состояния пилота, навыков, личности и ограничений (деньги, доступность станций и т.п.).

Важно: поведение пилота зависит не только от его личных потребностей, но и от состояния корабля. План, генерируемый планировщиком, должен вставлять сервисные цели (заправка/ремонт) как предусловия перед выполнением действий, требующих перемещения.

Основные потребности (0..100, 0 - идеал/сыто, 100 - критично):
- Hunger (Голод)
- Comfort (Комфорт / экипировка / жилище)
- Entertainment (Развлечения / досуг / мораль)
- SelfActualization (Самореализация - карьерный рост, достижения)

Потребности изменяются очень медленно (часы/дни в игровых секундах).

## 2. Ship-related needs (дополнение)
Пилот контролирует корабль, у корабля есть свои потребности, которые влияют на планирование:
- Fuel (топливо): CurrentFuel / MaxFuel, расход FuelPerUnit
- Health (состояние корпуса): CurrentHealth / MaxHealth (требуется ремонт при повреждениях)
- Repair need: если CurrentHealth < threshold -> RepairGoal

Planner должен:
- Оценивать fuelNeeded для предполагаемой поездки;
- Вставлять RefuelShipGoal, если топлива недостаточно плюс safetyReserve;
- Вставлять RepairShipGoal, если здоровье ниже порога, особенно перед рискованными задачами.

## 3. Поведение для Entertainment и Comfort (бары и сервисы)
- Для удовлетворения Entertainment и части Comfort (социальная составляющая) пилот посещает Bar на планете/станции.
- Посещение бара платное: VisitBarGoal вызывает TryPurchase("Drink" / "BarStay") или TryService("BarStay"). При покупке пилот теряет Credits, а потребность Entertainment уменьшается.
- Если у пилота недостаточно Credits, планировщик ставит EarnMoneyGoal перед VisitBarGoal.
- Поведение: VisitBarGoal включается в GoalChain: [EarnMoneyGoal (опционально) -> Refuel/Repair (если нужно) -> TravelTo -> Dock -> VisitBarGoal]

## 4. Динамика изменения (пример)
Поскольку симуляция работает с dt (секунды), используем скорость в единицах "за час":
- HungerIncreasePerHour = 1.0
- ComfortDecreasePerHour = 0.5
- EntertainmentDecreasePerHour = 0.3
- SelfActualizationDecreasePerHour = 0.1

Для корабля:
- FuelConsumption рассчитывается на основе пройденной дистанции и FuelPerUnit
- Health деградирует в бою/авариях; восстанавливается через RepairService

Вычисление применить:
delta = (ratePerHour / 3600.0f) * dt

## 5. Приоритет целей - обновлённая формула
Для каждой потребности вычисляем urgency; затем учитывать MoneyFactor и ShipFactor:

- urgency = NeedValue * (1 + PersonalityModifier)
- ShipFactor повышает приоритет сервисных задач:
  - если ship.CurrentFuel < requiredFuel + reserve → высокая приоритетность Refuel
  - если ship.CurrentHealth < repairThreshold → Repair priority ↑

MoneyFactor:
- если Credits < estimatedCost → increase priority for EarnMoneyGoal and reduce direct spending goals

Простой выбор цели:
score = urgency * ShipWeight / (1 + MoneyFactor)

## 6. Примеры деревьев решений

### Hunger (коротко)
1. Hunger > threshold?
2. FindNearestBodyWithService(Shop)
3. Estimate fuelNeeded
4. if ship.fuel >= fuelNeeded + reserve:
   - if Credits >= foodCost: [Travel -> Dock -> BuyFood]
   - else: [EarnMoney -> Travel -> Dock -> BuyFood]
5. else:
   - if Credits >= refuelCostNearby: [Refuel -> Travel -> Dock -> BuyFood]
   - else: [EarnMoney -> Refuel -> Travel -> BuyFood]

### Entertainment (бар)
1. Entertainment > threshold?
2. FindNearestBodyWithService(Bar)
3. Estimate fuelNeeded and barCost
4. if Credits >= barCost and fuel sufficient:
   - [Travel -> Dock -> VisitBarGoal]
5. else:
   - [EarnMoney -> (Refuel if needed) -> VisitBarGoal]

### Comfort (обновление)
- Комфорт покрывает желание апгрейда/ремонта и социальный комфорт.
- Для ремонта/улучшения корабля Planner формирует GoalChain: [EarnMoney? -> Travel -> Dock -> Repair/Upgrade]
- Часть "comfort via social" реализуется через VisitBarGoal (платный) - уменьшает Comfort/Entertainment.

## 7. Goal / Task types (минимальный набор, дополнение)
- TravelToLocationGoal(locationId)
- BuyItemGoal(itemType, amount)
- Trade(route, buyStation, sellStation)
- UpgradeShipGoal(partType)
- RestGoal(duration) - уменьшает Fatigue, повышает Morale
- TakeMissionGoal(missionId)
- Socialize / VisitBarGoal(locationId)
- RefuelShipGoal(stationId, amount)
- RepairShipGoal(stationId)
- EarnMoneyGoal(amount, preferredSource)
- WanderGoal / Idle

Каждый Goal имеет preconditions, estimatedCost, success/failure handlers, priorityScore.

## 8. Planner - интеграция действий и проверка предусловий
- Simulate loop:
  - UpdateNeeds(dt)
  - Compute urgencies
  - If Goals empty -> PlanNextGoal
  - PlanNextGoal must:
    - выбрать нужный тип цели
    - найти ближайшие станции/сервисы
    - оценить расстояния и fuelNeeded
    - вызвать EnsureShipSupportGoals - вставить Refuel/Repair/EarnMoney если нужно
    - вернуть GoalChain, где первые элементы обеспечивают технические предусловия

## 9. Псевдо-код примера: PlanEntertainmentGoal
```csharp
// Language: csharp
private Goal PlanEntertainmentGoal(PilotModel pilot, PilotNeeds needs)
{
    var bar = FindNearestPlanetWithService(pilot.Position, ServiceType.Bar);
    if (bar == null) return new RestGoal(1800f, NeedType.Entertainment);

    float barCost = bar.Market.GetPrice("Drink");
    float fuelNeeded = EstimateFuelForTrip(pilot.AssignedShipId, bar.Position);

    List<Goal> chain = new List<Goal>();

    if (pilot.Credits < barCost)
        chain.Add(new EarnMoneyGoal(barCost - pilot.Credits, MoneySource.Trade));

    if (ShipNeeds.NeedsRefuel(fuelNeeded + SafetyReserve))
        chain.Add(new RefuelShipGoal(FindNearestFuelStation(pilot.Position), fuelNeeded + SafetyReserve - ship.CurrentFuel));

    chain.Add(new TravelToLocationGoal(bar.Id, bar.Position));
    chain.Add(new DockAtStationGoal(bar.Id));
    chain.Add(new VisitBarGoal(bar.Id, 1)); // 1 drink

    return new GoalChain(chain);
}
```

## 10. EarnMoneyGoal - базовый контракт
- На MVP EarnMoneyGoal может быть stub: мгновенный приток credits (для упрощённого тестирования поведения).
- В полной версии: EarnMoneyGoal выполняет поиск миссии/трейда и ставит подзадачи (Travel -> Trade -> Sell) для получения дохода.
- Planner должен учитывать risk/time tradeoff при выборе источника заработка.

## 11. Баланс и тюнинг
- Настроить цены на Drink, Fuel per unit и Repair per HP в defaultMarket.
- Наблюдать, как часто Pilots генерируют EarnMoneyGoal (слишком частые укажут на плохой баланс цен/зарплат).
- SafetyReserve и пороги ремонта влияют на количество сервисных поездок.

## 12. Debug / Telemetry
- Логи: создание VisitBarGoal/RefuelShipGoal/RepairShipGoal/EarnMoneyGoal, покупки в баре, списания Credits, успешные/провальные сервисные операции.
- Debug UI: текущие потребности, очередь целей, следующая цель, требуемый fuel и ближайшая станция с сервисом.

## 13. Минимальная следующая реализация (MVP)
1. Добавить поля Needs в PilotModel и UpdateNeeds(dt) (если ещё не добавлены).
2. Добавить ShipNeeds helpers в ShipModel (EstimateFuelNeeded, NeedsRefuel, NeedsRepair).
3. Добавить VisitBarGoal, RefuelShipGoal, RepairShipGoal классы и интегрировать с CelestialModel API.
4. Изменить PilotGoalPlanner.PlanNextGoal чтобы вызывать EnsureShipSupportGoals.
5. Для тестов: реализовать EarnMoneyGoal как быстрый stub.
6. Прогон end-to-end тестов: пилот с высоким Entertainment и нулём денег должен поставить EarnMoneyGoal и затем VisitBarGoal.

---

Кратко: расширить planner так, чтобы он учитывал сервисные нужды ship (заправка/ремонт) и позволял пилоту ходить в бары за деньги; при отсутствии средств пилот сначала зарабатывает. Это обеспечивает предсказуемое поведение и предотвращает недостижимые целей (поездка без топлива или без денег).

