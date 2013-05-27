library game;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:spaceoff/html.dart';

part 'game_assets.dart';

void main() {
  initTabbedContent();
  List<Future> imageLoader = loadImages();
  CanvasElement gameContainer = query('#gamecontainer');
  CanvasElement hudContainer = query('#hudcontainer');
  Map<String, Sprite> sprites = new Map<String, Sprite>();
  assets.forEach((key, value) {
    sprites[key] = new Sprite(assets[key]);
  });

  window.setImmediate(() {
    gameContainer.width = MAX_WIDTH;
    gameContainer.height = MAX_HEIGHT;
    hudContainer.width = MAX_WIDTH;
    hudContainer.height = HUD_HEIGHT;

    Future.wait(imageLoader).then((images) {
      hudContainer.context2d..textBaseline = 'top'
                            ..font = '20px D3Radicalism';
      Atlas atlas = new Atlas(images[0], sprites);
      gameContainer.focus();
      Game game = new Game(gameContainer, hudContainer, atlas);
      gameContainer.onBlur.listen((data) => game.pause());
      gameContainer.onFocus.listen((data) => game.unpause());
      gameContainer.onKeyDown.listen((data) {
        // P
        if (data.keyCode == 80) {
          if (gameState.paused) {
            game.unpause();
          } else {
            game.pause();
          }
        }
      });
      game.start();
    });
  });
}

List<Future<ImageElement>> loadImages() {
  List<String> images = ['game_assets.png'];

  Completer<ImageElement> completer = new Completer<ImageElement>();

  List<Future> futures = new List<Future>();
  images.forEach((image) {
    Completer completer = new Completer();
    futures.add(completer.future);
    ImageCache.withImage(image, (element) {
      completer.complete(element);
    });
  });
  return futures;
}

void initTabbedContent() {
  Map<String, String> tabs = {"tabStory": "story", "tabControls": "controls", "tabCredits": "credits", "tabDebug": "debug"};
  String selectedTab = "tabStory";
  tabs.forEach((key, value) {
    Element tab = query("#$key");
    Element tabContent = query("#$value");

    tab.onClick.listen((listener) {
      if (key != selectedTab) {
        tab.classes.add("selectedTab");
        tabContent.classes.remove("hidden");
        query("#$selectedTab").classes.remove("selectedTab");
        query("#${tabs[selectedTab]}").classes.add("hidden");
        selectedTab = key;
      }
    });
  });
}

class Game {
  CanvasElement gameCanvas;
  CanvasElement hudCanvas;
  Atlas atlas;
  CanvasRenderingContext2D gameContext;
  CanvasRenderingContext2D hudContext;
  PlayerControlSystem playerControlSystem;
  num lastTime = 0;
  World currentWorld;
  AudioManager audioManager;
  Status playerStatus;
  Mass playerMass;
  Cannon playerCannon;
  HyperDrive playerHyperDrive;
  double playerScale;

  Game(this.gameCanvas, this.hudCanvas, this.atlas) {
    gameContext = gameCanvas.context2d;
    hudContext = hudCanvas.context2d;
    audioManager = createAudioManager(window.location.href);
    playerScale = 0.5;
  }

  void start() {
    currentWorld = new World();
    playerStatus = new Status();
    playerMass = new Mass(100 * playerScale);
    playerCannon = new Cannon(cooldownTime : 200, bulletSpeed: 0.5, bulletDamage: 5, amount: 1);
    playerHyperDrive = new HyperDrive();

    createWorld(currentWorld, 0);

    currentWorld.delta = 16;
    currentWorld.process();

    gameLoop(16);
  }

  void pause() {
    gameState.paused = true;
    if (document.activeElement != gameCanvas) {
      playerControlSystem.releaseAllKeys();
    }
  }

  void unpause() {
    gameState.paused = false;
  }

  void gameLoop(num time) {
    currentWorld.delta = time - lastTime;
    lastTime = time;
    currentWorld.process();
    if (!gameState.paused) {
      if (playerHyperDrive.active && !playerHyperDrive.shuttingDown && !gameState.nextLevelIsBeingPrepared) {
        prepareNextLevel();
      }
    }
    window.animationFrame.then(gameLoop);
  }

