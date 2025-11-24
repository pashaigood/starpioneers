QuestSamples - набор примерных "moves" в JSON для быстрой проверки композиции квестов.

Структура одного файла (пример):
- id, title, description, tags, prereqs, consumes, produces, roles, complexity, branchingPoints, beats, narrativeMoves

Файлы в папке:
- hook_smuggling.json
- investigation_market.json
- fetch_delivery.json
- moral_choice_help.json
- twist_agent_reveal.json
- confrontation_pursuit.json
- climax_standoff.json
- aftermath_reputation_shift.json

Использование:
- Композитор может грузить все JSON-файлы из этой папки и использовать их как начальный пул.
- Формат полей соответствует `Assets/Design/quest_system.md` (см. раздел "Формат одного хода").

