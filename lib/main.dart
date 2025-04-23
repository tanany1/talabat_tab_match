import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  if (args.isNotEmpty) {
    // This is the scene window - just run it normally without window_manager
    final windowId = int.tryParse(args[0]);
    runApp(SceneWindow(windowId: windowId ?? 0));
  } else {
    // Initialize window_manager only for the main window
    await windowManager.ensureInitialized();

    // Configure window_manager for main window
    await windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
      await windowManager.show();
    });

    // Add listener for maximize button
    windowManager.addListener(MyWindowListener());

    runApp(const MainApp());
  }
}

class MyWindowListener extends WindowListener {
  @override
  void onWindowMaximize() async {
    await windowManager.setFullScreen(true);
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
    return const MaterialApp(
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Timer Game.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title/logo image
              Container(
                height: 300,
                width: 500,
                child: Image.asset(
                  'assets/Layer 1.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5), // Spacing
              // Let's Play button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MainGameScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 200,
                  width: 200,
                  child: Image.asset(
                    'assets/LET’S PLAY.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
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
  bool isSceneWindowOpen = false; // Track if scene window is open
  int? sceneWindowId; // Store the window ID
  Timer? gameTimer;
  int secondsElapsed = 0;
  Map<String, bool> showXMarks = {};
  final AudioCache _audioCache = AudioCache();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final formatTime = (int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';


  List<Map<String, dynamic>> availableScenes = [
    {'id': 'kitchen', 'name': 'Kitchen Chaos', 'icon': 'assets/scenes_icons/Kitchenicon.png'},
    {'id': 'beach', 'name': 'Beach Day', 'icon': 'assets/scenes_icons/Beachicon.png'},
    {'id': 'study', 'name': 'Study Sesh', 'icon': 'assets/scenes_icons/Studyicon.png'},
    {'id': 'game Night', 'name': 'Game Night', 'icon': 'assets/scenes_icons/Gamenighticon.png'},
    {'id': 'celebration', 'name': 'Celebration Mode', 'icon': 'assets/scenes_icons/Celebrateicon.png'},
    {'id': 'cozy', 'name': 'Cozy Home', 'icon': 'assets/scenes_icons/Homeicon.png'},
  ];

  Map<String, List<Map<String, dynamic>>> sceneEmojis = {
    'kitchen': [
      {'id': 'bread', 'icon': 'assets/icons/kitchen/Bread.png', 'name': 'Bread'},
      {'id': 'egg', 'icon': 'assets/icons/kitchen/egg.png', 'name': 'Egg'},
      {'id': 'salt', 'icon': 'assets/icons/kitchen/salt.png', 'name': 'Salt'},
      {'id': 'milk', 'icon': 'assets/icons/kitchen/milk.png', 'name': 'Milk'},
      {'id': 'garlic', 'icon': 'assets/icons/kitchen/garlic.png', 'name': 'Garlic'},
      {'id': 'tomato', 'icon': 'assets/icons/kitchen/tomato.png', 'name': 'Tomato'},
      {'id': 'soup', 'icon': 'assets/icons/kitchen/soup.png', 'name': 'Soup'},
      {'id': 'knife', 'icon': 'assets/icons/kitchen/Knife.png', 'name': 'Knife'},
    ],
    'beach': [
      {'id': 'sunscreen', 'icon': 'assets/icons/beach/sunscreen.png', 'name': 'Sunscreen'},
      {'id': 'flipflop', 'icon': 'assets/icons/beach/flipflop.png', 'name': 'Flipflop'},
      {'id': 'juice box', 'icon': 'assets/icons/beach/juice.png', 'name': 'Juice Box'},
      {'id': 'watermelon', 'icon': 'assets/icons/beach/watermelon.png', 'name': 'Watermelon'},
      {'id': 'sunglasses', 'icon': 'assets/icons/beach/sunglasses.png', 'name': 'Sunglasses'},
      {'id': 'cap', 'icon': 'assets/icons/beach/cap.png', 'name': 'Cap'},
      {'id': 'ice cream', 'icon': 'assets/icons/beach/icecream.png', 'name': 'Ice Cream'},
      {'id': 'picnic basket', 'icon': 'assets/icons/beach/basket.png', 'name': 'Picnic Basket'},
    ],
    'study': [
      {'id': 'coffee', 'icon': 'assets/icons/study/coffee.png', 'name': 'Coffee'},
      {'id': 'bubbletea', 'icon': 'assets/icons/study/bubbletea.png', 'name': 'Bubble Tea'},
      {'id': 'biscuits', 'icon': 'assets/icons/study/Biscuits.png', 'name': 'Biscuits'},
      {'id': 'notebook', 'icon': 'assets/icons/study/notebook.png', 'name': 'Notebook'},
      {'id': 'pen', 'icon': 'assets/icons/study/pen.png', 'name': 'Pen'},
      {'id': 'cookies', 'icon': 'assets/icons/study/cookies.png', 'name': 'Cookies'},
      {'id': 'sandwich', 'icon': 'assets/icons/study/sandwich.png', 'name': 'Sandwich'},
      {'id': 'tissue', 'icon': 'assets/icons/study/tissue.png', 'name': 'Tissue'},
    ],
    'game Night': [
      {'id': 'pizza', 'icon': 'assets/icons/game/pizza.png', 'name': 'Pizza'},
      {'id': 'fries', 'icon': 'assets/icons/game/fries.png', 'name': 'Fries'},
      {'id': 'juice', 'icon': 'assets/icons/game/juice.png', 'name': 'Juice'},
      {'id': 'controller', 'icon': 'assets/icons/game/controllers.png', 'name': 'Controller'},
      {'id': 'couch', 'icon': 'assets/icons/game/couch.png', 'name': 'Pizza'},
      {'id': 'soft drink', 'icon': 'assets/icons/game/softdrink.png', 'name': 'Soft Drink'},
      {'id': 'popcorn', 'icon': 'assets/icons/game/popcorn.png', 'name': 'Popcorn'},
      {'id': 'burger', 'icon': 'assets/icons/game/burger.png', 'name': 'Burger'},
    ],
    'celebration': [
      {'id': 'cake', 'icon': 'assets/icons/celebration/cake.png', 'name': 'Cake'},
      {'id': 'balloon', 'icon': 'assets/icons/celebration/balloon.png', 'name': 'Balloon'},
      {'id': 'sparks', 'icon': 'assets/icons/celebration/sparks.png', 'name': 'Sparks'},
      {'id': 'lollipop', 'icon': 'assets/icons/celebration/lolipop.png', 'name': 'Lollipop'},
      {'id': 'cupcake', 'icon': 'assets/icons/celebration/cupcake.png', 'name': 'Cupcake'},
      {'id': 'gift', 'icon': 'assets/icons/celebration/gift.png', 'name': 'Gift'},
    ],
    'cozy': [
      {'id': 'candle', 'icon': 'assets/icons/cozy/Candel.png', 'name': 'Candle'},
      {'id': 'couch', 'icon': 'assets/icons/cozy/couch.png', 'name': 'Couch'},
      {'id': 'soup', 'icon': 'assets/icons/cozy/soup.png', 'name': 'Soup'},
      {'id': 'snack', 'icon': 'assets/icons/cozy/snack.png', 'name': 'Snack'},
      {'id': 'TV remote', 'icon': 'assets/icons/cozy/remote.png', 'name': 'TV Remote'},
      {'id': 'juice', 'icon': 'assets/icons/cozy/juice.png', 'name': 'Juice'},
      {'id': 'cover', 'icon': 'assets/icons/cozy/cover.png', 'name': 'Cover'},
      {'id': 'noodles', 'icon': 'assets/icons/cozy/noodles.png', 'name': 'Noodles'},
    ],
  };
  Map<String, List<Map<String, dynamic>>> wrongEmojis = {
    'kitchen': [
      {'id': 'sunscreen', 'icon': 'assets/icons/beach/sunscreen.png', 'name': 'Sunscreen'},
      {'id': 'notebook', 'icon': 'assets/icons/study/notebook.png', 'name': 'Notebook'},
      {'id': 'controller', 'icon': 'assets/icons/game/controllers.png', 'name': 'Controller'},
      {'id': 'balloon', 'icon': 'assets/icons/celebration/balloon.png', 'name': 'Balloon'},
      {'id': 'candle', 'icon': 'assets/icons/cozy/Candel.png', 'name': 'Candle'},
      {'id': 'cap', 'icon': 'assets/icons/beach/cap.png', 'name': 'Cap'},
      {'id': 'gift', 'icon': 'assets/icons/celebration/gift.png', 'name': 'Gift'},
      {'id': 'TV remote', 'icon': 'assets/icons/cozy/remote.png', 'name': 'TV Remote'},
      {'id': 'bubbletea', 'icon': 'assets/icons/study/bubbletea.png', 'name': 'Bubble Tea'}, // Added
      {'id': 'popcorn', 'icon': 'assets/icons/game/popcorn.png', 'name': 'Popcorn'}, // Added
    ],
    'beach': [
      {'id': 'bread', 'icon': 'assets/icons/kitchen/Bread.png', 'name': 'Bread'},
      {'id': 'coffee', 'icon': 'assets/icons/study/coffee.png', 'name': 'Coffee'},
      {'id': 'pizza', 'icon': 'assets/icons/game/pizza.png', 'name': 'Pizza'},
      {'id': 'cake', 'icon': 'assets/icons/celebration/cake.png', 'name': 'Cake'},
      {'id': 'soup', 'icon': 'assets/icons/cozy/soup.png', 'name': 'Soup'},
      {'id': 'pen', 'icon': 'assets/icons/study/pen.png', 'name': 'Pen'},
      {'id': 'lollipop', 'icon': 'assets/icons/celebration/lolipop.png', 'name': 'Lollipop'},
      {'id': 'knife', 'icon': 'assets/icons/kitchen/Knife.png', 'name': 'Knife'},
      {'id': 'cookies', 'icon': 'assets/icons/study/cookies.png', 'name': 'Cookies'}, // Added
      {'id': 'noodles', 'icon': 'assets/icons/cozy/noodles.png', 'name': 'Noodles'}, // Added
    ],
    'study': [
      {'id': 'egg', 'icon': 'assets/icons/kitchen/egg.png', 'name': 'Egg'},
      {'id': 'flipflop', 'icon': 'assets/icons/beach/flipflop.png', 'name': 'Flipflop'},
      {'id': 'fries', 'icon': 'assets/icons/game/fries.png', 'name': 'Fries'},
      {'id': 'sparks', 'icon': 'assets/icons/celebration/sparks.png', 'name': 'Sparks'},
      {'id': 'cover', 'icon': 'assets/icons/cozy/cover.png', 'name': 'Cover'},
      {'id': 'watermelon', 'icon': 'assets/icons/beach/watermelon.png', 'name': 'Watermelon'},
      {'id': 'cupcake', 'icon': 'assets/icons/celebration/cupcake.png', 'name': 'Cupcake'},
      {'id': 'salt', 'icon': 'assets/icons/kitchen/salt.png', 'name': 'Salt'},
      {'id': 'burger', 'icon': 'assets/icons/game/burger.png', 'name': 'Burger'}, // Added
      {'id': 'snack', 'icon': 'assets/icons/cozy/snack.png', 'name': 'Snack'}, // Added
    ],
    'game Night': [
      {'id': 'milk', 'icon': 'assets/icons/kitchen/milk.png', 'name': 'Milk'},
      {'id': 'sunglasses', 'icon': 'assets/icons/beach/sunglasses.png', 'name': 'Sunglasses'},
      {'id': 'bubbletea', 'icon': 'assets/icons/study/bubbletea.png', 'name': 'Bubble Tea'},
      {'id': 'cake', 'icon': 'assets/icons/celebration/cake.png', 'name': 'Cake'},
      {'id': 'candle', 'icon': 'assets/icons/cozy/Candel.png', 'name': 'Candle'},
      {'id': 'picnic basket', 'icon': 'assets/icons/beach/basket.png', 'name': 'Picnic Basket'},
      {'id': 'notebook', 'icon': 'assets/icons/study/notebook.png', 'name': 'Notebook'},
      {'id': 'garlic', 'icon': 'assets/icons/kitchen/garlic.png', 'name': 'Garlic'},
      {'id': 'tomato', 'icon': 'assets/icons/kitchen/tomato.png', 'name': 'Tomato'}, // Added
      {'id': 'lollipop', 'icon': 'assets/icons/celebration/lolipop.png', 'name': 'Lollipop'}, // Added
    ],
    'celebration': [
      {'id': 'tomato', 'icon': 'assets/icons/kitchen/tomato.png', 'name': 'Tomato'},
      {'id': 'juice box', 'icon': 'assets/icons/beach/juice.png', 'name': 'Juice Box'},
      {'id': 'sandwich', 'icon': 'assets/icons/study/sandwich.png', 'name': 'Sandwich'},
      {'id': 'controller', 'icon': 'assets/icons/game/controllers.png', 'name': 'Controller'},
      {'id': 'noodles', 'icon': 'assets/icons/cozy/noodles.png', 'name': 'Noodles'},
      {'id': 'ice cream', 'icon': 'assets/icons/beach/icecream.png', 'name': 'Ice Cream'},
      {'id': 'biscuits', 'icon': 'assets/icons/study/Biscuits.png', 'name': 'Biscuits'},
      {'id': 'soup', 'icon': 'assets/icons/kitchen/soup.png', 'name': 'Soup'},
      {'id': 'burger', 'icon': 'assets/icons/game/burger.png', 'name': 'Burger'}, // Added
      {'id': 'pen', 'icon': 'assets/icons/study/pen.png', 'name': 'Pen'}, // Added
      {'id': 'cover', 'icon': 'assets/icons/cozy/cover.png', 'name': 'Cover'}, // Added
      {'id': 'TV remote', 'icon': 'assets/icons/cozy/remote.png', 'name': 'TV Remote'}, // Added
    ],
    'cozy': [
      {'id': 'knife', 'icon': 'assets/icons/kitchen/Knife.png', 'name': 'Knife'},
      {'id': 'sunscreen', 'icon': 'assets/icons/beach/sunscreen.png', 'name': 'Sunscreen'},
      {'id': 'cookies', 'icon': 'assets/icons/study/cookies.png', 'name': 'Cookies'},
      {'id': 'burger', 'icon': 'assets/icons/game/burger.png', 'name': 'Burger'},
      {'id': 'balloon', 'icon': 'assets/icons/celebration/balloon.png', 'name': 'Balloon'},
      {'id': 'sunglasses', 'icon': 'assets/icons/beach/sunglasses.png', 'name': 'Sunglasses'},
      {'id': 'tissue', 'icon': 'assets/icons/study/tissue.png', 'name': 'Tissue'},
      {'id': 'soft drink', 'icon': 'assets/icons/game/softdrink.png', 'name': 'Soft Drink'},
      {'id': 'egg', 'icon': 'assets/icons/kitchen/egg.png', 'name': 'Egg'}, // Added
      {'id': 'gift', 'icon': 'assets/icons/celebration/gift.png', 'name': 'Gift'}, // Added
    ],
  };

  // Mapping for item image paths
  Map<String, Map<String, String>> itemImages = {
    'game Night': {
      'pizza': 'assets/items/game/GamenightPizza.png',
      'fries': 'assets/items/game/GamenightFries.png',
      'juice': 'assets/items/game/GamenightJuice.png',
      'controller': 'assets/items/game/GamenightController.png',
      'couch': 'assets/items/game/GameNightCouch .png',
      'soft drink': 'assets/items/game/Game NightSoftDrrink .png',
      'popcorn': 'assets/items/game/Game NightPopcorn.png',
      'burger': 'assets/items/game/Game NightBurger.png',
    },
    'kitchen': {
      'bread': 'assets/items/kitchen/Kitchen_bread.png',
      'egg': 'assets/items/kitchen/Kitchen_Eggs.png',
      'salt': 'assets/items/kitchen/Kitchen_Salt.png',
      'milk': 'assets/items/kitchen/Kitchen_milk.png',
      'garlic': 'assets/items/kitchen/Kitchen_Garlic.png',
      'tomato': 'assets/items/kitchen/Kitchen_Tomato.png',
      'soup': 'assets/items/kitchen/Kitchen_Soup.png',
      'knife': 'assets/items/kitchen/Kitchen_Knife.png',
    },
    'beach': {
      'sunscreen': 'assets/items/beach/Beachsunscreen.png',
      'juice box': 'assets/items/beach/Beachjuicebox.png',
      'watermelon': 'assets/items/beach/Beachwatermelon.png',
      'sunglasses': 'assets/items/beach/Beachglasses.png',
      'cap': 'assets/items/beach/Beachcap.png',
      'ice cream': 'assets/items/beach/Beachicecream.png',
      'flipflop': 'assets/items/beach/Beachflipflop.png',
      'picnic basket': 'assets/items/beach/Beachbasket.png',
    },
    'study': {
      'coffee': 'assets/items/study/StudyCoffee.png',
      'bubbletea': 'assets/items/study/StudyBubbleTeam.png',
      'biscuits': 'assets/items/study/StudyBiscuits.png',
      'notebook': 'assets/items/study/StudyNotebook.png',
      'pen': 'assets/items/study/StudyPen.png',
      'cookies': 'assets/items/study/StudyCookies.png',
      'sandwich': 'assets/items/study/StudySandwich.png',
      'tissue': 'assets/items/study/StudyTissues.png',
    },
    'celebration': {
      'cake': 'assets/items/celebration/CelebrationCake.png',
      'balloon': 'assets/items/celebration/Balloon.png',
      'sparks': 'assets/items/celebration/CelebrationSparks.png',
      'lollipop': 'assets/items/celebration/CelebrationLolipop.png',
      'cupcake': 'assets/items/celebration/CelebrationCupcake.png',
      'gift': 'assets/items/celebration/CelebrationGifts.png',
    },
    'cozy': {
      'candle': 'assets/items/cozy/HomeCandle.png',
      'couch': 'assets/items/cozy/HomeCouch.png',
      'soup': 'assets/items/cozy/HomeSoup.png',
      'snack': 'assets/items/cozy/HomeSnackBreak.png',
      'TV remote': 'assets/items/cozy/HomeTVRemote.png',
      'juice': 'assets/items/cozy/HomeJuice.png',
      'cover': 'assets/items/cozy/HomeCover.png',
      'noodles': 'assets/items/cozy/HomeNoodles.png',
    },
  };

  List<Map<String, dynamic>> shuffledEmojis = [];

  @override
  void initState() {
    super.initState();
    // Set up handler for scene window close events
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'window_closed' && fromWindowId == sceneWindowId) {
        setState(() {
          isSceneWindowOpen = false;
          sceneWindowId = null;
        });
      }
      return;
    });
    _audioPlayer.setReleaseMode(ReleaseMode.release);
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
    gameTimer?.cancel();
    super.dispose();
  }
  void startTimer() {
    gameTimer?.cancel();
    setState(() => secondsElapsed = 0);
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => secondsElapsed++);
    });
  }
  void _playSound(String soundPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundPath));
      print("Successfully playing: $soundPath");
    } catch (e) {
      print("Error playing sound: $e");
    }
  }
  Future<void> openSceneWindow() async {
    if (isSceneWindowOpen) return;

    // Create window with specific parameters
    final window = await DesktopMultiWindow.createWindow(
      jsonEncode({
        'fullscreen': true,
        'frameless': true,
      }),
    );

    // Configure the window
    window
      ..setFrame(const Offset(0, 0) &
      Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height))
      ..setTitle('Scene Viewer')
    // Make it frameless (no title bar)
      ..setFrame(const Offset(0, 0) & const Size(1920, 1080)) // Use a large size
    // Set the window to fullscreen mode
      ..center()
      ..show();

    setState(() {
      isSceneWindowOpen = true;
      sceneWindowId = window.windowId;
    });

    // Send any necessary scene data
    if (currentScene.isNotEmpty) {
      DesktopMultiWindow.invokeMethod(
          window.windowId, 'update_scene', currentScene);
      DesktopMultiWindow.invokeMethod(window.windowId, 'update_marked_emojis',
          jsonEncode(markedEmojis.toList()));
      if (showCongratulations) {
        DesktopMultiWindow.invokeMethod(
            window.windowId, 'show_congratulations', true);
      }
    }
  }

  void selectScene(String scene) {
    setState(() {
      currentScene = scene;
      markedEmojis.clear();
      showCongratulations = false;
      blinkingEmojis.clear();

      // Notify any open scene window about scene change
      if (isSceneWindowOpen && sceneWindowId != null) {
        DesktopMultiWindow.invokeMethod(sceneWindowId!, 'update_scene', scene);
        DesktopMultiWindow.invokeMethod(
            sceneWindowId!, 'update_marked_emojis', jsonEncode([]));
        DesktopMultiWindow.invokeMethod(
            sceneWindowId!, 'show_congratulations', false);
      }
      startTimer();
      // Shuffle emojis when selecting a new scene
      _shuffleEmojis();
    });
  }

  // Method to shuffle emojis
  void _shuffleEmojis() {
    if (currentScene.isEmpty) return;

    final sceneData =
    List<Map<String, dynamic>>.from(sceneEmojis[currentScene] ?? []);
    final wrongData =
    List<Map<String, dynamic>>.from(wrongEmojis[currentScene] ?? []);

    // Combine both lists
    shuffledEmojis = [...sceneData, ...wrongData];

    // Shuffle the combined list
    shuffledEmojis.shuffle();
  }

  void toggleEmoji(String emojiId) {
    final correctIds = sceneEmojis[currentScene]!.map((e) => e['id']).toList();

    if (correctIds.contains(emojiId)) {
      // Check if already selected - should not deselect
      if (!markedEmojis.contains(emojiId)) {
        setState(() {
          markedEmojis.add(emojiId);

          // Play correct sound
          _playSound('sounds/Correct Answer sound effect(MP3_160K).mp3');

          // Update scene window with selected emoji
          if (isSceneWindowOpen && sceneWindowId != null) {
            DesktopMultiWindow.invokeMethod(sceneWindowId!,
                'update_marked_emojis', jsonEncode(markedEmojis.toList()));
          }

          // Check if all correct emojis are found
          if (markedEmojis.length == correctIds.length &&
              markedEmojis.containsAll(correctIds)) {
            showCongratulations = true;

            // Stop the timer when game is completed
            gameTimer?.cancel();

            // Play congratulations sound
            _playSound('sounds/YEHEY CLAP SOUND EFFECT Awarding(MP3_160K).mp3');

            // Notify scene window about congratulations
            if (isSceneWindowOpen && sceneWindowId != null) {
              DesktopMultiWindow.invokeMethod(
                  sceneWindowId!, 'show_congratulations', true);
            }
          }
        });
      }
    } else {
      // Show X mark for incorrect emoji
      _showXMarkForIncorrectEmoji(emojiId);
    }
  }

  void _showXMarkForIncorrectEmoji(String emojiId) {
    // Show X mark
    setState(() => showXMarks[emojiId] = true);

    // First blink
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => showXMarks[emojiId] = false);

      // Second blink
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => showXMarks[emojiId] = true);

        // End animation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() => showXMarks[emojiId] = false);
        });
      });
    });

    // Play wrong sound
    _playSound('sounds/Wrong Buzzer - Sound Effect(MP3_160K) (mp3cut.net) (1).mp3');
  }

  void resetGame() {
    setState(() {
      currentScene = '';
      markedEmojis.clear();
      showCongratulations = false;
      blinkingEmojis.clear();
      shuffledEmojis.clear();
      gameTimer?.cancel();
      secondsElapsed = 0;

      // Update the existing scene window instead of closing it
      if (isSceneWindowOpen && sceneWindowId != null) {
        DesktopMultiWindow.invokeMethod(sceneWindowId!, 'reset_window');
      }
      if (showCongratulations) {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const WelcomeScreen(),
              ),
            );
          }
        });
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    if (shuffledEmojis.isEmpty && currentScene.isNotEmpty) {
      _shuffleEmojis();
    }

    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final gridCrossAxisCount =
    isSmallScreen ? 4 : (screenSize.width < 1000 ? 6 : 9);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2E8D5),
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF3D1101)),
          onPressed: currentScene.isEmpty ? null : resetGame,
        ),
        title: currentScene.isEmpty
            ? null
            : Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5E0E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            formatTime(secondsElapsed),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: isSceneWindowOpen
                ? 'Scene Window Already Open'
                : 'Open Scene Viewer',
            onPressed: isSceneWindowOpen ? null : openSceneWindow,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF2E8D5),
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: isSmallScreen ? 230 : 320, // Increased height even more
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFefdeca),
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            currentScene.isEmpty
                                ? 'Select a Scene'
                                : availableScenes.firstWhere(
                                    (scene) => scene['id'] == currentScene,
                                orElse: () => {'name': currentScene}
                            )['name'],
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3D1101),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Image.asset(
                            'assets/Talabat Logo.png',
                            height: isSmallScreen ? 50 : 70, // Increased logo height
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: isSmallScreen ? 50 : 70, // Matched height
                                color: Colors.transparent,
                                child: const Center(
                                  child: Text('Talabat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D1101),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // Increased spacing
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: availableScenes.map((scene) {
                            final isSelected = currentScene == scene['id'];
                            // Only apply reduced opacity when a scene has been selected and this isn't the selected one
                            final showReducedOpacity = currentScene.isNotEmpty && !isSelected;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GestureDetector(
                                onTap: () => selectScene(scene['id']),
                                child: Opacity(
                                  opacity: showReducedOpacity ? 0.4 : 1.0, // Full opacity unless this is not selected and another scene is
                                  child: Container(
                                    width: isSmallScreen ? 150 : 220,
                                    height: isSmallScreen ? 150 : 220,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF5E0E)
                                          : const Color(0xFF3D1101),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Display the scene icon image
                                        Image.asset(
                                          scene['icon'],
                                          width: isSmallScreen ? 100 : 140,
                                          height: isSmallScreen ? 100 : 140,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(height: 10),
                                        // Display scene name
                                        Text(
                                          scene['name'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 25 : 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            const SizedBox(height: 20,),
            Expanded(
              child: currentScene.isEmpty
                  ? Center(
                child: Image.asset(
                  'assets/Talabat Logo.png', // Add this image to your assets
                  fit: BoxFit.contain,
                ),
              ): GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCrossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: shuffledEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = shuffledEmojis[index];
                    final isMarked = markedEmojis.contains(emoji['id']);
                    final showXMark = showXMarks[emoji['id']] == true;

                    return GestureDetector(
                      onTap: () => toggleEmoji(emoji['id']),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isMarked
                              ? const Color(0xFFFF5E0E)
                              : const Color(0xFF3D1101),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  emoji['icon'],
                                  height: isSmallScreen ? 100 : 100,
                                  width: isSmallScreen ? 100 : 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            if (showXMark)
                              Center(
                                child: Image.asset(
                                  'assets/wrong-button.png', // Add this to your assets
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
              ),
            ),
            if (showCongratulations)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5E0E),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 30,
                      vertical: isSmallScreen ? 10 : 15,
                    ),
                  ),
                  child: Text(
                    'Play Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 18,
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

// SceneWindow class for the scene viewer
class SceneWindow extends StatefulWidget {
  final int windowId;

  const SceneWindow({super.key, required this.windowId});

  @override
  State<SceneWindow> createState() => _SceneWindowState();
}

class _SceneWindowState extends State<SceneWindow> {
  String currentScene = '';
  bool showCongratulations = false;
  List<String> markedEmojis = [];
  Map<String, double> itemOpacities = {};

  // Map scene IDs to appropriate image assets
  Map<String, String> sceneImages = {
    'kitchen': 'assets/scenes/Kitchen_Empty.jpg',
    'beach': 'assets/scenes/BeachEmpty.jpg',
    'study': 'assets/scenes/Study.jpg',
    'game Night': 'assets/scenes/Gamenight.jpg',
    'celebration': 'assets/scenes/Celebration Mode.jpg',
    'cozy': 'assets/scenes/Home.jpg',
  };

  // Mapping for item image paths
  Map<String, Map<String, String>> itemImages = {
    'game Night': {
      'pizza': 'assets/items/game/GamenightPizza.png',
      'fries': 'assets/items/game/GamenightFries.png',
      'juice': 'assets/items/game/GamenightJuice.png',
      'controller': 'assets/items/game/GamenightController.png',
      'couch': 'assets/items/game/GameNightCouch .png',
      'soft drink': 'assets/items/game/Game NightSoftDrrink .png',
      'popcorn': 'assets/items/game/Game NightPopcorn.png',
      'burger': 'assets/items/game/Game NightBurger.png',
    },
    'kitchen': {
      'bread': 'assets/items/kitchen/Kitchen_bread.png',
      'egg': 'assets/items/kitchen/Kitchen_Eggs.png',
      'salt': 'assets/items/kitchen/Kitchen_Salt.png',
      'milk': 'assets/items/kitchen/Kitchen_milk.png',
      'garlic': 'assets/items/kitchen/Kitchen_Garlic.png',
      'tomato': 'assets/items/kitchen/Kitchen_Tomato.png',
      'soup': 'assets/items/kitchen/Kitchen_Soup.png',
      'knife': 'assets/items/kitchen/Kitchen_Knife.png',
    },
    'beach': {
      'sunscreen': 'assets/items/beach/Beachsunscreen.png',
      'juice box': 'assets/items/beach/Beachjuicebox.png',
      'watermelon': 'assets/items/beach/Beachwatermelon.png',
      'sunglasses': 'assets/items/beach/Beachglasses.png',
      'cap': 'assets/items/beach/Beachcap.png',
      'ice cream': 'assets/items/beach/Beachicecream.png',
      'flipflop': 'assets/items/beach/Beachflipflop.png',
      'picnic basket': 'assets/items/beach/Beachbasket.png',
    },
    'study': {
      'coffee': 'assets/items/study/StudyCoffee.png',
      'bubbletea': 'assets/items/study/StudyBubbleTeam.png',
      'biscuits': 'assets/items/study/StudyBiscuits.png',
      'notebook': 'assets/items/study/StudyNotebook.png',
      'pen': 'assets/items/study/StudyPen.png',
      'cookies': 'assets/items/study/StudyCookies.png',
      'sandwich': 'assets/items/study/StudySandwich.png',
      'tissue': 'assets/items/study/StudyTissues.png',
    },
    'celebration': {
      'cake': 'assets/items/celebration/CelebrationCake.png',
      'balloon': 'assets/items/celebration/Balloon.png',
      'sparks': 'assets/items/celebration/CelebrationSparks.png',
      'lollipop': 'assets/items/celebration/CelebrationLolipop.png',
      'cupcake': 'assets/items/celebration/CelebrationCupcake.png',
      'gift': 'assets/items/celebration/CelebrationGifts.png',
    },
    'cozy': {
      'candle': 'assets/items/cozy/HomeCandle.png',
      'couch': 'assets/items/cozy/HomeCouch.png',
      'soup': 'assets/items/cozy/HomeSoup.png',
      'snack': 'assets/items/cozy/HomeSnackBreak.png',
      'TV remote': 'assets/items/cozy/HomeTVRemote.png',
      'juice': 'assets/items/cozy/HomeJuice.png',
      'cover': 'assets/items/cozy/HomeCover.png',
      'noodles': 'assets/items/cozy/HomeNoodles.png',
    },
  };

  @override
  void initState() {
    super.initState();

    // Make sure we're in fullscreen mode using SystemChrome
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Set up channel to receive scene updates
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'update_scene') {
        setState(() {
          currentScene = call.arguments as String;
          // Reset congratulations when scene changes
          showCongratulations = false;
          markedEmojis = [];
        });
      } else if (call.method == 'show_congratulations') {
        setState(() {
          showCongratulations = call.arguments as bool;
        });
      } else if (call.method == 'reset_window') {
        setState(() {
          currentScene = '';
          showCongratulations = false;
          markedEmojis = [];
        });
      } else if (call.method == 'update_marked_emojis') {
        final List<dynamic> jsonEmojis = jsonDecode(call.arguments as String);
        final List<String> newEmojis = jsonEmojis.cast<String>();

        // Find new emojis that weren't previously marked
        final newlyAddedEmojis = newEmojis.where((emoji) => !markedEmojis.contains(emoji)).toList();

        setState(() {
          markedEmojis = newEmojis;

          // Initialize opacity for new items
          for (final emoji in newlyAddedEmojis) {
            itemOpacities[emoji] = 0.0;

            // Start fade animation
            _animateItemOpacity(emoji);
          }
        });
      }
      return null;
    });
  }

// Move the dispose method outside of initState
  @override
  void dispose() {
    DesktopMultiWindow.invokeMethod(0, 'window_closed', widget.windowId);
    super.dispose();
  }

// Define _animateItemOpacity as a class method
  void _animateItemOpacity(String emojiId) {
    // Animation runs for 1 second
    const animationDuration = Duration(milliseconds: 1000);
    const fps = 60.0;
    const totalSteps = fps;
    final stepDuration = Duration(milliseconds: (1000 / fps).round());

    int step = 0;
    Timer.periodic(stepDuration, (timer) {
      if (step >= totalSteps || !mounted) {
        timer.cancel();
        if (mounted) {
          setState(() => itemOpacities[emojiId] = 1.0);
        }
        return;
      }

      step++;
      if (mounted) {
        setState(() => itemOpacities[emojiId] = step / totalSteps);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design, especially for portrait mode
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    // Enter full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          color: const Color(0xFFF2E8D5),
          width: double.infinity,
          height: double.infinity,
          child: currentScene.isEmpty
              ? Center(
            child: Image.asset(
              'assets/Select Scene.jpg',
              fit: BoxFit.contain,
            ),
          )
              : Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return showCongratulations
                    ? _buildCongratulationsCard(constraints)
                    : _buildSceneWithItems(constraints, isPortrait);
              },
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSceneWithItems(BoxConstraints constraints, bool isPortrait) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // First, show the scene base image
          Image.asset(
            sceneImages[currentScene] ?? 'assets/images/placeholder.png',
            fit: isPortrait ? BoxFit.fitWidth : BoxFit.contain,
          ),

          // Then, on top, show the marked items
          if (markedEmojis.isNotEmpty)
            ...markedEmojis.map((emojiId) {
              final itemPath = itemImages[currentScene]?[emojiId];
              if (itemPath == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  itemPath,
                  fit: BoxFit.contain,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCongratulationsCard(BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/Celebrarion screen copy.png',
        fit: BoxFit.contain,
      ),
    );
  }
}