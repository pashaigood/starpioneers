# Planet UI - USS и UXML спецификация

## Обзор

Этот документ описывает визуальную структуру Planet UI без конкретной реализации. Определяет:
- Иерархию USS классов и их назначение
- Структуру UXML документов
- Naming conventions
- Responsive breakpoints
- Темизацию и вариации

---

## 1. Naming Conventions

### 1.1 USS классы

**BEM-подобная методология**:
- **Block**: `.planet-card`, `.service-tile`, `.modal`
- **Element**: `.planet-card__header`, `.service-tile__icon`
- **Modifier**: `.planet-card--hidden`, `.service-tile--selected`, `.modal--error`

**Utility классы** (переиспользуемые):
- `.flex-row`, `.flex-column`
- `.gap-small`, `.gap-medium`, `.gap-large`
- `.text-primary`, `.text-secondary`, `.text-accent`
- `.bg-dark`, `.bg-light`, `.bg-transparent`
- `.rounded`, `.rounded-small`, `.rounded-large`

**State классы**:
- `.is-active`, `.is-disabled`, `.is-loading`, `.is-error`
- `.has-tooltip`, `.has-notification`

### 1.2 UXML элементы (name атрибут)

**Naming pattern**: `{type}-{descriptor}`

Примеры:
- `planet-card-root`
- `btn-takeoff`, `btn-refuel`, `btn-confirm`
- `label-planet-name`, `label-credits`
- `panel-services`, `panel-detail`
- `list-services`, `list-market-items`
- `slider-fuel-amount`
- `input-search-market`

**Префиксы**:
- `btn-` - кнопки
- `label-` - текстовые метки
- `panel-` - панели/контейнеры
- `list-` - списки/скролл вьюхи
- `slider-` - слайдеры
- `input-` - поля ввода
- `icon-` - иконки
- `bar-` - прогресс бары

---

## 2. Глобальные USS переменные

### 2.1 Цветовая палитра

```css
/* Основные цвета */
--color-primary: #00E5FF;        /* Акцентный cyan */
--color-primary-dark: #00CCDD;   /* Темнее для hover */
--color-primary-light: #33EEFF;  /* Светлее для highlights */

--color-success: #00FF88;        /* Зелёный успех */
--color-warning: #FFAA00;        /* Оранжевый предупреждение */
--color-error: #FF4444;          /* Красный ошибка */
--color-info: #4499FF;           /* Синий информация */

/* Нейтральные */
--color-text-primary: #FFFFFF;
--color-text-secondary: #CCCCCC;
--color-text-tertiary: #888888;
--color-text-disabled: #555555;

--color-bg-dark: #000000;
--color-bg-medium: #222222;
--color-bg-light: #444444;
--color-bg-overlay: rgba(0, 0, 0, 0.9);
--color-bg-panel: rgba(0, 0, 0, 0.6);
--color-bg-input: rgba(255, 255, 255, 0.1);

--color-border: #FFFFFF;
--color-border-subtle: rgba(255, 255, 255, 0.2);

/* Специальные */
--color-credits: #FFD700;        /* Золото для валюты */
--color-fuel: #00E5FF;           /* Cyan для топлива */
--color-health: #FF4444;         /* Красный для здоровья */
```

### 2.2 Размеры и spacing

```css
/* Spacing scale */
--space-xs: 4px;
--space-sm: 8px;
--space-md: 12px;
--space-lg: 16px;
--space-xl: 24px;
--space-2xl: 32px;
--space-3xl: 48px;

/* Font sizes */
--font-size-xs: 11px;
--font-size-sm: 12px;
--font-size-base: 14px;
--font-size-lg: 16px;
--font-size-xl: 18px;
--font-size-2xl: 24px;
--font-size-3xl: 32px;

/* Border radius */
--radius-sm: 3px;
--radius-md: 6px;
--radius-lg: 8px;
--radius-xl: 16px;
--radius-full: 999px;

/* Sizes */
--icon-size-sm: 24px;
--icon-size-md: 32px;
--icon-size-lg: 48px;

--button-height-sm: 32px;
--button-height-md: 40px;
--button-height-lg: 48px;

/* Layout */
--header-height: 72px;
--quick-actions-height: 60px;
--activity-log-height: 150px;

--sidebar-width: 40%;
--main-content-width: 60%;
```

