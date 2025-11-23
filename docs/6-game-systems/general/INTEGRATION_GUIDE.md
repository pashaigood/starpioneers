# Инструкции по интеграции системы потребностей в PilotModel

## Цель
Интегрировать новую систему потребностей и целей в существующий PilotModel без нарушения текущей функциональности.

## Шаг 1: Добавление новых полей

В `PilotModel.cs` добавить после существующих полей:

```csharp
[Header("Needs & Goals System")]
public PilotNeeds Needs;
public GoalQueue Goals;
private PilotGoalPlanner planner;
```

## Шаг 2: Инициализация в конструкторе

В конструкторе `PilotModel()` добавить после `rng = new System.Random(...)`:

```csharp
// Инициализировать систему потребностей и целей
Needs = new PilotNeeds();
Goals = new GoalQueue();
planner = new PilotGoalPlanner();
```

## Шаг 3: Обновление метода Simulate

Заменить текущий метод `Simulate(float dt)` на следующий:

```csharp
public void Simulate(float dt)
{
    lock (Sync)
    {
        // 1. Обновить потребности
        Needs.UpdateNeeds(dt, this);
        
        // 2. Обновить базовое состояние (fatigue, stress, morale, skills)
        UpdateBaseState(dt);
        
        // 3. Планировщик целей
        ResolveGoals(dt);
        
        // 4. Выполнить текущую цель (если есть назначенный корабль)
        if (AssignedShipId.HasValue)
        {
            try
            {
                var sim = GenericSimulationManager.Instance;
                if (sim != null)
                {
                    var ship = sim.GetById(AssignedShipId.Value) as ShipModel;
                    if (ship != null)
                    {
                        Goals.ExecuteCurrentGoal(dt, this, ship);
                        
                        // Синхронизировать позицию пилота с кораблём
                        Position = ship.Position;
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
            }
        }
    }
}
```

## Шаг 4: Перенос существующей логики в UpdateBaseState

Создать новый приватный метод `UpdateBaseState(float dt)` и перенести туда существующую логику из старого Simulate:

```csharp
private void UpdateBaseState(float dt)
{
    experienceTimer += dt;

    // Recover from fatigue when resting
    if (Status == PilotStatus.Resting)
    {
        restTimer += dt;
        if (restTimer > 3600f) // 1 hour of rest
        {
            Fatigue = Mathf.Max(0f, Fatigue - 10f);
            Stress = Mathf.Max(0f, Stress - 5f);
            Health = Mathf.Min(100f, Health + 1f);
            restTimer = 0f;
        }
    }

    // Gradual fatigue accumulation when active
    if (Status == PilotStatus.OnMission || Status == PilotStatus.InCombat)
    {
        Fatigue += dt * 0.5f; // Fatigue per second
        if (Status == PilotStatus.InCombat)
        {
            Stress += dt * 2f; // Higher stress in combat
            stressAccumulation += dt;
        }
        else
        {
            Stress += dt * 0.2f;
        }
    }

    // Stress recovery when not in combat
    if (Status != PilotStatus.InCombat)
    {
        Stress = Mathf.Max(0f, Stress - dt * 0.1f);
    }

    // Morale changes based on various factors
    UpdateMorale(dt);

    // Skill improvement through experience
    if (experienceTimer >= 3600f) // Every hour
    {
        ImproveThroughExperience();
        experienceTimer = 0f;
    }

    // Handle status transitions
    UpdateStatus(dt);
}
```

## Шаг 5: Добавление метода ResolveGoals

Создать новый приватный метод для планирования целей:

```csharp
private void ResolveGoals(float dt)
{
    // Если нет текущей цели или очередь пуста
    if (Goals.IsEmpty)
    {
        // Запросить у планировщика новую цель
        Goal newGoal = planner.PlanNextGoal(this, Needs);
        
        if (newGoal != null)
        {
            Goals.PushGoal(newGoal);
            Debug.Log($"[PilotModel] {Name}: New goal assigned: {newGoal.GetType().Name}");
        }
    }
}
```

## Шаг 6: Удаление старой логики DecideAndCommand

Старый метод `DecideAndCommand` можно удалить или закомментировать, так как теперь управление кораблём осуществляется через цели (Goals).

```csharp
// СТАРЫЙ КОД - больше не нужен
/*
public void DecideAndCommand(
    ShipModel ship,
    System.Random rng,
    float wanderRadius,
    double changeProbPerTick = 0.02
)
{
    // ... старая логика ...
}
*/
```

## Шаг 7: Проверка совместимости

После интеграции проверить:

1. **Компиляция**: Проект должен компилироваться без ошибок
2. **Инициализация**: Пилоты создаются с инициализированными Needs, Goals, planner
3. **Симуляция**: Пилоты обновляются в фоновом потоке без ошибок
4. **Логи**: В консоли появляются сообщения о планировании целей

