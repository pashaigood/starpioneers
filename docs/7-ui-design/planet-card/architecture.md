# Planet UI — Архитектура решения

## Обзор

Система Planet UI представляет собой полноэкранную карточку станции/планеты, которая открывается при посадке игрока. Система построена на следующих принципах:

- **MVC паттерн**: Разделение данных (Model), визуализации (View - UXML/USS) и логики (Controller)
- **Snapshot паттерн**: Чтение данных из моделей под lock один раз, работа с локальной копией
- **Event-driven**: Подписка на события изменения данных только при открытой карточке
- **UI Toolkit**: Использование Unity UI Toolkit (UXML/USS) для декларативного описания интерфейса
- **Responsive design**: Адаптация под разные разрешения экрана

---

## Архитектурные слои

### 1. Data Layer (Модели данных)

**Существующие модели:**
- `CelestialModel` — модель планеты/станции с сервисами и рынком
- `MarketModule` — данные рынка (цены, запасы товаров; доступны через `MarketModule.Stacks`, `GetPrice`, `TryBuy`, `TrySell`)
- `ShipModel` — модель корабля игрока/NPC
- `PlayerShipModel` — расширение ShipModel для игрока

**Новые модели данных (view models):**
- `PlanetCardSnapshot` — неизменяемый снимок данных планеты для UI
- `ServiceSnapshot` — снимок данных одного сервиса
- `MarketItemSnapshot` — снимок данных товара рынка
- `TransactionReceipt` — чек транзакции для журнала

**Ключевые характеристики:**
- Все snapshot-классы должны быть immutable (readonly поля)
- Snapshot создаётся под `lock(model.Sync)` один раз при открытии карточки
- При изменениях модели создаётся новый snapshot

### 2. Controller Layer (Логика и управление)

**Основные контроллеры:**

1. **`PlanetCardController`** — главный контроллер карточки планеты
   - Управляет открытием/закрытием карточки
   - Создаёт snapshots из CelestialModel
   - Координирует работу дочерних контроллеров
   - Обрабатывает основные действия (Взлёт, быстрая заправка, быстрый ремонт)

2. **`ServiceListController`** — контроллер списка сервисов
   - Отображает доступные сервисы планеты
   - Обрабатывает выбор сервиса
   - Управляет сортировкой и фильтрацией

3. **`ServiceDetailController`** — контроллер панели деталей сервиса
   - Отображает детали выбранного сервиса (верфь, рынок, заправка и т.д.)
   - Обрабатывает действия внутри сервиса (покупка, продажа, заправка)
   - Динамически меняет содержимое в зависимости от типа сервиса

4. **`QuickActionsController`** — контроллер панели быстрых действий
   - Обрабатывает быстрые действия (F, R, T, M, S)
   - Управляет видимостью и доступностью кнопок
   - Работает с хоткеями

5. **`TransactionLogController`** — контроллер журнала транзакций
   - Отображает историю действий игрока
   - Поддерживает undo последней транзакции (optimistic UI)

6. **`PlayerUIController`** — существующий контроллер HUD игрока
   - Расширяется для интеграции с Planet Card
   - Скрывает элементы HUD при открытой карточке

### 3. View Layer (Визуализация)

**UXML структура:**
- `planet_card.uxml` — корневой документ карточки планеты
- `service_tile.uxml` — шаблон плитки сервиса (может быть inline)
- `market_item_row.uxml` — шаблон строки товара рынка
- `ship_card.uxml` — шаблон карточки корабля в верфи

**USS стили:**
- `planet_card.uss` — основные стили карточки планеты
- Переиспользует стили из `simple.uss` (speed-button, hud-root, radial-slider и т.д.)
- Добавляет новые классы для специфичных элементов Planet Card

**Визуальные компоненты:**
- Фоновая анимация планеты (3D preview или видео-петля)
- Полупрозрачные панели с backdrop blur
- Радиальные индикаторы (fuel, shield)
- Прогресс-бары (health, reputation)
- Модальные окна подтверждения

---

## Поток данных

### Открытие карточки планеты

```
1. Player lands on planet → PlayerController.OnLandedAt(planetId)
2. PlanetCardController.OpenCard(planetId)
3. Get CelestialModel from GenericSimulationManager
4. Create PlanetCardSnapshot under lock(model.Sync):
   - Read all services
   - Read market data
   - Read player ship data (fuel, health, credits)
5. Bind snapshot to UXML elements
6. Subscribe to model change events:
   - Market.OnPriceChanged
   - Market.OnStockChanged
   - PlayerShip.OnCreditsChanged
7. Display card with animation (fade in + zoom)
```

