import 'package:learnlock/models/question.dart';
import 'package:learnlock/models/child_profile.dart';
import 'dart:math';

// Procedurally generated maths questions aligned to NSW Mathematics K-6 Syllabus
class MathsContent {
  static final _random = Random();

  static List<Question> generate({
    required int nswYear,
    required DifficultyLevel difficulty,
    int count = 5,
  }) {
    final generators = _getGenerators(nswYear, difficulty);
    return List.generate(count, (_) {
      final gen = generators[_random.nextInt(generators.length)];
      return gen();
    });
  }

  static List<Question Function()> _getGenerators(
      int year, DifficultyLevel difficulty) {
    if (year <= 2) {
      return _earlyYearsGenerators(difficulty);
    } else if (year <= 4) {
      return _middleYearsGenerators(difficulty);
    } else {
      return _upperYearsGenerators(difficulty);
    }
  }

  // K-2: Counting, addition, subtraction to 20/100
  static List<Question Function()> _earlyYearsGenerators(
      DifficultyLevel difficulty) {
    final max = difficulty.index <= 1 ? 10 : 20;
    return [
      () => _addition(max, difficulty),
      () => _subtraction(max, difficulty),
      () => _countingSequence(difficulty),
      () => _missingNumber(max, difficulty),
      () => _comparison(max, difficulty),
    ];
  }

  // 3-4: Multiplication, division, fractions, large numbers
  static List<Question Function()> _middleYearsGenerators(
      DifficultyLevel difficulty) {
    return [
      () => _multiplication(difficulty),
      () => _division(difficulty),
      () => _addition(100, difficulty),
      () => _subtraction(100, difficulty),
      () => _fractions(difficulty),
      () => _wordProblem(difficulty),
    ];
  }

  // 5-6: Percentages, decimals, harder operations
  static List<Question Function()> _upperYearsGenerators(
      DifficultyLevel difficulty) {
    return [
      () => _multiplication(difficulty, large: true),
      () => _division(difficulty, large: true),
      () => _decimals(difficulty),
      () => _percentages(difficulty),
      () => _fractions(difficulty, hard: true),
      () => _wordProblem(difficulty, hard: true),
    ];
  }

  static Question _addition(int max, DifficultyLevel difficulty) {
    final a = _random.nextInt(max) + 1;
    final b = _random.nextInt(max) + 1;
    final answer = (a + b).toString();
    final choices = _numericChoices(a + b, 4);
    return Question(
      id: 'maths_add_${a}_${b}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'What is $a + $b?',
      choices: choices,
      correctAnswer: answer,
      explanation: '$a + $b = ${a + b}. Count $a then add $b more!',
      encouragement: 'You can count on your fingers to help!',
      nswYear: 1,
    );
  }

  static Question _subtraction(int max, DifficultyLevel difficulty) {
    final b = _random.nextInt(max) + 1;
    final a = b + _random.nextInt(max);
    final answer = (a - b).toString();
    final choices = _numericChoices(a - b, 4);
    return Question(
      id: 'maths_sub_${a}_${b}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'What is $a - $b?',
      choices: choices,
      correctAnswer: answer,
      explanation: '$a - $b = ${a - b}. Start at $a and count back $b!',
      encouragement: 'Count backwards from $a on your fingers!',
      nswYear: 1,
    );
  }

  static Question _multiplication(DifficultyLevel difficulty, {bool large = false}) {
    final max = large ? 12 : (difficulty.index <= 1 ? 5 : 10);
    final a = _random.nextInt(max) + 2;
    final b = _random.nextInt(max) + 2;
    final answer = (a * b).toString();
    final choices = _numericChoices(a * b, 4);
    return Question(
      id: 'maths_mul_${a}_${b}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'What is $a × $b?',
      choices: choices,
      correctAnswer: answer,
      explanation: '$a × $b = ${a * b}. This means $a groups of $b!',
      encouragement: 'Think of your times tables!',
      nswYear: 3,
    );
  }

  static Question _division(DifficultyLevel difficulty, {bool large = false}) {
    final max = large ? 12 : (difficulty.index <= 1 ? 5 : 9);
    final b = _random.nextInt(max) + 2;
    final answer = _random.nextInt(large ? 12 : 9) + 1;
    final a = b * answer;
    final choices = _numericChoices(answer, 4);
    return Question(
      id: 'maths_div_${a}_${b}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'What is $a ÷ $b?',
      choices: choices,
      correctAnswer: answer.toString(),
      explanation: '$a ÷ $b = $answer. How many groups of $b fit in $a?',
      encouragement: 'Think about the matching multiplication!',
      nswYear: 3,
    );
  }

