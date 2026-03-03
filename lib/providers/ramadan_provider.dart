// lib/providers/ramadan_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/ramadan_question.dart';
import '../widgets/api_client.dart';
import 'package:dio/dio.dart';

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
  static const String _finishedKey = 'ramadan_quiz_finished_date';

  List<RamadanQuestion> _questions = [];
  RamadanStatus _status = RamadanStatus.initial;
  String? _errorMessage;
  int _currentIndex = 0;
  bool _isSubmitting = false;

  RamadanProvider(this._apiClient);

  List<RamadanQuestion> get questions => _questions;
  RamadanStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int get currentIndex => _currentIndex;
  bool get isSubmitting => _isSubmitting;

  double get progress =>
      _questions.isEmpty ? 0 : (_currentIndex) / _questions.length;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastFinishedDate = prefs.getString(_finishedKey);

    if (lastFinishedDate == today) {
      _status = RamadanStatus.alreadyAnswered;
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
      final data = await _apiClient.getActiveRamadanQuestions();
      _questions = data.map((json) => RamadanQuestion.fromJson(json)).toList();

      if (_questions.isEmpty) {
        _status = RamadanStatus.empty;
      } else {
        bool allAnswered = _questions.every((q) => q.hasAnswered);

        if (allAnswered) {
          _status = RamadanStatus.alreadyAnswered;
          _currentIndex = _questions.length;
          _saveFinishedLocally();
        } else {
          _status = RamadanStatus.ready;
          _currentIndex = _questions.indexWhere((q) => !q.hasAnswered);
          if (_currentIndex == -1) _currentIndex = 0;
        }
      }
    } on DioException catch (e) {
      // --- CORE FIX FOR GUEST MODE ---
      if (e.response?.statusCode == 401) {
        _status = RamadanStatus.unauthenticated;
      } else if (e.response?.statusCode == 403) {
        _status = RamadanStatus.alreadyAnswered;
        _saveFinishedLocally();
      } else {
        _status = RamadanStatus.error;
        _errorMessage = "Could not connect to server.";
      }
    } catch (e) {
      _status = RamadanStatus.error;
      _errorMessage = "An unexpected error occurred.";
    } finally {
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
        _saveFinishedLocally();
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isSubmitting = false;
      if (e.response?.statusCode == 403) {
        _status = RamadanStatus.alreadyAnswered;
        _currentIndex = _questions.length;
        _saveFinishedLocally();
        notifyListeners();
        return true;
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveFinishedLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(_finishedKey, today);
  }
}
