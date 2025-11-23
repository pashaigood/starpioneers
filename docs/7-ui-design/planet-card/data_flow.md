# Planet UI — Поток данных и синхронизация

## Обзор

Этот документ детально описывает паттерны работы с данными в Planet UI системе:
- Snapshot pattern для thread-safe чтения
- Event-driven обновления UI
- Optimistic UI с rollback
- Transaction flow
- Синхронизация между моделями и View

---

## 1. Snapshot Pattern

### 1.1 Концепция

**Проблема**: UI работает в main thread, модели симулируются в background thread. Длительное удержание lock блокирует симуляцию.

**Решение**: Snapshot — неизменяемая копия данных модели, созданная под lock за один раз.

**Преимущества**:
- Thread safety без длительных блокировок
- Консистентность данных в UI
- Упрощение тестирования
- Возможность сравнения старого и нового snapshot

### 1.2 Структура Snapshot классов

```csharp
/// <summary>
/// Immutable snapshot of planet data for UI
/// Created under lock(planet.Sync), consumed by UI without locks
/// </summary>
public class PlanetCardSnapshot
{
    // Identity
    public readonly Guid PlanetId;
    public readonly string PlanetName;
    public readonly string ViewKey;
    
    // Planet characteristics
    public readonly float Radius;
    public readonly float OrbitRadius;
    public readonly float OrbitalPeriod;
    public readonly float RotationPeriod;
    public readonly float Habitability;
    public readonly PlanetSpecialization Specialization;
    
    // Faction & politics
    public readonly Guid ControllingFactionId;
    public readonly string ControllingFactionName;
    public readonly float PlayerReputation; // with this faction
    
    // Services
    public readonly IReadOnlyList<ServiceSnapshot> AvailableServices;
    
    // Market (if ServiceType.Market available)
    public readonly IReadOnlyDictionary<string, MarketItemSnapshot> MarketItems;
    
    // Docking
    public readonly int DockCapacity;
    public readonly int UsedDocks;
    
    // Metadata
    public readonly DateTime CreatedAt;
    
    /// <summary>
    /// Create snapshot from CelestialModel and PlayerShipModel
    /// Must be called under both locks
    /// </summary>
    public PlanetCardSnapshot(CelestialModel planet, PlayerShipModel playerShip)
    {
        lock (planet.Sync)
        {
            PlanetId = planet.Id;
            PlanetName = planet.Name;
            ViewKey = planet.ViewKey;
            Radius = planet.Radius;
            OrbitRadius = planet.OrbitRadius;
            OrbitalPeriod = planet.OrbitalPeriod;
            RotationPeriod = planet.RotationPeriod;
            
            // Calculate habitability (from planet.data or formula)
            Habitability = planet.data?.habitability ?? 50f;
            Specialization = planet.data?.specialization ?? PlanetSpecialization.None;
            
            // TODO: Get faction from planet
            ControllingFactionId = Guid.Empty;
            ControllingFactionName = "Independent";
            
            // TODO: Get reputation from player's faction relationships
            PlayerReputation = 0f;
            
            // Copy services
            var services = new List<ServiceSnapshot>();
            foreach (var serviceType in planet.Services)
            {
                services.Add(new ServiceSnapshot(serviceType, planet));
            }
            AvailableServices = services.AsReadOnly();
            
            // Copy market if available
            if (planet.HasService(ServiceType.Market))
            {
                var items = new Dictionary<string, MarketItemSnapshot>();
                foreach (var kvp in planet.Market.Prices)
                {
                    string itemId = kvp.Key;
                    float price = kvp.Value;
                    int stock = planet.Market.Stock.ContainsKey(itemId) 
                        ? planet.Market.Stock[itemId] 
                        : 0;
                    
                    items[itemId] = new MarketItemSnapshot(
                        itemId, 
                        price, 
                        planet.Market.GetSellPrice(itemId),
                        stock
                    );
                }
                MarketItems = items;
            }
            else
            {
                MarketItems = new Dictionary<string, MarketItemSnapshot>();
            }
            
            DockCapacity = planet.DockCapacity;
            UsedDocks = 0; // TODO: calculate from reservedDocks
        }
        
        CreatedAt = DateTime.UtcNow;
    }
}

/// <summary>
/// Snapshot of one service
/// </summary>
public class ServiceSnapshot
{
    public readonly ServiceType Type;
    public readonly string Name;
    public readonly string Description;
    public readonly bool IsAvailable;
    public readonly string StatusText; // "Available", "Busy", "Offline"
    
    public ServiceSnapshot(ServiceType type, CelestialModel planet)
    {
        Type = type;
        Name = GetServiceName(type);
        Description = GetServiceDescription(type);
        IsAvailable = planet.HasService(type);
        StatusText = IsAvailable ? "Available" : "Unavailable";
    }
    
    static string GetServiceName(ServiceType type)
    {
        switch (type)
        {
            case ServiceType.Refuel: return "Refuel Station";
            case ServiceType.Repair: return "Repair Bay";
            case ServiceType.Shop: return "Ship Shop";
            case ServiceType.Market: return "Commodity Market";
            case ServiceType.MissionBoard: return "Mission Board";
            case ServiceType.Bar: return "Pilot's Bar";
            case ServiceType.Dock: return "Docking Port";
            default: return type.ToString();
        }
    }
    
    static string GetServiceDescription(ServiceType type)
    {
        switch (type)
        {
            case ServiceType.Refuel: return "Refuel your ship";
            case ServiceType.Repair: return "Repair hull damage";
            case ServiceType.Shop: return "Buy ships and components";
            case ServiceType.Market: return "Trade commodities";
            case ServiceType.MissionBoard: return "Accept missions";
            case ServiceType.Bar: return "Meet other pilots";
            case ServiceType.Dock: return "Docking services";
            default: return "";
        }
    }
}

/// <summary>
/// Snapshot of one market item
/// </summary>
public class MarketItemSnapshot
{
    public readonly string ItemId;
    public readonly float BuyPrice;
    public readonly float SellPrice;
    public readonly int Stock;
    
    public MarketItemSnapshot(string itemId, float buyPrice, float sellPrice, int stock)
    {
        ItemId = itemId;
        BuyPrice = buyPrice;
        SellPrice = sellPrice;
        Stock = stock;
    }
}

/// <summary>
/// Player ship state snapshot (separate from planet)
/// </summary>
public class PlayerShipSnapshot
{
    public readonly Guid ShipId;
    public readonly float CurrentFuel;
    public readonly float MaxFuel;
    public readonly float CurrentHealth;
    public readonly float MaxHealth;
    public readonly float Credits;
    
    public float FuelPercent => MaxFuel > 0 ? (CurrentFuel / MaxFuel) * 100f : 0f;
    public float HealthPercent => MaxHealth > 0 ? (CurrentHealth / MaxHealth) * 100f : 0f;
    
    public readonly DateTime CreatedAt;
    
    public PlayerShipSnapshot(PlayerShipModel ship)
    {
        lock (ship.Sync)
        {
            ShipId = ship.Id;
            CurrentFuel = ship.CurrentFuel;
            MaxFuel = ship.MaxFuel;
            CurrentHealth = ship.CurrentHealth;
            MaxHealth = ship.MaxHealth;
            Credits = ship.Credits;
        }
        
        CreatedAt = DateTime.UtcNow;
    }
}
```

