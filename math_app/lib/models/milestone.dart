import 'package:flutter/material.dart';

/// Represents a learning milestone - a group of related exercises.
///
/// Milestones organize the learning path into meaningful categories
/// (e.g., "Foundation Counting", "Number Sense", "Place Value").
///
/// When a child completes all exercises in a milestone, they can earn
/// a special milestone reward (if parents enable it).
class Milestone {
  /// Unique identifier (e.g., 'foundation_counting')
  final String id;

  /// Display title (e.g., 'Foundation Counting')
  final String title;

  /// Description of what this milestone covers
  final String description;

  /// Skill tags covered by this milestone
  final List<String> requiredSkillTags;

  /// Exercise IDs included in this milestone
  final List<String> exerciseIds;

  /// Display icon for this milestone
  final IconData icon;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredSkillTags,
    required this.exerciseIds,
    required this.icon,
  });

  // ============================================================================
  // PREDEFINED MILESTONES
  // ============================================================================

  /// Milestone 1: Foundation Counting (SET 1)
  static const foundationCounting = Milestone(
    id: 'foundation_counting',
    title: 'Foundation Counting',
    description: 'Counting objects, ordering numbers, and number sequences',
    requiredSkillTags: [
      'counting_1',
      'counting_2',
      'counting_3',
      'counting_4',
      'counting_5',
      'counting_10',
      'counting_11',
    ],
    exerciseIds: [
      'C1.1',  // Count the Dots V2
      'C1.2',  // Count the Objects
      'C2.1',  // Order Cards to 20
      'C3.1',  // Count Forward to 20
      'C4.1',  // What Comes Next?
      'C10.1', // Place Numbers on Line
    ],
    icon: Icons.onetwothree,
  );

  /// Milestone 2: Number Decomposition (includes Z1 + future decomposition exercises)
  static const numberDecomposition = Milestone(
    id: 'number_decomposition',
    title: 'Number Sense',
    description: 'Decomposing numbers and recognizing patterns',
    requiredSkillTags: [
      'decomposition_1',
      'decomposition_2',
      'decomposition_3',
      'decomposition_4',
      'decomposition_5',
      'decomposition_6',
      'decomposition_7',
      'decomposition_8',
      'decomposition_11',
      'decomposition_15',
      'decomposition_16',
    ],
    exerciseIds: [
      'Z1',    // Decompose 10
      'Z1.1',  // Decompose Numbers 2-9 (future)
      'Z1.2',  // Decompose on Boat (future)
      'Z1.4',  // All Ways to Make 10 (future)
      'Z1.5',  // Decompose 20 (future)
      'Z2.2',  // Complete to 10 (future)
      'Z3.1',  // Flash Recognition to 10 (future)
      'Z3.2',  // Flash Recognition to 20 (future)
    ],
    icon: Icons.psychology,
  );

  /// Milestone 3: Place Value Foundations (future)
  static const placeValue = Milestone(
    id: 'place_value',
    title: 'Place Value',
    description: 'Understanding tens and ones, bundling, place value notation',
    requiredSkillTags: [
      'place_value_1',
      'place_value_2',
      'place_value_3',
      'place_value_4',
      'place_value_5',
      'place_value_6',
    ],
    exerciseIds: [
      'P1.1',  // Bundle 10 Ones
      'P1.2',  // Make Bundles to 100
      'P2.1',  // Show Number with Blocks
      'P2.2',  // Read the Blocks
      'P3.1',  // Stellentafel Practice
      'P4.1',  // Hear and Write Numbers
      'P4.2',  // Inversion Challenge
      'P5.1',  // Tens-Ones Quiz
      'P6.1',  // 100-Chart Patterns
      'P6.2',  // Jump on 100-Chart
    ],
    icon: Icons.grid_3x3,
  );

  /// Milestone 4: Basic Addition Strategies (future)
  static const basicStrategies = Milestone(
    id: 'basic_strategies',
    title: 'Basic Strategies',
    description: 'Finger strategies, doubling, and power of 5/10',
    requiredSkillTags: [
      'basic_strategy_1',
      'basic_strategy_2',
      'basic_strategy_3',
      'basic_strategy_4',
      'basic_strategy_5',
      'basic_strategy_6',
      'basic_strategy_7',
      'basic_strategy_8',
      'basic_strategy_9',
      'basic_strategy_10',
    ],
    exerciseIds: [
      'F1.1',  // Finger Addition (future)
      'F1.2',  // Finger Subtraction (future)
      'D1.1',  // Doubles to 20 (future)
      'D2.1',  // Near Doubles (future)
      'P5.1',  // Power of 5 (future)
      'P10.1', // Power of 10 (future)
    ],
    icon: Icons.calculate,
  );

  /// Milestone 5: Combined Strategies (future)
  static const combinedStrategies = Milestone(
    id: 'combined_strategies',
    title: 'Combined Strategies',
    description: 'Using multiple strategies flexibly for efficient calculation',
    requiredSkillTags: [
      'combined_strategy_1',
      'combined_strategy_2',
      'combined_strategy_3',
      'combined_strategy_4',
      'combined_strategy_5',
      'combined_strategy_6',
      'combined_strategy_7',
      'combined_strategy_8',
      'combined_strategy_9',
      'combined_strategy_10',
    ],
    exerciseIds: [
      'CS1.1', // Choose Your Strategy (future)
      'CS2.1', // Make 10 Then Add (future)
      'CS3.1', // Partial Steps (future)
      'CS4.1', // Flexible Calculation (future)
    ],
    icon: Icons.scatter_plot,
  );

  // ============================================================================
  // MILESTONE REGISTRY
  // ============================================================================

  /// All defined milestones (in learning order)
  static const List<Milestone> allMilestones = [
    foundationCounting,
    numberDecomposition,
    placeValue,
    basicStrategies,
    combinedStrategies,
  ];

  /// Get milestone by ID
  static Milestone? getById(String id) {
    try {
      return allMilestones.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get milestone containing a specific exercise ID
  static Milestone? getByExerciseId(String exerciseId) {
    try {
      return allMilestones.firstWhere((m) => m.exerciseIds.contains(exerciseId));
    } catch (e) {
      return null;
    }
  }

  /// Get milestones that are currently implemented (have real exercises)
  static List<Milestone> getImplementedMilestones() {
    // For now, only Foundation Counting and Number Decomposition have any implemented exercises
    // As we add more exercises, we'll expand this list
    return [
      foundationCounting,
      numberDecomposition,
    ];
  }
}