  static Question _fractions(DifficultyLevel difficulty, {bool hard = false}) {
    final denominators = hard ? [3, 4, 5, 6, 8, 10] : [2, 4, 5, 10];
    final denom = denominators[_random.nextInt(denominators.length)];
    final num1 = _random.nextInt(denom - 1) + 1;
    final num2 = _random.nextInt(denom - 1) + 1;
    final sum = num1 + num2;
    if (sum > denom) {
      final answer = '$sum/$denom';
      final choices = [answer, '$num1/$denom', '$num2/$denom',
          '${sum - 1}/$denom']..shuffle(_random);
      return Question(
        id: 'maths_frac_${num1}_${num2}_${denom}',
        subject: SubjectType.maths,
        type: QuestionType.multipleChoice,
        difficulty: difficulty,
        prompt: '$num1/$denom + $num2/$denom = ?',
        choices: choices,
        correctAnswer: answer,
        explanation: 'Add the numerators: $num1 + $num2 = $sum. Denominator stays $denom!',
        encouragement: 'Add the top numbers and keep the bottom the same!',
        nswYear: 4,
      );
    }
    // Simpler: which fraction is bigger
    final answer = num1 > num2 ? '$num1/$denom' : '$num2/$denom';
    final choices = ['$num1/$denom', '$num2/$denom', '${denom ~/ 2}/$denom',
        '1/$denom']..shuffle(_random);
    return Question(
      id: 'maths_frac_big_${num1}_${num2}_${denom}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'Which fraction is bigger: $num1/$denom or $num2/$denom?',
      choices: choices,
      correctAnswer: answer,
      explanation: 'Compare the numerators: $num1 vs $num2. Bigger numerator = bigger fraction!',
      encouragement: 'When the bottom is the same, just compare the top numbers!',
      nswYear: 3,
    );
  }