### 1.3 Использование Snapshot в контроллере

```csharp
public class PlanetCardController
{
    // Current snapshots
    PlanetCardSnapshot currentPlanet;
    PlayerShipSnapshot currentShip;
    
    // Models (for events and mutations)
    CelestialModel planetModel;
    PlayerShipModel shipModel;
    
    // UI root
    VisualElement root;
    
    public void OpenCard(Guid planetId)
    {
        // Get models
        planetModel = GenericSimulationManager.Instance.GetById(planetId) as CelestialModel;
        shipModel = GetPlayerShip();
        
        if (planetModel == null || shipModel == null)
        {
            Debug.LogError("Cannot open planet card: model not found");
            return;
        }
        
        // Create snapshots
        RefreshSnapshot();
        
        // Subscribe to events
        SubscribeToEvents();
        
        // Bind UI
        BindUI();
        
        // Show with animation
        root.style.opacity = 1;
        root.style.display = DisplayStyle.Flex;
    }
    
    void RefreshSnapshot()
    {
        // Create fresh snapshots
        currentPlanet = new PlanetCardSnapshot(planetModel, shipModel);
        currentShip = new PlayerShipSnapshot(shipModel);
        
        Debug.Log($"Snapshot created at {currentPlanet.CreatedAt}");
    }
    
    void BindUI()
    {
        // Bind planet data
        root.Q<Label>("planet-name").text = currentPlanet.PlanetName;
        
        var habitabilityFill = root.Q<VisualElement>("habitability-fill");
        habitabilityFill.style.width = Length.Percent(currentPlanet.Habitability);
        
        root.Q<Label>("habitability-value").text = $"{currentPlanet.Habitability:F0}%";
        
        // Bind ship data
        root.Q<Label>("player-credits").text = $"{currentShip.Credits:F0} CR";
        
        var fuelRadial = root.Q<RadialSlider>("fuel-radial");
        if (fuelRadial != null)
            fuelRadial.value = currentShip.FuelPercent;
        
        // Bind services
        BindServiceList();
    }
    
    void BindServiceList()
    {
        var serviceList = root.Q<ScrollView>("service-list");
        serviceList.Clear();
        
        foreach (var service in currentPlanet.AvailableServices)
        {
            var tile = CreateServiceTile(service);
            serviceList.Add(tile);
        }
    }
}
```

