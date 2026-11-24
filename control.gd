extends Control

@export var time_limit := 10.0
var correct_index := 1 # AnswerB is correct

@onready var question_label = $VBoxContainer/QuestionLabel
@onready var timer_label = $VBoxContainer/TimerLabel
@onready var result_label = $VBoxContainer/ResultLabel
@onready var buttons = [
$VBoxContainer/AnswerA,
$VBoxContainer/AnswerB,
$VBoxContainer/AnswerC,
]
@onready var timer = $Timer

func _ready():
 question_label.text = "What is 2 + 2?"
 var answers = ["3", "4", "5"]
 for i in buttons.size():
  buttons[i].text = answers[i]
  buttons[i].pressed.connect(_on_answer.bind(i))
 result_label.text = ""
 timer.one_shot = true
 timer.wait_time = time_limit
 timer.timeout.connect(_on_timeout)
 timer.start()

func _process(_delta):
 timer_label.text = "Time: %d" % ceil(timer.time_left)

func _on_answer(index):
 timer.stop()
 _lock()
 if index == correct_index:
  result_label.text = "Correct!"
 else:
  result_label.text = "You're wrong!"

func _on_timeout():
 _lock()
 result_label.text = "You're wrong! Time's up."

func _lock():
 set_process(false)
 for b in buttons:
  b.disabled = true
