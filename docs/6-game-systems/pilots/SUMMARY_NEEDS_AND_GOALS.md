# Система потребностей и целей — Summary

## 🎯 Цель проекта
Создать систему принятия решений для NPC-пилотов на основе потребностей, которая позволит им автономно выбирать действия (покупка еды, отдых, торговля, миссии) в зависимости от внутреннего состояния.

## ✅ Что сделано (Phase 1 - Базовая инфраструктура)

### Созданные файлы

1. **PilotNeeds.cs** — Система потребностей
   - 4 базовые потребности: Hunger, Comfort, Entertainment, SelfActualization
   - Скорости изменения (NeedRates)
   - Пороги критичности (NeedThresholds)
   - Расчёт срочности с учётом личности пилота

2. **Goal.cs** — Базовый класс целей
   - Интерфейс Execute/OnComplete/OnFail
   - Таймауты и проверка состояния
   - Прогресс выполнения

3. **GoalQueue.cs** — Очередь целей
   - Управление последовательностью целей
   - Делегирование выполнения
   - Обработка завершения/провала

4. **PilotGoalPlanner.cs** — Планировщик целей
   - Анализ потребностей
   - Генерация целей по приоритету
   - Учёт личности (Caution, Greed, Loyalty, Aggression)

5. **Реализованные цели (MVP)**:
   - **WanderGoal** — блуждание по умолчанию
   - **TravelToLocationGoal** — перемещение к точке
   - **RestGoal** — отдых и восстановление

### Документация

1. **needs_and_goals_architecture.md** — Полная архитектура системы (600+ строк)
2. **README_NEEDS_AND_GOALS.md** — Краткий обзор и использование
3. **INTEGRATION_GUIDE.md** — Инструкции по интеграции в PilotModel

## 📐 Архитектурная схема

```
PilotModel.Simulate(dt)
    │
    ├─> Needs.UpdateNeeds(dt)          # Обновление потребностей
    │   ├─> Hunger += 1.0/hour
    │   ├─> Comfort -= 0.5/hour
    │   ├─> Entertainment -= 0.3/hour
    │   └─> SelfActualization -= 0.1/hour
    │
    ├─> ResolveGoals()                 # Планирование
    │   ├─> GetMostUrgentNeed()
    │   │   └─> (NeedType, urgency) с учётом личности
    │   └─> planner.PlanNextGoal()
    │       └─> Goal (Wander/Rest/Travel/etc)
    │
    └─> Goals.ExecuteCurrentGoal()     # Выполнение
        ├─> goal.Execute(dt)
        ├─> if Complete → OnComplete()
        └─> if Failed → OnFail()
```

## 🎨 Ключевые дизайн-решения

### 1. Потребности изменяются очень медленно
- Hunger: ~100 часов до критичного (1 unit/hour)
- Позволяет наблюдать поведение даже при нормальной скорости игры

### 2. Личность влияет на приоритеты
```csharp
hungerUrgency = Hunger * (1 + Caution * 0.5)       // Осторожные едят раньше
comfortUrgency = Comfort * (1 + Greed * 0.5)       // Жадные хотят лучшее
entertainmentUrgency = Entertainment * (1 - Loyalty * 0.3)  // Лояльные меньше отдыхают
selfActUrgency = SelfActualization * (1 + Aggression * 0.3) // Агрессивные стремятся к целям
```

### 3. Thread-safe дизайн
- Все операции под `lock(Sync)`
- Безопасно для фоновой симуляции
- Никаких Unity API из background threads

### 4. MVP-first подход
- Phase 1: Базовая инфраструктура (готово)
- Phase 2: Интеграция с PilotModel (следующий шаг)
- Phase 3: Hunger flow с PlanetModel
- Phase 4: Остальные потребности
- Phase 5: Баланс и полировка

## 📊 Пример поведенческого flow

### Hunger Flow (будущее - Phase 3)
```
1. Hunger > 70 (критично)
   ├─> Credits >= foodCost?
   │   ├─> Да:  [TravelToStation → Dock → BuyFood]
   │   └─> Нет: [EarnMoney → TravelToStation → Dock → BuyFood]
   │
2. Hunger снижается на 70 после успешной покупки
3. Morale повышается (+5)
4. Цикл повторяется через ~70-100 часов
```