### 2.3 Анимации

```css
/* Durations */
--duration-fast: 0.15s;
--duration-normal: 0.3s;
--duration-slow: 0.5s;

/* Easing */
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in: cubic-bezier(0.4, 0, 1, 1);
```

---

## 3. Базовые USS классы

### 3.1 Layout utilities

```css
/* Flexbox */
.flex-row { 
    display: flex; 
    flex-direction: row; 
}

.flex-column { 
    display: flex; 
    flex-direction: column; 
}

.flex-center {
    align-items: center;
    justify-content: center;
}

.flex-space-between {
    justify-content: space-between;
}

.flex-wrap { 
    flex-wrap: wrap; 
}

/* Gaps */
.gap-xs { gap: var(--space-xs); }
.gap-sm { gap: var(--space-sm); }
.gap-md { gap: var(--space-md); }
.gap-lg { gap: var(--space-lg); }
.gap-xl { gap: var(--space-xl); }
```

### 3.2 Spacing utilities

```css
/* Padding */
.p-0 { padding: 0; }
.p-sm { padding: var(--space-sm); }
.p-md { padding: var(--space-md); }
.p-lg { padding: var(--space-lg); }
.p-xl { padding: var(--space-xl); }

/* Margin */
.m-0 { margin: 0; }
.m-sm { margin: var(--space-sm); }
.m-md { margin: var(--space-md); }
.m-lg { margin: var(--space-lg); }
.m-xl { margin: var(--space-xl); }
```

### 3.3 Typography utilities

```css
.text-xs { font-size: var(--font-size-xs); }
.text-sm { font-size: var(--font-size-sm); }
.text-base { font-size: var(--font-size-base); }
.text-lg { font-size: var(--font-size-lg); }
.text-xl { font-size: var(--font-size-xl); }
.text-2xl { font-size: var(--font-size-2xl); }
.text-3xl { font-size: var(--font-size-3xl); }

.text-bold { font-weight: bold; }
.text-uppercase { text-transform: uppercase; }
.text-center { text-align: center; }

.text-primary { color: var(--color-text-primary); }
.text-secondary { color: var(--color-text-secondary); }
.text-tertiary { color: var(--color-text-tertiary); }
.text-accent { color: var(--color-primary); }
.text-success { color: var(--color-success); }
.text-warning { color: var(--color-warning); }
.text-error { color: var(--color-error); }
```

### 3.4 Background utilities

```css
.bg-transparent { background-color: transparent; }
.bg-dark { background-color: var(--color-bg-dark); }
.bg-medium { background-color: var(--color-bg-medium); }
.bg-light { background-color: var(--color-bg-light); }
.bg-panel { background-color: var(--color-bg-panel); }
.bg-overlay { background-color: var(--color-bg-overlay); }
```

### 3.5 Border utilities

```css
.border { border-width: 1px; border-color: var(--color-border); }
.border-subtle { border-width: 1px; border-color: var(--color-border-subtle); }
.border-accent { border-width: 1px; border-color: var(--color-primary); }

.rounded-sm { border-radius: var(--radius-sm); }
.rounded-md { border-radius: var(--radius-md); }
.rounded-lg { border-radius: var(--radius-lg); }
.rounded-xl { border-radius: var(--radius-xl); }
.rounded-full { border-radius: var(--radius-full); }
```

---

## 4. Component-specific USS классы

### 4.1 planet-card (корневой контейнер)

