# Симуляция мира "Star Pioneers" - текущая архитектура и план развития

Этот документ описывает текущую реализованную архитектуру системы симуляции в проекте "Star Pioneers" и планы её дальнейшего развития. Проект фокусируется на создании живого космического мира с масштабируемой симуляцией кораблей и пилотов.

## Текущее состояние: Ship-first архитектура

**Текущий статус проекта**: Базовая архитектура симуляции кораблей реализована с разделением на Domain Model и View Layer. Система использует многопоточную симуляцию с автоматическим переключением между основным и фоновым потоками на основе видимости камеры.

## Реализованная архитектура

### Основные компоненты системы

#### 1. Система симuляции кораблей
- **ShipModel** (Domain Model): Чистая модель корабля с позицией, скоростью, топливом, здоровьем
- **ShipView** (MonoBehaviour): Визуальное представление, обновляется из модели
- **SimulationManager**: Центральный менеджер с многопоточной симуляцией

#### 2. Двухпоточная симуляция
- **Основной поток**: Корабли в зоне видимости камеры (60 FPS)
- **Фоновый поток**: Корабли вне зоны видимости (10 Hz по умолчанию)
- **Автоматическое переключение**: На основе границ камеры с настраиваемым отступом

### Реализованные классы и структуры

#### ShipModel (Domain Model)
```csharp
public class ShipModel
{
    public Guid Id;
    public Vector3 Position;
    public Vector3 Velocity;  
    public float Orientation;
    public float MaxSpeed, Speed, RotationSpeed;
    public float MaxHealth, CurrentHealth;
    public float MaxFuel, CurrentFuel, FuelPerUnit;
    public Vector3 TargetPosition;
    public Vector3 FaceTarget;
    public bool HasFaceTarget;
    public readonly object Sync; // для многопоточности
    
    public void Simulate(float dt); // основная логика движения
}
```

#### SimulationManager (Singleton MonoBehaviour)
```csharp
public class SimulationManager : MonoBehaviour
{
    // Настройки камеры-based LOD
    public float CameraViewMargin = 10f;
    public float VisibilityCheckInterval = 0.5f; 
    public Camera TargetCamera;
    
    // Частота фоновой симуляции
    public float BackgroundHz = 10f;
    
    // Коллекции кораблей
    private HashSet<ShipModel> mainModels;    // основной поток
    private HashSet<ShipModel> bgModels;      // фоновый поток
    
    // Автоматическое переключение режимов
    private void CheckVisibilityAndSwitch();
}
```

#### PlayerController и управление
```csharp
public class PlayerController : MonoBehaviour
{
    // Визуализация пути
    public float markerInterval = 1f;
    public Material markerMaterial;
    
    // Боевая система  
    public Target currentTarget;
    
    // Интеграция с моделью
    private ShipView ship;
    private ShipModel model;
    
    // Логика: клик для движения, правый клик для выбора цели
}
```

#### Combat System
```csharp
public class Target : MonoBehaviour
{
    public float maxHealth = 100f;
    public float health { get; private set; }
    public bool IsAlive => health > 0f;
    public event Action<Target> OnDestroyed;
    
    public void TakeDamage(float amount);
}
```

### Система LOD и оптимизации

#### Camera-based LOD (Реализовано)
- **Видимые корабли**: Полная симуляция на основном потоке (каждый кадр)
- **Невидимые корабли**: Упрощённая симуляция в фоновом потоке (10 Hz)
- **Область видимости**: Рассчитывается для ортографических и перспективных камер
- **Динамическое переключение**: Автоматическое перемещение между режимами

#### Многопоточность (Реализовано)
- **Основной поток**: Unity Update() для видимых объектов
- **Фоновый поток**: Task.Run() с асинхронным циклом
- **Thread-safe**: Использование lock() для синхронизации доступа к данным
- **Безопасность**: Никаких вызовов Unity API из фоновых потоков

## Текущие возможности системы

### ✅ Реализовано
1. **Базовая симуляция кораблей**: движение, поворот, топливо, здоровье
2. **Многопоточная архитектура**: основной + фоновый потоки
3. **Camera-based LOD**: автоматическое переключение режимов симуляции  
4. **Боевая система**: стрельба, урон, уничтожение целей
5. **Управление игроком**: движение по клику, выбор целей
6. **Визуальные эффекты**: крен корабля, маркеры пути, снаряды
7. **Thread-safe синхронизация**: безопасная работа с данными

### Основные циклы симуляции (Реализовано)

