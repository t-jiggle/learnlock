import 'package:learnlock/models/question.dart';
import 'package:learnlock/models/child_profile.dart';
import 'dart:math';

// NSW K-6 spelling and sight-word content.
// Picture words (those with emoji) show the emoji prominently and ask the child
// to choose the correct spelling — they never see the word written out.
// Words without emoji use a scrambled-letters fallback.
class SpellingContent {
  static final _random = Random();

  // Words that have a clear, unambiguous emoji representation.
  static const _emojiWords = {
    // Animals
    'cat': '🐱', 'dog': '🐶', 'bird': '🐦', 'fish': '🐟', 'cow': '🐄',
    'pig': '🐷', 'hen': '🐔', 'frog': '🐸', 'duck': '🦆', 'bee': '🐝',
    'ant': '🐜', 'bear': '🐻', 'lion': '🦁', 'horse': '🐴', 'sheep': '🐑',
    'snake': '🐍', 'whale': '🐋', 'crab': '🦀', 'owl': '🦉', 'fox': '🦊',
    'wolf': '🐺', 'deer': '🦌', 'goat': '🐐', 'rabbit': '🐇', 'turtle': '🐢',
    'penguin': '🐧', 'elephant': '🐘', 'giraffe': '🦒', 'monkey': '🐒',
    'tiger': '🐯', 'zebra': '🦓', 'panda': '🐼', 'crocodile': '🐊',
    // Food & drink
    'apple': '🍎', 'cake': '🎂', 'egg': '🥚', 'bread': '🍞', 'milk': '🥛',
    'pizza': '🍕', 'rice': '🍚', 'grape': '🍇', 'lemon': '🍋',
    'peach': '🍑', 'pear': '🍐', 'corn': '🌽', 'carrot': '🥕',
    'strawberry': '🍓', 'banana': '🍌', 'cherry': '🍒',
    'mushroom': '🍄', 'cookie': '🍪', 'donut': '🍩',
    // Objects
    'ball': '⚽', 'book': '📚', 'boat': '⛵', 'car': '🚗', 'bus': '🚌',
    'star': '⭐', 'moon': '🌙', 'sun': '☀️', 'tree': '🌳', 'door': '🚪',
    'key': '🔑', 'hat': '🎩', 'cup': '☕', 'bell': '🔔',
    'drum': '🥁', 'clock': '🕐', 'phone': '📱', 'lamp': '💡',
    'pen': '🖊️', 'rocket': '🚀',
    'train': '🚂', 'plane': '✈️', 'ship': '🚢', 'truck': '🚛', 'bike': '🚲',
    // Nature
    'rain': '🌧️', 'snow': '❄️', 'flower': '🌸', 'leaf': '🍂', 'fire': '🔥',
    'cloud': '☁️', 'rainbow': '🌈', 'wave': '🌊',
    // Places
    'house': '🏠', 'school': '🏫', 'hospital': '🏥', 'castle': '🏰',
    // Sports & play
    'football': '🏈', 'basketball': '🏀', 'kite': '🪁',
    'robot': '🤖', 'crown': '👑', 'heart': '❤️',
  };