### Транзакция (заправка, покупка, ремонт)

```
1. User clicks "Refuel" button
2. ServiceDetailController validates input
3. Controller calls CelestialModel.ProvideRefuel(shipId, amount, out cost)
4. CelestialModel executes under lock:
   - Check if service available
   - Check if player has credits
   - Deduct stock/credits
   - Update ship fuel
5. On success:
   - Create TransactionReceipt
   - Update UI optimistically
   - Log to transaction journal
   - Play success animation/sound
6. On failure:
   - Show error toast
   - Revert optimistic UI changes
```

### Закрытие карточки

```
1. User clicks "Takeoff" button
2. PlanetCardController.ValidateTakeoff():
   - Check fuel >= minimum
   - Check health >= minimum
3. If validation fails:
   - Show warning modal
   - Offer quick actions (Refuel/Repair)
4. If validation passes:
   - Unsubscribe from all events
   - Play close animation
   - Dispose snapshot
   - Return to flight HUD
```

---

## Паттерн Snapshot

### Зачем нужен Snapshot?

- **Thread safety**: Избегаем длительных lock на моделях
- **Consistency**: UI работает с согласованными данными
- **Performance**: Читаем данные один раз, не блокируем симуляцию

### Структура Snapshot

```csharp
public class PlanetCardSnapshot
{
    // Immutable fields
    public readonly Guid PlanetId;
    public readonly string PlanetName;
    public readonly string ViewKey;
    public readonly float Habitability;
    public readonly PlanetSpecialization Specialization;
    public readonly FactionId ControllingFaction;
    public readonly float PlayerReputation;
    
    // Services
    public readonly IReadOnlyList<ServiceSnapshot> Services;
    
    // Market (if available)
    public readonly IReadOnlyDictionary<string, MarketItemSnapshot> MarketItems;
    
    // Player state
    public readonly float PlayerCredits;
    public readonly float ShipFuel;
    public readonly float ShipHealth;
    public readonly float ShipMaxFuel;
    public readonly float ShipMaxHealth;
    
    // Timestamp for staleness check
    public readonly DateTime CreatedAt;
    
    // Constructor creates snapshot under lock
    public PlanetCardSnapshot(CelestialModel planet, PlayerShipModel playerShip)
    {
        lock (planet.Sync)
        {
            PlanetId = planet.Id;
            PlanetName = planet.Name;
            // ... copy all needed data
        }
        
        lock (playerShip.Sync)
        {
            PlayerCredits = playerShip.Credits;
            ShipFuel = playerShip.CurrentFuel;
            // ... copy ship data
        }
        
        CreatedAt = DateTime.UtcNow;
    }
}
```

### Обновление Snapshot

- При событии изменения модели создаётся новый snapshot
- UI обновляется из нового snapshot
- Старый snapshot утилизируется

---

## Event-driven обновления

### События модели

```csharp
// В CelestialModel
public event Action<string, float> OnPriceChanged;
public event Action<string, int> OnStockChanged;

// В PlayerShipModel
public event Action<float> OnCreditsChanged;
public event Action<float, float> OnFuelChanged;
public event Action<float, float> OnHealthChanged;
```

### Подписка в контроллере

```csharp
public class PlanetCardController
{
    CelestialModel currentPlanet;
    PlayerShipModel playerShip;
    
    void OpenCard(Guid planetId)
    {
        currentPlanet = GetModel(planetId);
        playerShip = GetPlayerShip();
        
        // Subscribe
        currentPlanet.OnPriceChanged += OnMarketPriceChanged;
        currentPlanet.OnStockChanged += OnMarketStockChanged;
        playerShip.OnCreditsChanged += OnPlayerCreditsChanged;
        
        // Create initial snapshot
        RefreshSnapshot();
    }
    
    void CloseCard()
    {
        // Unsubscribe
        if (currentPlanet != null)
        {
            currentPlanet.OnPriceChanged -= OnMarketPriceChanged;
            currentPlanet.OnStockChanged -= OnMarketStockChanged;
        }
        
        if (playerShip != null)
        {
            playerShip.OnCreditsChanged -= OnPlayerCreditsChanged;
        }
        
        currentPlanet = null;
        playerShip = null;
    }
    
    void OnMarketPriceChanged(string item, float newPrice)
    {
        // Re-create snapshot for updated item
        RefreshSnapshot();
        // Or update only specific item in UI
    }
}
```

---

## Интеграция с существующей системой

### CelestialModel расширения

Требуется добавить события:
```csharp
public class CelestialModel
{
    // Events
    public event Action<string, float> OnPriceChanged;
    public event Action<string, int> OnStockChanged;
    public event Action<Guid> OnShipDocked;
    public event Action<Guid> OnShipUndocked;
}
```

