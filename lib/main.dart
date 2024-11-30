import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
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

  static List<double> barrierX = [2, 3.5];
  static double barrierWidth = 0.5;
  List<List<double>> barrierHeight = [
    [0.6, 0.4],
    [0.4, 0.6],
  ];

  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      height = gravity * time * time + velocity * time;
      setState(() {
        birdY = initialPos - height;
      });

      if (birdDead()) {
        timer.cancel();
        gameHasStarted = false;
        _showDialog();
      }

      moveMap();

      time += 0.05;
    });
  }

  void moveMap() {
    for (int i = 0; i < barrierX.length; i++) {
      setState(() {
        barrierX[i] -= 0.05;
      });

      if (barrierX[i] < -1.5) {
        barrierX[i] += 3;
      }
    }
  }

  void jump() {
    setState(() {
      time = 0;
      initialPos = birdY;
    });
  }

  bool birdDead() {
    if (birdY < -1 || birdY > 1) {
      return true;
    }

    for (int i = 0; i < barrierX.length; i++) {
      if (barrierX[i] <= 0.25 &&
          barrierX[i] + barrierWidth >= -0.25 &&
          (birdY <= -1 + barrierHeight[i][0] ||
              birdY >= 1 - barrierHeight[i][1])) {
        return true;
      }
    }
    return false;
  }

  void resetGame() {
    setState(() {
      birdY = 0;
      gameHasStarted = false;
      time = 0;
      initialPos = birdY;
      barrierX = [2, 3.5];
    });
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Game Over"),
          content: const Text("Quer jogar novamente?"),
          actions: [
            TextButton(
              child: const Text("Jogar"),
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
            )
          ],
        );
      },
    );
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
              flex: 3,
              child: Container(
                color: Colors.blue,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        alignment: Alignment(0, birdY),
                        child: const Bird(),
                      ),
                      Container(
                        alignment: Alignment(barrierX[0], 1.1),
                        child: Barrier(
                          size: barrierHeight[0][0],
                        ),
                      ),
                      Container(
                        alignment: Alignment(barrierX[0], -1.1),
                        child: Barrier(
                          size: barrierHeight[0][1],
                        ),
                      ),
                      Container(
                        alignment: Alignment(barrierX[1], 1.1),
                        child: Barrier(
                          size: barrierHeight[1][0],
                        ),
                      ),
                      Container(
                        alignment: Alignment(barrierX[1], -1.1),
                        child: Barrier(
                          size: barrierHeight[1][1],
                        ),
                      ),
                      Container(
                        alignment: const Alignment(0, -0.3),
                        child: Text(
                          gameHasStarted ? '' : 'TOQUE PARA COMEÇAR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
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

class Bird extends StatelessWidget {
  const Bird({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
      ),
    );
  }
}

class Barrier extends StatelessWidget {
  final double size;

  const Barrier({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: size * MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.green,
        border: Border.all(width: 4, color: Colors.green.shade800),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