  // NSW K-6 sight word lists (non-picture words)
  static const _wordsByYear = {
    0: [ // Kindergarten
      'a', 'and', 'at', 'big', 'can', 'for', 'go', 'had', 'has', 'he',
      'her', 'him', 'his', 'I', 'in', 'is', 'it', 'like', 'look', 'me',
      'mum', 'my', 'no', 'not', 'of', 'on', 'play', 'ran', 'run', 'said',
      'sat', 'see', 'she', 'so', 'the', 'this', 'to', 'up', 'was', 'we',
      'went', 'will', 'with', 'yes', 'you', 'am', 'be',
    ],
    1: [ // Year 1
      'about', 'after', 'again', 'all', 'also', 'any', 'are', 'back',
      'been', 'before', 'bring', 'came', 'come', 'day', 'did', 'down', 'eat',
      'find', 'first', 'fly', 'from', 'fun', 'gave', 'get', 'give', 'good',
      'got', 'have', 'help', 'here', 'home', 'how', 'into', 'just', 'keep',
      'know', 'let', 'live', 'long', 'made', 'make', 'many', 'more', 'most',
      'much', 'must', 'name', 'new', 'next', 'night', 'now', 'off', 'old',
      'once', 'one', 'only', 'open', 'our', 'out', 'over', 'own', 'part',
      'people', 'put', 'read', 'ride', 'right', 'road', 'same', 'saw', 'say',
    ],
    2: [ // Year 2
      'always', 'answer', 'around', 'ask', 'away', 'behind', 'below', 'best',
      'both', 'buy', 'carry', 'change', 'clean', 'close', 'cold', 'colour',
      'done', 'draw', 'drink', 'drop', 'dry', 'during', 'each', 'early',
      'enough', 'even', 'every', 'face', 'fall', 'far', 'fast', 'feel', 'few',
      'follow', 'food', 'four', 'front', 'full', 'garden', 'girl', 'green',
      'ground', 'grow', 'guess', 'happy', 'hard', 'head', 'heat', 'high',
      'hold', 'hurry', 'important', 'jump', 'kind', 'large', 'last', 'laugh',
      'learn', 'leave', 'left', 'light', 'list',
    ],
    3: [ // Year 3
      'afraid', 'agree', 'almost', 'along', 'already', 'although', 'another',
      'anything', 'apart', 'appear', 'arrived', 'attention', 'beautiful',
      'because', 'begin', 'between', 'body', 'break', 'build', 'busy',
      'careful', 'catch', 'caught', 'centre', 'certain', 'children',
      'choose', 'clear', 'climb', 'clothes', 'complete', 'consider',
      'contain', 'control', 'copy', 'corner', 'country', 'course', 'cover',
      'create', 'cross', 'decide', 'describe', 'desert', 'different',
      'difficult', 'direction', 'discover', 'distance', 'divide', 'double',
    ],
    4: [ // Year 4
      'absence', 'accident', 'achieve', 'acknowledge', 'actually', 'addition',
      'adventure', 'advertise', 'against', 'agriculture', 'allowed', 'analyse',
      'ancient', 'announce', 'apparent', 'appreciate', 'approach', 'approve',
      'argument', 'arrange', 'article', 'atmosphere', 'attack', 'attempt',
      'audience', 'available', 'average', 'balance', 'behaviour', 'believe',
      'benefit', 'breathe', 'brilliant', 'brought', 'business', 'calculate',
      'calendar', 'campaign', 'capable', 'captain', 'category', 'cause',
      'celebration', 'challenge', 'character', 'comfortable', 'communicate',
    ],
    5: [ // Year 5
      'abundance', 'accommodation', 'accomplishment', 'accurate',
      'adequate', 'adjacent', 'administration', 'admirable', 'adolescent',
      'aftermath', 'aggressive', 'allegiance', 'alliance', 'ambassador',
      'ambiguous', 'ambitious', 'amendment', 'analytical', 'anniversary',
      'anonymous', 'anticipate', 'approximately', 'architecture', 'arithmetic',
      'assertive', 'assistance', 'association', 'astonishment', 'authentic',
      'authorities', 'autobiography', 'availability', 'cautious', 'century',
      'circumstance', 'civilisation', 'classification', 'collaborate',
      'colleague', 'commitment', 'comparison', 'competent', 'composition',
    ],
    6: [ // Year 6
      'abbreviation', 'abolish', 'absolutely', 'abstain', 'acceleration',
      'accessible', 'accountability', 'acquisition', 'adaptation',
      'adequately', 'advancement', 'aggression', 'allegiance',
      'alternative', 'ambivalent', 'amendment', 'analytical', 'appropriate',
      'approximately', 'architecture', 'arthritis', 'assimilation', 'association',
      'atmosphere', 'authoritative', 'beneficial', 'biographical', 'catastrophe',
      'chronological', 'circumstances', 'classification', 'collaboration',
      'commemorate', 'commentary', 'commercial', 'committee', 'communication',
    ],
  };

  static List<Question> generate({
    required int nswYear,
    required DifficultyLevel difficulty,
    int count = 5,
  }) {
    final picturePool = _pictureWordsForYear(nswYear, difficulty)..shuffle(_random);
    final sightPool = _sightWordsForYear(nswYear, difficulty)..shuffle(_random);

    final questions = <Question>[];
    int pictureIdx = 0;
    int sightIdx = 0;
    // Aim for roughly half picture, half sight-word
    final pictureTarget = (count / 2).ceil();

    while (questions.length < count) {
      final wantPicture =
          questions.length < pictureTarget && pictureIdx < picturePool.length;
      if (wantPicture) {
        questions.add(
            _buildPictureQuestion(picturePool[pictureIdx++], nswYear, difficulty));
      } else if (sightIdx < sightPool.length) {
        questions.add(
            _buildScrambleQuestion(sightPool[sightIdx++], nswYear, difficulty));
      } else if (pictureIdx < picturePool.length) {
        questions.add(
            _buildPictureQuestion(picturePool[pictureIdx++], nswYear, difficulty));
      } else {
        break;
      }
    }
    return questions;
  }

  // ── Picture (emoji) question ──────────────────────────────────────────────