### Текущий MVP Flow (Phase 1)
```
1. Hunger > 70 (критично)
   └─> RestGoal(60s, Hunger)  # stub: "еда" через отдых
       └─> Hunger -= 50
```

## 🔧 Интеграция в проект

### Минимальные изменения в PilotModel:
```csharp
// Добавить поля:
public PilotNeeds Needs;
public GoalQueue Goals;
private PilotGoalPlanner planner;

// В конструкторе:
Needs = new PilotNeeds();
Goals = new GoalQueue();
planner = new PilotGoalPlanner();

// В Simulate(dt):
Needs.UpdateNeeds(dt, this);
if (Goals.IsEmpty)
    Goals.PushGoal(planner.PlanNextGoal(this, Needs));
Goals.ExecuteCurrentGoal(dt, this, ship);
```

### Обратная совместимость
Старая логика DecideAndCommand может быть сохранена опционально через флаг `UseNeedsSystem`.

## 🎯 Следующие шаги

### Phase 2: Интеграция (2-3 дня)
1. Обновить PilotModel.cs согласно INTEGRATION_GUIDE.md
2. Тестирование базового поведения (wander/rest)
3. Настройка логирования
4. Простой debug UI

### Phase 3: Hunger Flow (3-4 дня)
1. Создать PlanetModel stub с API:
   - `HasService(ServiceType)`
   - `RequestDock(shipId) → dockPosition`
   - `TryPurchase(item, qty) → cost`
2. Реализовать цели:
   - DockAtStationGoal
   - BuyItemGoal
   - EarnMoneyGoal (stub)
3. Обновить PlanHungerGoal в планировщике
4. End-to-end тест

### Phase 4: Остальные потребности (5-7 дней)
1. Comfort → upgrade ship
2. Entertainment → visit bar
3. SelfActualization → missions/trade

### Phase 5: Баланс (2-3 дня)
1. Телеметрия (частота целей, время выполнения)
2. Настройка скоростей и порогов
3. Debug UI для мониторинга

## 📈 Ожидаемые результаты

После полной реализации:

✅ **Автономные пилоты**: Сами решают что делать на основе потребностей  
✅ **Разнообразие поведения**: Личность влияет на приоритеты  
✅ **Масштабируемость**: Поддержка сотен пилотов в background  
✅ **Расширяемость**: Легко добавлять новые потребности и цели  
✅ **Отладка**: Логи и UI для мониторинга состояния  

## 🛠️ Технические детали

### Производительность
- Minimal allocations (Queue reuse)
- Simple priority calculation (O(1))
- One goal execution per pilot per tick
- Thread-safe для background simulation

### Зависимости
- Unity Engine (Vector3, Mathf, Debug)
- GenericSimulationManager (для поиска планет/кораблей)
- ShipModel (для управления кораблём)
- ISimulatable interface

### Расширения (будущее)
- Utility-based AI (вместо простого priority)
- Behavior Trees
- Cooperative planning (групповые цели)
- Machine Learning (адаптивное поведение)

## 📚 Документация

| Файл | Описание |
|------|----------|
| `needs_and_goals_architecture.md` | Полная архитектура (600+ строк) |
| `README_NEEDS_AND_GOALS.md` | Краткий обзор и API |
| `INTEGRATION_GUIDE.md` | Инструкции по интеграции |
| `pilots.md` | Дизайн-документ (game design) |
| `planets.md` | Интеграция с планетами (Phase 3+) |

## ✨ Ключевые особенности

1. **Простота использования**: Минимальная интеграция (3 поля + init)
2. **Гибкость**: Легко добавлять новые цели
3. **Наблюдаемость**: Подробное логирование
4. **Модульность**: Каждый компонент независим
5. **Тестируемость**: Чистые классы, легко юнит-тестировать

---

**Статус**: ✅ Phase 1 завершена  
**Готовность к интеграции**: Да  
**Следующий шаг**: Обновить PilotModel.cs  
**Дата**: November 6, 2025

