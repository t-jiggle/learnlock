import 'package:learnlock/models/question.dart';
import 'package:learnlock/models/child_profile.dart';
import 'dart:math';

// NSW English K-6 Syllabus: grammar and punctuation questions
class GrammarContent {
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
    if (year <= 2) return _earlyGenerators(difficulty);
    if (year <= 4) return _middleGenerators(difficulty);
    return _upperGenerators(difficulty);
  }

  static List<Question Function()> _earlyGenerators(DifficultyLevel d) => [
        () => _nounOrVerb(d),
        () => _plurals(d),
        () => _capitalLetters(d),
        () => _sentenceOrNot(d),
        () => _punctuationEnd(d),
      ];

  static List<Question Function()> _middleGenerators(DifficultyLevel d) => [
        () => _nounOrVerb(d),
        () => _adjectives(d),
        () => _tense(d),
        () => _possessiveApostrophe(d),
        () => _pronouns(d),
        () => _commas(d),
      ];

  static List<Question Function()> _upperGenerators(DifficultyLevel d) => [
        () => _tense(d),
        () => _conjunctions(d),
        () => _activePassive(d),
        () => _speechMarks(d),
        () => _adverbs(d),
        () => _subjectVerb(d),
      ];

  // ----- Question generators -----

  static Question _nounOrVerb(DifficultyLevel d) {
    final words = [
      ('dog', 'noun', 'A dog is a thing — it is a noun!'),
      ('run', 'verb', 'Run is an action — it is a verb!'),
      ('table', 'noun', 'A table is a thing — it is a noun!'),
      ('jump', 'verb', 'Jump is an action — it is a verb!'),
      ('cloud', 'noun', 'A cloud is a thing — it is a noun!'),
      ('sleep', 'verb', 'Sleep is an action — it is a verb!'),
      ('teacher', 'noun', 'A teacher is a person — it is a noun!'),
      ('sing', 'verb', 'Sing is an action — it is a verb!'),
    ];
    final item = words[_random.nextInt(words.length)];
    return Question(
      id: 'gram_nov_${item.$1}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Is the word "${item.$1}" a noun or a verb?',
      choices: ['noun', 'verb', 'adjective', 'neither'],
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Nouns are people, places or things. Verbs are actions!',
      nswYear: 1,
    );
  }

  static Question _plurals(DifficultyLevel d) {
    final words = [
      ('cat', 'cats', 'Just add -s!'),
      ('box', 'boxes', 'Words ending in -x add -es!'),
      ('child', 'children', 'Child is an irregular plural!'),
      ('mouse', 'mice', 'Mouse is an irregular plural!'),
      ('bus', 'buses', 'Words ending in -s add -es!'),
      ('leaf', 'leaves', 'Words ending in -f change to -ves!'),
      ('story', 'stories', 'Words ending in -y change to -ies!'),
      ('fish', 'fish', 'Fish stays the same — it is irregular!'),
    ];
    final item = words[_random.nextInt(words.length)];
    final distractors = <String>[];
    while (distractors.length < 3) {
      final w = words[_random.nextInt(words.length)].$2;
      if (w != item.$2 && !distractors.contains(w)) distractors.add(w);
    }
    final choices = [...distractors, item.$2]..shuffle(_random);
    return Question(
      id: 'gram_plural_${item.$1}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'What is the plural of "${item.$1}"?',
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Most plurals add -s, but some are special!',
      nswYear: 1,
    );
  }

  static Question _capitalLetters(DifficultyLevel d) {
    final sentences = [
      ('my name is emma.', 'My name is Emma.', 'Names and sentence starts need capitals!'),
      ('we live in sydney.', 'We live in Sydney.', 'Cities and sentence starts need capitals!'),
      ('sam went to the park on monday.', 'Sam went to the park on Monday.', 'Names and days of the week need capitals!'),
      ('the amazon river is in south america.', 'The Amazon River is in South America.', 'Proper nouns (names of places) need capitals!'),
    ];
    final item = sentences[_random.nextInt(sentences.length)];
    return Question(
      id: 'gram_cap_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Which sentence uses capital letters correctly?\n"${item.$1}"',
      choices: [item.$2, item.$1, item.$1.toUpperCase(),
          item.$2.toLowerCase()]
          ..shuffle(_random),
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Capital letters start sentences and name special things!',
      nswYear: 1,
    );
  }

  static Question _sentenceOrNot(DifficultyLevel d) {
    final examples = [
      ('The dog ran fast.', true, 'This is a complete sentence with a subject and verb!'),
      ('Running quickly through', false, 'This is a fragment — it has no subject!'),
      ('She likes to eat apples.', true, 'This is a complete sentence!'),
      ('Big blue sky', false, 'This is a fragment — no verb!'),
      ('Do you want to play?', true, 'This is a complete question sentence!'),
      ('Under the big tree near', false, 'This is a fragment — no subject or verb!'),
    ];
    final item = examples[_random.nextInt(examples.length)];
    return Question(
      id: 'gram_sent_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Is this a complete sentence?\n"${item.$1}"',
      choices: ['Yes, it is a complete sentence', 'No, it is a fragment',
          'It is a question', 'It is a heading'],
      correctAnswer: item.$2 ? 'Yes, it is a complete sentence' : 'No, it is a fragment',
      explanation: item.$3,
      encouragement: 'A sentence needs a subject (who/what) and a verb (action)!',
      nswYear: 2,
    );
  }

  static Question _punctuationEnd(DifficultyLevel d) {
    final items = [
      ('Where are you going', '?', 'Questions end with a question mark!'),
      ('The sky is blue', '.', 'Statements end with a full stop!'),
      ('Watch out for the car', '!', 'Exclamations end with an exclamation mark!'),
      ('What is your name', '?', 'Questions end with a question mark!'),
      ('She ran to school', '.', 'Statements end with a full stop!'),
      ('That is amazing', '!', 'Exclamations end with an exclamation mark!'),
    ];
    final item = items[_random.nextInt(items.length)];
    return Question(
      id: 'gram_punct_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'What punctuation goes at the end?\n"${item.$1}___"',
      choices: ['.', '?', '!', ','],
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Think about whether it is a question, statement or exclamation!',
      nswYear: 1,
    );
  }

  static Question _adjectives(DifficultyLevel d) {
    final items = [
      ('The ___ cat sat on the mat.', ['fluffy', 'run', 'quickly', 'they'], 'fluffy',
          'Fluffy describes the cat — it is an adjective!'),
      ('She wore a ___ dress.', ['pretty', 'dance', 'softly', 'him'], 'pretty',
          'Pretty describes the dress — it is an adjective!'),
      ('The ___ elephant splashed in the water.', ['enormous', 'swim', 'loudly', 'we'], 'enormous',
          'Enormous describes the elephant — it is an adjective!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$2)..shuffle(_random);
    return Question(
      id: 'gram_adj_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Which word is an adjective (describing word)?\n"${item.$1}"',
      choices: choices,
      correctAnswer: item.$3,
      explanation: item.$4,
      encouragement: 'Adjectives describe nouns. They tell us what something is like!',
      nswYear: 2,
    );
  }

  static Question _tense(DifficultyLevel d) {
    final items = [
      ('She ___ to school yesterday.', ['walked', 'walk', 'walks', 'walking'], 'walked',
          '"Yesterday" tells us it is past tense, so we use "walked"!'),
      ('He ___ his homework every night.', ['does', 'did', 'doing', 'done'], 'does',
          '"Every night" shows it happens regularly — present tense "does"!'),
      ('They ___ to the beach tomorrow.', ['will go', 'went', 'going', 'go'], 'will go',
          '"Tomorrow" shows future tense — we use "will go"!'),
      ('The birds ___ south last winter.', ['flew', 'fly', 'flown', 'flying'], 'flew',
          '"Last winter" shows past tense — we use "flew"!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$2)..shuffle(_random);
    return Question(
      id: 'gram_tense_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Choose the correct verb form:\n"${item.$1}"',
      choices: choices,
      correctAnswer: item.$3,
      explanation: item.$4,
      encouragement: 'Look for time clue words like "yesterday", "tomorrow" or "always"!',
      nswYear: 3,
    );
  }

  static Question _possessiveApostrophe(DifficultyLevel d) {
    final items = [
      ("the dog's bone", "dog's", 'The apostrophe -s shows the bone belongs to the dog!'),
      ("Emma's book", "Emma's", 'The apostrophe -s shows the book belongs to Emma!'),
      ("the children's toys", "children's", 'For plurals not ending in -s, add apostrophe -s!'),
      ("the teachers' staff room", "teachers'", 'For plurals ending in -s, add the apostrophe after!'),
    ];
    final item = items[_random.nextInt(items.length)];
    return Question(
      id: 'gram_apos_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Which shows possession correctly?\n"${item.$1}"',
      choices: [item.$2, item.$2.replaceAll("'", ''),
          item.$2.replaceAll("'s", "s'"), "${item.$2}s"]..shuffle(_random),
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'The apostrophe shows that something belongs to someone!',
      nswYear: 3,
    );
  }

  static Question _pronouns(DifficultyLevel d) {
    final items = [
      ('Sam is tired. ___ wants to sleep.', ['He', 'Her', 'They', 'It'], 'He',
          '"Sam" is male, so we use "He"!'),
      ('The cat licked ___ paw.', ['its', 'their', 'his', 'our'], 'its',
          'The cat is an animal, so we use "its"!'),
      ('Mia and I went to the park. ___ had fun.', ['We', 'They', 'Us', 'I'], 'We',
          '"Mia and I" is replaced by "We" as the subject!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$2)..shuffle(_random);
    return Question(
      id: 'gram_pron_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Choose the correct pronoun:\n"${item.$1}"',
      choices: choices,
      correctAnswer: item.$3,
      explanation: item.$4,
      encouragement: 'Pronouns replace nouns. Think about who or what the pronoun refers to!',
      nswYear: 2,
    );
  }

  static Question _commas(DifficultyLevel d) {
    final items = [
      ('I bought apples, bananas, oranges and grapes.',
          'I bought apples, bananas, oranges and grapes.',
          'Commas separate items in a list!'),
      ('After the rain stopped, we went outside.',
          'After the rain stopped, we went outside.',
          'A comma follows an introductory phrase!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final wrong = item.$1.replaceAll(',', '');
    return Question(
      id: 'gram_comma_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Which sentence uses commas correctly?',
      choices: [item.$2, wrong, '${item.$1},', item.$1.replaceFirst(',', '')]
          ..shuffle(_random),
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Commas help us pause in the right places when reading!',
      nswYear: 3,
    );
  }

  static Question _conjunctions(DifficultyLevel d) {
    final items = [
      ('I wanted to play, ___ it was raining.', ['but', 'so', 'then', 'also'], 'but',
          '"But" shows a contrast between two ideas!'),
      ('She studied hard, ___ she passed the test.', ['so', 'but', 'yet', 'however'], 'so',
          '"So" shows a result or consequence!'),
      ('He can walk ___ he can take the bus.', ['or', 'and', 'but', 'since'], 'or',
          '"Or" shows a choice between two options!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$2)..shuffle(_random);
    return Question(
      id: 'gram_conj_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Choose the best conjunction:\n"${item.$1}"',
      choices: choices,
      correctAnswer: item.$3,
      explanation: item.$4,
      encouragement: 'Conjunctions join ideas together. Think about the relationship between the two parts!',
      nswYear: 4,
    );
  }

  static Question _activePassive(DifficultyLevel d) {
    final items = [
      ('The dog chased the ball.', 'active', 'The subject (dog) is doing the action — active voice!'),
      ('The ball was chased by the dog.', 'passive', 'The subject receives the action — passive voice!'),
      ('Emma wrote the letter.', 'active', 'The subject (Emma) is doing the action — active voice!'),
      ('The letter was written by Emma.', 'passive', 'The subject receives the action — passive voice!'),
    ];
    final item = items[_random.nextInt(items.length)];
    return Question(
      id: 'gram_ap_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Is this sentence active or passive?\n"${item.$1}"',
      choices: ['active', 'passive', 'imperative', 'conditional'],
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Active: subject does the action. Passive: subject receives the action!',
      nswYear: 5,
    );
  }

  static Question _speechMarks(DifficultyLevel d) {
    final items = [
      ('"Come here," said Mia.', '"Come here," said Mia.',
          'Speech marks go around the spoken words!'),
      ('"I love this book!" exclaimed Jake.', '"I love this book!" exclaimed Jake.',
          'Exclamation marks inside speech marks show excitement!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final wrong = item.$1.replaceAll('"', '');
    return Question(
      id: 'gram_speech_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Which sentence uses speech marks correctly?',
      choices: [item.$2, wrong, '"${item.$1}', '${item.$1}"']..shuffle(_random),
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Speech marks ("...") show the exact words someone says!',
      nswYear: 4,
    );
  }

  static Question _adverbs(DifficultyLevel d) {
    final items = [
      ('She sang ___ beautifully.', ['very', 'run', 'the', 'apple'], 'very',
          '"Very" is an adverb — it modifies the adverb "beautifully"!'),
      ('He ran ___ to the finish line.', ['quickly', 'happy', 'big', 'a'], 'quickly',
          '"Quickly" is an adverb — it tells us HOW he ran!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$2)..shuffle(_random);
    return Question(
      id: 'gram_adv_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Which word is an adverb?\n"${item.$1}"',
      choices: choices,
      correctAnswer: item.$3,
      explanation: item.$4,
      encouragement: 'Adverbs modify verbs, adjectives or other adverbs. Many end in -ly!',
      nswYear: 4,
    );
  }

  static Question _subjectVerb(DifficultyLevel d) {
    final items = [
      ('The dogs ___ loudly.', ['bark', 'barks', 'barked was', 'barking is'], 'bark',
          'Plural subject "dogs" takes plural verb "bark"!'),
      ('She ___ to music every day.', ['listens', 'listen', 'listening', 'listened were'], 'listens',
          'Singular subject "She" takes "listens" (add -s)!'),
      ('The children ___ in the playground.', ['play', 'plays', 'is play', 'playing was'], 'play',
          'Plural subject "children" takes plural verb "play"!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$2)..shuffle(_random);
    return Question(
      id: 'gram_sv_${item.$1.hashCode}',
      subject: SubjectType.grammar,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Choose the correct verb form:\n"${item.$1}"',
      choices: choices,
      correctAnswer: item.$3,
      explanation: item.$4,
      encouragement: 'The verb must agree with its subject — singular or plural!',
      nswYear: 5,
    );
  }
}