  void createWorld(World world, int level) {
    double levelMod = pow(1.2, level);
    gameState.levelMod = levelMod;
    GroupManager groupManager = new GroupManager();
    TagManager tagManager = new TagManager();
    world.addManager(tagManager);
    world.addManager(groupManager);

    double playerX = UNIVERSE_WIDTH / 2;
    double playerY = UNIVERSE_HEIGHT / 2;
    double playerRadius = 45 * playerScale;
    Entity player = world.createEntity();
    player.addComponent(new Transform(playerX, playerY, angle : -PI/2));
    player.addComponent(new Velocity(0, 0));
    player.addComponent(new Spatial('spaceship.png', scale: 0.25));
    player.addComponent(new CircularBody(playerRadius));
    player.addComponent(new MiniMapRenderable("#1fe9f6"));
    player.addComponent(new ScoreComponent(-10, -10));
    player.addComponent(playerStatus);
    player.addComponent(playerMass);
    player.addComponent(playerCannon);
    player.addComponent(playerHyperDrive);
    player.addToWorld();

    Entity camera = world.createEntity();
    camera.addComponent(new CameraPosition());
    camera.addToWorld();

    addStars(world, groupManager);
    addAsteroids(world, playerX, playerY, playerRadius, levelMod);
    addUpgrades(world);

    tagManager.register(camera, TAG_CAMERA);
    tagManager.register(player, TAG_PLAYER);

    playerControlSystem = new PlayerControlSystem(gameCanvas);
    world.addSystem(playerControlSystem);
    world.addSystem(new HyperDriveSystem());
    world.addSystem(new AutoPilotControlSystem());
    world.addSystem(new MovementSystem());
    world.addSystem(new UpgradeCollectionSystem());
    world.addSystem(new CircularCollisionDetectionSystem());
    world.addSystem(new BulletSpawningSystem());
    world.addSystem(new SplittingDestructionSystem());
    world.addSystem(new DisapperearingDestructionSystem());
    world.addSystem(new PlayerDestructionSystem());
    world.addSystem(new ExpirationSystem());
    world.addSystem(new CameraSystem());
    world.addSystem(new NormalSpaceBackgroundRenderSystem(gameContext));
    world.addSystem(new HyperSpaceBackgroundRenderSystem(gameContext));
    world.addSystem(new BackgroundStarsRenderingSystem(gameContext, atlas));
    world.addSystem(new SpatialRenderingSystem(gameContext, atlas));
    world.addSystem(new ParticleRenderSystem(gameContext));
    world.addSystem(new MiniMapRenderSystem(hudContext));
    world.addSystem(new HudRenderSystem(hudContext));
    world.addSystem(new SoundSystem(audioManager));
    world.addSystem(new DebugSystem());

    world.addSystem(new MenuSystem(gameCanvas));

    world.initialize();
  }

  void addStars(World world, GroupManager groupManager) {
    for (int i = 0; i < sqrt(UNIVERSE_WIDTH * UNIVERSE_HEIGHT)/10; i++) {
      Entity star = world.createEntity();
      star.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
      star.addToWorld();
      groupManager.add(star, GROUP_BACKGROUND);
    }
  }

  void addAsteroids(World world, double playerX, double playerY, double playerRadius, double levelMod) {
    for (int i = 0; i < sqrt(UNIVERSE_WIDTH * UNIVERSE_HEIGHT)/100; i++) {
      double scale = generateRandom(0.2, 0.5);
      Entity asteroid = world.createEntity();
      double asteroidX = random.nextDouble() * UNIVERSE_WIDTH;
      double asteroidY = random.nextDouble() * UNIVERSE_HEIGHT;
      double asteroidRadius = 50 * scale;
      while (Utils.doCirclesCollide(playerX, playerY, playerRadius * 3, asteroidX, asteroidY, asteroidRadius)) {
        asteroidX = random.nextDouble() * UNIVERSE_WIDTH;
        asteroidY = random.nextDouble() * UNIVERSE_HEIGHT;
      }
      asteroid.addComponent(new Transform(asteroidX, asteroidY, angle: random.nextDouble() * FastMath.TWO_PI, rotationRate: generateRandom(0.15, 0.20)));
      asteroid.addComponent(generateRandomVelocity(0.025 * levelMod, 0.1 * levelMod));
      List<String> resources = new List<String>(64);
      for (int i = 0; i < 64; i++) {
        resources[i] = 'asteroid-0-$i.png';
      }
      asteroid.addComponent(new Spatial.animated(resources, scale : scale));
      asteroid.addComponent(new CircularBody(asteroidRadius));
      asteroid.addComponent(new Mass(100 * scale * levelMod));
      asteroid.addComponent(new MiniMapRenderable("#333"));
      asteroid.addComponent(new Status(maxHealth : 100 * scale * levelMod));
      asteroid.addComponent(new SplitsOnDestruction(generateRandom(2, 4).round().toInt()));
      asteroid.addComponent(new ScoreComponent(10 * scale, 100 * scale * levelMod));
      asteroid.addToWorld();
    }
  }

  void addUpgrades(World world) {
    for (int i = 0; i < 4; i++) {
      addUpgradeToWorld(world, new Upgrade("health", healthGain: 5, fillHealth: true));
    }
    for (int i = 0; i < min(1, MAX_BULLETS - playerCannon.amount); i++) {
      addUpgradeToWorld(world, new Upgrade("bullets", bullets: 1));
    }
    if (!playerHyperDrive.enabled) {
      addUpgradeToWorld(world, new Upgrade("hyperdrive", enableHyperDrive: true));
    }
  }

  void addUpgradeToWorld(World world, Upgrade upgradeComponent) {
    double scale = 0.2;
    Entity upgrade = world.createEntity();
    upgrade.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
    upgrade.addComponent(generateRandomVelocity(0.025, 0.1));
    upgrade.addComponent(new Spatial('upgrade_${upgradeComponent.name}.png', scale: scale));
    upgrade.addComponent(new CircularBody(50 * scale));
    upgrade.addComponent(new Mass(100 * scale));
    upgrade.addComponent(new MiniMapRenderable("#00FF00"));
    upgrade.addComponent(upgradeComponent);
    upgrade.addToWorld();
  }