---

## 2. Event-Driven обновления

### 2.1 События в моделях

Модели должны генерировать события при изменениях:

```csharp
// В CelestialModel
public class CelestialModel : ISimulatable
{
    // Market events
    public event Action<string, float> OnPriceChanged;
    public event Action<string, int> OnStockChanged;
    
    // Docking events
    public event Action<Guid, Vector3> OnShipDocked;
    public event Action<Guid> OnShipUndocked;
    
    // Service events
    public event Action<ServiceType> OnServiceAdded;
    public event Action<ServiceType> OnServiceRemoved;
    
    // Helper to raise events
    protected void RaisePriceChanged(string item, float newPrice)
    {
        OnPriceChanged?.Invoke(item, newPrice);
    }
    
    protected void RaiseStockChanged(string item, int newStock)
    {
        OnStockChanged?.Invoke(item, newStock);
    }
    
    // Example: modify TryBuy to raise event
    public bool TryPurchase(Guid buyerId, string itemName, int quantity, out float totalCost)
    {
        lock (sync)
        {
            bool success = Market.TryBuy(itemName, quantity, out totalCost);
            if (success)
            {
                RaiseStockChanged(itemName, Market.Stock[itemName]);
            }
            return success;
        }
    }
}

// В PlayerShipModel
public class PlayerShipModel : ShipModel
{
    float credits = 1000f;
    
    public float Credits
    {
        get { lock (Sync) { return credits; } }
    }
    
    public event Action<float> OnCreditsChanged;
    public event Action<float, float> OnFuelChanged;
    public event Action<float, float> OnHealthChanged;
    
    public bool TrySpendCredits(float amount)
    {
        lock (Sync)
        {
            if (credits < amount)
                return false;
            
            credits -= amount;
            OnCreditsChanged?.Invoke(credits);
            return true;
        }
    }
    
    public void AddCredits(float amount)
    {
        lock (Sync)
        {
            credits += amount;
            OnCreditsChanged?.Invoke(credits);
        }
    }
}
```

### 2.2 Подписка в контроллере

