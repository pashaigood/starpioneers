# Система потребностей и целей пилотов

## Краткий обзор

Система принятия решений для NPC-пилотов, основанная на потребностях (needs), мотивациях (motivations) и целях (goals).

## Архитектура

```
PilotModel
├── PilotNeeds         - Управление потребностями (Hunger, Comfort, Entertainment, SelfActualization)
├── GoalQueue          - Очередь целей для выполнения
└── PilotGoalPlanner   - Планировщик целей на основе потребностей
```

## Основные компоненты

### 1. PilotNeeds
Управляет четырьмя основными потребностями:
- **Hunger** (голод) - растёт со временем, требует еды
- **Comfort** (комфорт) - снижается, требует апгрейдов корабля
- **Entertainment** (развлечения) - снижается, требует отдыха/баров
- **SelfActualization** (самореализация) - снижается, требует миссий/торговли

### 2. Goal (базовый класс)
Абстрактный класс для всех целей:
- `Execute(dt, pilot, ship)` - выполнение цели
- `OnComplete(pilot)` - обработка успешного завершения
- `OnFail(pilot)` - обработка провала
- Таймауты и проверка состояния

### 3. Реализованные цели (MVP Phase 1-2)
- **WanderGoal** - случайное блуждание (цель по умолчанию)
- **TravelToLocationGoal** - перемещение к точке назначения
- **RestGoal** - отдых и восстановление сил

### 4. GoalQueue
Управление очередью целей:
- Добавление/удаление целей
- Выполнение текущей цели
- Обработка завершения/провала

### 5. PilotGoalPlanner
Планировщик целей:
- Анализ потребностей
- Генерация целей на основе приоритетов
- Учёт личности пилота

## Интеграция с PilotModel

### Добавленные поля
```csharp
public PilotNeeds Needs;
public GoalQueue Goals;
private PilotGoalPlanner planner;
```

### Цикл Simulate
```csharp
public void Simulate(float dt)
{
    lock (Sync)
    {
        // 1. Обновить потребности
        Needs.UpdateNeeds(dt, this);
        
        // 2. Планирование целей
        if (Goals.IsEmpty)
        {
            Goal newGoal = planner.PlanNextGoal(this, Needs);
            Goals.PushGoal(newGoal);
        }
        
        // 3. Выполнение текущей цели
        if (AssignedShipId.HasValue)
        {
            var ship = GetAssignedShip();
            Goals.ExecuteCurrentGoal(dt, this, ship);
        }
    }
}
```

## Скорости изменения потребностей (по умолчанию)

- **HungerIncreasePerHour**: 1.0 (~100 часов до критичного)
- **ComfortDecreasePerHour**: 0.5 (~200 часов)
- **EntertainmentDecreasePerHour**: 0.3 (~333 часа)
- **SelfActualizationDecreasePerHour**: 0.1 (~1000 часов)

## Пороги критичности

- **HungerCritical**: 70f
- **ComfortCritical**: 80f
- **EntertainmentCritical**: 75f
- **SelfActualizationCritical**: 85f

## Поток принятия решений

```
Simulate(dt)
    │
    ├─> UpdateNeeds(dt)
    │   └─> Hunger += rate * dt
    │
    ├─> ResolveGoals()
    │   ├─> GetMostUrgentNeed() → (NeedType, urgency)
    │   └─> PlanNextGoal(need) → Goal
    │
    └─> ExecuteCurrentGoal(dt)
        ├─> goal.Execute(dt, pilot, ship)
        ├─> if Complete → OnComplete()
        └─> if Failed → OnFail()
```

## Влияние личности на приоритеты

- **Caution** (осторожность) → ↑ приоритет Hunger
- **Greed** (жадность) → ↑ приоритет Comfort
- **Loyalty** (лояльность) → ↓ приоритет Entertainment
- **Aggression** (агрессия) → ↑ приоритет SelfActualization

## План реализации

