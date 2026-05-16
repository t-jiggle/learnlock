import 'package:learnlock/models/question.dart';
import 'package:learnlock/models/child_profile.dart';
import 'dart:math';

// NSW Mathematics K-6 Syllabus: Space and Geometry
class GeometryContent {
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
        () => _shapeNames2D(d),
        () => _shapeSides(d),
        () => _shapeProperties(d),
        () => _threeDShapes(d),
        () => _symmetry(d),
      ];

  static List<Question Function()> _middleGenerators(DifficultyLevel d) => [
        () => _shapeNames2D(d),
        () => _angles(d),
        () => _perimeter(d),
        () => _area(d),
        () => _lineTypes(d),
        () => _transformations(d),
      ];

  static List<Question Function()> _upperGenerators(DifficultyLevel d) => [
        () => _angles(d, harder: true),
        () => _perimeter(d, harder: true),
        () => _area(d, harder: true),
        () => _volume(d),
        () => _coordinates(d),
        () => _angleRules(d),
      ];

  static Question _shapeNames2D(DifficultyLevel d) {
    final shapes = [
      ('3 sides', 'triangle', 'A triangle has 3 sides!'),
      ('4 equal sides and 4 right angles', 'square', 'A square has 4 equal sides!'),
      ('4 sides, opposite sides equal, 4 right angles', 'rectangle', 'A rectangle has 4 right angles!'),
      ('5 sides', 'pentagon', 'A pentagon has 5 sides — think of the Pentagon building!'),
      ('6 sides', 'hexagon', 'A hexagon has 6 sides — think of a honeycomb!'),
      ('8 sides', 'octagon', 'An octagon has 8 sides — like a stop sign!'),
      ('round, no corners', 'circle', 'A circle is perfectly round with no sides or corners!'),
      ('4 sides, all sides equal', 'rhombus', 'A rhombus has 4 equal sides, like a tilted square!'),
    ];
    final item = shapes[_random.nextInt(shapes.length)];
    final answers = ['triangle', 'square', 'rectangle', 'pentagon',
        'hexagon', 'octagon', 'circle', 'rhombus'];
    final choices = [item.$2, ...answers.where((a) => a != item.$2).take(3)]
        ..shuffle(_random);
    return Question(
      id: 'geo_shape_${item.$2}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'What shape has: ${item.$1}?',
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Think about how many sides and corners the shape has!',
      nswYear: 1,
    );
  }

  static Question _shapeSides(DifficultyLevel d) {
    final shapes = [
      ('triangle', 3), ('square', 4), ('pentagon', 5),
      ('hexagon', 6), ('heptagon', 7), ('octagon', 8),
    ];
    final item = shapes[_random.nextInt(shapes.length)];
    final choices = _numericChoices(item.$2, 4);
    return Question(
      id: 'geo_sides_${item.$1}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'How many sides does a ${item.$1} have?',
      choices: choices,
      correctAnswer: item.$2.toString(),
      explanation: 'A ${item.$1} has ${item.$2} sides!',
      encouragement: 'Count the sides carefully!',
      nswYear: 1,
    );
  }

  static Question _shapeProperties(DifficultyLevel d) {
    final items = [
      ('Which shape has ALL sides the same length AND all angles the same?',
          'square', ['square', 'rectangle', 'rhombus', 'trapezium'],
          'A square has 4 equal sides and 4 equal 90° angles!'),
      ('Which shape has exactly 0 sides and 0 corners?',
          'circle', ['circle', 'oval', 'sphere', 'triangle'],
          'A circle is a curved shape with no straight sides or corners!'),
      ('Which shape always has 4 right angles?',
          'rectangle', ['rectangle', 'rhombus', 'parallelogram', 'trapezium'],
          'A rectangle (including squares) always has 4 right angles (90°)!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$3)..shuffle(_random);
    return Question(
      id: 'geo_prop_${item.$2}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: item.$1,
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$4,
      encouragement: 'Think about the special properties of each shape!',
      nswYear: 2,
    );
  }

  static Question _threeDShapes(DifficultyLevel d) {
    final shapes = [
      ('6 square faces', 'cube', 'A cube has 6 identical square faces!'),
      ('2 circular faces and 1 curved surface', 'cylinder', 'A cylinder is like a tin can!'),
      ('1 circular base and 1 apex (point)', 'cone', 'A cone is like an ice cream!'),
      ('no flat faces, perfectly round', 'sphere', 'A sphere is like a ball!'),
      ('4 triangular faces and 1 square base', 'square pyramid', 'A square pyramid is like the pyramids of Egypt!'),
      ('6 rectangular faces', 'rectangular prism', 'A rectangular prism is like a box!'),
    ];
    final item = shapes[_random.nextInt(shapes.length)];
    final names = ['cube', 'cylinder', 'cone', 'sphere', 'square pyramid', 'rectangular prism'];
    final choices = [item.$2, ...names.where((n) => n != item.$2).take(3)]
        ..shuffle(_random);
    return Question(
      id: 'geo_3d_${item.$2.replaceAll(' ', '_')}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'Which 3D shape has: ${item.$1}?',
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$3,
      encouragement: 'Think about 3D shapes you see every day — boxes, balls, cans!',
      nswYear: 2,
    );
  }

  static Question _symmetry(DifficultyLevel d) {
    final items = [
      ('Does a square have any lines of symmetry?', 'Yes, it has 4',
          ['Yes, it has 4', 'Yes, it has 1', 'No, it has none', 'Yes, it has 2'],
          'A square has 4 lines of symmetry — 2 through sides and 2 through corners!'),
      ('Does a circle have any lines of symmetry?', 'Yes, infinitely many',
          ['Yes, infinitely many', 'Yes, just 1', 'No, it has none', 'Yes, just 2'],
          'A circle has infinite lines of symmetry — any line through the centre works!'),
      ('Does a regular hexagon have lines of symmetry?', 'Yes, it has 6',
          ['Yes, it has 6', 'Yes, it has 3', 'No, it has none', 'Yes, it has 2'],
          'A regular hexagon has 6 lines of symmetry!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$3)..shuffle(_random);
    return Question(
      id: 'geo_sym_${item.$1.hashCode}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: item.$1,
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$4,
      encouragement: 'A line of symmetry divides a shape into two mirror-image halves!',
      nswYear: 2,
    );
  }

  static Question _angles(DifficultyLevel d, {bool harder = false}) {
    final items = [
      ('A right angle measures exactly', '90°', ['90°', '45°', '180°', '60°'],
          'A right angle is exactly 90° — like the corner of a square!'),
      ('An angle less than 90° is called', 'acute', ['acute', 'obtuse', 'reflex', 'right'],
          'Acute angles are less than 90° — they are sharp and small!'),
      ('An angle between 90° and 180° is called', 'obtuse', ['obtuse', 'acute', 'reflex', 'right'],
          'Obtuse angles are between 90° and 180° — they are wide!'),
      ('A straight line angle measures', '180°', ['180°', '90°', '360°', '270°'],
          'A straight line makes an angle of 180° — called a straight angle!'),
      ('A full rotation measures', '360°', ['360°', '180°', '270°', '90°'],
          'A full rotation (all the way around) is 360°!'),
    ];
    if (harder) {
      items.addAll([
        ('Two angles in a triangle add up to 120°. What is the third angle?', '60°',
            ['60°', '40°', '80°', '30°'],
            '180° - 120° = 60°. Angles in a triangle always add to 180°!'),
        ('Angles on a straight line add up to', '180°', ['180°', '360°', '90°', '270°'],
            'Angles on a straight line always add up to 180°!'),
      ]);
    }
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$3)..shuffle(_random);
    return Question(
      id: 'geo_angle_${item.$1.hashCode}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: item.$1,
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$4,
      encouragement: 'Remember: right angle = 90°, straight angle = 180°, full turn = 360°!',
      nswYear: 3,
    );
  }

  static Question _perimeter(DifficultyLevel d, {bool harder = false}) {
    if (!harder) {
      final side = _random.nextInt(8) + 2;
      final width = _random.nextInt(6) + 2;
      final p = 2 * (side + width);
      return Question(
        id: 'geo_perim_${side}_$width',
        subject: SubjectType.geometry,
        type: QuestionType.multipleChoice,
        difficulty: d,
        prompt: 'What is the perimeter of a rectangle ${side}cm long and ${width}cm wide?',
        choices: _numericChoices(p, 4, suffix: 'cm'),
        correctAnswer: '${p}cm',
        explanation: 'Perimeter = 2 × (length + width) = 2 × ($side + $width) = ${p}cm!',
        encouragement: 'Add up all the sides to find the perimeter!',
        nswYear: 3,
      );
    }
    // Harder: missing side given perimeter
    final side = _random.nextInt(8) + 3;
    final width = _random.nextInt(5) + 2;
    final p = 2 * (side + width);
    return Question(
      id: 'geo_perim_miss_${side}_$width',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'A rectangle has a perimeter of ${p}cm and one side is ${side}cm. What is the other side?',
      choices: _numericChoices(width, 4, suffix: 'cm'),
      correctAnswer: '${width}cm',
      explanation: 'Perimeter = 2 × (length + width). So ${width}cm = ($p ÷ 2) - $side!',
      encouragement: 'Work backwards from the perimeter formula!',
      nswYear: 5,
    );
  }

  static Question _area(DifficultyLevel d, {bool harder = false}) {
    if (!harder) {
      final l = _random.nextInt(8) + 2;
      final w = _random.nextInt(6) + 2;
      final area = l * w;
      return Question(
        id: 'geo_area_${l}_$w',
        subject: SubjectType.geometry,
        type: QuestionType.multipleChoice,
        difficulty: d,
        prompt: 'What is the area of a rectangle ${l}m long and ${w}m wide?',
        choices: _numericChoices(area, 4, suffix: 'm²'),
        correctAnswer: '${area}m²',
        explanation: 'Area = length × width = $l × $w = ${area}m²!',
        encouragement: 'Area = length × width. Count the squares inside!',
        nswYear: 4,
      );
    }
    // Triangle area
    final base = _random.nextInt(8) + 4;
    final height = _random.nextInt(6) + 2;
    final area = base * height ~/ 2;
    return Question(
      id: 'geo_tri_area_${base}_$height',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'What is the area of a triangle with base ${base}cm and height ${height}cm?',
      choices: _numericChoices(area, 4, suffix: 'cm²'),
      correctAnswer: '${area}cm²',
      explanation: 'Area of triangle = ½ × base × height = ½ × $base × $height = ${area}cm²!',
      encouragement: 'A triangle is half a rectangle!',
      nswYear: 5,
    );
  }

  static Question _volume(DifficultyLevel d) {
    final l = _random.nextInt(5) + 2;
    final w = _random.nextInt(4) + 2;
    final h = _random.nextInt(4) + 2;
    final vol = l * w * h;
    return Question(
      id: 'geo_vol_${l}_${w}_$h',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: 'What is the volume of a rectangular prism ${l}cm × ${w}cm × ${h}cm?',
      choices: _numericChoices(vol, 4, suffix: 'cm³'),
      correctAnswer: '${vol}cm³',
      explanation: 'Volume = length × width × height = $l × $w × $h = ${vol}cm³!',
      encouragement: 'Volume is how much space a 3D shape takes up!',
      nswYear: 6,
    );
  }

  static Question _coordinates(DifficultyLevel d) {
    final x = _random.nextInt(8) + 1;
    final y = _random.nextInt(8) + 1;
    final items = [
      ('A point is at ($x, $y). What is its x-coordinate?', '$x',
          ['$x', '$y', '${x + y}', '${(x * y).clamp(0, 20)}'],
          'The x-coordinate is always the first number in the pair ($x, $y)!'),
      ('A point is at ($x, $y). What is its y-coordinate?', '$y',
          ['$y', '$x', '${x + y}', '${(x * y).clamp(0, 20)}'],
          'The y-coordinate is always the second number in the pair ($x, $y)!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$3)..shuffle(_random);
    return Question(
      id: 'geo_coord_${x}_$y',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: item.$1,
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$4,
      encouragement: 'Remember: x is along the corridor, y is up the stairs!',
      nswYear: 5,
    );
  }

  static Question _lineTypes(DifficultyLevel d) {
    final items = [
      ('Lines that never meet and are always the same distance apart are called',
          'parallel', ['parallel', 'perpendicular', 'intersecting', 'diagonal'],
          'Parallel lines are like railway tracks — they never meet!'),
      ('Lines that meet at a right angle (90°) are called',
          'perpendicular', ['perpendicular', 'parallel', 'horizontal', 'diagonal'],
          'Perpendicular lines cross at exactly 90°!'),
      ('A line that goes straight across (left to right) is called',
          'horizontal', ['horizontal', 'vertical', 'diagonal', 'perpendicular'],
          'Horizontal lines are flat, like the horizon!'),
      ('A line that goes straight up and down is called',
          'vertical', ['vertical', 'horizontal', 'diagonal', 'parallel'],
          'Vertical lines go up and down, like a flag pole!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$3)..shuffle(_random);
    return Question(
      id: 'geo_line_${item.$2}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: item.$1,
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$4,
      encouragement: 'Look at lines around you — floors, walls, roads!',
      nswYear: 3,
    );
  }

  static Question _transformations(DifficultyLevel d) {
    final items = [
      ('Moving a shape without rotating or flipping it is called a',
          'translation', ['translation', 'reflection', 'rotation', 'enlargement'],
          'A translation slides the shape — it keeps the same orientation!'),
      ('Flipping a shape over a line is called a',
          'reflection', ['reflection', 'translation', 'rotation', 'enlargement'],
          'A reflection creates a mirror image of the shape!'),
      ('Turning a shape around a fixed point is called a',
          'rotation', ['rotation', 'translation', 'reflection', 'enlargement'],
          'A rotation turns the shape around a centre point!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$3)..shuffle(_random);
    return Question(
      id: 'geo_trans_${item.$2}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: item.$1,
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$4,
      encouragement: 'Slide, flip or turn — those are the three transformations!',
      nswYear: 4,
    );
  }

  static Question _angleRules(DifficultyLevel d) {
    final items = [
      ('Angles in a triangle add up to', '180°', ['180°', '360°', '90°', '270°'],
          'The three angles inside any triangle always add up to 180°!'),
      ('Angles in a quadrilateral add up to', '360°', ['360°', '180°', '270°', '90°'],
          'The four angles inside any quadrilateral always add up to 360°!'),
      ('Vertically opposite angles are', 'equal', ['equal', 'supplementary', 'complementary', 'different'],
          'When two lines cross, the opposite angles are always equal!'),
      ('Two angles that add to 90° are called', 'complementary',
          ['complementary', 'supplementary', 'equal', 'adjacent'],
          'Complementary angles add to 90°. Think: completing a right angle!'),
      ('Two angles that add to 180° are called', 'supplementary',
          ['supplementary', 'complementary', 'equal', 'adjacent'],
          'Supplementary angles add to 180°. They form a straight line!'),
    ];
    final item = items[_random.nextInt(items.length)];
    final choices = List<String>.from(item.$3)..shuffle(_random);
    return Question(
      id: 'geo_anglerule_${item.$2.hashCode}',
      subject: SubjectType.geometry,
      type: QuestionType.multipleChoice,
      difficulty: d,
      prompt: item.$1,
      choices: choices,
      correctAnswer: item.$2,
      explanation: item.$4,
      encouragement: 'These rules always work — geometry is very consistent!',
      nswYear: 5,
    );
  }

  static List<String> _numericChoices(int correct, int total, {String suffix = ''}) {
    final choices = {'$correct$suffix'};
    final rand = Random();
    while (choices.length < total) {
      final offset = rand.nextInt(5) + 1;
      final d = rand.nextBool() ? correct + offset : (correct - offset).abs();
      choices.add('$d$suffix');
    }
    return choices.toList()..shuffle(rand);
  }
}
