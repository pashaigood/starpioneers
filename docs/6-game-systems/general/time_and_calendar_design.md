# Дизайн системы времени и календаря - Star Pioneers (упрощённый)

Цель: минимально необходимая спецификация TimeManager - хранить и управлять глобальным множителем времени (timeScale) и предоставлять игровой календарь (SimDate) для подписки другими системами.

## Основные требования (минимум)
1. TimeManager обязан:
   - Хранить и менять глобальный множитель времени (TimeScale).
   - Поддерживать паузу (IsPaused) - при паузе симуляционное время не увеличивается.
   - Предоставлять структуру календаря (SimDate) и преобразования Tick ↔ SimDate.
   - Сохранять/восстанавливать текущее время (CurrentTick или SimDate) для сохранения/загрузки.
   - Выбрасывать событие при изменении TimeScale (OnTimeScaleChanged).

2. Календарь:
   - Базовые параметры: secondsPerMinute = 60, minutesPerHour = 60, hoursPerDay = 24, daysPerMonth = 30, monthsPerYear = 12 (все configurable).
   - Представление: `SimDate { Year, Month, Day, Hour, Minute, Second }`.
   - Internally хранить абсолютный счётчик тиков (long CurrentTick), где 1 tick = 1 игровая секунда (configurable).

3. Интерфейс (минимум):
   - `float TimeScale { get; set; }`
   - `bool IsPaused { get; set; }`
   - `long CurrentTick { get; }`
   - `SimDate CurrentDate { get; }`
   - void SetTimeScale(float value) - вызывает OnTimeScaleChanged
   - `event Action<float> OnTimeScaleChanged`
   - void SaveState(Serializer s) / void LoadState(Serializer s) - сохранять CurrentTick и TimeScale

## Интеграция (простая)
- Все системы, которые меняют или читают скорость мира, должны использовать TimeManager.Instance.TimeScale вместо прямых изменений в SimulationManager.
  - Пример: PlayerUIController.SetSpeedIndex -> TimeManager.Instance.SetTimeScale(...)
  - Пример: NPCSimpleController при вычислении сим-шага использует TimeManager.Instance.TimeScale
- GenericSimulationManager может оставить собственное поле BackgroundHz, но при расчётах dt использовать TimeManager.TimeScale как источник правды для умножения dt.

## Поведение времени
- Main update: dt_sim = Time.deltaTime * TimeManager.TimeScale (если IsPaused → dt_sim = 0)
- Background loops: использовать фиксированный шаг по вкусу проекта; но множитель TimeScale применяется одинаково.

## Сериализация
- При сохранении состояния сохранять:
  - CurrentTick (long)
  - TimeScale (float)
- При загрузке - восстановить CurrentTick → recompute CurrentDate и уведомить подписчиков при необходимости.

## Переходной план (минимум)
1. Добавить TimeManager skeleton с TimeScale, IsPaused, CurrentTick, SimDate, событиями и методами Save/Load.
2. Обновить PlayerUIController: менять TimeManager.TimeScale вместо GenericSimulationManager.GlobalTimeScale.
3. Обновить NPCSimpleController/GenericSimulationManager по чтению TimeScale (без изменения логики частот) - минимальная интеграция.

## Примечание
Это минимальная, лёгкая для внедрения спецификация. Дополнительные механики (аккумулятор, catch-up, сложный планировщик) - отдельные расширения, не обязательные сейчас.

