import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing.dart';
import '../services/database_service.dart';

enum DrawingTool {
  pen,
  highlighter,
  eraser,
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DrawingTool? tool,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tool: tool ?? this.tool,
    );
  }
}

class DrawingProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Drawing> _drawings = [];
  List<Drawing> get drawings => _drawings;

  List<DrawingStroke> _currentStrokes = [];
  List<DrawingStroke> get currentStrokes => _currentStrokes;

  final List<List<DrawingStroke>> _undoHistory = [];

  DrawingTool _currentTool = DrawingTool.pen;
  DrawingTool get currentTool => _currentTool;

  Color _currentColor = Colors.white;
  Color get currentColor => _currentColor;

  double _strokeWidth = 3.0;
  double get strokeWidth => _strokeWidth;

  String _backgroundType = 'blank';
  String get backgroundType => _backgroundType;

  bool _isDrawing = false;
  bool get isDrawing => _isDrawing;

  DrawingStroke? _activeStroke;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static const List<Color> availableColors = [
    Colors.white,
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF6B7280),
  ];

  Future<void> loadDrawings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _drawings = await _db.getDrawings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setBackgroundType(String type) {
    _backgroundType = type;
    notifyListeners();
  }

  void startStroke(Offset point) {
    _isDrawing = true;
    _activeStroke = DrawingStroke(
      points: [point],
      color: _currentTool == DrawingTool.eraser ? Colors.black : _currentColor,
      strokeWidth: _currentTool == DrawingTool.highlighter
          ? _strokeWidth * 3
          : _strokeWidth,
      tool: _currentTool,
    );
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_activeStroke == null) return;

    _activeStroke = _activeStroke!.copyWith(
      points: [..._activeStroke!.points, point],
    );
    notifyListeners();
  }

  void endStroke() {
    if (_activeStroke != null && _activeStroke!.points.length > 1) {

      _undoHistory.add(List.from(_currentStrokes));
      _currentStrokes.add(_activeStroke!);
    }
    _activeStroke = null;
    _isDrawing = false;
    notifyListeners();
  }

  List<DrawingStroke> getAllStrokes() {
    if (_activeStroke != null) {
      return [..._currentStrokes, _activeStroke!];
    }
    return _currentStrokes;
  }

  void undo() {
    if (_undoHistory.isNotEmpty) {
      _currentStrokes = _undoHistory.removeLast();
      notifyListeners();
    }
  }

  bool get canUndo => _undoHistory.isNotEmpty;

  void clear() {
    if (_currentStrokes.isNotEmpty) {
      _undoHistory.add(List.from(_currentStrokes));
    }
    _currentStrokes = [];
    notifyListeners();
  }

  void newDrawing() {
    _currentStrokes = [];
    _undoHistory.clear();
    _backgroundType = 'blank';
    notifyListeners();
  }

  Future<Drawing?> saveDrawing(String name, Uint8List imageData) async {
    final now = DateTime.now();
    final drawing = Drawing(
      id: _uuid.v4(),
      name: name,
      imageData: imageData,
      backgroundType: _backgroundType,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertDrawing(drawing);
    _drawings.insert(0, drawing);
    notifyListeners();

    return drawing;
  }

  Future<void> updateDrawing(String id, Uint8List imageData) async {
    final index = _drawings.indexWhere((d) => d.id == id);
    if (index == -1) return;

    final updated = _drawings[index].copyWith(
      imageData: imageData,
      backgroundType: _backgroundType,
      updatedAt: DateTime.now(),
    );

    await _db.updateDrawing(updated);
    _drawings[index] = updated;
    notifyListeners();
  }

  Future<void> deleteDrawing(String id) async {
    await _db.deleteDrawing(id);
    _drawings.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Future<void> loadDrawingForEdit(Drawing drawing) async {

    _currentStrokes = [];
    _undoHistory.clear();
    _backgroundType = drawing.backgroundType;

    notifyListeners();
  }
}
