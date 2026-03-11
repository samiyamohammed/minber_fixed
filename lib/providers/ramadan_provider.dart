import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ramadan_question.dart';
import '../widgets/api_client.dart';
import 'package:dio/dio.dart';
import 'dart:async';

enum RamadanStatus {
  initial,
  loading,
  ready,
  alreadyAnswered,
  unauthenticated,
  empty,
  error
}

class RamadanProvider with ChangeNotifier {
  final ApiClient _apiClient;

  List<RamadanQuestion> _questions = [];
  List<RamadanQuestion> _history = [];
  List<LeaderboardEntry> _leaderboard = [];

  // errors specific to secondary tabs
  String? _historyError;
  String? _leaderboardError;

  RamadanStatus _status = RamadanStatus.initial;
  String? _errorMessage;
  int _currentIndex = 0;
  bool _isSubmitting = false;

  bool _isLoadingHistory = false;
  bool _isLoadingLeaderboard = false;

  RamadanProvider(this._apiClient);

  // Getters
  List<RamadanQuestion> get questions => _questions;
  List<RamadanQuestion> get history => _history;
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  RamadanStatus get status => _status;
  String? get errorMessage => _errorMessage;
  // additional getters for tab-specific error messages
  String? get historyError => _historyError;
  String? get leaderboardError => _leaderboardError;

  int get currentIndex => _currentIndex;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;

  double get progress =>
      _questions.isEmpty ? 0 : (_currentIndex) / _questions.length;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      _status = RamadanStatus.unauthenticated;
      notifyListeners();
      return;
    }

    await fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    _status = RamadanStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final envelope = await _apiClient.getActiveRamadanQuestions();

      // unwrap list; envelope may contain message, count, etc.
      final List<dynamic> payload = (envelope['data'] as List<dynamic>?) ?? [];
      final String? backendMsg = envelope['message']?.toString();

      if (payload.isEmpty) {
        _status = RamadanStatus.empty;
        _errorMessage = backendMsg ??
            "No quiz questions are available for today. Please check back later!";
        return;
      }

      // Parse the list of questions
      try {
        _questions =
            payload.map((json) => RamadanQuestion.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Failed to parse questions: $e');
        _status = RamadanStatus.empty;
        _errorMessage = "Quiz data is malformed. Please try again later.";
        return;
      }

      // if unwrapping produced an empty list (unlikely)
      if (_questions.isEmpty) {
        _status = RamadanStatus.empty;
        _errorMessage = backendMsg ?? "No questions found for today.";
        return;
      }

      // Determine progress
      bool allAnswered = _questions.every((q) => q.hasAnswered);
      if (allAnswered) {
        _status = RamadanStatus.alreadyAnswered;
        _currentIndex = _questions.length;
      } else {
        _status = RamadanStatus.ready;
        _currentIndex = _questions.indexWhere((q) => !q.hasAnswered);
        if (_currentIndex == -1) _currentIndex = 0;
      }
    } on DioException catch (e) {
      String? backendMessage;
      if (e.response?.data is Map) {
        backendMessage = e.response?.data['message']?.toString();
      }

      switch (e.response?.statusCode) {
        case 401:
          _status = RamadanStatus.unauthenticated;
          break;
        case 403:
          _status = RamadanStatus.alreadyAnswered;
          break;
        case 404:
          _status = RamadanStatus.empty;
          _errorMessage =
              backendMessage ?? "Today's quiz is not available yet.";
          break;
        default:
          _status = RamadanStatus.error;
          _errorMessage = backendMessage ??
              "Network error or server is taking too long. Please try again.";
      }
    } on TimeoutException catch (_) {
      debugPrint("Provider Fetch Error: request timed out");
      _status = RamadanStatus.error;
      _errorMessage = "Request timed out. Check your connection and retry.";
    } catch (e) {
      debugPrint("Provider Fetch Error: $e");
      _status = RamadanStatus.error;
      _errorMessage = "Something went wrong. Please check your connection.";
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _historyError = null;
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final response = await _apiClient
          .getRamadanUserHistory()
          .timeout(const Duration(seconds: 10));

      // ApiClient returns a List<dynamic> already (it unwraps the envelope),
      // so just cast and process it directly.
      final List<dynamic> list = response as List<dynamic>;
      _history = list.map((json) => RamadanQuestion.fromJson(json)).toList();
    } on TimeoutException catch (_) {
      _historyError = "Request timed out. Please try again.";
      debugPrint("History Fetch Error: request timed out");
    } catch (e) {
      _historyError = e.toString();
      debugPrint("History Fetch Error: $e");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaderboard() async {
    _leaderboardError = null;
    _isLoadingLeaderboard = true;
    notifyListeners();
    try {
      final response = await _apiClient
          .getRamadanLeaderboardTop10()
          .timeout(const Duration(seconds: 10));

      // if the endpoint uses the envelope pattern the map may contain
      // `data` key; otherwise we expect top-level keys like `top10`.
      Map<String, dynamic> map;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        map = response['data'] as Map<String, dynamic>? ?? {};
      } else if (response is Map<String, dynamic>) {
        map = response;
      } else {
        map = {};
      }

      final List<dynamic> top10List = map['top10'] as List? ?? [];
      _leaderboard =
          top10List.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } on TimeoutException catch (_) {
      _leaderboardError = "Request timed out. Please try again.";
      debugPrint("Leaderboard Fetch Error: request timed out");
    } catch (e) {
      _leaderboardError = e.toString();
      debugPrint("Leaderboard Fetch Error: $e");
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<bool> submitAnswer(String optionId) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final questionId = _questions[_currentIndex].id;
      await _apiClient.submitRamadanAnswer(questionId, optionId);

      _currentIndex++;
      if (_currentIndex >= _questions.length) {
        _status = RamadanStatus.alreadyAnswered;
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _status = RamadanStatus.unauthenticated;
      }
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