  static Question _buildPictureQuestion(
      String word, int year, DifficultyLevel difficulty) {
    final emoji = _emojiWords[word]!;
    final distractors = _generateDistractors(word, 3);
    final allChoices = [...distractors, word]..shuffle(_random);

    return Question(
      id: 'spell_pic_${word}_${_random.nextInt(9999)}',
      subject: SubjectType.spelling,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: '$emoji\nWhat is this? Choose the correct spelling:',
      choices: allChoices,
      correctAnswer: word,
      explanation: 'The correct spelling is "$word".',
      encouragement: _encouragement(),
      nswYear: year,
    );
  }

  // ── Scramble (non-picture) question ──────────────────────────────────────

  static Question _buildScrambleQuestion(
      String word, int year, DifficultyLevel difficulty) {
    final scrambled = _scramble(word);
    final distractors = _generateDistractors(word, 3);
    final allChoices = [...distractors, word]..shuffle(_random);

    return Question(
      id: 'spell_${word}_${_random.nextInt(9999)}',
      subject: SubjectType.spelling,
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      prompt: 'Unscramble the letters and choose the correct spelling:\n"$scrambled"',
      choices: allChoices,
      correctAnswer: word,
      explanation: 'The correct spelling is "$word".',
      encouragement: _encouragement(),
      nswYear: year,
    );
  }

  // ── Word pool helpers ─────────────────────────────────────────────────────

  static List<String> _pictureWordsForYear(int year, DifficultyLevel difficulty) {
    final adjustedYear = _adjustedYear(year, difficulty);
    // Younger years: only short words; older years allow longer picture words
    final maxLen = adjustedYear <= 1 ? 5 : adjustedYear <= 3 ? 8 : 12;
    return _emojiWords.keys.where((w) => w.length <= maxLen).toList();
  }

  static List<String> _sightWordsForYear(int year, DifficultyLevel difficulty) {
    final targetYear = _adjustedYear(year, difficulty);
    final words = <String>[];
    for (int y = 0; y <= targetYear.clamp(0, 6); y++) {
      words.addAll(_wordsByYear[y] ?? []);
    }
    return words;
  }

  static int _adjustedYear(int year, DifficultyLevel difficulty) {
    return switch (difficulty) {
      DifficultyLevel.veryEasy => (year - 1).clamp(0, 6),
      DifficultyLevel.easy => year.clamp(0, 6),
      DifficultyLevel.medium => year.clamp(0, 6),
      DifficultyLevel.hard => (year + 1).clamp(0, 6),
      DifficultyLevel.veryHard => (year + 2).clamp(0, 6),
    };
  }

  // ── Distractor generation ─────────────────────────────────────────────────

  static String _scramble(String word) {
    if (word.length <= 2) return word;
    final chars = word.split('');
    final first = chars.removeAt(0);
    final last = chars.removeLast();
    chars.shuffle(_random);
    return '$first${chars.join()}$last';
  }

  static List<String> _generateDistractors(String word, int count) {
    final distortions = <String>[];
    final mutations = [_doubleRandom, _swapTwo, _addSilentE, _changeSuffix];
    int attempts = 0;
    while (distortions.length < count && attempts < 40) {
      attempts++;
      final mutation = mutations[_random.nextInt(mutations.length)];
      final distorted = mutation(word);
      if (distorted != word && !distortions.contains(distorted)) {
        distortions.add(distorted);
      }
    }
    return distortions;
  }

  static String _doubleRandom(String w) {
    if (w.length < 3) return '${w}e';
    final idx = 1 + _random.nextInt(w.length - 2);
    return w.substring(0, idx) + w[idx] + w.substring(idx);
  }

  static String _swapTwo(String w) {
    if (w.length < 3) return '${w}s';
    final idx = _random.nextInt(w.length - 1);
    final chars = w.split('');
    final tmp = chars[idx];
    chars[idx] = chars[idx + 1];
    chars[idx + 1] = tmp;
    return chars.join();
  }

  static String _addSilentE(String w) => '${w}e';

  static String _changeSuffix(String w) {
    if (w.endsWith('ing')) return '${w.substring(0, w.length - 3)}ed';
    if (w.endsWith('ed')) return '${w.substring(0, w.length - 2)}ing';
    if (w.endsWith('ly')) return w.substring(0, w.length - 2);
    return '${w}ly';
  }

  static String _encouragement() {
    const hints = [
      'Sound it out letter by letter!',
      'Try breaking it into smaller parts!',
      'Think about the sounds you hear!',
      'Look for word families you know!',
    ];
    return hints[_random.nextInt(hints.length)];
  }
}
