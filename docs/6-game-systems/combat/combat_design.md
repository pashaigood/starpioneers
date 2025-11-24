# Combat System Design — Tactical Real‑Time (2D Top‑Down)

Цель: сделать бои в реальном времени максимально тактическими и требующими постоянного участия игрока в контексте 2D top‑down space simulator (без активного прицеливания мышью).

Ключевые ограничения
- Игра — 2D топ‑даун; ориентация корабля важна (угол вокруг Z/Y).
- Нет активного прицеливания мышью; ввод — клавиатура/геймпад (thrust, rotate, fire, abilities, target cycle).
- Механики должны быть управляемы через клавиши/хоткеи и выводиться через HUD.

Основные принципы под 2D
- Facing и позиционирование остаются ключевыми: угол корабля относительно цели определяет эффективность.
- Управление — плавные манёвры: throttle / rotation / strafe (если поддерживается).
- Вовлечение достигается через тайминг (charge/dodge), распределение ресурсов (energy wheel) и выбор приоритетов (subsystems).

Адаптированные механики

1) Facing + Aim Cone (2D)
- Эффективность оружия рассчитывается по углу θ между forward (ориентацией корабля) и вектором на цель.
- Визуализация: конус/полоска перед кораблём на HUD вокруг корабля в 2D (не требует мыши).
- Игрок маневрирует (rotate + thrust) чтобы удерживать цель в конусе — активное участие через стандартный ввод.

2) Input model (keyboard / gamepad)
- Rotation: A/D или left stick X
- Thrust: W/S or right trigger
- Fire: Tap / Hold key (e.g., LCtrl или right trigger) — поддерживает tap/charge model
- Dodge: Space / face + button (directional dodge using current input)
- Target cycle: Tab / shoulder button — переключать ближайшую цель в порядке приоритета
- Subsystem select: 1..4 keys (rotate through subsystems of current target)

3) Energy Allocation Wheel (keyboard-friendly)
- Быстрая перераспределение энергии через клавиши (Q/E) или D‑pad: shift + direction → +10% weapons, -10% engines и т.д.
- Показывать текущее распределение в HUD (колёсико/бар) — мгновенная обратная связь для решений.

4) Weapon Modes with Skillful Timing (no mouse aiming)
- Tap: быстрый выстрел по направлению корабля.
- Hold/Charge: удерживайте кнопку; при отпуске выстрел в направлении forward с зарядным мультипликатором (sweet spot).
- Alt: переключение режима огня (single/burst) через хоткей.
- Все прицелы и попадания рассчитываются относительно forward и конуса, плюс lead assist (автоматический) для движения цели.

5) Heat / Overheat
- Heat per weapon, passive cooldown.
- Перегрев блокирует оружие — игрок меняет темп стрельбы и использует energy realloc.

6) Active Defense: Dodge / Boost
- Dodge выполняется через кнопку + текущее направление движения (или last input direction).
- Имеет короткую временную шкалу invuln и cooldown; тайминг важен для уменьшения урона.
- Boost (energy → engines) использует EnergyPool; в 2D даёт резкий рывок для фланга/вывода из линии огня.

7) Subsystem Targeting (keyboard-oriented)
- Cycle target (Tab). Открыть subsystem panel (Tab long) или нажать 1..4 для быстрых переключений на Shields/Weapons/Engines/Sensors.
- Focused fire на подсистему применяет полноценные урон/дисаблы; подсистемы имеют отдельный HP.

8) Manual Turret Replacement (controller-friendly)
- Нет мыши‑турелей. Вместо этого:
  - Sector targeting: переключение сектора (front/left/right/back) привязывается к кнопке; оружие в секторе получает точность бонус.
  - Hold turret key → временный фокус на секторе (игрок жертвует манёвром ради высокой точности).

9) Predictive Aim / Lead Assist (automatic)
- Автоматический lead assist вычисляет предсказание движения цели по линейному приближению; сила assist зависит от pilot skill / module.
- Для высокомобильных целей игрок всё равно должен вести корабль (rotate + thrust) чтобы уменьшить ошибку.

10) Tactical Abilities as Micro‑interactions (keyboard)
- Repair mini‑interaction: краткая последовательность клавиш / timing prompt (например, press at green zone) — выполняется через HUD без мыши.
- Overdrive: hold button to charge, release in sweet spot — риск/награда механика.

11) AI telegraphs & counters (2D)
- AI будет показывать визуальные и временные индикаторы (flashing, charge bar) перед сильными действиями.
- Тактики: flank (AI поворачивает для бокового огня), kite (stay back and fire), focus fire.

HUD / Feedback (2D‑centric)
- Energy wheel (corner) с клавишными подсказками.
- Target cone overlay around player sprite (2D).
- Per‑weapon heat bars and charge indicator.
- Subsystem list for current target (numbers 1..4).
- Combat log lines (bottom) for telegraphed AI actions.

Balance и настройки (рекомендуется data‑driven)
- Dodge cooldown 2–4s, invuln 0.1–0.2s.
- Charge sweet spot 0.15–0.25s window.
- Energy increment step 10% при хоткее.
- Lead assist factor 0.2–0.8 (0 = none, 1 = perfect).

Прототипный план (адаптированный под 2D)
1. Facing + Aim Cone (compute hit chance by θ) + target cycling.
2. Heat + Tap/Hold charge firing (keyboard inputs).
3. EnergyPool + quick realloc keys + HUD.
4. Dodge with directional input + cooldown.
5. Subsystem targeting (1..4) and one sample subsystem.
6. Simple AI pirate skirmisher that telegraphs charged attacks.
7. Playtest и баланс.

Интеграция с кодовой базой (конкретно)
- PlayerController.AttackState: оставить логику approach + HasFaceTarget; подключить ShipWeapons.TryFireAt, передавая state of charge (tap/hold), energy modifiers и facing-derived accuracy.
- Добавить классы:
  - Assets/Scripts/Combat/Weapon.cs
  - Assets/Scripts/Combat/ShipWeapons.cs
  - Assets/Scripts/Combat/EnergyPool.cs
  - Assets/Scripts/Combat/ChargeWeapon.cs
  - Assets/Scripts/Combat/Dodge.cs
- Использовать SimulationEventBus для событий боёв.

Заключение
- Перенести вовлекающие механики в клавиатурно/геймпад‑дружественный набор: facing/cone, charge timing, energy realloc, dodge и subsystem focus — без необходимости мышиного прицеливания.
- Предлагаю реализовать быстрый прототип: Facing+Cone + Tap/Hold + Dodge + Target cycle — после тестировать и расширять.
