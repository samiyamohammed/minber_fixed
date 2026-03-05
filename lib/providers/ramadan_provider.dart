// lib/providers/ramadan_provider.dart

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
      final response = await _apiClient.getActiveRamadanQuestions().timeout(
            const Duration(seconds: 10),
          );

      if (response == null || (response is List && response.isEmpty)) {
        _status = RamadanStatus.empty;
      } else {
        _questions = (response as List)
            .map((json) => RamadanQuestion.fromJson(json))
            .toList();

        if (_questions.isEmpty) {
          _status = RamadanStatus.empty;
        } else {
          bool allAnswered = _questions.every((q) => q.hasAnswered);
          if (allAnswered) {
            _status = RamadanStatus.alreadyAnswered;
            _currentIndex = _questions.length;
          } else {
            _status = RamadanStatus.ready;
            _currentIndex = _questions.indexWhere((q) => !q.hasAnswered);
            if (_currentIndex == -1) _currentIndex = 0;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _status = RamadanStatus.unauthenticated;
      } else if (e.response?.statusCode == 403) {
        _status = RamadanStatus.alreadyAnswered;
      } else {
        _status = RamadanStatus.error;
        _errorMessage = "Could not connect to the quiz server.";
      }
    } catch (e) {
      _status = RamadanStatus.error;
      _errorMessage = "Something went wrong. Please try again.";
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final response = await _apiClient.getRamadanUserHistory();
      _history = (response as List)
          .map((json) => RamadanQuestion.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("History Fetch Error: $e");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaderboard() async {
    _isLoadingLeaderboard = true;
    notifyListeners();
    try {
      final response = await _apiClient.getRamadanLeaderboardTop10();
      // Swagger shows { "top10": [...] }
      final List top10List = response['top10'] as List? ?? [];
      _leaderboard =
          top10List.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } catch (e) {
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