```css
.planet-card-root {
    /* Fullscreen overlay */
    position: absolute;
    left: 0; top: 0; right: 0; bottom: 0;
    background-color: var(--color-bg-overlay);
    display: flex;
    flex-direction: column;
    opacity: 1;
    transition: opacity var(--duration-normal) var(--ease-in-out);
}

.planet-card-root--hidden {
    opacity: 0;
    pointer-events: none;
}

.planet-card-root--loading {
    /* Show spinner overlay */
}
```

### 4.2 background-layer (фон)

```css
.background-layer {
    position: absolute;
    left: 0; top: 0; right: 0; bottom: 0;
    overflow: hidden;
    z-index: -1;
}

.background-layer__planet {
    width: 100%; 
    height: 100%;
    background-size: cover;
    background-position: center;
    /* Динамически устанавливается background-image */
}

.background-layer__stars {
    position: absolute;
    left: -10%; top: -10%; right: -10%; bottom: -10%;
    background-repeat: repeat;
    opacity: 0.5;
}

.background-layer__vignette {
    /* Темная виньетка по краям */
    position: absolute;
    left: 0; top: 0; right: 0; bottom: 0;
    background: radial-gradient(ellipse at center, transparent 30%, rgba(0,0,0,0.8) 100%);
}
```

### 4.3 header-panel (верхняя панель)

```css
.header-panel {
    height: var(--header-height);
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    padding: 0 var(--space-xl);
    background-color: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(10px);
}

.header-section {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: var(--space-md);
}

.header-section--left {
    justify-content: flex-start;
}

.header-section--center {
    justify-content: center;
    flex: 1;
}

.header-section--right {
    justify-content: flex-end;
}
```

### 4.4 badge (статусные бейджи)

```css
.badge {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: var(--space-sm) var(--space-md);
    background-color: var(--color-bg-input);
    border-radius: var(--radius-md);
    gap: var(--space-xs);
}

.badge--clickable {
    cursor: pointer;
}

.badge--clickable:hover {
    background-color: rgba(255, 255, 255, 0.15);
}

.badge__label {
    color: var(--color-text-secondary);
    font-size: var(--font-size-xs);
    text-transform: uppercase;
    letter-spacing: 0.8px;
}

.badge__value {
    color: var(--color-text-primary);
    font-size: var(--font-size-lg);
    font-weight: bold;
}

.badge__icon {
    width: var(--icon-size-sm);
    height: var(--icon-size-sm);
}
```

### 4.5 progress-bar (прогресс бары)

```css
.progress-bar {
    width: 100%;
    height: 4px;
    background-color: var(--color-bg-input);
    border-radius: var(--radius-sm);
    overflow: hidden;
}

.progress-bar--thick {
    height: 6px;
}

.progress-bar__fill {
    height: 100%;
    background-color: var(--color-primary);
    border-radius: var(--radius-sm);
    transition: width var(--duration-normal) var(--ease-out);
}

.progress-bar__fill--success {
    background-color: var(--color-success);
}

.progress-bar__fill--warning {
    background-color: var(--color-warning);
}

.progress-bar__fill--error {
    background-color: var(--color-error);
}
```

### 4.6 button (кнопки)

```css
.button {
    padding: var(--space-sm) var(--space-lg);
    background-color: var(--color-bg-input);
    color: var(--color-text-primary);
    border-width: 1px;
    border-color: var(--color-border);
    border-radius: var(--radius-md);
    font-size: var(--font-size-base);
    cursor: pointer;
    transition: background-color var(--duration-fast), 
                transform var(--duration-fast);
}

.button:hover {
    background-color: rgba(255, 255, 255, 0.2);
    transform: translateY(-2px);
}

.button:active {
    transform: translateY(0);
}

.button--primary {
    background-color: var(--color-primary);
    color: var(--color-bg-dark);
    border-color: var(--color-primary);
    /* Свечение */
    box-shadow: 0 0 8px rgba(0, 229, 255, 0.5);
}

.button--primary:hover {
    background-color: var(--color-primary-dark);
    box-shadow: 0 0 12px rgba(0, 229, 255, 0.8);
}

.button--secondary {
    background-color: transparent;
    border-color: var(--color-border-subtle);
}

.button--small {
    padding: var(--space-xs) var(--space-md);
    font-size: var(--font-size-sm);
}

.button--large {
    padding: var(--space-md) var(--space-xl);
    font-size: var(--font-size-lg);
}

.button--icon-only {
    width: var(--button-height-md);
    height: var(--button-height-md);
    padding: 0;
}

.button:disabled, .button--disabled {
    opacity: 0.5;
    cursor: not-allowed;
    pointer-events: none;
}
```