### ✅ Phase 1: Базовая инфраструктура (ГОТОВО)
- [x] PilotNeeds.cs
- [x] Goal.cs
- [x] GoalQueue.cs
- [x] PilotGoalPlanner.cs
- [x] WanderGoal.cs
- [x] TravelToLocationGoal.cs
- [x] RestGoal.cs

### ⏳ Phase 2: Интеграция с PilotModel (СЛЕДУЮЩИЙ ШАГ)
- [ ] Добавить поля Needs, Goals, planner в PilotModel
- [ ] Обновить PilotModel.Simulate()
- [ ] Тестирование простых целей (wander, rest)

### 📋 Phase 3: Hunger Flow
- [ ] PlanetModel stub с базовым API
- [ ] DockAtStationGoal
- [ ] BuyItemGoal
- [ ] EarnMoneyGoal (stub)
- [ ] Интеграция с планировщиком

### 📋 Phase 4: Остальные потребности
- [ ] Comfort → UpgradeShipGoal
- [ ] Entertainment → посещение баров
- [ ] SelfActualization → миссии/торговля

### 📋 Phase 5: Баланс и полировка
- [ ] Телеметрия
- [ ] Debug UI
- [ ] Настройка параметров

## Файловая структура

```
Assets/
├── entities/
│   └── Pilot/
│       ├── PilotModel.cs (существующий, требует обновления)
│       ├── PilotNeeds.cs (новый)
│       ├── GoalQueue.cs (новый)
│       ├── PilotGoalPlanner.cs (новый)
│       └── Goals/
│           ├── Goal.cs (новый, базовый класс)
│           ├── WanderGoal.cs (новый)
│           ├── TravelToLocationGoal.cs (новый)
│           ├── RestGoal.cs (новый)
│           ├── DockAtStationGoal.cs (TODO)
│           ├── BuyItemGoal.cs (TODO)
│           └── EarnMoneyGoal.cs (TODO)
└── Design/
    └── SettingBible/
        ├── needs_and_goals_architecture.md (детальная архитектура)
        ├── pilots.md (дизайн-документ)
        └── planets.md (интеграция с планетами)
```

## Debug и мониторинг

### Логирование
Все ключевые события логируются:
```
[PilotGoalPlanner] Pilot John: Hunger urgent (75.3), planning RestGoal
[GoalQueue] Pilot John: Started goal RestGoal
[GoalQueue] Pilot John: Goal RestGoal completed
```

### Debug UI (будущее)
```csharp
GUILayout.Label($"Pilot: {pilot.Name}");
GUILayout.Label($"Hunger: {pilot.Needs.Hunger:F1}");
GUILayout.Label($"Current Goal: {pilot.Goals.GetCurrentGoalInfo()}");
```

## Примеры использования

### Создание пилота с потребностями
```csharp
var pilot = new PilotModel("John", "Alpha-1");
// Needs, Goals, planner инициализируются автоматически в конструкторе
```

### Ручное добавление цели
```csharp
pilot.Goals.PushGoal(new RestGoal(300f, NeedType.Hunger));
```

### Проверка состояния
```csharp
var (needType, urgency) = pilot.Needs.GetMostUrgentNeed(pilot);
bool critical = pilot.Needs.IsNeedCritical(NeedType.Hunger);
```

## Thread Safety

Все компоненты thread-safe:
- Все изменения PilotModel под `lock(Sync)`
- Goals выполняются под тем же lock
- Безопасно для фоновой симуляции

## Производительность

- Минимальные аллокации в runtime
- Простые вычисления срочности (O(1))
- Один goal execution per pilot per tick
- Подходит для сотен пилотов

## Дальнейшее развитие

1. **Utility-based AI**: замена простого приоритета на utility curves
2. **Behavior Trees**: более гибкая структура решений
3. **Cooperative planning**: кооперация между пилотами
4. **Dynamic economy**: интеграция с рыночными ценами
5. **Social interactions**: репутация, дружба, соперничество

---

**Статус**: Phase 1 завершена, готово к интеграции с PilotModel  
**Дата создания**: November 6, 2025  
**Следующий шаг**: Обновление PilotModel.cs

