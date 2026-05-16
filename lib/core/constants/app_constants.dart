class AppConstants {
  static const appName = 'LearnLock';

  // Web OAuth 2.0 client ID from google-services.json (oauth_client with client_type: 3).
  // Required by google_sign_in on Android to request an idToken for Firebase Auth.
  static const googleWebClientId =
      '468204062380-0e2ttcp6i807gas56md05pkf1b83b6bo.apps.googleusercontent.com';
  static const defaultLearningMinutes = 2;
  static const defaultEarnedMinutes = 30;
  static const targetAccuracy = 0.75;

  // Subject display names
  static const subjectNames = {
    'spelling': 'Spelling',
    'grammar': 'Grammar',
    'maths': 'Maths',
    'geometry': 'Geometry',
  };

  // Subject emoji / icons
  static const subjectEmoji = {
    'spelling': '📚',
    'grammar': '✏️',
    'maths': '🔢',
    'geometry': '📐',
  };

  // Encouragement messages by accuracy band
  static const encouragementHigh = [
    "You're on fire! Amazing work! 🔥",
    "Brilliant! You're so smart! ⭐",
    "Wow, incredible! Keep it up! 🚀",
    "You're a superstar learner! 🌟",
    "Outstanding! I'm so proud of you! 🎉",
  ];

  static const encouragementMid = [
    "Great job! You're getting it! 😊",
    "Well done! Keep practising! 💪",
    "You're doing really well! 🌈",
    "Nice work! You're learning so much! 🎓",
    "Keep going, you're doing great! 👏",
  ];

  static const encouragementLow = [
    "That's okay! Learning takes practice! 🤗",
    "Good try! Let's keep going! 💫",
    "Don't worry, you'll get it next time! 🌟",
    "Every mistake helps us learn! Keep it up! 🌱",
    "You're brave for trying! That's what counts! 🦁",
  ];

  // NSW Syllabus grade bands
  static const nswGradeBands = ['K-2', '3-4', '5-6', '7+'];
}
