import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/issue_data.dart';
import '../build_env.dart';

class IssueGeneratorService {
  static const String _issuesDir = '.github/ISSUES';
  
  /// Create a bug report (GitHub API or Local File Fallback)
  Future<String> createBugReport(BugData data) async {
    // Try GitHub API first
    if (BuildEnv.githubToken.isNotEmpty) {
      try {
        return await _createGitHubIssue(
          title: "BUG: ${data.title}",
          body: _formatBugBody(data),
          labels: ['bug', 'qa-bot'],
        );
      } catch (e) {
        print("GitHub API failed: $e. Falling back to local file.");
      }
    }
    
    // Fallback: Local File
    return await _createLocalFile(
      type: 'bug',
      title: data.title,
      content: _formatBugFileContent(data),
    );
  }
  
  /// Create a feature request (GitHub API or Local File Fallback)
  Future<String> createFeatureRequest(FeatureData data) async {
    // Try GitHub API first
    if (BuildEnv.githubToken.isNotEmpty) {
      try {
        return await _createGitHubIssue(
          title: "FEAT: ${data.title}",
          body: _formatFeatureBody(data),
          labels: ['enhancement', 'qa-bot'],
        );
      } catch (e) {
        print("GitHub API failed: $e. Falling back to local file.");
      }
    }
    
    // Fallback: Local File
    return await _createLocalFile(
      type: 'feature',
      title: data.title,
      content: _formatFeatureFileContent(data),
    );
  }

  // --- GitHub API Logic ---

  Future<String> _createGitHubIssue({
    required String title,
    required String body,
    required List<String> labels,
  }) async {
    final uri = Uri.parse('https://api.github.com/repos/${BuildEnv.githubRepo}/issues');
    
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${BuildEnv.githubToken}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'body': body,
        'labels': labels,
      }),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['html_url'] as String; // Return URL to the issue
    } else {
      throw Exception('Failed to create issue: ${response.statusCode} ${response.body}');
    }
  }

  String _formatBugBody(BugData data) {
    return '''
**Priority:** ${data.priority}
**Source:** QA Assistant Bot

## Description
${data.description}

## Steps to Reproduce
${data.stepsToReproduce.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

## Expected Behavior
${data.expectedBehavior}

## Actual Behavior
${data.actualBehavior}
''';
  }

  String _formatFeatureBody(FeatureData data) {
    return '''
**Priority:** ${data.priority}
**Source:** QA Assistant Bot

## Description
${data.description}

## User Story
${data.userStory}

## Acceptance Criteria
${data.acceptanceCriteria.map((c) => '- [ ] $c').join('\n')}
''';
  }

  // --- Local File Fallback Logic (Legacy) ---

  Future<String> _createLocalFile({required String type, required String title, required String content}) async {
      final projectRoot = await _getProjectRoot();
      final issueNum = await _getNextIssueNumber(type);
      
      final sanitized = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${type}_${issueNum.toString().padLeft(3, '0')}_${timestamp}_$sanitized.md';
      final filepath = '$projectRoot/$_issuesDir/$filename';
      
      final file = File(filepath);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      
      return "Local File: $filepath";
  }

  String _formatBugFileContent(BugData data) => "# Bug: ${data.title}\n\n${_formatBugBody(data)}";
  String _formatFeatureFileContent(FeatureData data) => "# Feature: ${data.title}\n\n${_formatFeatureBody(data)}";

  Future<String> _getProjectRoot() async {
    final currentDir = Directory.current.path;
    if (await File('$currentDir/pubspec.yaml').exists()) return currentDir;
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/fortune141_issues';
  }
  
  Future<int> _getNextIssueNumber(String type) async {
    try {
      final projectRoot = await _getProjectRoot();
      final dir = Directory('$projectRoot/$_issuesDir');
      if (!await dir.exists()) return 1;
      final files = await dir.list().where((f) => f.path.contains('${type}_')).toList();
      if (files.isEmpty) return 1;
      return files.length + 1;
    } catch (e) {
      return 1;
    }
  }
}