  static Question _decimals(DifficultyLevel difficulty) {
    final a = (_random.nextInt(90) + 10) / 10.0;
    final b = (_random.nextInt(50) + 5) / 10.0;
    final answer = (a + b).toStringAsFixed(1);
    final choices = _decimalChoices(a + b, 4);
    return Question(
      id: 'maths_dec_${a}_${b}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'What is ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(1)}?',
      choices: choices,
      correctAnswer: answer,
      explanation: 'Line up the decimal points and add: ${a.toStringAsFixed(1)} + ${b.toStringAsFixed(1)} = $answer',
      encouragement: 'Line up the decimal points first!',
      nswYear: 5,
    );
  }

  static Question _percentages(DifficultyLevel difficulty) {
    final percents = [10, 20, 25, 50, 75];
    final pct = percents[_random.nextInt(percents.length)];
    final whole = (_random.nextInt(9) + 1) * 20;
    final answer = (whole * pct ~/ 100).toString();
    final choices = _numericChoices(whole * pct ~/ 100, 4);
    return Question(
      id: 'maths_pct_${pct}_${whole}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'What is $pct% of $whole?',
      choices: choices,
      correctAnswer: answer,
      explanation: '$pct% of $whole = ${whole * pct ~/ 100}. Divide by ${100 ~/ pct} to find $pct%!',
      encouragement: 'Percent means "out of 100". You\'ve got this!',
      nswYear: 6,
    );
  }

  static Question _countingSequence(DifficultyLevel difficulty) {
    final step = difficulty.index <= 1 ? 1 : (difficulty.index <= 3 ? 2 : 5);
    final start = _random.nextInt(20) * step;
    final sequence = List.generate(4, (i) => start + i * step);
    final next = start + 4 * step;
    final choices = _numericChoices(next, 4);
    return Question(
      id: 'maths_seq_${start}_${step}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'What comes next?\n${sequence.join(', ')}, __?',
      choices: choices,
      correctAnswer: next.toString(),
      explanation: 'The pattern adds $step each time. $start, ${sequence[1]}, ${sequence[2]}, ${sequence[3]}, $next!',
      encouragement: 'Look at the pattern — what is being added each time?',
      nswYear: 1,
    );
  }

  static Question _missingNumber(int max, DifficultyLevel difficulty) {
    final a = _random.nextInt(max) + 1;
    final b = _random.nextInt(max) + 1;
    final c = a + b;
    final choices = _numericChoices(b, 4);
    return Question(
      id: 'maths_miss_${a}_${b}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: '$a + ___ = $c',
      choices: choices,
      correctAnswer: b.toString(),
      explanation: 'If $a + ___ = $c, then the missing number is $c - $a = $b!',
      encouragement: 'Think: what do you add to $a to get $c?',
      nswYear: 1,
    );
  }

  static Question _comparison(int max, DifficultyLevel difficulty) {
    final a = _random.nextInt(max) + 1;
    int b;
    do { b = _random.nextInt(max) + 1; } while (b == a);
    final answer = a > b ? '$a is bigger' : '$b is bigger';
    final choices = ['$a is bigger', '$b is bigger', 'They are equal',
        '${a + b} is biggest']..shuffle(_random);
    return Question(
      id: 'maths_cmp_${a}_${b}',
      subject: SubjectType.maths,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'Which number is bigger: $a or $b?',
      choices: choices,
      correctAnswer: answer,
      explanation: '${a > b ? a : b} is the bigger number because it comes later when counting!',
      encouragement: 'Count up from 1 — which number do you reach first?',
      nswYear: 0,
    );
  }

  static Question _wordProblem(DifficultyLevel difficulty, {bool hard = false}) {
    final templates = hard ? _hardWordProblems : _easyWordProblems;
    return templates[_random.nextInt(templates.length)](difficulty);
  }

  static List<Question Function(DifficultyLevel)> get _easyWordProblems => [
        (d) {
          final apples = _random.nextInt(8) + 2;
          final more = _random.nextInt(5) + 1;
          final answer = apples + more;
          return Question(
            id: 'maths_word_apple_$apples',
            subject: SubjectType.maths,
            type: QuestionType.multipleChoice,
            difficulty: d,
            prompt: 'Sam has $apples apples. Mia gives Sam $more more apples. How many apples does Sam have now?',
            choices: _numericChoices(answer, 4),
            correctAnswer: answer.toString(),
            explanation: '$apples + $more = $answer apples in total!',
            encouragement: 'Draw the apples if it helps!',
            nswYear: 1,
          );
        },
        (d) {
          final cookies = _random.nextInt(12) + 5;
          final eaten = _random.nextInt(4) + 1;
          final answer = cookies - eaten;
          return Question(
            id: 'maths_word_cookie_$cookies',
            subject: SubjectType.maths,
            type: QuestionType.multipleChoice,
            difficulty: d,
            prompt: 'There are $cookies cookies on a plate. Jake eats $eaten cookies. How many are left?',
            choices: _numericChoices(answer, 4),
            correctAnswer: answer.toString(),
            explanation: '$cookies - $eaten = $answer cookies left!',
            encouragement: 'Take away means subtract!',
            nswYear: 1,
          );
        },
      ];

  static List<Question Function(DifficultyLevel)> get _hardWordProblems => [
        (d) {
          final bags = _random.nextInt(5) + 3;
          final each = _random.nextInt(8) + 4;
          final answer = bags * each;
          return Question(
            id: 'maths_word_bags_$bags',
            subject: SubjectType.maths,
            type: QuestionType.multipleChoice,
            difficulty: d,
            prompt: 'A baker packs $each rolls into each of $bags bags. How many rolls are there altogether?',
            choices: _numericChoices(answer, 4),
            correctAnswer: answer.toString(),
            explanation: '$bags × $each = $answer rolls altogether!',
            encouragement: 'Equal groups means multiplication!',
            nswYear: 3,
          );
        },
        (d) {
          final total = (_random.nextInt(8) + 3) * 4;
          final people = 4;
          final answer = total ~/ people;
          return Question(
            id: 'maths_word_share_$total',
            subject: SubjectType.maths,
            type: QuestionType.multipleChoice,
            difficulty: d,
            prompt: '$total stickers are shared equally among $people friends. How many does each friend get?',
            choices: _numericChoices(answer, 4),
            correctAnswer: answer.toString(),
            explanation: '$total ÷ $people = $answer stickers each!',
            encouragement: 'Shared equally means divide!',
            nswYear: 3,
          );
        },
      ];

  static List<String> _numericChoices(int correct, int total) {
    final choices = {correct.toString()};
    while (choices.length < total) {
      final offset = _random.nextInt(6) + 1;
      final distractor = _random.nextBool() ? correct + offset : (correct - offset).abs();
      choices.add(distractor.toString());
    }
    return choices.toList()..shuffle(_random);
  }

  static List<String> _decimalChoices(double correct, int total) {
    final choices = {correct.toStringAsFixed(1)};
    while (choices.length < total) {
      final offset = (_random.nextInt(4) + 1) * 0.1;
      final distractor = _random.nextBool() ? correct + offset : (correct - offset).abs();
      choices.add(distractor.toStringAsFixed(1));
    }
    return choices.toList()..shuffle(_random);
  }
}
