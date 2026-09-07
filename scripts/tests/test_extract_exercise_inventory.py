import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from extract_exercise_inventory import parse_exercises

SAMPLE = """\
class ExerciseService {
  final List<Exercise> _allExercises = [
    Exercise(
      id: 'C1.1',
      title: 'Count the Dots',
      skillTags: ['counting_1'],
      exerciseBuilder: (userProfile) => CountDotsExerciseV2(userProfile: userProfile),
    ),
    Exercise(
      id: 'S1.2',
      title: 'Finger Klappen',
      skillTags: ['basic_strategy_2'],
      exerciseBuilder: (userProfile) => FingerCalculationExercise(
        exerciseConfig: ExerciseConfig(
          id: 'S1.2-nested',
          title: 'Nested Should Be Ignored',
          skillTags: ['ignore_me'],
        ),
        userProfile: userProfile,
      ),
    ),
    Exercise(
      id: 'S3.6',
      title: 'Zehner verdoppeln',
      skillTags: ['strategy_doubling_tens_1', 'basic_strategy_11'],
      exerciseBuilder: (userProfile) => DoublingTensExercise(userProfile: userProfile),
    ),
  ];
}
"""


class ParseExercisesTest(unittest.TestCase):
    def test_finds_every_top_level_exercise(self):
        rows = parse_exercises(SAMPLE)
        self.assertEqual([r["exercise_id"] for r in rows], ["C1.1", "S1.2", "S3.6"])

    def test_ignores_nested_exercise_config(self):
        rows = parse_exercises(SAMPLE)
        s12 = next(r for r in rows if r["exercise_id"] == "S1.2")
        self.assertEqual(s12["title"], "Finger Klappen")
        self.assertEqual(s12["skill_tags"], ["basic_strategy_2"])

    def test_captures_widget_class_and_multiple_tags(self):
        rows = parse_exercises(SAMPLE)
        s36 = next(r for r in rows if r["exercise_id"] == "S3.6")
        self.assertEqual(s36["widget_class"], "DoublingTensExercise")
        self.assertEqual(s36["skill_tags"], ["strategy_doubling_tens_1", "basic_strategy_11"])


if __name__ == "__main__":
    unittest.main()
