# Planet UI - Спецификация UI компонентов

## Обзор компонентов

Карточка планеты состоит из иерархии компонентов, каждый с чётко определённой ответственностью.

---

## Иерархия компонентов

```
PlanetCardRoot
├── BackgroundLayer (фон с анимацией планеты)
├── HeaderPanel (верхняя панель)
│   ├── NavigationSection (назад, название планеты)
│   ├── StatusBadgesSection (пригодность, специализация, фракция)
│   └── ActionsSection (кредиты, кнопки взлёта и карты)
├── MainContentArea
│   ├── VisualPanel (левая панель - визуализация планеты)
│   │   ├── PlanetPreview (3D preview или видео)
│   │   └── StatsBar (основные характеристики)
│   └── ServicesPanel (правая панель)
│       ├── ServiceList (список сервисов)
│       └── ServiceDetailPanel (детали выбранного сервиса)
├── QuickActionsBar (панель быстрых действий)
└── ActivityLogBar (журнал транзакций)
```

---

## 1. PlanetCardRoot

**Назначение**: Корневой контейнер всей карточки планеты.

**UXML структура**:
```xml
<ui:VisualElement name="planet-card-root" class="planet-card-root">
    <!-- дочерние элементы -->
</ui:VisualElement>
```

**USS классы**:
- `.planet-card-root` - полноэкранный контейнер
- `.planet-card-root--hidden` - модификатор для скрытия

**Стили**:
```css
.planet-card-root {
    position: absolute;
    left: 0; top: 0; right: 0; bottom: 0;
    background-color: rgba(0, 0, 0, 0.9);
    display: flex;
    flex-direction: column;
    opacity: 1;
    transition: opacity 0.3s ease-in-out;
}

.planet-card-root--hidden {
    opacity: 0;
    pointer-events: none;
}
```

**Ответственность контроллера**:
- Управление видимостью (show/hide с анимацией)
- Координация дочерних контроллеров
- Обработка хоткеев (Esc для закрытия)

---

## 2. BackgroundLayer

**Назначение**: Фоновый слой с анимированным изображением/видео планеты.

**UXML структура**:
```xml
<ui:VisualElement name="background-layer" class="background-layer">
    <ui:VisualElement name="planet-background" class="planet-background" />
    <ui:VisualElement name="parallax-stars" class="parallax-stars" />
</ui:VisualElement>
```

**USS классы**:
- `.background-layer` - фиксированный фон
- `.planet-background` - изображение планеты
- `.parallax-stars` - параллакс слой со звёздами

**Стили**:
```css
.background-layer {
    position: absolute;
    left: 0; top: 0; right: 0; bottom: 0;
    overflow: hidden;
    z-index: -1;
}

.planet-background {
    width: 100%; height: 100%;
    background-image: url('project://path/to/planet.png');
    background-size: cover;
    background-position: center;
}

.parallax-stars {
    position: absolute;
    left: -10%; top: -10%; right: -10%; bottom: -10%;
    background-image: url('project://path/to/stars.png');
    background-repeat: repeat;
}
```

**Функционал**:
- Динамическая загрузка фона на основе `planet.ViewKey`
- Параллакс эффект при движении мыши (опционально)
- Медленная анимация вращения (`rotationAngle`)

**Ответственность контроллера**:
- Загрузить текстуру/видео по ViewKey
- Применить параллакс трансформацию (при включенной опции)
- Обновлять rotation angle

---

## 3. HeaderPanel

**Назначение**: Верхняя фиксированная панель с названием, статусами и основными действиями.

### 3.1 NavigationSection

**UXML структура**:
```xml
<ui:VisualElement name="navigation-section" class="header-section header-section--left">
    <ui:Button name="btn-back" class="icon-button icon-button--back" />
    <ui:Label name="planet-name" text="Earth" class="planet-name" />
    <ui:VisualElement name="view-key-icon" class="view-key-icon" />
</ui:VisualElement>
```

**USS классы**:
- `.header-section` - базовый стиль секции header
- `.header-section--left` - выравнивание влево
- `.icon-button` - стиль иконочной кнопки
- `.planet-name` - стиль названия планеты (H1)
- `.view-key-icon` - маленькая иконка view key

