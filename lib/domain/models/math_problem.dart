import 'package:flutter/foundation.dart';

/// The kind of reasoning a problem asks for.
enum MathOperator {
  /// "How many?" for 1–3 items, recognised at a glance.
  subitize,

  /// "How many?" for up to 5 items, counted one by one.
  count,

  /// Items in the basket plus items Bingo is holding.
  add,

  /// Items in the basket minus items that bounce away.
  subtract,
}

/// The toy drawn on screen for a problem.
enum CountObjectType { bone, ball }

@immutable
class MathProblem {
  const MathProblem({
    required this.operands,
    required this.operator,
    required this.correctAnswer,
    required this.objectType,
  });

  /// Single operand for subitize/count; two operands for add/subtract.
  final List<int> operands;
  final MathOperator operator;
  final int correctAnswer;
  final CountObjectType objectType;

  int get firstOperand => operands.first;
  int get secondOperand => operands.length > 1 ? operands[1] : 0;

  bool get isQuantityRecognition =>
      operator == MathOperator.subitize || operator == MathOperator.count;

  bool isCorrect(int answer) => answer == correctAnswer;

  @override
  bool operator ==(Object other) =>
      other is MathProblem &&
      listEquals(other.operands, operands) &&
      other.operator == operator &&
      other.correctAnswer == correctAnswer &&
      other.objectType == objectType;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(operands),
    operator,
    correctAnswer,
    objectType,
  );

  @override
  String toString() =>
      'MathProblem($operator $operands = $correctAnswer, $objectType)';
}