```csharp
public class PlanetCardController
{
    void SubscribeToEvents()
    {
        if (planetModel != null)
        {
            planetModel.OnPriceChanged += OnMarketPriceChanged;
            planetModel.OnStockChanged += OnMarketStockChanged;
        }
        
        if (shipModel != null)
        {
            shipModel.OnCreditsChanged += OnPlayerCreditsChanged;
            shipModel.OnFuelChanged += OnPlayerFuelChanged;
            shipModel.OnHealthChanged += OnPlayerHealthChanged;
        }
    }
    
    void UnsubscribeFromEvents()
    {
        if (planetModel != null)
        {
            planetModel.OnPriceChanged -= OnMarketPriceChanged;
            planetModel.OnStockChanged -= OnMarketStockChanged;
        }
        
        if (shipModel != null)
        {
            shipModel.OnCreditsChanged -= OnPlayerCreditsChanged;
            shipModel.OnFuelChanged -= OnPlayerFuelChanged;
            shipModel.OnHealthChanged -= OnPlayerHealthChanged;
        }
    }
    
    // Event handlers
    void OnMarketPriceChanged(string item, float newPrice)
    {
        // Option 1: Refresh entire snapshot
        RefreshSnapshot();
        BindUI();
        
        // Option 2: Update only affected item (more efficient)
        UpdateMarketItem(item);
    }
    
    void OnMarketStockChanged(string item, int newStock)
    {
        UpdateMarketItem(item);
    }
    
    void OnPlayerCreditsChanged(float newCredits)
    {
        // Update credits display immediately
        root.Q<Label>("player-credits").text = $"{newCredits:F0} CR";
        
        // Refresh ship snapshot
        currentShip = new PlayerShipSnapshot(shipModel);
    }
    
    void OnPlayerFuelChanged(float currentFuel, float maxFuel)
    {
        // Update fuel radial
        var fuelRadial = root.Q<RadialSlider>("fuel-radial");
        if (fuelRadial != null)
        {
            float percent = maxFuel > 0 ? (currentFuel / maxFuel) * 100f : 0f;
            fuelRadial.value = percent;
        }
        
        // Refresh ship snapshot
        currentShip = new PlayerShipSnapshot(shipModel);
    }
    
    void OnPlayerHealthChanged(float currentHealth, float maxHealth)
    {
        // Update health bar (if displayed)
        // Refresh ship snapshot
        currentShip = new PlayerShipSnapshot(shipModel);
    }
    
    void UpdateMarketItem(string itemId)
    {
        // Find market item row in UI
        var itemRow = root.Q<VisualElement>($"market-item-{itemId}");
        if (itemRow == null)
            return;
        
        // Get fresh data from model
        float buyPrice;
        float sellPrice;
        int stock;
        
        lock (planetModel.Sync)
        {
            buyPrice = planetModel.Market.GetBuyPrice(itemId);
            sellPrice = planetModel.Market.GetSellPrice(itemId);
            stock = planetModel.Market.Stock.ContainsKey(itemId) 
                ? planetModel.Market.Stock[itemId] 
                : 0;
        }
        
        // Update UI elements
        itemRow.Q<Label>("item-buy-price").text = $"{buyPrice:F1} CR";
        itemRow.Q<Label>("item-sell-price").text = $"{sellPrice:F1} CR";
        itemRow.Q<Label>("item-stock").text = stock.ToString();
        
        // Update snapshot (partial)
        if (currentPlanet.MarketItems.ContainsKey(itemId))
        {
            // Create updated dictionary (immutable pattern)
            var updatedItems = new Dictionary<string, MarketItemSnapshot>(currentPlanet.MarketItems);
            updatedItems[itemId] = new MarketItemSnapshot(itemId, buyPrice, sellPrice, stock);
            
            // Replace snapshot (careful with immutability)
            // In real implementation, would recreate PlanetCardSnapshot
        }
    }
    
    public void CloseCard()
    {
        // Unsubscribe before closing
        UnsubscribeFromEvents();
        
        // Hide UI
        root.style.opacity = 0;
        root.style.display = DisplayStyle.None;
        
        // Clear references
        planetModel = null;
        shipModel = null;
        currentPlanet = null;
        currentShip = null;
    }
}
```

---

## 3. Transaction Flow

### 3.1 Refuel Transaction (пример)

```
User clicks "Refuel 50 units"
    ↓
ServiceDetailController.OnRefuelButtonClicked()
    ↓
Validate input (amount > 0, amount <= (maxFuel - currentFuel))
    ↓
Check player credits >= total cost
    ↓
[OPTIMISTIC UI] Update UI immediately:
    - Show fuel bar at new level
    - Show credits reduced
    - Show transaction in activity log
    - Show "Processing..." spinner
    ↓
Call CelestialModel.ProvideRefuel(shipId, amount, out cost)
    ↓
[IN MODEL LOCK]
    - Check fuel stock available
    - Deduct fuel from station
    - Call PlayerShip.AddFuel(amount)
    - Call PlayerShip.TrySpendCredits(cost)
    - Return success/failure
    ↓
[BACK IN CONTROLLER]
If success:
    - Create TransactionReceipt
    - Add to activity log with UNDO button (5-10 sec timer)
    - Play success sound/animation
    - Events will fire (OnFuelChanged, OnCreditsChanged) → UI auto-updates
If failure:
    - Rollback optimistic UI changes
    - Show error toast
    - Play error sound
```