### 4.7 service-tile (плитка сервиса)

```css
.service-tile {
    display: flex;
    flex-direction: row;
    align-items: center;
    padding: var(--space-md);
    background-color: var(--color-bg-input);
    border-radius: var(--radius-md);
    gap: var(--space-md);
    margin-bottom: var(--space-sm);
    cursor: pointer;
    transition: transform var(--duration-fast), 
                background-color var(--duration-fast);
}

.service-tile:hover {
    transform: translateY(-4px);
    background-color: rgba(255, 255, 255, 0.15);
}

.service-tile--selected {
    background-color: rgba(0, 229, 255, 0.2);
    border-left-width: 4px;
    border-left-color: var(--color-primary);
}

.service-tile--unavailable {
    opacity: 0.5;
    cursor: not-allowed;
}

.service-tile__icon {
    width: var(--icon-size-lg);
    height: var(--icon-size-lg);
    background-size: contain;
    background-repeat: no-repeat;
}

.service-tile__info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: var(--space-xs);
}

.service-tile__name {
    color: var(--color-text-primary);
    font-size: var(--font-size-xl);
    font-weight: bold;
}

.service-tile__status {
    color: var(--color-text-secondary);
    font-size: var(--font-size-base);
}

.service-tile__action {
    /* Quick action button */
}
```

### 4.8 market-item-row (строка товара рынка)

```css
.market-item-row {
    display: flex;
    flex-direction: row;
    align-items: center;
    padding: var(--space-sm) var(--space-md);
    background-color: rgba(255, 255, 255, 0.05);
    border-radius: var(--radius-sm);
    gap: var(--space-md);
    margin-bottom: var(--space-xs);
}

.market-item-row:hover {
    background-color: rgba(255, 255, 255, 0.1);
}

.market-item-row__name {
    flex: 2;
    color: var(--color-text-primary);
    font-size: var(--font-size-base);
}

.market-item-row__price {
    flex: 1;
    font-size: var(--font-size-base);
}

.market-item-row__price--buy {
    color: var(--color-error);
}

.market-item-row__price--sell {
    color: var(--color-success);
}

.market-item-row__stock {
    flex: 1;
    color: var(--color-text-secondary);
    font-size: var(--font-size-base);
}

.market-item-row__actions {
    display: flex;
    gap: var(--space-xs);
}
```

### 4.9 modal (модальные окна)

```css
.modal-overlay {
    position: absolute;
    left: 0; top: 0; right: 0; bottom: 0;
    background-color: rgba(0, 0, 0, 0.8);
    display: flex;
    align-items: center;
    justify-content: center;
    backdrop-filter: blur(5px);
}

.modal-content {
    min-width: 400px;
    max-width: 600px;
    padding: var(--space-xl);
    background-color: rgba(20, 20, 20, 0.95);
    border-radius: var(--radius-lg);
    border-width: 1px;
    border-color: var(--color-primary);
    box-shadow: 0 0 20px rgba(0, 229, 255, 0.3);
}

.modal__title {
    color: var(--color-text-primary);
    font-size: var(--font-size-2xl);
    font-weight: bold;
    margin-bottom: var(--space-lg);
}

.modal__message {
    color: var(--color-text-secondary);
    font-size: var(--font-size-lg);
    margin-bottom: var(--space-lg);
}

.modal__actions {
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    gap: var(--space-md);
    margin-top: var(--space-xl);
}
```

