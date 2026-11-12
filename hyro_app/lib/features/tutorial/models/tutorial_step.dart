import 'package:flutter/material.dart';

enum TutorialStepType {
  welcome,
  pomodoro,
  categoriesAndTasks,
  strictMode,
  agenda,
  friendsAndDuels,
  dailyMissions,
}

class TutorialStep {
  final TutorialStepType type;
  final int stepNumber;
  final String tag;
  final String title;
  final String highlightPhrase;
  final String description;
  final String mascotSvg;
  final Color accentColor;
  final IconData badgeIcon;
  final List<String> bulletPoints;

  const TutorialStep({
    required this.type,
    required this.stepNumber,
    required this.tag,
    required this.title,
    required this.highlightPhrase,
    required this.description,
    required this.mascotSvg,
    required this.accentColor,
    required this.badgeIcon,
    required this.bulletPoints,
  });
}

