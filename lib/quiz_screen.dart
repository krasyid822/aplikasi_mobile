import 'dart:async';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Daftar pertanyaan
  final List<Map<String, Object>> _questions = [
    {
      'question': 'Siapa pencipta bahasa pemrograman Dart?',
      'answers': ['Google', 'Microsoft', 'Apple', 'Facebook'],
      'correctAnswer': 'Google',
    },
    {
      'question': 'Flutter menggunakan bahasa pemrograman apa?',
      'answers': ['Python', 'Dart', 'Java', 'C++'],
      'correctAnswer': 'Dart',
    },
    {
      'question': 'Widget yang tidak dapat berubah disebut?',
      'answers': [
        'StatefulWidget',
        'ImmutableWidget',
        'StatelessWidget',
        'StaticWidget',
      ],
      'correctAnswer': 'StatelessWidget',
    },
    {
      'question': 'Apa fungsi setState pada Flutter?',
      'answers': [
        'Mengganti tema',
        'Memperbarui UI',
        'Menambah widget',
        'Menghapus widget',
      ],
      'correctAnswer': 'Memperbarui UI',
    },
    {
      'question': 'Tipe data untuk bilangan pecahan di Dart?',
      'answers': ['int', 'double', 'num', 'float'],
      'correctAnswer': 'double',
    },
    {
      'question': 'Keyword untuk membuat kelas di Dart?',
      'answers': ['struct', 'class', 'object', 'type'],
      'correctAnswer': 'class',
    },
    {
      'question': 'Widget untuk menampilkan teks di Flutter?',
      'answers': ['Text', 'Label', 'Typography', 'StringWidget'],
      'correctAnswer': 'Text',
    },
    {
      'question': 'Perintah untuk menjalankan aplikasi Flutter di debug?',
      'answers': ['flutter run', 'dart start', 'flutter build', 'dart run'],
      'correctAnswer': 'flutter run',
    },
    {
      'question': 'State management sederhana dapat dilakukan dengan?',
      'answers': ['Provider', 'setState', 'Bloc', 'Redux'],
      'correctAnswer': 'setState',
    },
    {
      'question': 'Package manager untuk Dart dan Flutter?',
      'answers': ['npm', 'pub', 'pip', 'mvn'],
      'correctAnswer': 'pub',
    },
    {
      'question': 'Method untuk menambahkan elemen ke List di Dart?',
      'answers': ['add', 'push', 'append', 'insertLast'],
      'correctAnswer': 'add',
    },
    {
      'question': 'Operator yang digunakan untuk membandingkan kesetaraan?',
      'answers': ['==', '=', '===', '!='],
      'correctAnswer': '==',
    },
    {
      'question': 'File konfigurasi utama Flutter untuk dependencies?',
      'answers': [
        'pubspec.yaml',
        'package.json',
        'build.gradle',
        'settings.gradle',
      ],
      'correctAnswer': 'pubspec.yaml',
    },
  ];
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String _selectedAnswer = '';
  // Timer per soal
  static const int _timePerQuestion =
      15; // detik per soal (ubah sesuai kebutuhan)
  int _remainingSeconds = _timePerQuestion;
  Timer? _timer;
  // Toggle apakah koreksi jawaban (menandai jawaban benar/salah) ditampilkan.
  // Ubah nilai ini di kode untuk mengaktifkan/non-aktifkan koreksi.
  //
  // =======================
  static const bool _showCorrectAnswer = true;
  //========================
  //
  void _checkAnswer(String answer) {
    if (_isAnswered) return; // supaya tidak double tap
    // stop timer when user answers
    _cancelTimer();
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      if (answer == _questions[_currentIndex]['correctAnswer']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    // move to next question and restart timer
    setState(() {
      _currentIndex++;
      _isAnswered = false;
      _selectedAnswer = '';
      _remainingSeconds = _timePerQuestion;
    });
    // start timer for next question if any
    if (_currentIndex < _questions.length) {
      _startTimer();
    }
  }

  void _restartQuiz() {
    _cancelTimer();
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isAnswered = false;
      _selectedAnswer = '';
      _remainingSeconds = _timePerQuestion;
    });
    _startTimer();
  }

  void _startTimer() {
    _cancelTimer();
    _remainingSeconds = _timePerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }
        if (_remainingSeconds == 0) {
          _cancelTimer();
          _handleTimeUp();
        }
      });
    });
  }

  void _cancelTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _timer = null;
  }

  void _handleTimeUp() {
    if (_isAnswered) return; // already answered
    setState(() {
      _isAnswered = true;
      _selectedAnswer = ''; // user didn't select
      // score unchanged
    });
    // show a brief snackbar to inform user (if context still mounted)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu habis! Pertanyaan dianggap salah.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    // auto-advance after short delay if not last question
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        _nextQuestion();
      } else {
        // go to result screen
        setState(() {
          _currentIndex = _questions.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // start timer for first question
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Quiz'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _score >= (_questions.length / 2)
                    ? Icons.emoji_events
                    : Icons.sentiment_dissatisfied,
                size: 72,
                color: _score >= (_questions.length / 2)
                    ? Colors.amber
                    : Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Skor Anda: $_score / ${_questions.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _score >= (_questions.length / 2)
                    ? 'Bagus! Anda lulus.'
                    : 'Coba lagi untuk memperbaiki skor.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _restartQuiz,
                icon: const Icon(Icons.replay),
                label: const Text('Ulangi Quiz'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final currentQuestion = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Quiz Pilihan Ganda'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pertanyaan ${_currentIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text('Skor: $_score'),
                  avatar: const Icon(Icons.star, color: Colors.white, size: 18),
                  backgroundColor: Colors.deepPurpleAccent,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              color: Colors.deepPurpleAccent,
              backgroundColor: Colors.deepPurple.shade100,
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            // Timer row
            Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Sisa waktu: $_remainingSeconds s',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _remainingSeconds / _timePerQuestion,
                    color: _remainingSeconds <= 5
                        ? Colors.redAccent
                        : Colors.green,
                    backgroundColor: Colors.grey.shade300,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Animated question card
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey<int>(_currentIndex),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // use withAlpha to avoid withOpacity deprecation warning
                  color: Theme.of(context).colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      // avoid withOpacity deprecation warning
                      color: Colors.black.withAlpha(8),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Decorative image/logo on the left
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: FlutterLogo(size: 48),
                    ),
                    Expanded(
                      child: Text(
                        currentQuestion['question'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Animated answers list
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Column(
                key: ValueKey<int>(_currentIndex),
                children: [
                  ...(currentQuestion['answers'] as List<String>)
                      .asMap()
                      .entries
                      .map((entry) {
                        final idx = entry.key;
                        final answer = entry.value;
                        final isCorrect =
                            answer == currentQuestion['correctAnswer'];
                        final isSelected = answer == _selectedAnswer;

                        // base colors for options when not answered
                        final List<Color> baseColors = [
                          Colors.indigo,
                          Colors.teal,
                          Colors.orange,
                          Colors.pink,
                        ];

                        final Color base = baseColors[idx % baseColors.length];
                        Color buttonColor = base;
                        Color textColor = Colors.white;

                        if (_isAnswered) {
                          if (!_showCorrectAnswer) {
                            // jika koreksi dimatikan, semua opsi netral setelah dijawab
                            buttonColor = Colors.grey.shade200;
                            textColor = Colors.black87;
                          } else {
                            if (isSelected && isCorrect) {
                              buttonColor = Colors.green;
                              textColor = Colors.white;
                            } else if (isSelected && !isCorrect) {
                              buttonColor = Colors.redAccent;
                              textColor = Colors.white;
                            } else if (!isSelected && isCorrect) {
                              // reveal correct answer
                              buttonColor = Colors.green.shade200;
                              textColor = Colors.black;
                            } else {
                              buttonColor = Colors.grey.shade200;
                              textColor = Colors.black87;
                            }
                          }
                        }

                        // letter label for option (A, B, C, ...)
                        final String letter = String.fromCharCode(65 + idx);

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: buttonColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                if (!_isAnswered)
                                  BoxShadow(
                                    color: base.withAlpha(30),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _isAnswered
                                    ? null
                                    : () => _checkAnswer(answer),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.white24,
                                        child: Text(
                                          letter,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          answer,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: textColor,
                                            fontWeight:
                                                (isSelected &&
                                                    _showCorrectAnswer)
                                                ? FontWeight.w700
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (_isAnswered &&
                                          isSelected &&
                                          _showCorrectAnswer)
                                        Icon(
                                          isCorrect
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_isAnswered && _currentIndex < _questions.length - 1)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Pertanyaan Selanjutnya'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              )
            else if (_isAnswered && _currentIndex == _questions.length - 1)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.check),
                  label: const Text('Lihat Hasil'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
