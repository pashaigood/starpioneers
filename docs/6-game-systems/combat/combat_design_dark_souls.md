# Combat Variation - "Dark Souls" Timing Layer (for Rhythm Targeting)

Цель
- Внести в уже описанную систему ритма и телеграфов механики "Dark Souls" - жёсткий тайминг, парирование/контратака, минимизация урона через точные действия.
- Сохранить управление на уровне таргетов/режимов (без прямого пилотажа) и добавить высокий порог мастерства через тайминг.

Ключевая идея
- Добавляем несколько ограниченных по частоте, но высокоэффективных действий, чувствительных к таймингу:
  - Parry (perfect block + stagger → riposte)
  - Guard (timed damage reduction)
  - Evade/Counter micro-interaction (timed mitigation + short buff)
- Действия открываются и оцениваются внутри execution windows / telegraphs - игрок должен нажать в узком окне для максимума эффекта.

Принципы дизайна
- Без дополнительных ресурсов (нет CP). Ограничение частоты - cooldowns и action-meter (восстанавливается за время/при успехи).
- Высокий риск/высокая награда: perfect parry даёт длинный punish (stagger), но промах = уязвимость (частичный откат action-meter).
- Поддержка нескольких противников: parry применим по-целям (target-specific); group guard - уменьшенный эффект по группе.

Механики

1) Action Meter (AM)
- Лёгкая "энергия действий", float 0..100, авто-реген 10/с (настраиваемо).
- Parry требует AM >= P_cost (например 30). Успех не расходует сильно, неудача отнимает небольшой штраф.
- Guard (timed block) - меньшая стоимость (10), сокращает входящий урон на X% если выполнено в window.
- Роль AM - предотвращать спам, но не превращать в ресурсный мини-гейм.

2) Parry / Riposte
- Telegraphed heavy attack → starts parry window (очень узкая, 0.08-0.16s), центр окна обычно синхронизован с beat.
- Нажатие "Parry" в window + AM >= cost → perfect: target Staggered(duration 0.8-1.6s), enemy cannot act; открывается PunishWindow (0.6-1.2s) для мощной контратаки (riposte).
- Riposte - специальная команда/режим (hotkey) применяемый к staggared target; даёт большой урон/подавление щитов.
- Неудачная попытка (клик вне window) - парирование не сработало и AM -= smallPenalty; incoming attack наносит полный урон.

3) Guard (timed mitigation)
- Более простая механика: при telegraph короткая возможность нажать Guard → снижает входящий урон на e.g. 50% (в зависимости от timing quality).
- Guard требует меньшего AM и имеет короткий cooldown (e.g., 1.5s).

4) Evade / Mini-counter
- Для non-telegraphed лёгких атак: короткое window для Evade (должно быть fast reaction).
- Успешный Evade даёт небольшой invuln и +short buff (speed/accuracy) для следующего execution window.

5) Punish Window & Follow-up
- После успешного Parry, CombatTacticsManager создаёт PunishWindow(targetId, duration).
- Любая power action (e.g., FocusFire charged, Overload) в PunishWindow получает значительный multiplier и шанс instant subsystem disable.

6) Multiple enemies handling
- Parry is per-target - player must choose which telegraph to parry (priority).
- Group Guard: hold special key (or double-tap) → applies a weaker Guard to top-K enemies (scaled mitigation).
- Suggestion: automatic recommendation highlights the most dangerous telegraph to parry.

UI integration (конкретно)
- TargetCard shows Parry glyph when enemy telegraphs heavy shot; small countdown arc and a distinct color for parry window.
- BeatBar / Execution Window: when Parry window active - show secondary marker (parry slot) and separate sound cue.
- PunishIndicator: over target when staggered; shows riposte hotkey (e.g., F).
- ActionMeter UI: small radial or bar near BeatBar showing current AM and required cost for Parry/Guard.
- Feedback: perfect parry = strong green flash + distinct chime; fail = red flash + harder sound.

Parameters (recommended starting values)
- AM max = 100, regen = 8-12 / s.
- ParryCost = 30, ParryWindow = 0.08-0.14 s.
- GuardCost = 10, GuardWindow = 0.12-0.20 s, GuardCooldown = 1.5 s.
- ParryStagger = 0.8-1.4 s (tune with weapon speeds).
- PunishWindowDuration = ParryStagger (same window).
- RiposteMultiplier = 2.0-3.0 (big reward).

Algorithm sketches

Parry handling (pseudo):
```csharp
// on telegraph start for target t:
CombatTacticsManager.StartParryWindow(t, windowDuration);

// on player press Parry:
if (CombatTacticsManager.IsParryWindowActive(t) && ActionMeter >= ParryCost) {
    ActionMeter -= ParryCost*0.2f; // small cost on success
    t.ApplyStagger(ParryStagger);
    CombatTacticsManager.OpenPunishWindow(t, ParryStagger);
    UI.ShowRiposte(t);
} else {
    ActionMeter = Mathf.Max(0, ActionMeter - ParryCost*0.5f); // penalty
    // failure: full incoming damage applies
}
```

Punish application (pseudo):
- While PunishWindow active: any PowerAction applied to t multiplies damage by RiposteMultiplier and increases disableChance.

Design notes - why это работает для target-only control
- Parry/Guard встроены в existing telegraph + execution window model - игрок остаётся на уровне наблюдений/кликов.
- Высокая сложность достигается через узкие окна и AM management, а не через прямое управление.
- Множественные противники дают тактический выбор: кого парировать? когда использовать group guard? - сохраняется глубина.

Прототипный план (быстро)
1. Add ActionMeter and UI.
2. Implement Parry window on heavy telegraphs + Parry input handling.
3. Implement Stagger and PunishWindow + Riposte action.
4. Implement Guard (timed mitigation) and Evade basics.
5. Playtest single and multi-enemy scenarios; iterate timings.

Заключение
- Механика "Dark Souls" может быть успешно адаптирована к нашей модели: вместо прямого пилотажа игрок получает набор высоко-временных micro-actions (parry/guard/riposte) встроенных в ритм и телеграфы. Это даёт требовательный, награждающий за мастерство боевой опыт без изменения базовой идеи управления через цели/режимы.
