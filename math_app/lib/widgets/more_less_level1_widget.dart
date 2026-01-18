import 'dart:math';
import 'package:flutter/material.dart';

class MoreLessLevel1Widget extends StatefulWidget {
  final Function(bool isWin) onRoundComplete;
  final int totalRounds;

  const MoreLessLevel1Widget({
    Key? key,
    required this.onRoundComplete,
    required this.totalRounds,
  }) : super(key: key);

  @override
  _MoreLessLevel1WidgetState createState() => _MoreLessLevel1WidgetState();
}

enum GamePhase { rolling, evaluating, calculating, rewarding }

class _MoreLessLevel1WidgetState extends State<MoreLessLevel1Widget> with SingleTickerProviderStateMixin {
  int _childScore = 0;
  int _computerScore = 0;
  int? _childRoll;
  int? _computerRoll;
  GamePhase _phase = GamePhase.rolling;
  String _feedbackMessage = 'Roll the dice!';
  
  // For animation
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _rollDice() {
    setState(() {
      _childRoll = Random().nextInt(6) + 1;
      _computerRoll = Random().nextInt(6) + 1;
      _phase = GamePhase.evaluating;
      _feedbackMessage = 'Who has more?';
    });
    _animController.forward(from: 0.0);
  }

  void _evaluateWinner(bool childSelected) {
    if (_childRoll == null || _computerRoll == null) return;

    bool isDraw = _childRoll == _computerRoll;
    bool childWon = _childRoll! > _computerRoll!;
    bool correctSelection = false;

    if (isDraw) {
      // If draw, user should ideally say "Equal". 
      // For simplicity in this UI, if they click either when equal, we might say "It's equal! Roll again."
      // But let's assume we have an "Equal" button or handle it.
      // Let's implement an "Equal" button.
      return; 
    }

    if (childSelected == childWon) {
      correctSelection = true;
    }

    if (correctSelection) {
      setState(() {
        _phase = GamePhase.calculating;
        _feedbackMessage = 'How many more?';
      });
    } else {
      // Visual feedback for wrong answer?
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Look carefully! Count the dots.')),
      );
    }
  }

  void _evaluateDraw() {
    if (_childRoll == _computerRoll) {
      setState(() {
         // Draw means no points, next round immediately or re-roll?
         // Card says: "Der Spieler, der mehr Plättchen hat..." -> imply nothing happens on draw.
         _feedbackMessage = "It's a tie! No points.";
      });
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
           widget.onRoundComplete(true); // Technically correct interaction
           _resetRound();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not equal! Someone has more.')),
      );
    }
  }

  void _checkDifference(int difference) {
    if (_childRoll == null || _computerRoll == null) return;
    
    int actualDifference = (_childRoll! - _computerRoll!).abs();
    
    if (difference == actualDifference) {
      // Correct!
      setState(() {
        _phase = GamePhase.rewarding;
        if (_childRoll! > _computerRoll!) {
          _childScore += actualDifference;
          _feedbackMessage = 'You get $actualDifference points!';
        } else {
          _computerScore += actualDifference;
          _feedbackMessage = 'Computer gets $actualDifference points!';
        }
      });
      
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          widget.onRoundComplete(true);
          _resetRound();
        }
      });
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Try again! Count the extra dots.')),
      );
    }
  }

  void _resetRound() {
    setState(() {
      _childRoll = null;
      _computerRoll = null;
      _phase = GamePhase.rolling;
      _feedbackMessage = 'Roll the dice!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Score Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreCard('You', _childScore, Colors.blue),
                _buildScoreCard('Computer', _computerScore, Colors.red),
              ],
            ),
          ),
          
          // Feedback
          Text(
            _feedbackMessage,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),

          // Game Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerArea('You', _childRoll, Colors.blue),
              _buildPlayerArea('Computer', _computerRoll, Colors.red),
            ],
          ),
          
          SizedBox(height: 32),

          // Controls
          _buildControls(),
          
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 18, color: color)),
        Text(score.toString(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPlayerArea(String label, int? roll, Color color) {
    return Column(
      children: [
        // Dice
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2,2))],
          ),
          child: roll != null ? Center(child: _buildDiceFace(roll, color)) : Icon(Icons.help_outline, color: Colors.grey.shade300, size: 40),
        ),
        SizedBox(height: 16),
        // Markers (Linear stack for comparison)
        Container(
          width: 60,
          height: 200, // Fixed height for alignment
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: roll != null ? _buildMarkerStack(roll, color) : null,
        ),
      ],
    );
  }
  
  Widget _buildDiceFace(int number, Color color) {
    // Simple text for now, or dots if time permits. Text is clearer for debugging but dots are pedagogical.
    // Let's do dots.
    return CustomPaint(
      size: Size(60, 60),
      painter: DicePainter(number, color),
    );
  }

  Widget _buildMarkerStack(int count, Color color) {
    // Align bottom
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(count, (index) {
        bool isExtra = false;
        if (_phase == GamePhase.calculating || _phase == GamePhase.rewarding) {
           // Highlight difference
           int otherRoll = (color == Colors.blue) ? (_computerRoll ?? 0) : (_childRoll ?? 0);
           if (index >= otherRoll) {
             isExtra = true;
           }
        }
        
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: EdgeInsets.all(4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isExtra ? color : color.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControls() {
    if (_phase == GamePhase.rolling) {
      return ElevatedButton.icon(
        onPressed: _rollDice,
        icon: Icon(Icons.casino),
        label: Text('Roll Dice', style: TextStyle(fontSize: 20)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    } else if (_phase == GamePhase.evaluating) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _evaluateWinner(true),
            child: Text('I have more'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: _evaluateDraw,
            child: Text('Equal'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          ),
           SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _evaluateWinner(false),
            child: Text('Computer has more'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      );
    } else if (_phase == GamePhase.calculating) {
      // Show numbers 1-5
      return Wrap(
        spacing: 8,
        children: List.generate(5, (index) {
          int val = index + 1;
          return ElevatedButton(
            onPressed: () => _checkDifference(val),
            child: Text('$val'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(20),
              shape: CircleBorder(),
            ),
          );
        }),
      );
    } else {
      return SizedBox.shrink(); // Rewarding phase, wait for timeout
    }
  }
}

class DicePainter extends CustomPainter {
  final int number;
  final Color color;
  
  DicePainter(this.number, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width / 10;
    final center = size.center(Offset.zero);
    
    // Standard dice positions
    final positions = <Offset>[];
    
    if (number % 2 == 1) positions.add(center); // Center dot for 1, 3, 5
    if (number >= 2) {
      positions.add(Offset(size.width * 0.2, size.height * 0.2)); // Top Left
      positions.add(Offset(size.width * 0.8, size.height * 0.8)); // Bottom Right
    }
    if (number >= 4) {
      positions.add(Offset(size.width * 0.8, size.height * 0.2)); // Top Right
      positions.add(Offset(size.width * 0.2, size.height * 0.8)); // Bottom Left
    }
    if (number == 6) {
      positions.add(Offset(size.width * 0.2, size.height * 0.5)); // Middle Left
      positions.add(Offset(size.width * 0.8, size.height * 0.5)); // Middle Right
    }
    
    for (var pos in positions) {
      canvas.drawCircle(pos, r, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) => oldDelegate.number != number;
}
