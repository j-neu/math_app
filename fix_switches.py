#!/usr/bin/env python3
"""
Quick script to add finale case to all switch statements on ScaffoldLevel
"""
import re
import os

exercises = [
    'math_app/lib/exercises/decompose_10_exercise.dart',
    'math_app/lib/exercises/count_objects_exercise.dart',
    'math_app/lib/exercises/count_forward_exercise.dart',
    'math_app/lib/exercises/order_cards_exercise.dart',
    'math_app/lib/exercises/what_comes_next_exercise.dart',
    'math_app/lib/exercises/place_numbers_exercise.dart',
]

finale_case = """
      case ScaffoldLevel.finale:
        // Finale level not yet implemented for this exercise
        return const Center(
          child: Text('Finale level coming soon!'),
        );
"""

for exercise_path in exercises:
    if not os.path.exists(exercise_path):
        print(f"Skipping {exercise_path} (not found)")
        continue

    with open(exercise_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find switch statements and add finale case before the closing brace
    # Pattern: switch (...) { ... case ScaffoldLevel.independentMastery: ... }
    # We'll add the finale case before the closing }

    # Simple approach: find "case ScaffoldLevel.independentMastery:" followed by content then "    }"
    # and insert finale case before the }

    pattern = r'(case ScaffoldLevel\.independentMastery:.*?(?=\n    \}))'

    def add_finale(match):
        return match.group(0) + finale_case

    # Use a more general approach: find the last case before } in switch statements
    # Actually, let's just add it after each independentMastery case

    original_content = content

    # Find all occurrences of the pattern
    modified = re.sub(
        r'(case ScaffoldLevel\.independentMastery:(?:(?!case ScaffoldLevel\.).)*?return[^;]*;)',
        r'\1' + finale_case,
        content,
        flags=re.DOTALL
    )

    if modified != original_content:
        with open(exercise_path, 'w', encoding='utf-8') as f:
            f.write(modified)
        print(f"Updated {exercise_path}")
    else:
        print(f"No changes needed for {exercise_path}")

print("Done!")
