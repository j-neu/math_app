import 'package:flutter/material.dart';
import 'package:math_app/main.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/services/user_service.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final UserService _userService = UserService();
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    print('=== UserSelectionScreen._loadUsers() START ===');
    setState(() => _isLoading = true);
    final users = await _userService.getAllUsers();
    print('=== UserSelectionScreen._loadUsers() - Got ${users.length} users ===');
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _showCreateUserDialog() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController(text: '6');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter child\'s name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text.trim()) ?? 6;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }

                Navigator.of(context).pop({
                  'name': name,
                  'age': age,
                });
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final newUser = UserProfile(
        id: _userService.generateUserId(),
        name: result['name'] as String,
        age: result['age'] as int,
        skillTags: [],
      );

      print('=== UserSelectionScreen - Creating new user: ${newUser.name} (id: ${newUser.id}) ===');
      await _userService.saveUser(newUser);
      print('=== UserSelectionScreen - User saved, reloading list ===');
      await _loadUsers();
      print('=== UserSelectionScreen - Navigating to HomeScreen ===');

      // Navigate to HomeScreen for the new user
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HomeScreen(userProfile: newUser),
          ),
        );
        // Reload when coming back
        _loadUsers();
      }
    }
  }

  void _selectUser(UserProfile user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomeScreen(userProfile: user),
      ),
    );
    // Reload users when coming back (user data may have changed)
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Who is learning today?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // List of existing users
                  if (_users.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first user to get started!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                user.diagnosticProgress != null
                                    ? 'Diagnostic in progress (Question ${user.diagnosticProgress! + 1})'
                                    : user.skillTags.isEmpty
                                        ? 'New user - Start diagnostic test'
                                        : '${user.skillTags.length} skills to practice',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _selectUser(user),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Add new user button
                  ElevatedButton.icon(
                    onPressed: _showCreateUserDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add New User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Start without diagnostic button (for testing)
                  OutlinedButton.icon(
                    onPressed: _showSkipDiagnosticDialog,
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('Start Without Diagnostic (Not Recommended)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[700]!, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showSkipDiagnosticDialog() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController(text: '6');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Expanded(child: Text('Skip Diagnostic Test')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'This will create a user with ALL 88 skills to practice. This is intended for testing exercises, not for actual learning.',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter child\'s name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text.trim()) ?? 6;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }

                Navigator.of(context).pop({
                  'name': name,
                  'age': age,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Create (Skip Diagnostic)'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      // Create list of ALL 88 skills from the taxonomy
      final allSkills = [
        // Counting skills (11)
        'counting_1', 'counting_2', 'counting_3', 'counting_4', 'counting_5',
        'counting_6', 'counting_7', 'counting_8', 'counting_9', 'counting_10', 'counting_11',
        // Decomposition skills (16, but skill 14 doesn't exist in taxonomy)
        'decomposition_1', 'decomposition_2', 'decomposition_3', 'decomposition_4', 'decomposition_5',
        'decomposition_6', 'decomposition_7', 'decomposition_8', 'decomposition_9', 'decomposition_10',
        'decomposition_11', 'decomposition_12', 'decomposition_13', 'decomposition_15', 'decomposition_16',
        // Place value skills (6)
        'place_value_1', 'place_value_2', 'place_value_3', 'place_value_4', 'place_value_5', 'place_value_6',
        // Basic strategy skills (23)
        'basic_strategy_1', 'basic_strategy_2', 'basic_strategy_3', 'basic_strategy_4', 'basic_strategy_5',
        'basic_strategy_6', 'basic_strategy_7', 'basic_strategy_8', 'basic_strategy_9', 'basic_strategy_10',
        'basic_strategy_11', 'basic_strategy_12', 'basic_strategy_13', 'basic_strategy_14', 'basic_strategy_15',
        'basic_strategy_16', 'basic_strategy_17', 'basic_strategy_18', 'basic_strategy_19', 'basic_strategy_20',
        'basic_strategy_21', 'basic_strategy_22', 'basic_strategy_23',
        // Combined strategy skills (20)
        'combined_strategy_1', 'combined_strategy_2', 'combined_strategy_3', 'combined_strategy_4', 'combined_strategy_5',
        'combined_strategy_6', 'combined_strategy_7', 'combined_strategy_8', 'combined_strategy_9', 'combined_strategy_10',
        'combined_strategy_11', 'combined_strategy_12', 'combined_strategy_13', 'combined_strategy_14', 'combined_strategy_15',
        'combined_strategy_16', 'combined_strategy_17', 'combined_strategy_18', 'combined_strategy_19', 'combined_strategy_20',
        // PIKAS ordinal skills (2)
        'ordinal_1', 'ordinal_2',
        // PIKAS representation skills (4)
        'representation_1', 'representation_2', 'representation_3', 'representation_4',
        // PIKAS operational sense skills (3)
        'operation_sense_add', 'operation_sense_sub', 'operation_sense_story',
        // PIKAS number line skills (3)
        'number_line_rechenstrich', 'number_line_zahlenstrahl', 'number_line_strategies',
      ];

      final newUser = UserProfile(
        id: _userService.generateUserId(),
        name: result['name'] as String,
        age: result['age'] as int,
        skillTags: allSkills, // All 88 skills
      );

      print('=== UserSelectionScreen - Creating test user with ${allSkills.length} skills: ${newUser.name} (id: ${newUser.id}) ===');
      await _userService.saveUser(newUser);
      print('=== UserSelectionScreen - User saved, reloading list ===');
      await _loadUsers();
      print('=== UserSelectionScreen - Navigating to HomeScreen ===');

      // Navigate to HomeScreen for the new user
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HomeScreen(userProfile: newUser),
          ),
        );
        // Reload when coming back
        _loadUsers();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}