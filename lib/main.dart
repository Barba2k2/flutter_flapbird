import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Flappy Bird',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
              child: const Text(
                'Jogar',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScoreScreen()),
                );
              },
              child: const Text(
                'Pontuações',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  List<Map<String, dynamic>> scores = [];

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedScores = prefs.getStringList('scores');

    if (savedScores != null) {
      setState(() {
        scores = savedScores.map((score) {
          final parts = score.split(':');
          return {
            'score': int.parse(parts[0]),
            'time': int.parse(parts[1]),
            'date': parts[2],
          };
        }).toList();

        scores.sort((a, b) => b['score'].compareTo(a['score']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Melhores Pontuações'),
        backgroundColor: Colors.green,
      ),
      body: scores.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma pontuação ainda!',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            )
          : ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final score = scores[index];
                return ListTile(
                  title: Text(
                    'Pontos: ${score['score']}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  subtitle: Text(
                    'Tempo: ${(score['time'] / 1000).toStringAsFixed(1)}s\nData: ${score['date']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static double birdY = 0;
  double initialPos = birdY;
  double height = 0;
  double time = 0;
  double gravity = -4.9;
  double velocity = 3.5;
  bool gameHasStarted = false;

  int score = 0;
  int elapsedTime = 0;
  late DateTime startTime;

  final double birdWidth = 50;
  final double birdHeight = 50;
  final double barrierWidth = 50;
  double gameSpeed = 0.02;

  List<double> barrierX = [2, 3.5];
  List<List<double>> barrierHeight = [
    [0.6, 0.4],
    [0.4, 0.6],
  ];

  Timer? gameTimer;
  Timer? scoreTimer;

  void startGame() {
    gameHasStarted = true;
    startTime = DateTime.now();

    birdY = 0;
    initialPos = 0;
    time = 0;
    score = 0;
    elapsedTime = 0;
    barrierX = [2, 3.5];

    gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        height = gravity * time * time + velocity * time;
        setState(() {
          birdY = initialPos - height;
          elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
          moveBarriers();

          if (checkCollision()) {
            timer.cancel();
            scoreTimer?.cancel();
            saveScore();
            _showDialog();
            return;
          }
        });

        time += 0.016;

        gameSpeed = 0.02 + (score / 100) * 0.01;
      },
    );

    scoreTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (timer) {
        setState(() {
          score++;
        });
      },
    );
  }

  final bool debugMode = true;

  final double pipeWidth = 60.0;
  final double birdSize = 50.0;

  bool checkCollision() {
    if (birdY < -0.95 || birdY > 0.95) {
      return true;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final birdXInPixels = screenWidth / 2;
    final birdYInPixels = ((birdY + 1) / 2) * screenHeight;

    final birdLeft = birdXInPixels - birdSize / 2;
    final birdRight = birdXInPixels + birdSize / 2;
    final birdTop = birdYInPixels - birdSize / 2;
    final birdBottom = birdYInPixels + birdSize / 2;

    for (int i = 0; i < barrierX.length; i++) {
      final pipeXInPixels = ((barrierX[i] + 1) / 2) * screenWidth;

      final pipeLeft = pipeXInPixels - pipeWidth / 2;
      final pipeRight = pipeXInPixels + pipeWidth / 2;

      if (birdRight > pipeLeft && birdLeft < pipeRight) {
        final topPipeHeight = barrierHeight[i][0] * screenHeight * 0.4;
        final bottomPipeStartY = screenHeight * (1 - barrierHeight[i][1] * 0.4);

        if (birdTop < topPipeHeight) {
          return true;
        }

        if (birdBottom > bottomPipeStartY) {
          return true;
        }
      }
    }
    return false;
  }

  void moveBarriers() {
    for (int i = 0; i < barrierX.length; i++) {
      setState(() {
        barrierX[i] -= gameSpeed;

        if (barrierX[i] < -2) {
          barrierX[i] += 4;

          double minHeight = 0.3;
          double maxHeight = 0.5;
          double gap = 0.3;

          double topHeight = minHeight +
              (maxHeight - minHeight) *
                  (DateTime.now().millisecondsSinceEpoch % 100) /
                  100;

          barrierHeight[i] = [topHeight, 1.0 - topHeight - gap];
        }
      });
    }
  }

  void jump() {
    setState(() {
      time = 0;
      initialPos = birdY;
    });
  }

  Future<void> saveScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedScores = prefs.getStringList('scores') ?? [];

      final now = DateTime.now();
      final scoreString =
          '$score:$elapsedTime:${now.day}/${now.month}/${now.year}';

      savedScores.add(scoreString);
      await prefs.setStringList('scores', savedScores);
    } catch (e) {
      debugPrint('Erro ao salvar pontuação: $e');
    }
  }

  void resetGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.brown,
          title: const Text(
            "Game Over",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pontuação: $score",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "Tempo: ${(elapsedTime / 1000).toStringAsFixed(1)}s",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                "Menu",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MenuScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            TextButton(
              child: const Text(
                "Jogar Novamente",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                resetGame();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    scoreTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (gameHasStarted) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.blue),
                  AnimatedContainer(
                    duration: Duration.zero,
                    alignment: Alignment(0, birdY),
                    child: SizedBox(
                      width: birdWidth,
                      height: birdHeight,
                      child: const Bird(),
                    ),
                  ),
                  ...barrierX
                      .asMap()
                      .entries
                      .map((entry) {
                        int i = entry.key;
                        double x = entry.value;
                        return [
                          AnimatedContainer(
                            duration: Duration.zero,
                            alignment: Alignment(x, -1.1),
                            child: Barrier(
                              size: barrierHeight[i][0],
                              isBottom: false,
                            ),
                          ),
                          AnimatedContainer(
                            duration: Duration.zero,
                            alignment: Alignment(x, 1.1),
                            child: Barrier(
                              size: barrierHeight[i][1],
                              isBottom: true,
                            ),
                          ),
                        ];
                      })
                      .expand((x) => x)
                      .toList(),
                  if (debugMode)
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bird Y: ${birdY.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Barrier X: [${barrierX.map((x) => x.toStringAsFixed(2)).join(", ")}]',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 50,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pontos: $score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tempo: ${(elapsedTime / 1000).toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!gameHasStarted)
                    const Center(
                      child: Text(
                        'TOQUE PARA COMEÇAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Bird extends StatelessWidget {
  const Bird({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
      ),
    );
  }
}

class Barrier extends StatelessWidget {
  final double size;
  final bool isBottom;

  const Barrier({
    super.key,
    required this.size,
    required this.isBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: size * MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.green,
        border: Border.all(
          width: 4,
          color: Colors.green.shade800,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
