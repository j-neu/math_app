# Common Development Pitfalls & Best Practices

This document outlines common errors encountered during development of the Math App, specifically related to the Exercise framework, Mixins, and Dart language features. Read this to avoid compilation errors and structural issues.

## 1. Enum Usage: You Cannot Instantiate Enums
**The Error:**
Trying to create new instances of `ScaffoldLevel` to define custom levels.
```dart
// ❌ WRONG: Enums cannot be instantiated
final myLevel = ScaffoldLevel(6, 'My Custom Level'); 
```

**The Solution:**
`ScaffoldLevel` is a fixed Enum with 5 values. If your exercise has more levels or needs custom metadata (like specific titles/colors per level), create a private configuration class and map it to the standard Enum for compatibility.

```dart
// ✅ CORRECT: Define a config class
class _LevelConfig {
  final int levelNumber;
  final String title;
  final ScaffoldLevel mappedLevel; 
  // ... other properties
  const _LevelConfig({...});
}

// Use a list of these configs
final List<_LevelConfig> _levels = [
  _LevelConfig(..., mappedLevel: ScaffoldLevel.guidedExploration),
  // ...
];
```

## 2. ExerciseProgressMixin Requirements
**The Error:**
"The non-abstract class ... is missing implementations for these members..."

**The Solution:**
When using `ExerciseProgressMixin`, you **MUST** override all abstract getters. It is not optional.

```dart
class _MyExerciseState extends State<MyExercise> with ExerciseProgressMixin {
  // ... other overrides ...

  // ⚠️ These are often forgotten:
  @override
  int get problemTimeLimit => 30; // Seconds per problem for completion

  @override
  int get finaleMinProblems => 10; // Min problems to solve in finale
}
```

## 3. Mixin Lifecycle Methods & State Access
**The Error:**
1. `Error: Superclass has no method named 'loadProgress'.`
2. `Error: The getter 'progress' isn't defined...`
3. `Error: The method 'updateExerciseStatus' isn't defined...`

**The Solution:**
The `ExerciseProgressMixin` encapsulates state management. Do not try to override internal methods or access private/undefined properties.

*   **Initialization:** Do NOT override `loadProgress`. Call `initializeProgress()` in `initState`.
*   **Accessing Data:** Use `currentProgress` (nullable) or `isLevelUnlocked(int)`. Do NOT assume a `progress` property exists.
*   **Updating Status:** Status updates (finished/completed) are handled automatically by `saveProgress()`. Do not call `updateExerciseStatus` manually unless the mixin explicitly exposes it (it usually doesn't).
*   **Parameters:** Check method signatures carefully. `recordProblemResult` takes `correct` (not `isCorrect`).

```dart
// ✅ CORRECT Pattern:
@override
void initState() {
  super.initState();
  _init();
}

Future<void> _init() async {
  await initializeProgress(); // Call mixin method
  if (mounted) {
    // Access state via public mixin methods/getters
    if (isLevelUnlocked(2)) { ... }
  }
}
```

## 4. Widget Parameter Mismatches
**The Error:**
Passing complex objects to widgets that expect simple types, or assuming named parameters exist when they don't.

*   **SegmentedProgressBar:** Expects `totalSegments` (int) and `results` (List<bool>), NOT a list of Level objects.
*   **InstructionModal:** Check the constructor. It often changes. Ensure you pass `levelTitle` and `instructionText`.

## 5. Handling Exercises with > 5 Levels
**The Context:**
The `ScaffoldLevel` enum only supports 5 standard levels (Guided -> Supported -> Independent -> Challenge -> Finale).

**The Strategy:**
If an exercise (like `count_steps_100field`) implies 6+ levels:
1.  Do **not** try to add to the Enum.
2.  Use the **Standard Enum** for *logic* (unlocking, database storage).
    *   Example: Map your Level 1 & 2 -> `ScaffoldLevel.guidedExploration` logic (or spread them out).
3.  Use **Local State** (`int _currentLevelNumber`) to track the specific sub-level within the UI.
4.  Unlock the next "Enum Level" only when the corresponding block of local levels is done.

## 6. Static Analysis is Your Friend
Before running, always check:
1.  Are all Mixin overrides present?
2.  Are named parameters correct? (VS Code/Android Studio usually highlights these in red).
3.  Are you trying to instantiate an Enum?

## 7. Exercise Registration is Mandatory
**The Error:**
"I created the exercise file, but it doesn't show up on the home screen / learning path."

**The Solution:**
Creating the file is not enough. You must register it in **two** places:

1.  **`ExerciseService`** (`lib/services/exercise_service.dart`): Add it to the `_allExercises` list so the app knows how to build it.
    ```dart
    Exercise(
      id: 'C6.3',
      title: 'Count Backwards',
      exerciseBuilder: (userProfile) => MyNewExercise(userProfile: userProfile),
    ),
    ```

2.  **`Milestone`** (`lib/models/milestone.dart`): Add the ID (e.g., 'C6.3') to the `exerciseIds` list of the relevant Milestone (e.g., `foundationCounting`).
    ```dart
    static const foundationCounting = Milestone(
      // ...
      exerciseIds: [
        // ...
        'C6.3', // <-- Don't forget this!
      ],
    );
    ```

## 8. Layout & Viewport calculations (Zooming/Centering)
**The Error:**
Using `MediaQuery.of(context).size` to calculate zoom/center positions leads to inaccuracies because it returns the *full screen size*, ignoring AppBar, Keyboard, or other parent widgets.

**The Solution:**
Use `LayoutBuilder` to get the *exact* available constraints for your widget.

```dart
// ❌ RISKY:
double viewportH = MediaQuery.of(context).size.height;

// ✅ CORRECT:
return LayoutBuilder(
  builder: (context, constraints) {
    // Store size for use in zooming logic
    _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
    return Stack(...); 
  }
);
```