### 4.10 toast (всплывающие уведомления)

```css
.toast {
    position: absolute;
    top: var(--space-xl);
    right: var(--space-xl);
    min-width: 300px;
    padding: var(--space-md) var(--space-lg);
    background-color: rgba(20, 20, 20, 0.95);
    border-radius: var(--radius-md);
    border-left-width: 4px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    animation: toast-slide-in var(--duration-normal) var(--ease-out);
}

.toast--success {
    border-left-color: var(--color-success);
}

.toast--warning {
    border-left-color: var(--color-warning);
}

.toast--error {
    border-left-color: var(--color-error);
}

.toast--info {
    border-left-color: var(--color-info);
}

.toast__message {
    color: var(--color-text-primary);
    font-size: var(--font-size-base);
}
```

---

## 5. UXML структура документов

### 5.1 planet_card.uxml (главный документ)

```xml
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <Style src="planet_card.uss" />
    
    <!-- Корневой контейнер -->
    <ui:VisualElement name="planet-card-root" class="planet-card-root">
        
        <!-- Фоновый слой -->
        <ui:VisualElement name="background-layer" class="background-layer">
            <ui:VisualElement name="background-planet" class="background-layer__planet" />
            <ui:VisualElement name="background-stars" class="background-layer__stars" />
            <ui:VisualElement name="background-vignette" class="background-layer__vignette" />
        </ui:VisualElement>
        
        <!-- Верхняя панель (Header) -->
        <ui:VisualElement name="header-panel" class="header-panel">
            <!-- Navigation section -->
            <!-- Status badges section -->
            <!-- Actions section -->
        </ui:VisualElement>
        
        <!-- Основной контент -->
        <ui:VisualElement name="main-content" class="main-content flex-row">
            <!-- Visual panel (левая панель) -->
            <ui:VisualElement name="visual-panel" class="visual-panel">
                <!-- Planet preview -->
                <!-- Stats bar -->
            </ui:VisualElement>
            
            <!-- Services panel (правая панель) -->
            <ui:VisualElement name="services-panel" class="services-panel flex-column">
                <!-- Service list -->
                <!-- Service detail panel -->
            </ui:VisualElement>
        </ui:VisualElement>
        
        <!-- Quick actions bar -->
        <ui:VisualElement name="quick-actions-bar" class="quick-actions-bar">
            <!-- Quick action buttons -->
        </ui:VisualElement>
        
        <!-- Activity log -->
        <ui:VisualElement name="activity-log-bar" class="activity-log-bar">
            <!-- Transaction log -->
        </ui:VisualElement>
        
        <!-- Modal container (пустой, заполняется динамически) -->
        <ui:VisualElement name="modal-container" class="modal-container" />
        
        <!-- Toast container (пустой, заполняется динамически) -->
        <ui:VisualElement name="toast-container" class="toast-container" />
    </ui:VisualElement>
</ui:UXML>
```

### 5.2 header_section.uxml (секция header)