**Стили**:
```css
.header-section {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 12px;
    padding: 16px;
}

.header-section--left {
    justify-content: flex-start;
}

.icon-button {
    width: 40px;
    height: 40px;
    background-color: transparent;
    border-width: 1px;
    border-color: #FFFFFF;
    border-radius: 4px;
}

.icon-button--back {
    background-image: url('project://path/to/icon-back.png');
}

.planet-name {
    color: #FFFFFF;
    font-size: 32px;
    font-weight: bold;
    letter-spacing: 1.5px;
}

.view-key-icon {
    width: 24px;
    height: 24px;
    background-image: url('project://path/to/icon-planet.png');
}
```

**Функционал**:
- Кнопка "Назад" → закрывает карточку (или возвращает в систему)
- Название планеты - отображает `planet.Name`
- View key icon - визуальный индикатор типа планеты

### 3.2 StatusBadgesSection

**UXML структура**:
```xml
<ui:VisualElement name="status-badges-section" class="header-section header-section--center">
    <ui:VisualElement name="habitability-badge" class="badge badge--habitability">
        <ui:Label text="Habitability" class="badge-label" />
        <ui:VisualElement name="habitability-bar" class="badge-bar">
            <ui:VisualElement name="habitability-fill" class="badge-bar-fill" />
        </ui:VisualElement>
        <ui:Label name="habitability-value" text="78%" class="badge-value" />
    </ui:VisualElement>
    
    <ui:VisualElement name="specialization-badge" class="badge badge--specialization">
        <ui:Label name="specialization-label" text="Agricultural" class="badge-label" />
        <ui:VisualElement name="specialization-icon" class="specialization-icon" />
    </ui:VisualElement>
    
    <ui:VisualElement name="faction-badge" class="badge badge--faction">
        <ui:Label name="faction-label" text="Solar Federation" class="badge-label" />
        <ui:VisualElement name="faction-icon" class="faction-icon" />
        <ui:VisualElement name="reputation-bar" class="reputation-bar">
            <ui:VisualElement name="reputation-fill" class="reputation-bar-fill" />
        </ui:VisualElement>
    </ui:VisualElement>
</ui:VisualElement>
```

**USS классы**:
- `.badge` - базовый стиль бейджа
- `.badge--habitability` / `.badge--specialization` / `.badge--faction` - модификаторы
- `.badge-bar` - контейнер прогресс-бара
- `.badge-bar-fill` - заполнение прогресс-бара
- `.reputation-bar` - бар репутации с фракцией

**Стили**:
```css
.badge {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 8px 12px;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 6px;
    gap: 4px;
}

.badge-label {
    color: #CCCCCC;
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.8px;
}

.badge-value {
    color: #FFFFFF;
    font-size: 16px;
    font-weight: bold;
}

.badge-bar {
    width: 80px;
    height: 4px;
    background-color: rgba(255, 255, 255, 0.2);
    border-radius: 2px;
}

.badge-bar-fill {
    height: 100%;
    background-color: #00FF88; /* зелёный для высокой пригодности */
    border-radius: 2px;
}

.reputation-bar {
    width: 100px;
    height: 6px;
    background-color: rgba(255, 255, 255, 0.2);
    border-radius: 3px;
}

.reputation-bar-fill {
    height: 100%;
    background-color: #00E5FF; /* акцентный цвет */
    border-radius: 3px;
}
```

**Функционал**:
- Habitability бар - цвет меняется от красного (низкая) до зелёного (высокая)
- Specialization - иконка специализации планеты
- Faction - показывает фракцию и репутацию игрока (Friendly/Neutral/Hostile)
- Tooltip при наведении с подробностями

### 3.3 ActionsSection

**UXML структура**:
```xml
<ui:VisualElement name="actions-section" class="header-section header-section--right">
    <ui:Label name="player-credits" text="1,250 CR" class="player-credits" />
    <ui:Button name="btn-open-map" text="Map" class="header-button" />
    <ui:Button name="btn-takeoff" text="Takeoff (T)" class="header-button header-button--primary" />
</ui:VisualElement>
```

**USS классы**:
- `.header-section--right` - выравнивание вправо
- `.player-credits` - стиль отображения кредитов
- `.header-button` - стиль кнопки в header
- `.header-button--primary` - главная CTA кнопка (Takeoff)