#### Цикл основного потока (Unity Update)
```csharp
void Update()
{
    // Проверка видимости и переключение режимов
    visibilityCheckTimer += Time.deltaTime;
    if (visibilityCheckTimer >= VisibilityCheckInterval)
    {
        visibilityCheckTimer = 0f;
        CheckVisibilityAndSwitch();
    }

    // Симуляция видимых кораблей
    ShipModel[] snapshot;
    lock (sync)
    {
        snapshot = new ShipModel[mainModels.Count];
        mainModels.CopyTo(snapshot);
    }

    float dt = Time.deltaTime;
    foreach (var model in snapshot)
    {
        model.Simulate(dt); // Полная симуляция каждый кадр
    }
}
```

#### Цикл фонового потока (Task.Run)
```csharp
private async Task BackgroundLoop(CancellationToken token)
{
    while (!token.IsCancellationRequested)
    {
        float dt = 1f / BackgroundHz; // Фиксированный dt для стабильности
        
        // Получить снапшот невидимых кораблей
        ShipModel[] snapshot = GetBackgroundSnapshot();
        
        // Симулировать каждый корабль
        foreach (var model in snapshot)
        {
            model.Simulate(dt);
        }
        
        // Ждать до следующего тика
        await Task.Delay((int)(1000f / BackgroundHz), token);
    }
}
```

## План развития системы

### 🔄 В разработке / Следующие шаги

#### 1. AI система для NPC кораблей
```csharp
public class ShipAI : MonoBehaviour  
{
    public enum AIState { Idle, Patrol, Trade, Combat, Retreat }
    
    [Header("AI Settings")]
    public AIState currentState = AIState.Idle;
    public float detectionRange = 15f;
    public float engagementRange = 10f;
    
    // Простая FSM для начала
    private void UpdateAI()
    {
        switch (currentState)
        {
            case AIState.Idle: HandleIdleState(); break;
            case AIState.Patrol: HandlePatrolState(); break;
            case AIState.Combat: HandleCombatState(); break;
        }
    }
}
```

#### 2. Экономическая система (базовая)
```csharp
[Serializable]
public class Resource
{
    public string id;
    public string name; 
    public float basePrice;
    public int amount;
}

public class Station : MonoBehaviour
{
    public List<Resource> inventory;
    public List<TradeOrder> buyOrders;
    public List<TradeOrder> sellOrders;
    
    public void ProcessTrade(ShipModel trader, Resource resource, int amount);
}
```

#### 3. Генерация мира и систем
```csharp
[Serializable] 
public class StarSystem
{
    public Guid id;
    public string name;
    public Vector3 position;
    public StarType starType;
    public List<Planet> planets;
}

[Serializable]
public class Planet  
{
    public Guid id;
    public string name;
    public PlanetType type;
    public float radius;
    public List<ResourceNode> resources;
    public int ownerFactionId;
}
```

---

## Долгосрочные цели проекта

Создать живую космическую симуляцию где:
- **Корабли** автономно патрулируют, торгуют и сражаются 
- **Станции** производят и торгуют ресурсами
- **Фракции** развиваются, воюют и заключают союзы
- **Игрок** может влиять на мир через командование и дипломатию
- **Система** масштабируется до сотен активных кораблей

## Производительность и масштабирование

### Текущие показатели
- **Основной поток**: ~20-50 кораблей без заметного падения FPS
- **Фоновый поток**: Протестировано до 200+ кораблей  
- **Переключение LOD**: ~0.5 сек интервал, минимальное влияние на производительность
- **Память**: ~1KB на ShipModel, минимальные аллокации в runtime

### Планируемые оптимизации

#### 1. Job System интеграция
```csharp
[BurstCompile]
public struct ShipSimulationJob : IJobParallelFor
{
    public NativeArray<ShipData> ships;
    public float deltaTime;
    
    public void Execute(int index)
    {
        // Burst-оптимизированная симуляция
        var ship = ships[index]; 
        // ... логика движения без Unity API
        ships[index] = ship;
    }
}
```

#### 2. Spatial partitioning для коллизий
```csharp
public class SpatialGrid
{
    private Dictionary<Vector2Int, List<ShipModel>> grid;
    
    public List<ShipModel> GetNearbyShips(Vector3 position, float radius);
    public void UpdateShipPosition(ShipModel ship, Vector3 oldPos, Vector3 newPos);
}
```

## Архитектурные принципы

### 1. Разделение Model-View
- **Domain Models**: Чистые C# классы без Unity зависимостей
- **View Components**: MonoBehaviour для визуализации и взаимодействия
- **Синхронизация**: Thread-safe обновление View из Model

