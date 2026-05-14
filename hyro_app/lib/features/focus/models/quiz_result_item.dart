class QuizResultItem {
  final int id;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String quizType;

  const QuizResultItem({
    required this.id,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.quizType = '',
  });

  @override
  String toString() {
    return 'QuizResultItem(id: $id, correct: $isCorrect, type: $quizType)';
  }
}