### PlayerShipModel расширения

Требуется добавить:
```csharp
public class PlayerShipModel : ShipModel
{
    public float Credits { get; private set; } = 1000f;
    
    public event Action<float> OnCreditsChanged;
    
    public bool TrySpendCredits(float amount)
    {
        lock (Sync)
        {
            if (Credits < amount)
                return false;
            
            Credits -= amount;
            OnCreditsChanged?.Invoke(Credits);
            return true;
        }
    }
    
    public void AddCredits(float amount)
    {
        lock (Sync)
        {
            Credits += amount;
            OnCreditsChanged?.Invoke(Credits);
        }
    }
}
```

### PlayerUIController интеграция

```csharp
public class PlayerUIController
{
    PlanetCardController planetCardController;
    
    void Start()
    {
        // ... existing code ...
        
        // Initialize Planet Card controller
        planetCardController = new PlanetCardController(root.Q("planet-card-container"));
        planetCardController.Hide();
    }
    
    public void OnPlayerLanded(Guid planetId)
    {
        // Hide flight HUD
        HideFlightHUD();
        
        // Show planet card
        planetCardController.OpenCard(planetId);
    }
    
    public void OnPlayerTookOff()
    {
        // Hide planet card
        planetCardController.CloseCard();
        
        // Show flight HUD
        ShowFlightHUD();
    }
}
```

---

## Accessibility и управление

### Клавиатурные хоткеи

- **T** — Взлёт (Takeoff)
- **F** — Быстрая заправка (Fast Refuel)
- **R** — Быстрый ремонт (Rapid Repair)
- **M** — Открыть рынок (Market)
- **S** — Открыть верфь (Shop)
- **Esc** — Закрыть карточку / назад

### Контроллер (геймпад)

- **D-pad / Left Stick** — Навигация по сервисам
- **A** — Выбор / подтверждение
- **B** — Назад / отмена
- **X** — Быстрая заправка
- **Y** — Быстрый ремонт
- **LB/RB** — Переключение вкладок

### Accessibility опции

- **Масштабирование текста** — 80% / 100% / 120% / 150%
- **Высокий контраст** — увеличение контрастности текста и границ
- **Уменьшение анимаций** — отключение параллакса и плавных переходов
- **Screen reader labels** — ARIA-подобные метки для важных элементов

---

## Performance соображения

### Оптимизации

1. **Snapshot caching**: Не пересоздавать snapshot при каждом frame
2. **Lazy loading**: Грузить детали сервиса только при выборе
3. **Virtual scrolling**: Для больших списков товаров (>100 items)
4. **Asset preloading**: Предзагружать иконки и превью при приближении к планете
5. **Pooling**: Переиспользовать VisualElement для списков

### Метрики производительности

- **Время открытия карточки**: < 200ms
- **Время реакции на клик**: < 50ms
- **FPS при открытой карточке**: >= 60 fps (на средней конфигурации)
- **Memory footprint**: < 50 MB для карточки

---

## Тестирование

### Unit тесты

- Snapshot creation и immutability
- Transaction validation logic
- Credit spending и refunding
- Event subscription/unsubscription

### Integration тесты

- Открытие/закрытие карточки
- Транзакции с моделями (refuel, repair, purchase)
- Undo механизм
- Multi-threaded доступ к моделям

### UI тесты

- Навигация по сервисам
- Валидация форм
- Хоткеи и контроллер
- Responsive behaviour на разных разрешениях

---

## Будущие расширения

### Фаза 2

- **Faction reputation UI**: Детальная панель отношений с фракциями
- **Mission board**: Интеграция доски миссий в карточку
- **Bar/Social hub**: NPC диалоги и социальные взаимодействия
- **Ship comparison tool**: Сравнение до 3 кораблей side-by-side

### Фаза 3

- **Dynamic news feed**: События в системе, цены, политика
- **Station upgrades**: Игрок может инвестировать в улучшение станции
- **Persistent NPCs**: NPC пилоты на станции, взаимодействия
- **Multiplayer integration**: Другие игроки на станции

---

## Резюме

Planet UI система построена на проверенных паттернах:
- **Snapshot pattern** для thread-safe работы с данными
- **Event-driven updates** для реактивного UI
- **MVC separation** для чёткого разделения ответственности
- **Responsive design** для поддержки разных устройств
- **Accessibility first** для инклюзивности

Система интегрируется с существующими `CelestialModel`, `ShipModel`, `PlayerUIController` и использует Unity UI Toolkit для декларативного описания интерфейса.