**Стили**:
```css
.header-section--right {
    justify-content: flex-end;
}

.player-credits {
    color: #FFD700; /* золотой цвет для валюты */
    font-size: 18px;
    font-weight: bold;
    letter-spacing: 1px;
}

.header-button {
    padding: 10px 20px;
    background-color: rgba(255, 255, 255, 0.1);
    color: #FFFFFF;
    border-width: 1px;
    border-color: #FFFFFF;
    border-radius: 4px;
    font-size: 14px;
}

.header-button--primary {
    background-color: #00E5FF; /* акцентный цвет */
    color: #000000;
    border-color: #00E5FF;
    /* свечение */
    box-shadow: 0 0 8px rgba(0, 229, 255, 0.5);
}

.header-button:hover {
    background-color: rgba(255, 255, 255, 0.2);
}

.header-button--primary:hover {
    background-color: #00CCDD;
    box-shadow: 0 0 12px rgba(0, 229, 255, 0.8);
}
```

**Функционал**:
- Player credits - обновляется при событии `OnCreditsChanged`
- Map button → открывает карту системы
- Takeoff button → валидация (топливо, здоровье), затем взлёт

---

## 4. MainContentArea

### 4.1 VisualPanel (левая панель)

**UXML структура**:
```xml
<ui:VisualElement name="visual-panel" class="visual-panel">
    <ui:VisualElement name="planet-preview" class="planet-preview">
        <!-- Здесь может быть 3D RenderTexture или видео -->
    </ui:VisualElement>
    
    <ui:VisualElement name="stats-bar" class="stats-bar">
        <ui:VisualElement name="stat-radius" class="stat-pill">
            <ui:Label text="Radius" class="stat-label" />
            <ui:Label name="stat-radius-value" text="6,371 km" class="stat-value" />
        </ui:VisualElement>
        
        <ui:VisualElement name="stat-orbit" class="stat-pill">
            <ui:Label text="Orbit" class="stat-label" />
            <ui:Label name="stat-orbit-value" text="149.6M km" class="stat-value" />
        </ui:VisualElement>
        
        <ui:VisualElement name="stat-period" class="stat-pill">
            <ui:Label text="Period" class="stat-label" />
            <ui:Label name="stat-period-value" text="365.25d" class="stat-value" />
        </ui:VisualElement>
        
        <ui:VisualElement name="stat-population" class="stat-pill">
            <ui:Label text="Population" class="stat-label" />
            <ui:Label name="stat-population-value" text="7.8B" class="stat-value" />
        </ui:VisualElement>
    </ui:VisualElement>
</ui:VisualElement>
```

**USS классы**:
- `.visual-panel` - левая панель (60% ширины)
- `.planet-preview` - контейнер превью планеты
- `.stats-bar` - горизонтальный ряд статов
- `.stat-pill` - одна "таблетка" со статом

**Стили**:
```css
.visual-panel {
    flex: 6; /* 60% ширины */
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 24px;
    gap: 16px;
}

.planet-preview {
    width: 100%;
    min-height: 520px;
    max-height: 70vh;
    background-color: rgba(0, 0, 0, 0.5);
    border-radius: 8px;
    overflow: hidden;
}

.stats-bar {
    width: 100%;
    display: flex;
    flex-direction: row;
    justify-content: space-around;
    gap: 8px;
}

.stat-pill {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 8px 16px;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 16px;
    cursor: pointer; /* интерактивность для tooltip */
}

.stat-pill:hover {
    background-color: rgba(255, 255, 255, 0.2);
}

.stat-label {
    color: #AAAAAA;
    font-size: 12px;
    text-transform: uppercase;
}

.stat-value {
    color: #FFFFFF;
    font-size: 16px;
    font-weight: bold;
}
```

**Функционал**:
- Planet preview - загружает 3D RenderTexture или видео-петлю
- Параллакс при движении мыши (опционально)
- Клик для поворота, двойной клик для fullscreen
- Stats bar - tooltip с подробной информацией при наведении

### 4.2 ServicesPanel (правая панель)