  void prepareNextLevel() {
    gameState.nextLevelIsBeingPrepared = true;
    TagManager tagManager = currentWorld.getManager(new TagManager().runtimeType);
    Entity player = tagManager.getEntity(TAG_PLAYER);
    player.addComponent(new AutoPilot(angle: FastMath.THREE_PI_HALVES, velocity: 0.7));
    player.changedInWorld();

    Future<World> nextWorldFuture = createAndInitWorld(++gameState.currentLevel);
    nextWorldFuture.then((nextWorld) {
      if (!playerStatus.destroyed) {
        currentWorld = nextWorld;
        tagManager = currentWorld.getManager(new TagManager().runtimeType);
        player = tagManager.getEntity(TAG_PLAYER);
        player.removeComponent(AutoPilot);
        player.changedInWorld();
        playerHyperDrive.shuttingDown = true;
        gameState.nextLevelIsBeingPrepared = false;
      }
    });
  }

  Future<World> createAndInitWorld(int level) {
    Completer<World> completer = new Completer<World>();
    completeNextWorld(completer, level);
    return completer.future;
  }

  void completeNextWorld(Completer<World> completer, int level, [int elapsed = 0]) {
    if (gameState.paused) {
      new Timer(new Duration(milliseconds: 500), () {
        completeNextWorld(completer, level, elapsed);
      });
    } else {
      if (elapsed < 8000) {
        new Timer(new Duration(milliseconds: 500), () {
          completeNextWorld(completer, level, elapsed + 500);
        });
      } else {
        World nextWorld = new World();
        createWorld(nextWorld, level);
        completer.complete(nextWorld);
      }
    }
  }
}

AudioManager createAudioManager(String location) {
  AudioManager audioManager;
  var url = 'resources/sfx/';
  int slashIndex = location.lastIndexOf('/');
  if (slashIndex < 0) {
    url = '/$url';
  } else {
    url = '${location.substring(0, slashIndex)}/$url';
  }
  try {
    audioManager = new AudioElementManager(url);
    AudioSource source = audioManager.makeSource('non-positional');
    source.positional = false;
  } catch (e) {
    audioManager = new AudioElementManager(url);
  }

  audioManager.makeClip('shoot', 'shoot.ogg').load();

  return audioManager;
}

class AudioElementManager implements AudioManager {
  String baseURL;
  AudioElementManager([this.baseURL = '/']);

  Map<String, AudiElementClip> _clips = new Map<String, AudiElementClip>();

  AudioClip makeClip(String name, String url) {
    AudioClip clip = _clips[name];
    if (clip != null) {
      return clip;
    }
    clip = new AudiElementClip._internal(this, name, "$baseURL$url");
    _clips[name] = clip;
    return clip;
  }

  AudioSound playClipFromSource(String sourceName, String clipName, [bool looped=false]) {
    _clips[clipName].play();
    return null;
  }

  dynamic noSuchMethod(Invocation im) {}
}

class AudiElementClip implements AudioClip {
  final AudioManager _manager;
  String _name;
  String _url;
  List<AudioElement> audioElements = new List();
  AudiElementClip._internal(this._manager, this._name, this._url);

  Future<AudioClip> load() {
    var audioElement = new AudioElement();
    var completer = new Completer<AudioClip>();
    audioElement.onLoad.listen((data) => completer.complete(this));
    audioElement.src = _url;
    audioElements.add(audioElement);
    return completer.future;
  }

  void play() {
    var playable = audioElements.where((element) => element.ended).iterator;
    var audioElement;
    if (playable.moveNext()) {
      audioElement = playable.current;
    } else {
      audioElement = audioElements[0].clone(false);
      audioElements.add(audioElement);
    }
    audioElement.play();
  }

  dynamic noSuchMethod(Invocation im) {}
}

class DebugSystem extends VoidEntitySystem {
  SpanElement fpsElement = query("#fps");
  SpanElement playerPosElement = query("#playerPos");
  SpanElement cameraPosElement = query("#cameraPos");
  SpanElement entityCountElement = query("#entityCount");
  ComponentMapper<CameraPosition> cameraPositionMapper;
  ComponentMapper<Transform> positionMapper;
  TagManager tagManager;

  void initialize() {
    cameraPositionMapper = new ComponentMapper<CameraPosition>(CameraPosition, world);
    positionMapper = new ComponentMapper<Transform>(Transform, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Entity player = tagManager.getEntity(TAG_PLAYER);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);
    Transform playerPos = positionMapper.get(player);

    num fps = 1000 ~/ world.delta;
    fpsElement.text = "${fps}";
    cameraPosElement.text = "x: ${cameraPos.x}; y: ${cameraPos.y}";
    playerPosElement.text = "x: ${playerPos.x}; y: ${playerPos.y}";
    entityCountElement.text = "${world.entityManager.activeEntityCount}";
  }
}