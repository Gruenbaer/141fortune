import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../components/rack.dart';
import '../components/pool_ball.dart';
import '../models/player.dart';
import '../models/inning.dart';

import 'statistics_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  Set<int> _activeRackBalls = {};
  int _foulCount = 0;
  bool _isSafety = false;
  int _pendingPoints = 0;
  int _rackStartCount = 15;

  @override
  void initState() {
    super.initState();
    _resetRack(15);
  }

  int? _lastKnownBallCount;

  void _resetRack(int count, {bool isUndoReset = false}) {
    // Only reset ball positions on undo - otherwise keep existing balls stable
    if (isUndoReset) {
      setState(() {
        _activeRackBalls = Set.from(Iterable.generate(count));
        _rackStartCount = count;
        _lastKnownBallCount = count;
      });
    }
  }

  void _toggleRackBall(int idx) {
    setState(() {
      if (_activeRackBalls.contains(idx)) {
        if (_activeRackBalls.length <= 1) return;
        _activeRackBalls.remove(idx);
      } else {
        _activeRackBalls.add(idx);
      }
    });
  }

  void _onPotAllRack() {
    setState(() {
      final newSet = <int>{};
      if (_activeRackBalls.contains(0)) {
        newSet.add(0);
      } else if (_activeRackBalls.isNotEmpty) {
        newSet.add(_activeRackBalls.first);
      }
      _activeRackBalls = newSet;
    });
  }

  void _onRestoreAllRack() {
    setState(() {
      _activeRackBalls = Set.from(Iterable.generate(15));
    });
  }

  void _onReRackPress() {
    final pointsToAdd = _rackStartCount - _activeRackBalls.length;
    setState(() {
      _pendingPoints += pointsToAdd;
      // Don't reset balls - only update baseline count
      _rackStartCount = 15;
      _lastKnownBallCount = 15;
    });
  }

  void _onAcceptPress(GameProvider provider) {
    final diff = _rackStartCount - _activeRackBalls.length;
    final currentRun = _pendingPoints + diff;

    // Check for break foul (foul on first shot of rack)
    final isBreakFoul = _foulCount > 0 && provider.inningHistory.isEmpty;
    
    if (isBreakFoul) {
      _showBreakFoulDialog(context, provider);
      return;
    }

    // Check victory BEFORE turn switches
    final currentPlayer = provider.turn == 1 ? provider.player1 : provider.player2;
    final currentGoal = provider.turn == 1 ? provider.gameSettings.goalP1 : provider.gameSettings.goalP2;
    final willWin = (currentPlayer.score + currentRun) >= currentGoal;

    provider.processTurn141(
      points: currentRun > 0 ? currentRun : 0,
      foulPoints: _foulCount,
      isSafety: _isSafety,
      shouldSwitchTurn: true,
      newBallsOnTable: _activeRackBalls.length,
    );

    setState(() {
      _pendingPoints = 0;
      _foulCount = 0;
      _isSafety = false;
    });

    if (willWin) {
      // Delay slightly to let UI update before showing dialog
      Future.delayed(const Duration(milliseconds: 100), () {
        _showScorecard(context, provider);
      });
    } else {
      // RESET local baseline for the next player so their run starts at 0
      setState(() {
        _rackStartCount = _activeRackBalls.length;
      });
    }
  }

  void _showBreakFoulDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF7F1D1D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red, width: 2),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.amber, size: 64),
              const SizedBox(height: 16),
              const Text(
                "BREAK FOUL",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "-2",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Apply -2 penalty
                  provider.processTurn141(
                    points: 0,
                    foulPoints: 2,
                    isSafety: false,
                    shouldSwitchTurn: true,
                    newBallsOnTable: _activeRackBalls.length,
                  );
                  
                  setState(() {
                    _foulCount = 0;
                    _pendingPoints = 0;
                    _isSafety = false;
                  });
                  
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("OK", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final p1 = provider.player1;
    final p2 = provider.player2;
    final turn = provider.turn;
    
    // Sync ball count on undo (when provider's ballsOnTable changes externally)
    if (_pendingPoints == 0 && 
        _lastKnownBallCount != null && 
        provider.ballsOnTable != _lastKnownBallCount &&
        provider.ballsOnTable != _activeRackBalls.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _resetRack(provider.ballsOnTable, isUndoReset: true);
        }
      });
    }
    
    final diff = _rackStartCount - _activeRackBalls.length;
    final currentRun = _pendingPoints + diff;
    final reRackNeeded = _activeRackBalls.length == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerCard(p1, turn == 1, const Color(0xFF22C55E), provider, currentRun),
                  _buildCenterStats(totalBallsPotted: p1.score + p2.score + currentRun, provider: provider),
                  _buildPlayerCard(p2, turn == 2, const Color(0xFF3B82F6), provider, currentRun),
                ],
              ),
            ),
            
            // Table Area
            Container(
              height: 450,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF14532D),
                border: Border.symmetric(
                  horizontal: BorderSide(color: Color(0xFF713F12), width: 8),
                ),
              ),
              child: Stack(
                children: [
                  // Details Buttons
                  Positioned(
                    top: 12,
                    left: 16,
                    child: _buildDetailsButton(context, provider),
                  ),
                  Positioned(
                    top: 12,
                    right: 16,
                    child: _buildDetailsButton(context, provider),
                  ),
                   // Break Ball Spot
                  Positioned(
                    top: 100,
                    left: 20,
                    child: Column(
                      children: [
                        Text(provider.t('breakBall').toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _toggleRackBall(0),
                          child: PoolBall(number: 1, size: 50, isPotted: !_activeRackBalls.contains(0)),
                        ),
                      ],
                    ),
                  ),
                  
                  // Rack
                  Rack(
                    ballsOnTable: 15,
                    activeBalls: _activeRackBalls,
                    onToggle: _toggleRackBall,
                    is141Mode: true,
                  ),
                  
                  // Pot/Restore Rack Buttons
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _onPotAllRack,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(provider.t('potAll').toUpperCase(), style: const TextStyle(color: Colors.white, letterSpacing: 1, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _onRestoreAllRack,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(provider.t('restoreAll').toUpperCase(), style: const TextStyle(color: Colors.white, letterSpacing: 1, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Toggles
                  Row(
                    children: [
                      Expanded(
                        child: _buildToggleButton(
                          provider.t('foul').toUpperCase(),
                          "$_foulCount",
                          _foulCount > 0,
                          const Color(0xFFEF4444),
                          () => setState(() => _foulCount = (_foulCount + 1) % 3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildToggleButton(
                          provider.t('safety').toUpperCase(),
                          _isSafety ? provider.t('on').toUpperCase() : provider.t('off').toUpperCase(),
                          _isSafety,
                          const Color(0xFF3B82F6),
                          () => setState(() => _isSafety = !_isSafety),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Commit Actions
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: provider.inningHistory.isEmpty ? null : provider.undoLastTurn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF374151),
                            foregroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.undo, size: 20),
                              const SizedBox(width: 8),
                              Text(provider.t('undo').toUpperCase(), style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 90,
                        child: ElevatedButton(
                          onPressed: reRackNeeded ? _onReRackPress : () => _onAcceptPress(provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: reRackNeeded ? const Color(0xFFFBBF24) : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (reRackNeeded ? "RE-RACK" : provider.t('accept')).toUpperCase(), 
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                              ),
                              Text(
                                reRackNeeded 
                                  ? "${provider.t('continueGame')} (+$diff)" 
                                  : "${provider.t('history')} (+$currentRun)", 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player p, bool isActive, Color activeColor, GameProvider provider, int currentRun) {
    return Column(
      children: [
        Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: activeColor, width: 2) : null,
          ),
          child: Column(
            children: [
              Text(p.name, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              Text("${p.score}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (isActive && currentRun > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Text(
              "+$currentRun",
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 22, // Double sized as requested
                fontWeight: FontWeight.bold
              ),
            ),
          )
        else
          const SizedBox(height: 38), // Placeholder to keep layout stable
      ],
    );
  }

  Widget _buildCenterStats({required int totalBallsPotted, required GameProvider provider}) {
    return Column(
      children: [
        Text(provider.t('rack').toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        Text("${(totalBallsPotted ~/ 14) + 1}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showScorecard(BuildContext context, GameProvider provider) {
    final winner = provider.turn == 1 ? provider.player1 : provider.player2;
    final loser = provider.turn == 1 ? provider.player2 : provider.player1;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Victory Splash
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.rotate(
                            angle: (1 - value) * 0.5,
                            child: child,
                          ),
                        );
                      },
                      child: const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "🎉 VICTORY! 🎉",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winner.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "won the match!",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Score Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreDetail(winner.name, winner.score, Colors.amber),
                    Container(
                      height: 60,
                      width: 2,
                      color: Colors.white12,
                    ),
                    _buildScoreDetail(loser.name, loser.score, const Color(0xFF3B82F6)),
                  ],
                ),
              ),
              
              const Divider(color: Colors.white12, height: 1),
              
              // Scoresheet Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "14.1 SCORE SHEET",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              // Scrollable Inning Table
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Table(
                      border: TableBorder.all(color: Colors.white12, width: 1),
                      columnWidths: const {
                        0: FixedColumnWidth(50),
                        1: FlexColumnWidth(2),
                        2: FixedColumnWidth(60),
                        3: FlexColumnWidth(2),
                        4: FixedColumnWidth(60),
                      },
                      children: [
                        // Header Row
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFF1F2937)),
                          children: [
                            _buildTableHeader("Inn."),
                            _buildTableHeader(provider.player1.name),
                            _buildTableHeader("Total"),
                            _buildTableHeader(provider.player2.name),
                            _buildTableHeader("Total"),
                          ],
                        ),
                        // Inning Rows (reversed to show newest first)
                        ...List.generate(provider.inningHistory.length, (index) {
                          final inning = provider.inningHistory[provider.inningHistory.length - 1 - index];
                          final inningNum = provider.inningHistory.length - index;
                          
                          return TableRow(
                            children: [
                              _buildTableCell(inningNum.toString(), isCenter: true),
                              _buildTableCell(
                                inning.player == 1 
                                  ? "${inning.points}${inning.penalty > 0 ? ' (-${inning.penalty})' : ''}" 
                                  : "",
                              ),
                              _buildTableCell(
                                inning.player == 1 ? inning.total.toString() : "",
                                isCenter: true,
                                isBold: true,
                              ),
                              _buildTableCell(
                                inning.player == 2 
                                  ? "${inning.points}${inning.penalty > 0 ? ' (-${inning.penalty})' : ''}" 
                                  : "",
                              ),
                              _buildTableCell(
                                inning.player == 2 ? inning.total.toString() : "",
                                isCenter: true,
                                isBold: true,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.bar_chart),
                        label: Text(provider.t('statistics').toUpperCase()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop(); // Go back to Home
                        },
                        icon: const Icon(Icons.home),
                        label: Text(provider.t('restart').toUpperCase()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isCenter = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildScoreDetail(String name, int score, Color color) {
    return Column(
      children: [
        Text(name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text("$score", style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildToggleButton(String label, String value, bool isActive, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : const Color(0xFF1F2937),
          border: Border.all(color: isActive ? activeColor : const Color(0xFF374151), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(color: isActive ? activeColor : Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsButton(BuildContext context, GameProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          provider.t('history').toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }
}