**UXML структура**:
```xml
<ui:VisualElement name="services-panel" class="services-panel">
    <!-- 4.2.1 ServiceList -->
    <ui:ScrollView name="service-list" class="service-list">
        <!-- динамически генерируемые ServiceTile -->
    </ui:ScrollView>
    
    <!-- 4.2.2 ServiceDetailPanel -->
    <ui:VisualElement name="service-detail-panel" class="service-detail-panel">
        <!-- содержимое зависит от выбранного сервиса -->
    </ui:VisualElement>
</ui:VisualElement>
```

**USS классы**:
- `.services-panel` - правая панель (40% ширины)
- `.service-list` - прокручиваемый список сервисов
- `.service-detail-panel` - панель деталей выбранного сервиса

**Стили**:
```css
.services-panel {
    flex: 4; /* 40% ширины */
    display: flex;
    flex-direction: column;
    gap: 16px;
    padding: 24px;
}

.service-list {
    flex: 0 0 auto;
    max-height: 40vh;
    overflow-y: auto;
}

.service-detail-panel {
    flex: 1;
    background-color: rgba(0, 0, 0, 0.6);
    border-radius: 8px;
    padding: 16px;
    overflow-y: auto;
}
```

#### 4.2.1 ServiceTile (элемент списка сервисов)

**UXML структура**:
```xml
<ui:VisualElement name="service-tile-{serviceType}" class="service-tile">
    <ui:VisualElement name="service-icon" class="service-icon service-icon--{serviceType}" />
    <ui:VisualElement class="service-info">
        <ui:Label name="service-name" text="Refuel Station" class="service-name" />
        <ui:Label name="service-status" text="Available" class="service-status" />
    </ui:VisualElement>
    <ui:Button name="service-quick-action" text="Refuel" class="service-quick-button" />
</ui:VisualElement>
```

**USS классы**:
- `.service-tile` - карточка сервиса
- `.service-tile--selected` - модификатор для выбранного
- `.service-icon` - иконка сервиса
- `.service-quick-button` - быстрая кнопка действия

**Стили**:
```css
.service-tile {
    display: flex;
    flex-direction: row;
    align-items: center;
    padding: 12px;
    background-color: rgba(255, 255, 255, 0.05);
    border-radius: 6px;
    gap: 12px;
    margin-bottom: 8px;
    cursor: pointer;
    transition: transform 0.15s ease, background-color 0.15s ease;
}

.service-tile:hover {
    transform: translateY(-4px);
    background-color: rgba(255, 255, 255, 0.1);
}

.service-tile--selected {
    background-color: rgba(0, 229, 255, 0.2);
    border-left-width: 4px;
    border-left-color: #00E5FF;
}

.service-icon {
    width: 48px;
    height: 48px;
    background-size: contain;
    background-repeat: no-repeat;
}

.service-icon--refuel {
    background-image: url('project://path/to/icon-refuel.png');
}

.service-icon--repair {
    background-image: url('project://path/to/icon-repair.png');
}

.service-icon--shop {
    background-image: url('project://path/to/icon-shop.png');
}

.service-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.service-name {
    color: #FFFFFF;
    font-size: 18px;
    font-weight: bold;
}

.service-status {
    color: #AAAAAA;
    font-size: 14px;
}

.service-quick-button {
    padding: 8px 16px;
    background-color: #00E5FF;
    color: #000000;
    border-radius: 4px;
    border-width: 0;
}

.service-quick-button:hover {
    background-color: #00CCDD;
}
```

**Функционал**:
- Клик на tile → выбрать сервис и показать детали в ServiceDetailPanel
- Hover → поднятие карточки (translateY)
- Quick action button → выполнить быстрое действие без открытия деталей

#### 4.2.2 ServiceDetailPanel содержимое

Содержимое зависит от типа сервиса. Примеры:

##### Refuel Service Detail