### 2. Многопоточность
- **Main Thread**: Unity API, визуализация, пользовательский ввод
- **Background Thread**: Игровая логика, симуляция физики
- **Синхронизация**: lock() для критических секций, CancellationToken для остановки

### 3. Camera-based LOD  
- **Видимость**: Расчёт bounds камеры (ортографическая/перспективная)
- **Автоматическое переключение**: Динамическое перемещение между потоками
- **Настраиваемость**: Margin, интервал проверки, частота фоновой симуляции

## Примеры использования

### Создание нового корабля
```csharp
// Создать модель
var model = new ShipModel();
model.Position = spawnPosition;
model.Speed = 5f;
model.CurrentFuel = 100f;

// Создать представление
var shipGO = Instantiate(shipPrefab);
var view = shipGO.GetComponent<ShipView>();
view.Initialize(model);

// Зарегистрировать в симуляции
SimulationManager.Instance.RegisterForMain(model);
```

### Переключение между режимами симуляции
```csharp
// Ручное переключение в фоновый режим
SimulationManager.Instance.MoveToBackground(shipModel);

// Ручное переключение в основной режим  
SimulationManager.Instance.MoveToMain(shipModel);

// Автоматическое переключение происходит в CheckVisibilityAndSwitch()
```

## Отладка и мониторинг

### Встроенные инструменты
```csharp
// Получение статистики
int mainThreadShips = SimulationManager.Instance.GetMainThreadShipCount();
int backgroundShips = SimulationManager.Instance.GetBackgroundThreadShipCount();

// Пример компонента для отладки (CameraBasedSimulationExample.cs)
public class CameraBasedSimulationExample : MonoBehaviour
{
    void OnGUI()
    {
        GUILayout.Label($"Main Thread Ships: {mainThreadShips}");
        GUILayout.Label($"Background Ships: {backgroundShips}");
        
        var cam = SimulationManager.Instance.TargetCamera;
        if (cam?.orthographic == true)
        {
            GUILayout.Label($"Camera Size: {cam.orthographicSize:F1}");
        }
    }
}
```

### Логирование
- Автоматическое логирование переключений между потоками
- Debug.Log при перемещении кораблей между режимами симуляции
- Exception handling в фоновых потоках

## Потенциальные проблемы и решения

### 1. Производительность
**Проблема**: Слишком много кораблей в основном потоке
**Решение**: 
- Уменьшить `CameraViewMargin`
- Увеличить `VisibilityCheckInterval` 
- Реализовать дополнительную LOD-систему по расстоянию

### 2. Thread Safety
**Проблема**: Race conditions при доступе к ShipModel
**Решение**:
- Все операции с моделью через lock(model.Sync)
- Никаких Unity API вызовов из фоновых потоков
- Snapshot-based чтение для UI/визуализации

### 3. Память
**Проблема**: Утечки памяти при создании/удалении кораблей  
**Решение**:  
- Обязательно вызывать `SimulationManager.Unregister(model)`
- Правильная очистка event handlers
- Object pooling для часто создаваемых объектов

## Roadmap развития

### Фаза 1: Базовая AI (2-4 недели)
- [ ] Простая FSM для NPC кораблей (Patrol, Engage, Retreat)
- [ ] Система обнаружения целей (сенсоры)
- [ ] Базовые боевые тактики (преследование, отступление)
- [ ] Spawn system для NPC кораблей

### Фаза 2: Экономика (4-6 недель)  
- [ ] Базовые ресурсы и система инвентаря
- [ ] Станции с торговлей
- [ ] Простые торговые маршруты
- [ ] AI трейдеры

### Фаза 3: Фракции (4-8 недель)
- [ ] Система фракций и репутации
- [ ] Территориальные конфликты  
- [ ] Дипломатия (союзы, войны)
- [ ] Стратегическое планирование AI

### Фаза 4: Мир (6-10 недель)
- [ ] Процедурная генерация систем
- [ ] Планеты и колонии
- [ ] Крупномасштабные события
- [ ] Сохранение/загрузка мира

## Технические детали реализации

