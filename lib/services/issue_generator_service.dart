import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/issue_data.dart';

class IssueGeneratorService {
  static const String _issuesDir = '.github/ISSUES';
  
  /// Get the project root directory (assumes app is in project during development)
  Future<String> _getProjectRoot() async {
    // During development, we're running from the project directory
    // In production, we'd need a different approach
    final currentDir = Directory.current.path;
    
    // Check if we're in the project (has pubspec.yaml)
    if (await File('$currentDir/pubspec.yaml').exists()) {
      return currentDir;
    }
    
    // Fallback: use app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/fortune141_issues';
  }
  
  /// Get the next available issue number for a given type
  Future<int> _getNextIssueNumber(String type) async {
    try {
      final projectRoot = await _getProjectRoot();
      final issuesPath = '$projectRoot/$_issuesDir';
      final dir = Directory(issuesPath);
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        return 1;
      }
      
      final files = await dir.list().where((f) => f.path.contains('$type_')).toList();
      
      if (files.isEmpty) return 1;
      
      // Extract numbers from filenames
      final numbers = files.map((f) {
        final match = RegExp(r'${type}_(\d+)_').firstMatch(f.path);
        return match != null ? int.tryParse(match.group(1)!) : null;
      }).where((n) => n != null).cast<int>().toList();
      
      return numbers.isEmpty ? 1 : numbers.reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      return 1;
    }
  }
  
  /// Format bug report content
  String _formatBugReport(int issueNum, BugData data) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm').format(now);
    
    return '''# Bug Report #$issueNum: ${data.title}

**Priority:** ${data.priority}  
**Status:** Planned  
**Created:** $timestamp  
**Source:** QA Assistant Bot

## Description
${data.description}

## Steps to Reproduce
${data.stepsToReproduce.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

## Expected Behavior
${data.expectedBehavior}

## Actual Behavior
${data.actualBehavior}

## Labels
`bug`, `qa-bot-generated`
''';
  }
  
  /// Format feature request content
  String _formatFeatureRequest(int issueNum, FeatureData data) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm').format(now);
    
    return '''# Feature Request #$issueNum: ${data.title}

**Priority:** ${data.priority}  
**Status:** Planned  
**Created:** $timestamp  
**Source:** QA Assistant Bot

## Description
${data.description}

## User Story
${data.userStory}

## Acceptance Criteria
${data.acceptanceCriteria.map((c) => '- [ ] $c').join('\n')}

## Labels
`enhancement`, `qa-bot-generated`
''';
  }
  
 /// Create a bug report file
  Future<String> createBugReport(BugData data) async {
    try {
      final projectRoot = await _getProjectRoot();
      final issueNum = await _getNextIssueNumber('bug');
      
      // Sanitize title for filename
      final sanitized = data.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'bug_${issueNum.toString().padLeft(3, '0')}_${timestamp}_$sanitized.md';
      final filepath = '$projectRoot/$_issuesDir/$filename';
      
      final file = File(filepath);
      await file.parent.create(recursive: true);
      await file.writeAsString(_formatBugReport(issueNum, data));
      
      return filepath;
    } catch (e) {
      throw Exception('Failed to create bug report: $e');
    }
  }
  
  /// Create a feature request file
  Future<String> createFeatureRequest(FeatureData data) async {
    try {
      final projectRoot = await _getProjectRoot();
      final issueNum = await _getNextIssueNumber('feature');
      
      // Sanitize title for filename
      final sanitized = data.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'feature_${issueNum.toString().padLeft(3, '0')}_${timestamp}_$sanitized.md';
      final filepath = '$projectRoot/$_issuesDir/$filename';
      
      final file = File(filepath);
      await file.parent.create(recursive: true);
      await file.writeAsString(_formatFeatureRequest(issueNum, data));
      
      return filepath;
    } catch (e) {
      throw Exception('Failed to create feature request: $e');
    }
  }
}
