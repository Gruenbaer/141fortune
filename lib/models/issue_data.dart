class IssueData {
  final String title;
  final String description;
  final String priority;
  
  IssueData({
    required this.title,
    required this.description,
    this.priority = 'medium',
  });
}

class BugData extends IssueData {
  final List<String> stepsToReproduce;
  final String expectedBehavior;
  final String actualBehavior;
  
  BugData({
    required super.title,
    required super.description,
    required this.stepsToReproduce,
    required this.expectedBehavior,
    required this.actualBehavior,
    super.priority,
  });
  
  factory BugData.fromJson(Map<String, dynamic> json) {
    return BugData(
      title: json['title'] ?? 'Untitled Bug',
      description: json['description'] ?? '',
      stepsToReproduce: (json['steps'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      expectedBehavior: json['expected'] ?? '',
      actualBehavior: json['actual'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }
}

class FeatureData extends IssueData {
  final String userStory;
  final List<String> acceptanceCriteria;
  
  FeatureData({
    required super.title,
    required super.description,
    required this.userStory,
    required this.acceptanceCriteria,
    super.priority,
  });
  
  factory FeatureData.fromJson(Map<String, dynamic> json) {
    return FeatureData(
      title: json['title'] ?? 'Untitled Feature',
      description: json['description'] ?? '',
      userStory: json['user_story'] ?? '',
      acceptanceCriteria: (json['acceptance_criteria'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      priority: json['priority'] ?? 'medium',
    );
  }
}
