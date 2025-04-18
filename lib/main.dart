import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.isNotEmpty) {
    final windowId = int.tryParse(args[0]);
    runApp(SceneWindow(windowId: windowId ?? 0));
  } else {
    runApp(MainApp());
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talabat Tab & Match',
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF2E8D5),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tap & Match by Talabat',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5E0E),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tap fast. Stack the cart!',
                  style: TextStyle(fontSize: 24, color: Color(0xFF3D1101)),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5E0E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MainGameScreen()),
                    );
                  },
                  child: const Text(
                    'Start Game',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  String currentScene = '';
  Set<String> markedEmojis = {};
  bool showCongratulations = false;
  Map<String, bool> blinkingEmojis = {};

  List<Map<String, dynamic>> availableScenes = [
    {'id': 'kitchen', 'name': 'Kitchen Chaos', 'icon': '🍳'},
    {'id': 'beach', 'name': 'Beach Day', 'icon': '🏖️'},
    {'id': 'study', 'name': 'Study Sesh', 'icon': '📚 '},
    {'id': 'game Night', 'name': 'Game Night', 'icon': '🎉'},
    {'id': 'celebration', 'name': 'Celebration Mode', 'icon': '🎁 '},
    {'id': 'cozy', 'name': 'Cozy Home Night', 'icon': '🏠 '},
  ];

  Map<String, List<Map<String, dynamic>>> sceneEmojis = {
    'kitchen': [
      {'id': 'bread', 'icon': '🍞', 'name': 'Bread'},
      {'id': 'egg', 'icon': '🥚', 'name': 'Egg'},
      {'id': 'salt', 'icon': '🧂', 'name': 'Salt'},
      {'id': 'cheese', 'icon': '🧀', 'name': 'Cheese'},
      {'id': 'milk', 'icon': '🥛', 'name': 'Milk'},
      {'id': 'garlic', 'icon': '🧄', 'name': 'Garlic'},
      {'id': 'tomato', 'icon': '🍅', 'name': 'Tomato'},
      {'id': 'paper_towel', 'icon': '🧻', 'name': 'Paper Towel'},
      {'id': 'knife', 'icon': '🔪', 'name': 'Knife'},
    ],
    'beach': [
      {'id': 'sunscreen', 'icon': '🧴', 'name': 'Sunscreen'},
      {'id': 'juice box', 'icon': '🧃', 'name': 'Juice Box'},
      {'id': 'watermelon', 'icon': '🍉', 'name': 'Watermelon'},
      {'id': 'sunglasses', 'icon': '🕶️', 'name': 'Sunglasses'},
      {'id': 'cap', 'icon': '🧢', 'name': 'Cap'},
      {'id': 'ice cream', 'icon': '🍦', 'name': 'Ice Cream'},
      {'id': 'ice', 'icon': '🧊', 'name': 'Ice'},
      {'id': 'picnic basket', 'icon': '🧺 ', 'name': 'Picnic Basket'},
    ],
    'study': [
      {'id': 'coffee', 'icon': '☕', 'name': 'Coffee'},
      {'id': 'chocolate', 'icon': '🍫', 'name': 'Chocolate'},
      {'id': 'notebook', 'icon': '📒', 'name': 'Notebook'},
      {'id': 'pen', 'icon': '🖊️', 'name': 'Pen'},
      {'id': 'cookies', 'icon': '🍪', 'name': 'Cookies'},
      {'id': 'sandwich', 'icon': '🥪', 'name': 'Sandwich'},
      {'id': 'tissue', 'icon': '🧻', 'name': 'Tissue'},
    ],
    'game Night': [
      {'id': 'pizza', 'icon': '🍕', 'name': 'Pizza'},
      {'id': 'fries', 'icon': '🍟', 'name': 'Fries'},
      {'id': 'juice', 'icon': '🧃', 'name': 'Juice'},
      {'id': 'controller', 'icon': '🎮', 'name': 'Controller'},
      {'id': 'nachos', 'icon': '🧀', 'name': 'Nachos'},
      {'id': 'soda drink', 'icon': '🥤', 'name': 'Soft Drink'},
      {'id': 'popcorn', 'icon': '🍿', 'name': 'Popcorn'},
      {'id': 'burger', 'icon': '🍔', 'name': 'Burger'},
    ],
    'celebration': [
      {'id': 'cake', 'icon': '🎂', 'name': 'Cake'},
      {'id': 'party popper', 'icon': '🎉', 'name': 'Party Popper'},
      {'id': 'balloon', 'icon': '🎈', 'name': 'Balloon'},
      {'id': 'sparkling drink', 'icon': '🍾', 'name': 'Sparkling Drink'},
      {'id': 'lollipop', 'icon': '🍭', 'name': 'Lollipop'},
      {'id': 'cupcake', 'icon': '🧁', 'name': 'Cupcake'},
      {'id': 'sliced cake', 'icon': '🍰', 'name': 'Sliced Cake'},
      {'id': 'gift', 'icon': '🎁', 'name': 'Gift'},
    ],
    'cozy': [
      {'id': 'candle', 'icon': '🕯️', 'name': 'Candle'},
      {'id': 'couch', 'icon': '🛋️', 'name': 'Couch'},
      {'id': 'soup', 'icon': '🍲', 'name': 'Soup'},
      {'id': 'socks', 'icon': '🧦', 'name': 'Socks'},
      {'id': 'TV remote', 'icon': '📺', 'name': 'TV Remote'},
      {'id': 'juice', 'icon': '🧃', 'name': 'Juice'},
      {'id': 'noodles', 'icon': '🍜', 'name': 'Noodles'},
      {'id': 'chocolate', 'icon': '🍫', 'name': 'Chocolate'},
    ],
  };

  Map<String, List<Map<String, dynamic>>> wrongEmojis = {
    'kitchen': [
      {'id': 'dog', 'icon': '🐕', 'name': 'Dog'},
      {'id': 'ball1', 'icon': '⚽', 'name': 'Soccer Ball'},
      {'id': 'ball2', 'icon': '🏀', 'name': 'Basketball'},
      {'id': 'ball3', 'icon': '🏈', 'name': 'Football'},
      {'id': 'ball4', 'icon': '⚾', 'name': 'Baseball'},
      {'id': 'ball5', 'icon': '🎾', 'name': 'Tennis Ball'},
      {'id': 'ball6', 'icon': '🏐', 'name': 'Volleyball'},
      {'id': 'ball7', 'icon': '🥎', 'name': 'Softball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
    ],
    'beach': [
      {'id': 'dog', 'icon': '🐕', 'name': 'Dog'},
      {'id': 'ball1', 'icon': '⚽', 'name': 'Soccer Ball'},
      {'id': 'ball2', 'icon': '🏀', 'name': 'Basketball'},
      {'id': 'ball3', 'icon': '🏈', 'name': 'Football'},
      {'id': 'ball4', 'icon': '⚾', 'name': 'Baseball'},
      {'id': 'ball5', 'icon': '🎾', 'name': 'Tennis Ball'},
      {'id': 'ball6', 'icon': '🏐', 'name': 'Volleyball'},
      {'id': 'ball7', 'icon': '🥎', 'name': 'Softball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
    ],
    'study': [
      {'id': 'dog', 'icon': '🐕', 'name': 'Dog'},
      {'id': 'ball1', 'icon': '⚽', 'name': 'Soccer Ball'},
      {'id': 'ball2', 'icon': '🏀', 'name': 'Basketball'},
      {'id': 'ball3', 'icon': '🏈', 'name': 'Football'},
      {'id': 'ball4', 'icon': '⚾', 'name': 'Baseball'},
      {'id': 'ball5', 'icon': '🎾', 'name': 'Tennis Ball'},
      {'id': 'ball6', 'icon': '🏐', 'name': 'Volleyball'},
      {'id': 'ball7', 'icon': '🥎', 'name': 'Softball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
    ],
    'game Night': [
      {'id': 'dog', 'icon': '🐕', 'name': 'Dog'},
      {'id': 'ball1', 'icon': '⚽', 'name': 'Soccer Ball'},
      {'id': 'ball2', 'icon': '🏀', 'name': 'Basketball'},
      {'id': 'ball3', 'icon': '🏈', 'name': 'Football'},
      {'id': 'ball4', 'icon': '⚾', 'name': 'Baseball'},
      {'id': 'ball5', 'icon': '🎾', 'name': 'Tennis Ball'},
      {'id': 'ball6', 'icon': '🏐', 'name': 'Volleyball'},
      {'id': 'ball7', 'icon': '🥎', 'name': 'Softball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
    ],
    'celebration': [
      {'id': 'dog', 'icon': '🐕', 'name': 'Dog'},
      {'id': 'ball1', 'icon': '⚽', 'name': 'Soccer Ball'},
      {'id': 'ball2', 'icon': '🏀', 'name': 'Basketball'},
      {'id': 'ball3', 'icon': '🏈', 'name': 'Football'},
      {'id': 'ball4', 'icon': '⚾', 'name': 'Baseball'},
      {'id': 'ball5', 'icon': '🎾', 'name': 'Tennis Ball'},
      {'id': 'ball6', 'icon': '🏐', 'name': 'Volleyball'},
      {'id': 'ball7', 'icon': '🥎', 'name': 'Softball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
    ],
    'cozy': [
      {'id': 'dog', 'icon': '🐕', 'name': 'Dog'},
      {'id': 'ball1', 'icon': '⚽', 'name': 'Soccer Ball'},
      {'id': 'ball2', 'icon': '🏀', 'name': 'Basketball'},
      {'id': 'ball3', 'icon': '🏈', 'name': 'Football'},
      {'id': 'ball4', 'icon': '⚾', 'name': 'Baseball'},
      {'id': 'ball5', 'icon': '🎾', 'name': 'Tennis Ball'},
      {'id': 'ball6', 'icon': '🏐', 'name': 'Volleyball'},
      {'id': 'ball7', 'icon': '🥎', 'name': 'Softball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
      {'id': 'ball8', 'icon': '🎱', 'name': 'Pool Ball'},
    ],
  };

  List<Map<String, dynamic>> shuffledEmojis = [];

  @override
  void initState() {
    super.initState();
  }

  void openSceneWindow() async {
    final window = await DesktopMultiWindow.createWindow(
      jsonEncode({}),
    );
    window
      ..setFrame(const Offset(700, 300) & const Size(800, 800))
      ..setTitle('Scene Viewer')
      ..show();
    if (currentScene.isNotEmpty) {
      DesktopMultiWindow.invokeMethod(window.windowId, 'update_scene', currentScene);

      // Send the congratulations state to the scene window
      if (showCongratulations) {
        DesktopMultiWindow.invokeMethod(window.windowId, 'show_congratulations', true);
      }
    }
  }

  void selectScene(String scene) {
    setState(() {
      currentScene = scene;
      markedEmojis.clear();
      showCongratulations = false;
      blinkingEmojis.clear();

      // Notify any open third windows about scene change
      for (int i = 1; i < 10; i++) { // Reasonable window ID range
        DesktopMultiWindow.invokeMethod(i, 'update_scene', scene);
        DesktopMultiWindow.invokeMethod(i, 'show_congratulations', false);
      }

      // Shuffle emojis when selecting a new scene
      _shuffleEmojis();
    });
  }

  // Method to shuffle emojis
  void _shuffleEmojis() {
    if (currentScene.isEmpty) return;

    final sceneData = List<Map<String, dynamic>>.from(sceneEmojis[currentScene] ?? []);
    final wrongData = List<Map<String, dynamic>>.from(wrongEmojis[currentScene] ?? []);

    // Combine both lists
    shuffledEmojis = [...sceneData, ...wrongData];

    // Shuffle the combined list
    shuffledEmojis.shuffle();
  }

  void toggleEmoji(String emojiId) {
    final correctIds = sceneEmojis[currentScene]!.map((e) => e['id']).toList();

    if (correctIds.contains(emojiId)) {
      setState(() {
        if (markedEmojis.contains(emojiId)) {
          markedEmojis.remove(emojiId);
        } else {
          markedEmojis.add(emojiId);

          // Check if all correct emojis are found
          if (markedEmojis.length == correctIds.length &&
              markedEmojis.containsAll(correctIds)) {
            showCongratulations = true;

            // Notify all scene windows about congratulations
            for (int i = 1; i < 10; i++) {
              DesktopMultiWindow.invokeMethod(i, 'show_congratulations', true);
            }
          }
        }
      });
    } else {
      // Only blink the wrong emoji that was tapped
      _blinkIncorrectEmoji(emojiId);
    }
  }

  void _blinkIncorrectEmoji(String emojiId) {
    // Make only this specific emoji blink
    setState(() => blinkingEmojis[emojiId] = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => blinkingEmojis[emojiId] = false);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => blinkingEmojis[emojiId] = true);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() => blinkingEmojis[emojiId] = false);
        });
      });
    });
  }

  void resetGame() {
    setState(() {
      currentScene = '';
      markedEmojis.clear();
      showCongratulations = false;
      blinkingEmojis.clear();

      // Reset all scene windows
      for (int i = 1; i < 10; i++) { // Reasonable window ID range
        DesktopMultiWindow.invokeMethod(i, 'reset_window', null);
      }
    });

    // Navigate back to welcome screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (shuffledEmojis.isEmpty && currentScene.isNotEmpty) {
      _shuffleEmojis();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talabat Tab & Match'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Open Scene Viewer',
            onPressed: openSceneWindow,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF2E8D5),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Select a Scene:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 220,
              width: 1100,
              decoration: BoxDecoration(color: Colors.orange,borderRadius: BorderRadius.circular(25)),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: availableScenes.map((scene) {
                    final isSelected = currentScene == scene['id'];
                    return GestureDetector(
                      onTap: () => selectScene(scene['id']),
                      child: Container(
                        width: 160,
                        height: 180,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF5E0E)
                              : const Color(0xFF3D1101),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(scene['icon'],
                                style: const TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            Text(
                              scene['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 30),
            const Text('Find these items:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: shuffledEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = shuffledEmojis[index];
                  final isMarked = markedEmojis.contains(emoji['id']);
                  final isBlinking = blinkingEmojis[emoji['id']] == true;

                  return GestureDetector(
                    onTap: () => toggleEmoji(emoji['id']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBlinking
                            ? Colors.red
                            : isMarked
                            ? const Color(0xFFFF5E0E)
                            : const Color(0xFF3D1101),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji['icon'],
                              style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 5),
                          Text(
                            emoji['name'],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (showCongratulations)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: resetGame, // Changed to use resetGame method
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5E0E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Play Again',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// SceneWindow class for the scene viewer
class SceneWindow extends StatefulWidget {
  int windowId;

  SceneWindow({super.key, required this.windowId});

  @override
  State<SceneWindow> createState() => _SceneWindowState();
}

class _SceneWindowState extends State<SceneWindow> {
  String currentScene = '';
  bool showCongratulations = false;

  // Map scene IDs to appropriate image assets
  Map<String, String> sceneImages = {
    'kitchen': 'assets/images/kitchen.png',
    'beach': 'assets/images/beach.png',
    'study': 'assets/images/study.png',
    'game Night': 'assets/scenes/game_night.png',
    'celebration': 'assets/images/celebration.png',
    'cozy': 'assets/images/cozy_home.png',
  };

  @override
  void initState() {
    super.initState();
    // Set up channel to receive scene updates
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'update_scene') {
        setState(() {
          currentScene = call.arguments as String;
          // Reset congratulations when scene changes
          showCongratulations = false;
        });
      } else if (call.method == 'show_congratulations') {
        setState(() {
          showCongratulations = call.arguments as bool;
        });
      } else if (call.method == 'reset_window') {
        setState(() {
          currentScene = '';
          showCongratulations = false;
        });
      }
      return;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          color: const Color(0xFFF2E8D5),
          width: double.infinity,
          height: double.infinity,
          child: currentScene.isEmpty
              ? const Center(
              child: Text('Please select a scene in the main window',
                  style: TextStyle(fontSize: 18))
          )
              : Center(
            child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Container for Scene Image or Congratulations Message
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.9,
                          maxHeight: constraints.maxHeight * 0.7,
                        ),
                        child: showCongratulations
                            ? _buildCongratulationsCard(constraints)
                            : _buildSceneImage(),
                      ),
                    ],
                  );
                }
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSceneImage() {
    return AspectRatio(
      aspectRatio: 16 / 9, // Keep a consistent aspect ratio
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          sceneImages[currentScene] ?? 'assets/images/placeholder.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildCongratulationsCard(BoxConstraints constraints) {
    // Calculate a responsive width based on the container constraints
    double cardWidth = constraints.maxWidth * 0.8;

    return Container(
      width: cardWidth,
      constraints: const BoxConstraints(
        maxWidth: 600, // Maximum width of the card
        minHeight: 300, // Minimum height to ensure visibility
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFF5E0E), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 10),
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: constraints.maxWidth < 400 ? 24 : 30,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF5E0E),
                ),
              ),
              const SizedBox(width: 10),
              const Text('🎉', style: TextStyle(fontSize: 36)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'You found all the items!',
            style: TextStyle(
              fontSize: constraints.maxWidth < 400 ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D1101),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFF5E0E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 60,
            ),
          ),
        ],
      ),
    );
  }
}