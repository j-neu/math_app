#!/usr/bin/env python3
"""Add default cases to switch statements"""
import re

exercises = [
    'math_app/lib/exercises/decompose_10_exercise.dart',
    'math_app/lib/exercises/count_objects_exercise.dart',
    'math_app/lib/exercises/count_forward_exercise.dart',
    'math_app/lib/exercises/order_cards_exercise.dart',
    'math_app/lib/exercises/what_comes_next_exercise.dart',
    'math_app/lib/exercises/place_numbers_exercise.dart',
]

for path in exercises:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern: Find switch on ScaffoldLevel that doesn't already have default or finale
    # Look for pattern: switch (...) { ... case ... } without default or finale
    pattern = r'(switch\s*\([^)]*(?:currentLevel|_currentLevel)\)\s*\{(?:(?!default:|case\s+ScaffoldLevel\.finale:).)*?)(    \})'

    def add_default(match):
        switch_content = match.group(1)
        closing_brace = match.group(2)

        # Check if already has default or finale
        if 'default:' in switch_content or 'ScaffoldLevel.finale' in switch_content:
            return match.group(0)

        default_case = "\n      default:\n        // Finale level not yet implemented\n        return const Center(child: Text('Finale level coming soon!'));\n"

        return switch_content + default_case + closing_brace

    modified = re.sub(pattern, add_default, content, flags=re.DOTALL)

    if modified != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(modified)
        print(f"Updated {path}")
    else:
        print(f"No changes for {path}")

print("Done!")