```xml
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <!-- Navigation section -->
    <ui:VisualElement name="header-nav" class="header-section header-section--left">
        <ui:Button name="btn-back" class="button button--icon-only" />
        <ui:Label name="label-planet-name" text="Earth" class="text-3xl text-bold" />
        <ui:VisualElement name="icon-view-key" class="icon icon-planet" />
    </ui:VisualElement>
    
    <!-- Status badges section -->
    <ui:VisualElement name="header-status" class="header-section header-section--center gap-md">
        <!-- Habitability badge -->
        <ui:VisualElement name="badge-habitability" class="badge">
            <ui:Label text="Habitability" class="badge__label" />
            <ui:VisualElement name="bar-habitability" class="progress-bar">
                <ui:VisualElement name="fill-habitability" class="progress-bar__fill" />
            </ui:VisualElement>
            <ui:Label name="value-habitability" text="78%" class="badge__value" />
        </ui:VisualElement>
        
        <!-- Specialization badge -->
        <ui:VisualElement name="badge-specialization" class="badge">
            <ui:Label name="label-specialization" text="Agricultural" class="badge__label" />
            <ui:VisualElement name="icon-specialization" class="badge__icon" />
        </ui:VisualElement>
        
        <!-- Faction badge -->
        <ui:VisualElement name="badge-faction" class="badge badge--clickable">
            <ui:Label name="label-faction" text="Solar Federation" class="badge__label" />
            <ui:VisualElement name="icon-faction" class="badge__icon" />
            <ui:VisualElement name="bar-reputation" class="progress-bar">
                <ui:VisualElement name="fill-reputation" class="progress-bar__fill" />
            </ui:VisualElement>
        </ui:VisualElement>
    </ui:VisualElement>
    
    <!-- Actions section -->
    <ui:VisualElement name="header-actions" class="header-section header-section--right gap-md">
        <ui:Label name="label-credits" text="1,250 CR" class="text-lg text-bold text-accent" />
        <ui:Button name="btn-open-map" text="Map" class="button button--secondary" />
        <ui:Button name="btn-takeoff" text="Takeoff (T)" class="button button--primary button--large" />
    </ui:VisualElement>
</ui:UXML>
```

### 5.3 service_list.uxml (список сервисов)

```xml
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <ui:ScrollView name="list-services" class="service-list">
        <!-- Динамически генерируемые service-tile элементы -->
        <!-- Пример структуры одного tile: -->
        <!--
        <ui:VisualElement name="service-tile-refuel" class="service-tile">
            <ui:VisualElement name="icon-service-refuel" class="service-tile__icon" />
            <ui:VisualElement class="service-tile__info">
                <ui:Label name="label-service-name" text="Refuel Station" class="service-tile__name" />
                <ui:Label name="label-service-status" text="Available" class="service-tile__status" />
            </ui:VisualElement>
            <ui:Button name="btn-quick-refuel" text="Refuel" class="button button--small" />
        </ui:VisualElement>
        -->
    </ui:ScrollView>
</ui:UXML>
```

### 5.4 service_detail_refuel.uxml (детали заправки)

```xml
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <ui:VisualElement name="panel-refuel-detail" class="service-detail flex-column gap-lg">
        <ui:Label text="Refuel Station" class="text-2xl text-bold" />
        
        <!-- Price info -->
        <ui:VisualElement class="flex-row gap-md">
            <ui:Label text="Fuel Price:" class="text-secondary" />
            <ui:Label name="label-fuel-price" text="5.0 CR/unit" class="text-primary text-bold" />
        </ui:VisualElement>
        
        <!-- Fuel slider -->
        <ui:VisualElement class="flex-column gap-sm">
            <ui:Slider name="slider-fuel-amount" low-value="0" high-value="100" />
            <ui:Label name="label-fuel-amount" text="50 units" class="text-center" />
        </ui:VisualElement>
        
        <!-- Preset buttons -->
        <ui:VisualElement class="flex-row gap-sm">
            <ui:Button name="btn-refuel-25" text="25%" class="button button--secondary flex-1" />
            <ui:Button name="btn-refuel-50" text="50%" class="button button--secondary flex-1" />
            <ui:Button name="btn-refuel-full" text="Full" class="button button--secondary flex-1" />
        </ui:VisualElement>
        
        <!-- Total cost -->
        <ui:VisualElement class="flex-row gap-md">
            <ui:Label text="Total Cost:" class="text-secondary" />
            <ui:Label name="label-total-cost" text="250 CR" class="text-accent text-bold text-xl" />
        </ui:VisualElement>
        
        <!-- Confirm button -->
        <ui:Button name="btn-confirm-refuel" text="Confirm Refuel" class="button button--primary button--large" />
    </ui:VisualElement>
</ui:UXML>
```

### 5.5 confirmation_modal.uxml (модал подтверждения)