### 3.2 Optimistic UI + Rollback

```csharp
public class ServiceDetailController
{
    // Store state before optimistic update
    struct OptimisticState
    {
        public float PreviousFuel;
        public float PreviousCredits;
        public DateTime Timestamp;
    }
    
    OptimisticState? pendingOptimistic;
    
    public void OnRefuelButtonClicked()
    {
        float amount = GetRequestedFuelAmount();
        float unitPrice = currentPlanet.MarketItems["Fuel"].BuyPrice;
        float cost = amount * unitPrice;
        
        // Validate
        if (amount <= 0)
        {
            ShowError("Invalid fuel amount");
            return;
        }
        
        if (currentShip.Credits < cost)
        {
            ShowError("Insufficient credits");
            return;
        }
        
        // Store current state for rollback
        pendingOptimistic = new OptimisticState
        {
            PreviousFuel = currentShip.CurrentFuel,
            PreviousCredits = currentShip.Credits,
            Timestamp = DateTime.UtcNow
        };
        
        // Optimistic update UI
        UpdateFuelDisplay(currentShip.CurrentFuel + amount);
        UpdateCreditsDisplay(currentShip.Credits - cost);
        ShowProcessingIndicator();
        
        // Execute actual transaction (async to avoid blocking UI)
        ExecuteRefuelTransaction(amount, cost);
    }
    
    async void ExecuteRefuelTransaction(float amount, float cost)
    {
        // Call model (this may block on lock briefly)
        bool success = await Task.Run(() =>
        {
            bool result = planetModel.ProvideRefuel(shipModel.Id, amount, out float actualCost);
            if (result)
            {
                // Deduct credits and add fuel
                bool creditsOk = shipModel.TrySpendCredits(actualCost);
                if (creditsOk)
                {
                    shipModel.AddFuel(amount);
                    return true;
                }
            }
            return false;
        });
        
        HideProcessingIndicator();
        
        if (success)
        {
            // Success: clear optimistic state, log transaction
            pendingOptimistic = null;
            LogTransaction("Refuel", amount, cost);
            PlaySuccessAnimation();
            
            // Events (OnFuelChanged, OnCreditsChanged) will sync UI
        }
        else
        {
            // Failure: rollback optimistic changes
            RollbackOptimisticUI();
            ShowError("Refuel failed");
            PlayErrorSound();
        }
    }
    
    void RollbackOptimisticUI()
    {
        if (!pendingOptimistic.HasValue)
            return;
        
        var state = pendingOptimistic.Value;
        
        // Restore previous values
        UpdateFuelDisplay(state.PreviousFuel);
        UpdateCreditsDisplay(state.PreviousCredits);
        
        pendingOptimistic = null;
    }
    
    void UpdateFuelDisplay(float fuel)
    {
        var fuelRadial = root.Q<RadialSlider>("fuel-radial");
        if (fuelRadial != null)
        {
            float percent = shipModel.MaxFuel > 0 ? (fuel / shipModel.MaxFuel) * 100f : 0f;
            fuelRadial.value = percent;
        }
    }
    
    void UpdateCreditsDisplay(float credits)
    {
        root.Q<Label>("player-credits").text = $"{credits:F0} CR";
    }
}
```

### 3.3 Transaction Receipt & Undo