## Пример ожидаемого лога

```
[PilotModel] John: New goal assigned: WanderGoal
[GoalQueue] Pilot John: Started goal WanderGoal
[PilotGoalPlanner] Pilot John: Hunger urgent (75.3), planning RestGoal
[PilotModel] John: New goal assigned: RestGoal
[GoalQueue] Pilot John: Started goal RestGoal
[RestGoal] Pilot John finished resting (60.0s), Hunger reduced
[GoalQueue] Pilot John: Goal RestGoal completed
```

## Тестирование

### Тест 1: Базовая инициализация
```csharp
var pilot = new PilotModel("TestPilot", "Test-1");
Debug.Assert(pilot.Needs != null, "Needs not initialized");
Debug.Assert(pilot.Goals != null, "Goals not initialized");
Debug.Assert(pilot.Goals.IsEmpty, "Goals should be empty on init");
```

### Тест 2: Цикл потребностей
```csharp
var pilot = new PilotModel();
pilot.Needs.Hunger = 0f;

// Симулировать 10 часов
for (int i = 0; i < 36000; i++) // 3600 sec/hour * 10 hours
{
    pilot.Simulate(1f); // 1 second per tick
}

Debug.Log($"Hunger after 10 hours: {pilot.Needs.Hunger}"); // Ожидается ~10.0
```

### Тест 3: Планирование целей
```csharp
var pilot = new PilotModel();
pilot.Needs.Hunger = 80f; // критичный уровень
pilot.AssignedShipId = someShip.Id;

// Симулировать один tick
pilot.Simulate(0.1f);

Debug.Assert(!pilot.Goals.IsEmpty, "Goal should be created for critical hunger");
Debug.Log($"Current goal: {pilot.Goals.CurrentGoal.GetType().Name}");
```

## Обратная совместимость

Если необходимо сохранить старое поведение (простое блуждание) параллельно с новой системой:

1. Добавить флаг `public bool UseNeedsSystem = true;`
2. В Simulate проверять флаг:

```csharp
public void Simulate(float dt)
{
    lock (Sync)
    {
        if (UseNeedsSystem)
        {
            // Новая система потребностей и целей
            Needs.UpdateNeeds(dt, this);
            UpdateBaseState(dt);
            ResolveGoals(dt);
            // ...
        }
        else
        {
            // Старая система (простое блуждание)
            UpdateBaseState(dt);
            if (AssignedShipId.HasValue)
            {
                var ship = GetAssignedShip();
                DecideAndCommand(ship, rng, WanderRadius);
            }
        }
    }
}
```

## Известные проблемы и решения

### Проблема 1: NullReferenceException при доступе к Needs/Goals
**Причина**: Старые сохранённые пилоты без инициализированных полей

**Решение**: Добавить lazy initialization в геттеры
```csharp
public PilotNeeds Needs
{
    get
    {
        if (_needs == null)
            _needs = new PilotNeeds();
        return _needs;
    }
    set { _needs = value; }
}
private PilotNeeds _needs;
```

### Проблема 2: Пилоты не двигаются
**Причина**: Корабль не найден или не назначен

**Решение**: Проверить логи, добавить debug-вывод
```csharp
if (ship == null)
{
    Debug.LogWarning($"Pilot {Name}: Assigned ship {AssignedShipId} not found");
    return;
}
```

### Проблема 3: Слишком частое переключение целей
**Причина**: Пороги критичности слишком низкие

**Решение**: Увеличить пороги в NeedThresholds
```csharp
Needs.Thresholds.HungerCritical = 80f; // вместо 70f
```

## Следующие шаги после интеграции

1. **Мониторинг**: Запустить игру с несколькими пилотами и наблюдать логи
2. **Балансировка**: Настроить скорости изменения потребностей
3. **Debug UI**: Создать простой UI для отображения потребностей и целей
4. **Phase 3**: Начать интеграцию с PlanetModel (hunger flow)

## Контрольный список

- [ ] Добавлены поля Needs, Goals, planner
- [ ] Обновлён конструктор с инициализацией
- [ ] Refactored Simulate → UpdateBaseState + ResolveGoals
- [ ] Удалена/закомментирована старая логика DecideAndCommand
- [ ] Проект компилируется без ошибок
- [ ] Базовые тесты пройдены
- [ ] Логи показывают планирование целей
- [ ] Пилоты двигаются и выполняют цели

---

**Важно**: После интеграции сделать коммит с описанием `feat: integrate needs and goals system into PilotModel`

**Следующий документ**: После успешной интеграции переходить к `planets_integration.md` для Phase 3

