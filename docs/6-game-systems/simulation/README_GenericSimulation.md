# Generic Simulation System

Эта система предоставляет generic решение для симуляции различных типов объектов в игре Star Pioneers.

## Архитектура

### ISimulatable Interface
Базовый интерфейс для всех симулируемых объектов:
- `Guid Id` - уникальный идентификатор
- `Vector3 Position` - позиция в мире
- `object Sync` - объект для синхронизации между потоками
- `void Simulate(float dt)` - метод симуляции

### GenericSimulationManager
Основной менеджер симуляции, который:
- Управляет симуляцией на главном потоке (видимые объекты)
- Управляет симуляцией в фоновом потоке (невидимые объекты)
- Автоматически переключает объекты между потоками на основе видимости камеры
- Поддерживает любые типы объектов, реализующие ISimulatable
- Предоставляет методы для поиска объектов по типу

### Типы объектов

#### ShipModel
Модель корабля с:
- Движением к цели
- Расходом топлива
- Здоровьем
- Ориентацией

#### StarSystemModel
Модель звездной системы с:
- Различными типами звезд (красный карлик, желтый карлик, голубой сверхгигант, красный гигант, белый карлик)
- Циклами солнечной активности
- Движением в галактике
- Расчетом обитаемой зоны

#### PilotModel
Модель пилота с:
- Навыками (пилотирование, навигация, бой, торговля, технические, лидерство)
- Состоянием (здоровье, усталость, мораль, стресс)
- Карьерой (звание, часы полета, выполненные миссии)
- Личностными качествами (агрессивность, осторожность, лояльность, жадность)

## Использование

### Создание объектов
```csharp
// Создание корабля
var ship = SimulationUtils.CreateRandomShip(position);
SimulationUtils.RegisterShip(ship, background: true);

// Создание звездной системы
var system = SimulationUtils.CreateRandomStarSystem(position, "System-001");
SimulationUtils.RegisterStarSystem(system, background: true);

// Создание пилота
var pilot = SimulationUtils.CreateRandomPilot("John Doe", "Viper");
SimulationUtils.RegisterPilot(pilot, background: true);
```

### Поиск объектов
```csharp
// Получить все корабли
var ships = SimulationUtils.GetAllShips();

// Найти корабли рядом с позицией
var nearbyShips = SimulationUtils.FindShipsNear(position, 50f);

// Найти доступных пилотов
var availablePilots = SimulationUtils.FindAvailablePilots();

// Найти опытных пилотов
var skilledPilots = SimulationUtils.FindSkilledPilots(SkillType.Combat, 70f);
```

### Назначение пилотов
```csharp
// Назначить пилота на корабль
SimulationUtils.AssignPilotToShip(pilot, ship);

// Освободить пилота
SimulationUtils.UnassignPilot(pilot);
```

### Статистика симуляции
```csharp
var stats = SimulationUtils.GetSimulationStats();
Debug.Log($"Ships: {stats.ShipCount}, Systems: {stats.StarSystemCount}, Pilots: {stats.PilotCount}");
```

## Обратная совместимость

Старый `SimulationManager` помечен как устаревший, но продолжает работать через `SimulationManagerLegacy.cs`, который перенаправляет вызовы к новому `GenericSimulationManager`.

## Производительность

- Видимые объекты симулируются на главном потоке в реальном времени
- Невидимые объекты симулируются в фоновом потоке с настраиваемой частотой
- Автоматическое переключение между потоками на основе видимости камеры
- Потокобезопасная синхронизация данных

## Расширение

Чтобы добавить новый тип объекта:
1. Создайте класс, реализующий `ISimulatable`
2. Реализуйте метод `Simulate(float dt)`
3. Добавьте convenience методы в `SimulationUtils` при необходимости

Пример:
```csharp
public class StationModel : ISimulatable
{
    public Guid Id { get; private set; }
    public Vector3 Position { get; set; }
    public readonly object Sync = new object();
    
    public void Simulate(float dt)
    {
        // Логика симуляции станции
    }
}
```