```xml
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <ui:VisualElement name="modal-takeoff" class="modal-overlay">
        <ui:VisualElement class="modal-content flex-column gap-lg">
            <ui:Label text="Confirm Takeoff" class="modal__title" />
            <ui:Label name="modal-message" text="Ready for takeoff?" class="modal__message" />
            
            <!-- Preflight checklist -->
            <ui:VisualElement name="preflight-checklist" class="flex-column gap-sm">
                <ui:VisualElement name="check-fuel" class="flex-row gap-sm">
                    <ui:VisualElement name="icon-check-fuel" class="icon icon-check-ok" />
                    <ui:Label text="Fuel: OK" class="text-success" />
                </ui:VisualElement>
                
                <ui:VisualElement name="check-health" class="flex-row gap-sm">
                    <ui:VisualElement name="icon-check-health" class="icon icon-check-warning" />
                    <ui:Label text="Hull: Low" class="text-warning" />
                </ui:VisualElement>
            </ui:VisualElement>
            
            <!-- Actions -->
            <ui:VisualElement class="modal__actions">
                <ui:Button name="btn-modal-cancel" text="Cancel" class="button button--secondary" />
                <ui:Button name="btn-modal-confirm" text="Confirm" class="button button--primary" />
            </ui:VisualElement>
        </ui:VisualElement>
    </ui:VisualElement>
</ui:UXML>
```

---

## 6. Responsive Design

### 6.1 Breakpoints

```css
/* Desktop (по умолчанию) */
/* min-width: 1280px */

/* Tablet */
@media (max-width: 1279px) and (min-width: 768px) {
    .main-content {
        /* 50/50 split вместо 60/40 */
    }
    
    .header-section--center {
        /* Некоторые бейджи скрыть */
    }
}

/* Mobile */
@media (max-width: 767px) {
    .main-content {
        flex-direction: column; /* Вертикальный layout */
    }
    
    .visual-panel {
        order: 1;
        min-height: 300px;
    }
    
    .services-panel {
        order: 2;
    }
    
    .quick-actions-bar {
        /* Скрыть, показать FAB */
    }
}
```

### 6.2 Mobile-specific классы

```css
.mobile-only {
    display: none;
}

@media (max-width: 767px) {
    .mobile-only {
        display: flex;
    }
    
    .desktop-only {
        display: none;
    }
}

/* FAB (Floating Action Button) для mobile */
.fab {
    position: absolute;
    bottom: var(--space-xl);
    right: var(--space-xl);
    width: 56px;
    height: 56px;
    border-radius: var(--radius-full);
    background-color: var(--color-primary);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
}

.fab--expanded {
    /* Раскрытое меню действий */
}
```

---

## 7. Animations и Transitions

### 7.1 Entrance animations

```css
/* Fade in + zoom */
@keyframes planet-card-entrance {
    from {
        opacity: 0;
        transform: scale(0.95);
    }
    to {
        opacity: 1;
        transform: scale(1);
    }
}

.planet-card-root {
    animation: planet-card-entrance var(--duration-normal) var(--ease-out);
}
```

### 7.2 Hover animations

```css
/* Lift on hover */
.service-tile {
    transition: transform var(--duration-fast), 
                box-shadow var(--duration-fast);
}

.service-tile:hover {
    transform: translateY(-4px);
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.3);
}
```

### 7.3 Loading state

```css
.is-loading {
    position: relative;
    pointer-events: none;
}

.is-loading::after {
    content: "";
    position: absolute;
    left: 50%; top: 50%;
    width: 32px; height: 32px;
    margin-left: -16px; margin-top: -16px;
    border: 3px solid var(--color-border-subtle);
    border-top-color: var(--color-primary);
    border-radius: 50%;
    animation: spinner-rotate 1s linear infinite;
}

@keyframes spinner-rotate {
    to { transform: rotate(360deg); }
}
```

### 7.4 Toast animations

