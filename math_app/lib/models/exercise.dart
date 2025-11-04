import 'package:flutter/material.dart';
import 'user_profile.dart';

class Exercise {
  final String id;
  final String title;
  final List<String> skillTags;

  // Content can now be:
  // 1. A Widget (legacy placeholder style)
  // 2. A Widget builder function
  // 3. Null (content provided by dedicated exercise widget)
  final dynamic actionContent;
  final dynamic imageContent;
  final dynamic symbolContent;

  // New: Optional dedicated exercise widget that manages all 3 views
  // DEPRECATED: Use exerciseBuilder instead for Phase 2.5+ exercises
  final Widget? exerciseWidget;

  // Phase 2.5: Widget builder that receives UserProfile for progress tracking
  final Widget Function(UserProfile)? exerciseBuilder;

  Exercise({
    required this.id,
    required this.title,
    required this.skillTags,
    this.actionContent,
    this.imageContent,
    this.symbolContent,
    this.exerciseWidget, // Legacy support
    this.exerciseBuilder, // New: preferred for progress tracking
  });
}