**UXML структура**:
```xml
<ui:VisualElement name="refuel-detail" class="service-detail refuel-detail">
    <ui:Label text="Refuel Station" class="service-detail-title" />
    
    <ui:VisualElement class="price-info">
        <ui:Label text="Fuel Price:" class="price-label" />
        <ui:Label name="fuel-price" text="5.0 CR/unit" class="price-value" />
    </ui:VisualElement>
    
    <ui:VisualElement class="fuel-slider-container">
        <ui:Slider name="fuel-amount-slider" low-value="0" high-value="100" class="fuel-slider" />
        <ui:Label name="fuel-amount-label" text="50 units" class="fuel-amount-label" />
    </ui:VisualElement>
    
    <ui:VisualElement class="preset-buttons">
        <ui:Button name="btn-refuel-25" text="25%" class="preset-button" />
        <ui:Button name="btn-refuel-50" text="50%" class="preset-button" />
        <ui:Button name="btn-refuel-full" text="Full" class="preset-button" />
    </ui:VisualElement>
    
    <ui:VisualElement class="total-cost">
        <ui:Label text="Total Cost:" class="total-label" />
        <ui:Label name="total-cost-value" text="250 CR" class="total-value" />
    </ui:VisualElement>
    
    <ui:Button name="btn-confirm-refuel" text="Confirm Refuel" class="confirm-button" />
</ui:VisualElement>
```

##### Ship Shop Service Detail

**UXML структура**:
```xml
<ui:VisualElement name="shop-detail" class="service-detail shop-detail">
    <ui:Label text="Ship Shop" class="service-detail-title" />
    
    <ui:ScrollView name="ship-list" class="ship-list">
        <!-- динамически генерируемые ShipCard -->
    </ui:ScrollView>
</ui:VisualElement>
```

**ShipCard структура**:
```xml
<ui:VisualElement name="ship-card-{shipId}" class="ship-card">
    <ui:VisualElement name="ship-thumbnail" class="ship-thumbnail" />
    <ui:VisualElement class="ship-info">
        <ui:Label name="ship-name" text="Viper MkII" class="ship-name" />
        <ui:Label name="ship-class" text="Fighter" class="ship-class" />
        <ui:VisualElement class="ship-stats">
            <ui:Label text="Speed: 150" class="ship-stat" />
            <ui:Label text="Cargo: 20t" class="ship-stat" />
            <ui:Label text="HP: 300" class="ship-stat" />
        </ui:VisualElement>
    </ui:VisualElement>
    <ui:VisualElement class="ship-actions">
        <ui:Label name="ship-price" text="5,000 CR" class="ship-price" />
        <ui:Button name="btn-buy-ship" text="Buy" class="buy-button" />
        <ui:Button name="btn-inspect-ship" text="Inspect" class="inspect-button" />
    </ui:VisualElement>
</ui:VisualElement>
```

##### Market Service Detail

**UXML структура**:
```xml
<ui:VisualElement name="market-detail" class="service-detail market-detail">
    <ui:Label text="Market" class="service-detail-title" />
    
    <ui:VisualElement class="market-search">
        <ui:TextField name="market-search-input" placeholder="Search items..." class="search-input" />
    </ui:VisualElement>
    
    <ui:ScrollView name="market-items-list" class="market-items-list">
        <!-- динамически генерируемые MarketItemRow -->
    </ui:ScrollView>
</ui:VisualElement>
```

**MarketItemRow структура**:
```xml
<ui:VisualElement name="market-item-{itemId}" class="market-item-row">
    <ui:Label name="item-name" text="Food" class="item-name" />
    <ui:Label name="item-buy-price" text="10 CR" class="item-price item-price--buy" />
    <ui:Label name="item-sell-price" text="8 CR" class="item-price item-price--sell" />
    <ui:Label name="item-stock" text="150" class="item-stock" />
    <ui:Button name="btn-buy-item" text="Buy" class="item-button item-button--buy" />
    <ui:Button name="btn-sell-item" text="Sell" class="item-button item-button--sell" />
</ui:VisualElement>
```

---

## 5. QuickActionsBar

**Назначение**: Всегда видимая панель быстрых действий.

**UXML структура**:
```xml
<ui:VisualElement name="quick-actions-bar" class="quick-actions-bar">
    <ui:Button name="btn-quick-takeoff" text="Takeoff (T)" class="quick-action-button quick-action-button--primary" />
    <ui:Button name="btn-quick-refuel" text="Refuel (F)" class="quick-action-button" />
    <ui:Button name="btn-quick-repair" text="Repair (R)" class="quick-action-button" />
    <ui:Button name="btn-quick-market" text="Market (M)" class="quick-action-button" />
    <ui:Button name="btn-quick-shop" text="Shop (S)" class="quick-action-button" />
</ui:VisualElement>
```