```css
@keyframes toast-slide-in {
    from {
        transform: translateX(100%);
        opacity: 0;
    }
    to {
        transform: translateX(0);
        opacity: 1;
    }
}

@keyframes toast-slide-out {
    from {
        transform: translateX(0);
        opacity: 1;
    }
    to {
        transform: translateX(100%);
        opacity: 0;
    }
}

.toast {
    animation: toast-slide-in var(--duration-normal) var(--ease-out);
}

.toast--closing {
    animation: toast-slide-out var(--duration-normal) var(--ease-in);
}
```

---

## 8. Accessibility стили

### 8.1 High contrast mode

```css
@media (prefers-contrast: high) {
    .planet-card-root {
        background-color: #000000; /* Полностью чёрный */
    }
    
    .button {
        border-width: 2px; /* Толще границы */
    }
    
    .text-secondary {
        color: #FFFFFF; /* Весь текст белый */
    }
}
```

### 8.2 Reduced motion

```css
@media (prefers-reduced-motion: reduce) {
    * {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
    
    .background-layer__stars {
        /* Отключить параллакс */
    }
}
```

### 8.3 Focus states

```css
.button:focus,
.service-tile:focus,
.market-item-row:focus {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
}

/* Keyboard navigation highlight */
.keyboard-focus {
    box-shadow: 0 0 0 3px rgba(0, 229, 255, 0.5);
}
```

---

## 9. Темизация

### 9.1 Theme variants

```css
/* Dark theme (по умолчанию) */
:root {
    /* Уже определено выше */
}

/* Light theme (если потребуется) */
[data-theme="light"] {
    --color-bg-dark: #FFFFFF;
    --color-bg-medium: #F0F0F0;
    --color-bg-light: #E0E0E0;
    --color-text-primary: #000000;
    --color-text-secondary: #444444;
    /* И т.д. */
}

/* Cyberpunk theme */
[data-theme="cyberpunk"] {
    --color-primary: #FF00FF; /* Пурпурный */
    --color-success: #00FFFF; /* Cyan */
    /* И т.д. */
}
```

### 9.2 Применение темы

```xml
<!-- В корневом элементе UXML -->
<ui:VisualElement name="planet-card-root" data-theme="dark" class="planet-card-root">
    <!-- ... -->
</ui:VisualElement>
```

---

## 10. Организация файлов

```
Assets/UI/
├── planet_card/
│   ├── planet_card.uxml              # Главный документ
│   ├── planet_card.uss               # Основные стили
│   ├── components/
│   │   ├── header_section.uxml
│   │   ├── service_tile.uxml
│   │   ├── service_detail_refuel.uxml
│   │   ├── service_detail_market.uxml
│   │   ├── service_detail_shop.uxml
│   │   ├── modal_confirmation.uxml
│   │   └── toast.uxml
│   ├── styles/
│   │   ├── variables.uss             # CSS переменные
│   │   ├── utilities.uss             # Utility классы
│   │   ├── components.uss            # Component-specific стили
│   │   ├── animations.uss            # Анимации
│   │   ├── responsive.uss            # Media queries
│   │   └── accessibility.uss         # Accessibility стили
│   └── themes/
│       ├── dark.uss
│       ├── light.uss
│       └── cyberpunk.uss
└── simple.uss                         # Существующий HUD (переиспользуется)
```

---

## Резюме USS/UXML спецификации

**Ключевые принципы**:
1. **Модульность**: Компоненты в отдельных файлах, переиспользуемые классы
2. **Consistency**: Единая система именования (BEM-like), CSS переменные для всех значений
3. **Responsive**: Media queries для адаптации под разные размеры экрана
4. **Accessibility**: Focus states, high contrast, reduced motion
5. **Themeable**: CSS переменные позволяют легко менять темы
6. **Performance**: Минимизация сложных селекторов, использование CSS transitions вместо JS анимаций

**USS структура**: Variables → Utilities → Components → Responsive → Accessibility

**UXML структура**: Семантические имена элементов, чёткая иерархия, переиспользование через template

Конкретная реализация будет следовать этой спецификации, все классы и элементы уже определены.

