# Writing questions

Each level has its own file: `data/questions/level_1.json` ... `level_4.json`.
Questions are shuffled and reshuffled when a level's pool runs out. Because every level is
a separate file, two people can write questions at the same time without conflicts.

```json
{
  "questions": [
	{"type": "quiz", "question": "3x + 5 = 20, x = ?", "options": ["3", "4", "5", "6"], "answer": 2},
	{"type": "quiz", "question": "Identify the picture", "image": "res://assets/art/q1.png",
	 "options": ["A", "B", "C", "D"], "answer": 0, "time": 20},
	{"type": "match", "time": 25, "question": "Match each group to the right category.",
	 "slots": ["MATH", "LANGUAGE", "LOGIC"],
	 "shards": [{"text": "Circle area = pi r^2, 2x + 1 = 5", "slot": 0},
				{"text": "Effective sentences, synonyms", "slot": 1},
				{"text": "If P then Q; P true so Q true", "slot": 2}]}
  ]
}
```

| Field | Meaning |
|---|---|
| `type` | `quiz` (multiple choice) or `match` (memory-shard puzzle). Default `quiz`. |
| `question` | text shown on the panel (required) |
| `time` | optional seconds for this question (overrides the level default) |
| `options`, `answer` | quiz: 2+ options, `answer` is the 0-based index of the right one |
| `image` | quiz, optional `res://` path to a picture |
| `slots`, `shards` | match: same number of each; every shard's `slot` is unique, 0-based |

## Check your file
```
python3 tools/check_questions.py
```
In Godot, a broken question is skipped and a warning appears in the Output panel with the
file name and question number.