**USS классы**:
- `.quick-actions-bar` - горизонтальная панель действий
- `.quick-action-button` - кнопка быстрого действия
- `.quick-action-button--primary` - главная кнопка (Takeoff)

**Стили**:
```css
.quick-actions-bar {
    position: absolute;
    bottom: 80px;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    flex-direction: row;
    gap: 12px;
    padding: 12px;
    background-color: rgba(0, 0, 0, 0.8);
    border-radius: 8px;
}

.quick-action-button {
    padding: 12px 24px;
    background-color: rgba(255, 255, 255, 0.1);
    color: #FFFFFF;
    border-width: 1px;
    border-color: #FFFFFF;
    border-radius: 4px;
    font-size: 14px;
}

.quick-action-button--primary {
    background-color: #00E5FF;
    color: #000000;
    border-color: #00E5FF;
}

.quick-action-button:hover {
    background-color: rgba(255, 255, 255, 0.2);
}
```

**Функционал**:
- Хоткеи T, F, R, M, S
- Кнопки всегда видны и доступны
- На мобильных - FAB (Floating Action Button) с раскрывающимся меню

---

## 6. ActivityLogBar

**Назначение**: Журнал последних транзакций с возможностью undo.

**UXML структура**:
```xml
<ui:VisualElement name="activity-log-bar" class="activity-log-bar">
    <ui:ScrollView name="activity-log-list" class="activity-log-list">
        <!-- динамически генерируемые ActivityLogEntry -->
    </ui:ScrollView>
</ui:VisualElement>
```

**ActivityLogEntry структура**:
```xml
<ui:VisualElement name="activity-log-entry-{id}" class="activity-log-entry">
    <ui:Label name="activity-timestamp" text="12:34:56" class="activity-timestamp" />
    <ui:Label name="activity-description" text="Refueled 50 units" class="activity-description" />
    <ui:Label name="activity-cost" text="-250 CR" class="activity-cost" />
    <ui:Button name="btn-undo" text="Undo" class="undo-button" />
</ui:VisualElement>
```

**USS классы**:
- `.activity-log-bar` - нижняя панель журнала
- `.activity-log-entry` - одна запись в журнале
- `.undo-button` - кнопка отмены (видна 5-10 сек)

**Стили**:
```css
.activity-log-bar {
    position: absolute;
    bottom: 12px;
    left: 12px;
    width: 400px;
    max-height: 150px;
    background-color: rgba(0, 0, 0, 0.8);
    border-radius: 6px;
    padding: 8px;
    overflow-y: auto;
}

.activity-log-entry {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 8px;
    padding: 6px;
    background-color: rgba(255, 255, 255, 0.05);
    border-radius: 4px;
    margin-bottom: 4px;
}

.activity-timestamp {
    color: #888888;
    font-size: 12px;
    min-width: 60px;
}

.activity-description {
    flex: 1;
    color: #FFFFFF;
    font-size: 14px;
}

.activity-cost {
    color: #FF4444; /* красный для расходов */
    font-size: 14px;
    font-weight: bold;
}

.activity-cost--positive {
    color: #00FF88; /* зелёный для доходов */
}

.undo-button {
    padding: 4px 8px;
    background-color: rgba(255, 255, 0, 0.3);
    color: #FFFFFF;
    border-radius: 3px;
    font-size: 12px;
}
```

**Функционал**:
- Автоматическое добавление записей при транзакциях
- Кнопка Undo видна 5-10 секунд после транзакции
- При клике на Undo - откат транзакции (если возможно)

---

## 7. Модальные окна

### 7.1 ConfirmationModal (подтверждение взлёта)