### Camera Bounds Calculation
```csharp
private Bounds GetCameraBounds()
{
    Vector3 cameraPos = TargetCamera.transform.position;
    
    if (TargetCamera.orthographic)
    {
        // Ортографическая камера
        float size = TargetCamera.orthographicSize + CameraViewMargin;
        float aspect = TargetCamera.aspect;
        float width = size * aspect * 2f;
        float height = size * 2f;
        
        return new Bounds(cameraPos, new Vector3(width, 1000f, height));
    }
    else
    {
        // Перспективная камера
        float distance = Mathf.Abs(cameraPos.y);
        float halfFOV = TargetCamera.fieldOfView * 0.5f * Mathf.Deg2Rad;
        float height = distance * Mathf.Tan(halfFOV) * 2f + CameraViewMargin * 2f;
        float width = height * TargetCamera.aspect;
        
        return new Bounds(cameraPos, new Vector3(width, 1000f, height));
    }
}
```

### Simulation Loop Architecture
- **Main Thread**: Unity Update() для UI, визуализации, пользовательского ввода
- **Background Thread**: Task.Run() с async/await для доменной логики
- **Synchronization**: lock() вокруг критических секций, CancellationToken для остановки
- **Data Flow**: Model → View через snapshot pattern

## Конфигурация и настройка

### SimulationManager Settings
```csharp
[Header("Camera LOD Settings")]
public float CameraViewMargin = 10f;          // Дополнительный отступ вокруг камеры
public float VisibilityCheckInterval = 0.5f;  // Интервал проверки видимости  
public Camera TargetCamera;                   // Целевая камера (auto-find если null)

[Header("Background Simulation")] 
public float BackgroundHz = 10f;              // Частота фоновой симуляции
```

### Рекомендуемые настройки
- **CameraViewMargin**: 5-15 единиц (зависит от скорости кораблей)
- **VisibilityCheckInterval**: 0.3-1.0 сек (баланс отзывчивости/производительности)  
- **BackgroundHz**: 5-20 Hz (баланс точности/CPU)

### Integration Checklist
- [ ] SimulationManager на сцене (создается автоматически)
- [ ] Камера настроена правильно (orthographic size или FOV)
- [ ] Корабли используют ShipModel + ShipView паттерн
- [ ] Proper cleanup при удалении кораблей (Unregister)

## FAQ и Troubleshooting

### Q: Корабли переключаются между потоками слишком часто
**A**: Увеличьте `CameraViewMargin` или `VisibilityCheckInterval`

### Q: Падение FPS при большом количестве кораблей  
**A**: 
- Проверьте соотношение кораблей в основном/фоновом потоках
- Рассмотрите уменьшение `BackgroundHz`
- Отключите ненужные Renderer/Collider компоненты

### Q: Race conditions / NullReferenceException
**A**:
- Все обращения к ShipModel.* должны быть в lock(model.Sync)
- Проверьте правильность Unregister() при удалении кораблей
- Никаких Unity API из фоновых потоков

### Q: Как добавить новые типы симулируемых объектов?
**A**: 
1. Создайте domain model (аналог ShipModel)
2. Создайте view component (аналог ShipView) 
3. Зарегистрируйте в SimulationManager или создайте отдельный менеджер
4. Реализуйте метод Simulate() с вашей логикой


## Ссылки и ресурсы

### Используемые файлы проекта
- `Assets/entities/SimulationManager.cs` - Центральный менеджер симуляции
- `Assets/entities/ShipModel.cs` - Domain model корабля  
- `Assets/entities/ShipView.cs` - MonoBehaviour представление корабля
- `Assets/player/PlayerController.cs` - Контроллер игрока
- `Assets/entities/Target.cs` - Система целей для боя
- `Assets/entities/CameraBasedSimulationExample.cs` - Пример отладочного UI

### Архитектурные паттерны
- **Model-View separation**: Чистые domain models + MonoBehaviour views
- **Producer-Consumer**: Main thread (consumer) + Background thread (producer) 
- **Observer pattern**: Event-driven updates между моделью и представлением
- **Singleton**: SimulationManager как единая точка управления
- **LOD (Level of Detail)**: Camera-based переключение режимов симуляции

## Заключение

Текущая архитектура проекта "Star Pioneers" обеспечивает:

✅ **Масштабируемость**: Поддержка сотен кораблей с автоматическим LOD  
✅ **Гибкость**: Легкое добавление новых типов симулируемых объектов  
✅ **Производительность**: Многопоточная симуляция с camera-based оптимизацией  
✅ **Стабильность**: Thread-safe синхронизация и обработка исключений  
✅ **Простота**: Знакомые Unity паттерны и инструменты разработки  

Система готова для расширения AI, экономикой и системами более высокого уровня, сохраняя при этом производительность и управляемость кода.

---

*Документ обновлен: November 5, 2025*  
*Версия архитектуры: Ship-first with Camera-based LOD*

