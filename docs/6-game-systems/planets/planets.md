# Planets - MVP (design, non-code)

Цель: описать на уровне дизайна, какие данные и поведение должны быть доступны на планетах/телесных объектах, чтобы реализовать MVP hunger-flow, обслуживание кораблей (заправка/ремонт), простую торговлю и социальные услуги (бары). Документ - для дизайнеров и разработчиков, без вставки рабочего кода.

## Краткая идея
Планета/станция предоставляет сервисы (Shop, Dock, Market, MissionBoard, Repair, Fuel, Bar и т.п.), базовую рыночную информацию (цены/запасы) и примитивную систему резервирования доков. Планировщик пилотов должен уметь:

- находить ближайшее тело с нужным сервисом (например, Fuel или Repair),
- оценивать стоимость и время поездки,
- резервировать док,
- вызывать сервис (купить еду, заправиться, отремонтироваться, посидеть в баре).

Экономика для MVP статична или с лёгкой флуктуацией.

## Обязательные поля в CelestialBodyData (дизайнерская конфигурация)
- Название тела и визуальные параметры.
- Services - список сервисов, доступных на теле. Минимальный набор: Shop, Dock, Market, MissionBoard, Repair, Fuel, Bar.
- marketPriceMultiplier - множитель к базовым ценам.
- defaultMarket - ссылка на ассет с набором товаров/услуг и стартовыми запасами (включая Fuel и RepairService как "услуги").
- defaultServicePrices - объект, где задаются цены услуг (Fuel per unit, Repair per health-point, Bar service price, Drink price и т.п.).
- dockOffsets - набор локальных позиций/отступов, используемых как ориентиры докинга.
- Комментарии в инспекторе: краткое описание каждого поля и рекомендации по наполнению.

(Это описание для ScriptableObject - список полей, которые должен увидеть дизайнер в редакторе.)

## PlanetModel / PlanetRuntime - что должно предоставлять (поведение)
- Services - runtime-версия списка сервисов.
- MarketModule (runtime) - текущие цены и доступные количества по товарам и услугам (включая Fuel и RepairService). Использует `MarketModule.Stacks` и вспомогательные методы `GetPrice`/`GetBuyPrice`/`GetSellPrice`.
- DockCapacity и простой пул/таблица резервированных доков (RequestDock/ReleaseDock).
- API/контракты:
  - HasService(service) - быстрое проверочное свойство.
  - EstimatePrice(itemOrService) / GetPrice(itemOrService) - возвращает цену для планировщика.
  - TryPurchase(buyerId, itemOrService, qty) - попытка покупки/заказа услуги.
  - ProvideRefuel(shipId, amountRequested, out float cost) - заправка; атомарная операция.
  - ProvideRepair(shipId, out float cost) - ремонт; атомарная операция (или ремонт на единицу).
  - RequestDock(shipId) - попытка зарезервировать док; возвращает позицию подхода/оценку ожидания (или отказ).
  - ReleaseDock(shipId) - освобождение ранее зарезервированного дока.
  - EstimateTravelTime(fromPosition, shipProfile) - грубая оценка времени полёта.
- Симуляция цен/стока: для MVP - статичные, с опциональной лёгкой флуктуацией.

## MarketModule - концепция
- Хранит пары (itemId → price) и (itemId → stock) и также услуги (e.g., "Fuel" price per unit, "RepairService" price per HP, "Drink" price).
- Предоставляет операции чтения (GetPrice, GetStock) и попытку покупки/заказа услуги (TryBuy/TryService) с атомарным изменением запаса.
- Для услуг (Fuel/Repair) может быть отдельный API (ProvideRefuel/ProvideRepair) для учёта особенностей логики.

## Требования к GenericSimulationManager (дизайн)
- Удобный поиск тел по сервису: FindNearestBodyWithService(position, serviceType) и FindNearestBodiesWithServices(position, services[]).
- Методы для получения данных рынка у тела по Id: используйте `MarketModule` (`GetPrice`, `GetBuyPrice`, `Stacks`).
- Эти helper-методы упрощают логику планировщика пилота.

## Поток взаимодействия - примеры

Пример: пилот нуждается в еде
1. Planner: Hunger высокий → FindNearestBodyWithService(pos, ServiceType.Shop)
2. Получает price = planet.GetPrice("Food") и fuelEstimate = EstimateFuelForTrip(ship, planet)
3. Если ship.CurrentFuel >= fuelEstimate + safetyReserve:
   - Если Credits >= price: TravelTo(planet) → RequestDock → TryPurchase("Food") → pilot.Needs.SatisfyNeed(Hunger)
   - Иначе: поставить цель EarnMoney, затем повторить покупку
4. Если топлива не хватает:
   - Если Credits >= refuelCostNearby: вставить RefuelGoal перед поездкой
   - Иначе: вставить EarnMoneyGoal -> Refuel -> Travel -> Buy

Пример: заправка
1. PilotGoalPlanner генерирует RefuelShipGoal(amount)
2. RefuelShipGoal: TravelTo(nearestFuelStation) -> RequestDock -> ProvideRefuel(shipId, amount)
3. Station уменьшает запас топлива и возвращает cost; пилот списывает Credits и получает топливо

Пример: бар (Entertainment)
1. Planner: Entertainment высоким → FindNearestBodyWithService(pos, ServiceType.Bar)
2. VisitBarGoal: Travel -> Dock -> TryPurchase("Drink", 1) или TryPurchaseService("BarStay", duration)
3. При успешной покупке: pilot.Needs.SatisfyNeed(Entertainment, value); Credits списаны
4. Если Credits недостаточно: EarnMoneyGoal вставляется перед VisitBarGoal

## Синхронизация и атомарность
- Все операции, изменяющие стоки или резерв доков, должны быть атомарными и защищены lock'ами на стороне PlanetModel.
- RequestDock должна учитывать DockCapacity и возвращать ожидаемое время ожидания или отказ.
- ProvideRefuel/ProvideRepair должны корректно возвращать причину отказа (нет ресурса / сервис недоступен / недостаточно средств).

## Тюнинг и рекомендации для тестирования
- Для быстрой итерации использовать timeScale >> 1 и логирование событий (поездка, док, покупка, заправка, ремонт).
- Начать с нескольких тел с сервисами Fuel/Repair/Bar/Shop и разными marketPriceMultiplier.
- Логировать очереди целей пилотов и события сервисов, чтобы видеть поведение при недостатке денег/топлива.
- Параметры для балансировки: цена топлива, скорость расхода топлива, скорость поломок (health decay), fixed docking time, DockCapacity.

## MVP-ограничения и будущие расширения
- MVP: статичная экономика, простая модель услуг (Fuel, Repair, Bar), простое резервирование доков и фиксированные цены.
- Расширения: динамические цены, очереди докинга с тайм-аутами, разные типы топлива, тарифы за ремонт, персонализованные бары (VIP услуги).

---

Коротко: CelestialBodyData должен позволять дизайнерам включать сервисы Fuel/Repair/Bar и задавать цены услуг. PlanetModel предоставляет `MarketModule` с товарами и услугами (через `MarketModule.Stacks` и методы `GetPrice`/`TryBuy`/`TrySell`), атомарные операции `ProvideRefuel`/`ProvideRepair`, и простой пул доков для `Request`/`Release`. Это даёт планировщикам пилотов все данные для удовлетворения как пилота, так и корабля.