```csharp
/// <summary>
/// Record of a transaction for activity log and undo
/// </summary>
public class TransactionReceipt
{
    public Guid ReceiptId { get; } = Guid.NewGuid();
    public DateTime Timestamp { get; set; }
    public string Description { get; set; }
    public float Cost { get; set; } // negative for spending, positive for earnings
    
    // Undo data
    public Func<bool> UndoAction { get; set; }
    public bool CanUndo { get; set; }
    public float UndoTimeoutSeconds { get; set; } = 10f;
}

public class TransactionLogController
{
    List<TransactionReceipt> recentTransactions = new List<TransactionReceipt>();
    
    public void LogTransaction(TransactionReceipt receipt)
    {
        recentTransactions.Add(receipt);
        
        // Add to UI
        var entry = CreateActivityLogEntry(receipt);
        activityLogList.Add(entry);
        
        // Start undo timer if applicable
        if (receipt.CanUndo)
        {
            StartUndoTimer(receipt);
        }
    }
    
    VisualElement CreateActivityLogEntry(TransactionReceipt receipt)
    {
        var entry = new VisualElement();
        entry.AddToClassList("activity-log-entry");
        
        var timestamp = new Label(receipt.Timestamp.ToString("HH:mm:ss"));
        timestamp.AddToClassList("activity-timestamp");
        entry.Add(timestamp);
        
        var description = new Label(receipt.Description);
        description.AddToClassList("activity-description");
        entry.Add(description);
        
        var cost = new Label($"{receipt.Cost:+0.0;-0.0} CR");
        cost.AddToClassList("activity-cost");
        if (receipt.Cost > 0)
            cost.AddToClassList("activity-cost--positive");
        entry.Add(cost);
        
        if (receipt.CanUndo)
        {
            var undoBtn = new Button(() => UndoTransaction(receipt));
            undoBtn.text = "Undo";
            undoBtn.AddToClassList("undo-button");
            entry.Add(undoBtn);
        }
        
        return entry;
    }
    
    void StartUndoTimer(TransactionReceipt receipt)
    {
        // After timeout, disable undo
        var timer = new System.Threading.Timer(
            _ => DisableUndo(receipt),
            null,
            (int)(receipt.UndoTimeoutSeconds * 1000),
            System.Threading.Timeout.Infinite
        );
    }
    
    void DisableUndo(TransactionReceipt receipt)
    {
        receipt.CanUndo = false;
        
        // Update UI on main thread
        UnityMainThreadDispatcher.Enqueue(() =>
        {
            var entry = activityLogList.Q<VisualElement>($"activity-log-entry-{receipt.ReceiptId}");
            if (entry != null)
            {
                var undoBtn = entry.Q<Button>("btn-undo");
                if (undoBtn != null)
                {
                    undoBtn.SetEnabled(false);
                    undoBtn.style.opacity = 0.3f;
                }
            }
        });
    }
    
    void UndoTransaction(TransactionReceipt receipt)
    {
        if (!receipt.CanUndo || receipt.UndoAction == null)
        {
            ShowError("Cannot undo this transaction");
            return;
        }
        
        bool success = receipt.UndoAction();
        
        if (success)
        {
            // Remove from log
            recentTransactions.Remove(receipt);
            
            // Update UI
            var entry = activityLogList.Q<VisualElement>($"activity-log-entry-{receipt.ReceiptId}");
            if (entry != null)
                activityLogList.Remove(entry);
            
            ShowSuccess("Transaction undone");
        }
        else
        {
            ShowError("Failed to undo transaction");
        }
    }
}
```

---

## 4. Multi-threaded синхронизация

### 4.1 Правила доступа

**Main thread (UI)**:
- Читает snapshot (без locks)
- Вызывает методы моделей (которые берут lock внутри)
- Обрабатывает события (приходят в main thread через dispatcher)

**Background thread (simulation)**:
- Обновляет модели под lock
- Генерирует события (dispatch в main thread)
- НЕ трогает UI напрямую

### 4.2 Event Dispatcher

```csharp
/// <summary>
/// Dispatch model events to main thread for UI updates
/// </summary>
public class UnityMainThreadDispatcher : MonoBehaviour
{
    static UnityMainThreadDispatcher instance;
    Queue<Action> actionQueue = new Queue<Action>();
    
    public static void Enqueue(Action action)
    {
        lock (instance.actionQueue)
        {
            instance.actionQueue.Enqueue(action);
        }
    }
    
    void Update()
    {
        // Execute all queued actions in main thread
        lock (actionQueue)
        {
            while (actionQueue.Count > 0)
            {
                var action = actionQueue.Dequeue();
                try
                {
                    action();
                }
                catch (Exception ex)
                {
                    Debug.LogError($"Error executing queued action: {ex}");
                }
            }
        }
    }
}

// Usage in CelestialModel
public class CelestialModel
{
    protected void RaisePriceChanged(string item, float newPrice)
    {
        // Dispatch to main thread
        UnityMainThreadDispatcher.Enqueue(() =>
        {
            OnPriceChanged?.Invoke(item, newPrice);
        });
    }
}
```