**UXML структура**:
```xml
<ui:VisualElement name="confirmation-modal" class="modal-overlay">
    <ui:VisualElement class="modal-content">
        <ui:Label text="Confirm Takeoff" class="modal-title" />
        <ui:Label name="modal-message" text="Ready for takeoff?" class="modal-message" />
        
        <ui:VisualElement name="preflight-checklist" class="preflight-checklist">
            <ui:VisualElement name="check-fuel" class="checklist-item">
                <ui:VisualElement name="check-fuel-icon" class="check-icon check-icon--ok" />
                <ui:Label text="Fuel: OK" class="check-label" />
            </ui:VisualElement>
            
            <ui:VisualElement name="check-health" class="checklist-item">
                <ui:VisualElement name="check-health-icon" class="check-icon check-icon--warning" />
                <ui:Label text="Hull: Low" class="check-label check-label--warning" />
            </ui:VisualElement>
        </ui:VisualElement>
        
        <ui:VisualElement class="modal-actions">
            <ui:Button name="btn-cancel" text="Cancel" class="modal-button modal-button--secondary" />
            <ui:Button name="btn-confirm" text="Confirm" class="modal-button modal-button--primary" />
        </ui:VisualElement>
    </ui:VisualElement>
</ui:VisualElement>
```

**USS классы**:
- `.modal-overlay` - полупрозрачный оверлей
- `.modal-content` - содержимое модала
- `.preflight-checklist` - список проверок перед взлётом
- `.check-icon--ok` / `.check-icon--warning` / `.check-icon--error` - иконки статуса

**Стили**:
```css
.modal-overlay {
    position: absolute;
    left: 0; top: 0; right: 0; bottom: 0;
    background-color: rgba(0, 0, 0, 0.7);
    display: flex;
    align-items: center;
    justify-content: center;
}

.modal-content {
    width: 400px;
    padding: 24px;
    background-color: rgba(20, 20, 20, 0.95);
    border-radius: 8px;
    border-width: 1px;
    border-color: #00E5FF;
}

.modal-title {
    color: #FFFFFF;
    font-size: 24px;
    font-weight: bold;
    margin-bottom: 16px;
}

.modal-message {
    color: #CCCCCC;
    font-size: 16px;
    margin-bottom: 16px;
}

.preflight-checklist {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-bottom: 16px;
}

.checklist-item {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 8px;
}

.check-icon {
    width: 24px;
    height: 24px;
}

.check-icon--ok {
    background-image: url('project://path/to/icon-check-ok.png');
}

.check-icon--warning {
    background-image: url('project://path/to/icon-check-warning.png');
}

.check-icon--error {
    background-image: url('project://path/to/icon-check-error.png');
}

.check-label--warning {
    color: #FFAA00;
}

.modal-actions {
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    gap: 12px;
}

.modal-button {
    padding: 10px 20px;
    border-radius: 4px;
    font-size: 14px;
}

.modal-button--secondary {
    background-color: rgba(255, 255, 255, 0.1);
    color: #FFFFFF;
}

.modal-button--primary {
    background-color: #00E5FF;
    color: #000000;
}
```

---

## Responsive поведение

### Desktop (>1280px)
- Стандартная layout (60/40 split)
- Все элементы видны одновременно

### Tablet (768px - 1280px)
- Layout меняется на 50/50 split
- Некоторые бейджи в header сворачиваются

### Mobile (&lt;768px)
- Vertical layout: визуал планеты сверху, сервисы снизу
- Quick actions bar → FAB (Floating Action Button)
- Stats bar → аккордеон (раскрывается по клику)
- Service detail panel → fullscreen modal

---

## Accessibility

### Screen Reader
- Все кнопки и интерактивные элементы имеют `name` атрибут
- Важные статусы (fuel, health) объявляются при изменении

### Keyboard Navigation
- Tab для навигации между элементами
- Arrow keys для списков (сервисы, товары)
- Enter для активации
- Esc для закрытия модалов и карточки

### High Contrast Mode
- Увеличить border-width всех элементов
- Убрать backdrop blur
- Усилить контраст текста (чёрный/белый)

### Reduce Motion
- Отключить параллакс
- Отключить анимации открытия/закрытия
- Использовать только fade transitions

---

## Резюме компонентов

Всего создаётся:
- **1 корневой компонент**: PlanetCardRoot
- **3 основных панели**: Header, MainContent, QuickActions + ActivityLog
- **6+ переиспользуемых элементов**: ServiceTile, ShipCard, MarketItemRow, ActivityLogEntry, StatPill, Badge
- **2+ модальных окна**: ConfirmationModal, ErrorToast

Каждый компонент имеет:
- Чёткую ответственность
- Декларативную UXML структуру
- Переиспользуемые USS классы
- Модификаторы для вариаций (--primary, --selected, --warning)

