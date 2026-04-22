class QuizResultItem {
  final int id;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;

  const QuizResultItem({
    required this.id,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  @override
  String toString() {
    return 'QuizResultItem(id: $id, correct: $isCorrect)';
  }
}