### 4.3 Deadlock prevention

**Правило**: Всегда брать locks в одном порядке:
1. `CelestialModel.Sync`
2. `PlayerShipModel.Sync`
3. Другие модели

**Пример безопасного кода**:
```csharp
public void ExecuteTransaction()
{
    // CORRECT: lock planet first, then ship
    lock (planetModel.Sync)
    {
        lock (shipModel.Sync)
        {
            // safe to access both
        }
    }
}

public void ExecuteTransactionWrong()
{
    // WRONG: lock ship first, then planet (reverse order → deadlock risk)
    lock (shipModel.Sync)
    {
        lock (planetModel.Sync) // DEADLOCK RISK!
        {
            // ...
        }
    }
}
```

---

## 5. Snapshot staleness и refresh strategy

### 5.1 Когда обновлять snapshot?

**Полный refresh** (RefreshSnapshot + BindUI):
- При открытии карточки
- При больших изменениях (например, faction takeover)
- По таймеру (каждые 5-10 секунд) для синхронизации с симуляцией

**Частичный refresh** (UpdateSpecificItem):
- При событии OnPriceChanged → обновить только цену товара
- При событии OnStockChanged → обновить только stock
- При событии OnCreditsChanged → обновить только credits label

### 5.2 Staleness check

```csharp
public class PlanetCardController
{
    const float MAX_SNAPSHOT_AGE_SECONDS = 10f;
    
    void Update()
    {
        // Periodically check if snapshot is stale
        if (currentPlanet != null)
        {
            var age = (DateTime.UtcNow - currentPlanet.CreatedAt).TotalSeconds;
            if (age > MAX_SNAPSHOT_AGE_SECONDS)
            {
                Debug.Log("Snapshot is stale, refreshing...");
                RefreshSnapshot();
                BindUI();
            }
        }
    }
}
```

---

## 6. Error handling

### 6.1 Transaction errors

**Типы ошибок**:
- Insufficient credits
- Insufficient stock
- Service unavailable
- Ship at full capacity
- Transaction timeout

**Обработка**:
```csharp
enum TransactionError
{
    None,
    InsufficientCredits,
    InsufficientStock,
    ServiceUnavailable,
    ShipFull,
    Timeout,
    Unknown
}

void HandleTransactionError(TransactionError error)
{
    string message;
    
    switch (error)
    {
        case TransactionError.InsufficientCredits:
            message = "Not enough credits";
            // Highlight credits display
            HighlightElement("player-credits", Color.red);
            break;
        
        case TransactionError.InsufficientStock:
            message = "Item out of stock";
            break;
        
        case TransactionError.ServiceUnavailable:
            message = "Service temporarily unavailable";
            break;
        
        case TransactionError.ShipFull:
            message = "Ship cargo/fuel is full";
            break;
        
        default:
            message = "Transaction failed";
            break;
    }
    
    ShowErrorToast(message);
    PlayErrorSound();
    
    // Rollback optimistic UI if applicable
    RollbackOptimisticUI();
}

void ShowErrorToast(string message)
{
    var toast = new VisualElement();
    toast.AddToClassList("error-toast");
    
    var label = new Label(message);
    toast.Add(label);
    
    root.Add(toast);
    
    // Auto-hide after 3 seconds
    var timer = new System.Threading.Timer(_ =>
    {
        UnityMainThreadDispatcher.Enqueue(() =>
        {
            root.Remove(toast);
        });
    }, null, 3000, System.Threading.Timeout.Infinite);
}
```

---

## Резюме data flow

1. **Snapshot creation**: Под lock читаем все данные моделей один раз
2. **UI binding**: Привязываем snapshot к UI элементам без locks
3. **Event subscription**: Подписываемся на события моделей
4. **Transactions**: Optimistic UI → вызов модели → rollback или confirm
5. **Event handling**: При событии обновляем snapshot частично или полностью
6. **Thread safety**: События диспатчатся в main thread, locks берутся в порядке
7. **Staleness**: Периодический refresh snapshot для синхронизации с симуляцией

Этот подход обеспечивает:
- **Thread safety** без длительных блокировок
- **Responsiveness** благодаря optimistic UI
- **Consistency** через snapshot pattern
- **Reliability** через rollback механизм

