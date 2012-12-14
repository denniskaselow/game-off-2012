import 'dart:html' hide Entity;
import 'dart:math';

import 'package:spaceoff/html.dart';

void main() {
  initTabbedContent();
  loadImages();

  CanvasElement gameContainer = query('#gamecontainer');
  CanvasElement hudContainer = query('#hudcontainer');
  window.requestLayoutFrame(() {
    gameContainer.width = MAX_WIDTH;
    gameContainer.height = MAX_HEIGHT;
    hudContainer.width = MAX_WIDTH;
    hudContainer.height = HUD_HEIGHT;

    Game game = new Game(gameContainer, hudContainer);
    game.start();
  });
}

void loadImages() {
   // TODO use http://www.codeandweb.com/texturepacker
  List<String> images = ['spaceship.png', 'spaceship_thrusters.png', 'hud_dummy.png', 'bullet_dummy.png', 'star_00.png', 'star_01.png', 'star_02.png', 'star_03.png', 'star_04.png', 'star_05.png', 'upgrade_health.png', 'upgrade_bullets.png'];
  images.forEach((image) => ImageCache.withImage(image, (element) {}));
}

void initTabbedContent() {
  Map<String, String> tabs = {"tabStory": "story", "tabControls": "controls", "tabCredits": "credits", "tabDebug": "debug"};
  String selectedTab = "tabStory";
  tabs.forEach((key, value) {
    Element tab = query("#$key");
    Element tabContent = query("#$value");

    tab.on.click.add((listener) {
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
  CanvasRenderingContext2D gameContext;
  CanvasRenderingContext2D hudContext;
  num lastTime = 0;
  World world;
  AudioManager audioManager;
  Status playerStatus;
  Mass playerMass;
  Cannon playerCannon;
  HyperDrive playerHyperDrive;
  double playerScale;
  int currentLevel = 0;
  bool nextLevelIsBeingPrepared = false;

  Game(this.gameCanvas, this.hudCanvas) {
    gameContext = gameCanvas.context2d;
    hudContext = hudCanvas.context2d;
    audioManager = createAudioManager(window.location.href);
    playerScale = 0.5;
    playerStatus = new Status();
    playerMass = new Mass(100 * playerScale);
    playerCannon = new Cannon(cooldownTime : 200, bulletSpeed: 0.5, bulletDamage: 5, amount: 1);
    playerHyperDrive = new HyperDrive();
  }

  void start() {
    world = new World();

    createWorld(world, 0);

    world.delta = 16;
    world.process();

    gameLoop(16);
  }

  void createWorld(World world, int level) {
    double levelMod = (1 + level/10);
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
    player.addComponent(playerStatus);
    player.addComponent(playerMass);
    player.addComponent(playerCannon);
    player.addComponent(playerHyperDrive);
    player.addToWorld();

    Entity camera = world.createEntity();
    camera.addComponent(new CameraPosition());
    camera.addToWorld();

    for (int i = 0; i < sqrt(UNIVERSE_WIDTH * UNIVERSE_HEIGHT)/10; i++) {
      Entity star = world.createEntity();
      star.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
      star.addComponent(new Spatial('star_0${random.nextInt(6)}.png'));
      star.addComponent(new Background());
      star.addToWorld();
      groupManager.add(star, GROUP_BACKGROUND);
    }

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
      asteroid.addComponent(generateRandomVelocity(0.025 * levelMod, 0.075 * levelMod));
      asteroid.addComponent(new Spatial.asSprite('asteroid_strip64.png', 0, 0, 128, 128, scale : scale));
      asteroid.addComponent(new CircularBody(asteroidRadius));
      asteroid.addComponent(new Mass(100 * scale * levelMod));
      asteroid.addComponent(new MiniMapRenderable("#333"));
      asteroid.addComponent(new Status(maxHealth : 100 * scale * levelMod));
      asteroid.addComponent(new SplitsOnDestruction(generateRandom(2, 4).round().toInt()));
      asteroid.addToWorld();
    }

    for (int i = 0; i < 5; i++) {
      addUpgradeToWorld(world, new Upgrade("health", healthGain: 20, fillHealth: true));
    }

    for (int i = 0; i < 2; i++) {
      addUpgradeToWorld(world, new Upgrade("bullets", bullets: 1));
    }

    tagManager.register(TAG_CAMERA, camera);
    tagManager.register(TAG_PLAYER, player);

    world.addSystem(new PlayerControlSystem(gameCanvas));
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
    world.addSystem(new BackgroundStarsRenderingSystem(gameContext));
    world.addSystem(new SpatialRenderingSystem(gameContext));
    world.addSystem(new ParticleRenderSystem(gameContext));
    world.addSystem(new MiniMapRenderSystem(hudContext));
    world.addSystem(new HudRenderSystem(hudContext));
    world.addSystem(new SoundSystem(audioManager));
    world.addSystem(new DebugSystem());

    world.initialize();
  }

  void addUpgradeToWorld(World world, Upgrade upgradeComponent) {
    double scale = 0.2;
    Entity upgrade = world.createEntity();
    upgrade.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
    upgrade.addComponent(generateRandomVelocity(0.025, 0.075));
    upgrade.addComponent(new Spatial('upgrade_${upgradeComponent.name}.png', scale: scale));
    upgrade.addComponent(new CircularBody(50 * scale));
    upgrade.addComponent(new Mass(100 * scale));
    upgrade.addComponent(new MiniMapRenderable("green"));
    upgrade.addComponent(upgradeComponent);
    upgrade.addToWorld();
  }

  void gameLoop(num time) {
    world.delta = time - lastTime;
    lastTime = time;
    world.process();

    if (playerStatus.leaveLevel && !nextLevelIsBeingPrepared) {
      prepareNextLevel();
    }
    requestRedraw();
  }

  void prepareNextLevel() {
    nextLevelIsBeingPrepared = true;
    TagManager tagManager = world.getManager(new TagManager().runtimeType);
    Entity player = tagManager.getEntity(TAG_PLAYER);
    player.addComponent(new AutoPilot(angle: FastMath.THREE_PI_HALVES, velocity: 0.7));
    player.changedInWorld();

    Future<World> nextWorldFuture = createAndInitWorld(++currentLevel);
    nextWorldFuture.then((nextWorld) {
      if (!playerStatus.destroyed) {
        world = nextWorld;
        tagManager = world.getManager(new TagManager().runtimeType);
        player = tagManager.getEntity(TAG_PLAYER);
        player.removeComponent(new AutoPilot.hack());
        player.changedInWorld();
        playerStatus.leaveLevel = false;
        playerStatus.enterLevel = true;
        nextLevelIsBeingPrepared = false;
      }
    });
  }

  void requestRedraw() {
    window.requestAnimationFrame(gameLoop);
  }

  Future<World> createAndInitWorld(int level) {
    Completer<World> completer = new Completer<World>();
    window.setTimeout(() {
      World nextWorld = new World();
      createWorld(nextWorld, level);
      completer.complete(nextWorld);
    }, 8000);
    return completer.future;
  }
}



AudioManager createAudioManager(String location) {
  try {
    AudioManager audioManager = new AudioManager();
    int slashIndex = location.lastIndexOf('/');
    if (slashIndex < 0) {
      audioManager.baseURL = '';
    } else {
      audioManager.baseURL = location.substring(0, slashIndex);
    }
    AudioSource source = audioManager.makeSource('non-positional');
    source.positional = false;

    AudioClip clip = audioManager.makeClip('shoot', 'resources/sfx/shoot.ogg');
    clip.load();
//    clip = audioManager.makeClip('hyperspace', 'resources/sfx/hyperspace.ogg');
//    clip.load();

    return audioManager;
  } catch (e) {
    // Browser doesn't support AudioContext
  }
  return new AudioManagerDummy();
}

class AudioManagerDummy implements AudioManager {
  dynamic noSuchMethod(InvocationMirror im) {}
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
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    positionMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
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