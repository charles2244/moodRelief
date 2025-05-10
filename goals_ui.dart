import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/create_goal_strategy.dart';
import '../controller/goal_strategy.dart';
import '../controller/select_goals_strategy.dart';
import '../services/goals_service.dart';
import 'goals_history.dart';
import 'select_goal_page.dart';


class GoalsPage extends StatefulWidget {
  final int userId;
  const GoalsPage({super.key, required this.userId});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late final GoalsDatabase _goalsDatabase;
  List<Map<String, dynamic>> _userGoals = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? expandedIndex;
  int? _userId;

  @override
  void initState() {
    super.initState();
    print('Loading GoalsPage for userId: ${widget.userId}');
    _goalsDatabase = GoalsDatabase(
      selectGoalStrategy: SupabaseSelectGoalStrategy(),
      createGoalStrategy: SupabaseCreateGoalStrategy(),
      goalStrategy: SupabaseGoalStrategy(),
    );
    _loadUserGoals();
  }

  Future<void> _loadUserGoals() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Remove int.parse() since widget.userId is already int
      final goals = await _goalsDatabase.getUserGoals(widget.userId);

      await _loadAchievement(widget.userId);

      setState(() {
        _userGoals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load goals: $e';
      });
    }
  }
  Future<void> _loadAchievement(int userId) async {
    final achievementResult = await _goalsDatabase.checkAchievement(userId);
    final title = achievementResult?['Achievement title'];

    print(title);

    if (title != null) {
      // 3. pop up achievement unlocked banner
      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
        ..showMaterialBanner(
          MaterialBanner(
            content: Text('Achievement Unlocked: $title'),
            backgroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () {}, // not do anything
                child: SizedBox.shrink(), // empty widget，cannot see
              ),
            ],
          ),
        );

      // 4. delay 2 sec auto hide the banner
      await Future.delayed(Duration(seconds: 5));
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    }
  }

  void _showConfirmDialog({
    required String message,
    required IconData icon,
    required VoidCallback onYes,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Image.asset(
                      'assets/rabbitabc.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 130,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('No', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onYes();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Yes', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage(String imagePath, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imagePath,
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _showEditGoalDialog(Map<String, dynamic> goal) {
    final TextEditingController titleController =
    TextEditingController(text: goal['goaltitle']);
    final TextEditingController descriptionController =
    TextEditingController(text: goal['goaldescription']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 400,
            minWidth: 300,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Goal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter new title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        _showConfirmDialog(
                          message: "Save changes to this goal?",
                          icon: Icons.edit_note,
                          onYes: () async {
                            try {
                              await _goalsDatabase.createGoalStrategy.updateGoal(
                                goal['goalid'],
                                titleController.text,
                                descriptionController.text,
                              );
                              _loadUserGoals();
                              _showSuccessMessage('https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//goal_update.png', 'Goal Updated');
                            } catch (e) {
                              _showSuccessMessage('assets/lg_672375_1631068111_61381fcf8e38b-removebg-preview.png', 'Failed to update goal');
                            }
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Edit'),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF975EE0),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/home'),
              child: Image.network(
                'https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//homeIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/gift'),
              child: Image.network(
                'https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//RewardsIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/target'),
              child: Image.network(
                'https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//GoalsIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Image.network(
                'https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//ProfileIcon.png',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.purple),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      Image.network(
                        'https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//unnamed-removebg-preview.png',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Goals',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Image.network(
                        'https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//unnamed-removebg-preview2.png',
                        width: 80,
                        height: 80,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.purple),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectGoalPage(
                            userId: widget.userId.toString(),
                          ),
                        ),
                      ).then((_) => _loadUserGoals());
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _userGoals.isEmpty
                  ? const Center(
                child: Text(
                  'No goals yet. Add some!',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadUserGoals,
                child: ListView.builder(
                  itemCount: _userGoals.length,
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    final goal = _userGoals[index];
                    bool isExpanded = expandedIndex == index;
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.favorite, color: Colors.white),
                            title: Text(
                              goal['goaltitle'] ?? 'No title',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            onTap: () {
                              setState(() {
                                expandedIndex = isExpanded ? null : index;
                              });
                            },
                          ),
                        ),
                        if (isExpanded)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal['goaldescription'] ?? 'No description',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (goal['goalType'] == 'ownGoal')
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _showEditGoalDialog(goal),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _showConfirmDialog(
                                          message: "Are you sure to remove this goal?",
                                          icon: Icons.delete_forever,
                                          onYes: () async {
                                            try {
                                              await _goalsDatabase.removeGoal(goal['goalid']);
                                              _loadUserGoals();
                                              _showSuccessMessage('https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//lg_672375_1631068111_61381fcf8e38b-removebg-preview.png', 'Goal Removed');
                                            } catch (e) {
                                              _showSuccessMessage('https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image//lg_672375_1631068111_61381fcf8e38b-removebg-preview.png', 'Failed to remove goal: $e');
                                            }
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.purple,
                                      ),
                                      child: const Text('Remove'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showConfirmDialog(
                                          message: "Are you sure you have completed the task?",
                                          icon: Icons.check_circle_outline,
                                          onYes: () async {
                                            await _goalsDatabase.completeGoal(
                                              goal['goalid'],
                                              widget.userId.toString(),
                                            );
                                            final pointsAwarded = goal['pointsawarded'] ?? 0;
                                            await _loadUserGoals();
                                            _showSuccessMessage(
                                              'https://qnvoajikwadxpgertimm.supabase.co/storage/v1/object/public/image/pngtree-cute-rabbit-cartoon-eating-carrot-png-image_6104181.png',
                                              '$pointsAwarded Points Awarded',
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple[500],
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Complete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalHistoryPage(
                        userId: widget.userId.toString(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View History',
                  style: TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.bold,
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