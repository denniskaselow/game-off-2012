library html;

import 'dart:math';
import 'dart:html' hide Entity;
import 'package:spaceoff/spaceoff.dart';
export 'package:spaceoff/spaceoff.dart';
import 'package:simple_audio/simple_audio.dart';

part 'src/html/input_systems.dart';
part 'src/html/render_systems.dart';
part 'src/html/sound_systems.dart';

class Game {
  CanvasElement gameCanvas;
  CanvasElement hudCanvas;
  CanvasRenderingContext2D gameContext;
  CanvasRenderingContext2D hudContext;
  num lastTime = 0;
  World world;

  Game(this.gameCanvas, this.hudCanvas) {
    gameContext = gameCanvas.context2d;
    hudContext = hudCanvas.context2d;
  }

  void start() {
    AudioManager audioManager = createAudioManager(window.location.href);
    world = new World();
    GroupManager groupManager = new GroupManager();
    TagManager tagManager = new TagManager();
    world.addManager(tagManager);
    world.addManager(groupManager);

    Entity player = world.createEntity();
    player.addComponent(new Transform(UNIVERSE_WIDTH - 100, UNIVERSE_HEIGHT - 100));
    player.addComponent(new Velocity(0, 0));
    num scale = 0.5;
    player.addComponent(new Spatial('spaceship.png', scale: 0.25));
    player.addComponent(new CircularBody(45 * scale));
    player.addComponent(new Mass(100 * scale));
    player.addComponent(new Status());
    player.addComponent(new MiniMapRenderable("#1fe9f6"));
    player.addComponent(new Cannon(cooldownTime : 200, bulletSpeed: 0.5, bulletDamage: 5, amount: 1));
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
      Entity asteroid = world.createEntity();
      asteroid.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT, angle: random.nextDouble() * FastMath.TWO_PI, rotationRate: generateRandom(0.15, 0.20)));
      asteroid.addComponent(generateRandomVelocity(0.025, 0.075));
      scale = generateRandom(0.2, 0.5);
      asteroid.addComponent(new Spatial.asSprite('asteroid_strip64.png', 0, 0, 128, 128, scale : scale));
      asteroid.addComponent(new CircularBody(50 * scale));
      asteroid.addComponent(new Mass(100 * scale));
      asteroid.addComponent(new MiniMapRenderable("#333"));
      asteroid.addComponent(new Status(maxHealth : 100 * scale));
      asteroid.addComponent(new SplitsOnDestruction(generateRandom(2, 4).round().toInt()));
      asteroid.addToWorld();
    }

    for (int i = 0; i < 5; i++) {
      Entity upgrade = world.createEntity();
      upgrade.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
      upgrade.addComponent(generateRandomVelocity(0.025, 0.075));
      scale = 0.2;
      upgrade.addComponent(new Spatial('upgrade_health.png', scale: scale));
      upgrade.addComponent(new CircularBody(50 * scale));
      upgrade.addComponent(new Mass(100 * scale));
      upgrade.addComponent(new MiniMapRenderable("green"));
      upgrade.addComponent(new Upgrade(maxHealth: 20));
      upgrade.addToWorld();
    }

    for (int i = 0; i < 2; i++) {
      Entity upgrade = world.createEntity();
      upgrade.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
      upgrade.addComponent(generateRandomVelocity(0.025, 0.075));
      scale = 0.2;
      upgrade.addComponent(new Spatial('upgrade_bullets.png', scale: scale));
      upgrade.addComponent(new CircularBody(50 * scale));
      upgrade.addComponent(new Mass(100 * scale));
      upgrade.addComponent(new MiniMapRenderable("green"));
      upgrade.addComponent(new Upgrade(bullets: 1));
      upgrade.addToWorld();
    }

    tagManager.register(TAG_CAMERA, camera);
    tagManager.register(TAG_PLAYER, player);

    world.addSystem(new PlayerControlSystem(gameCanvas));
    world.addSystem(new MovementSystem());
    world.addSystem(new UpgradeCollectionSystem());
    world.addSystem(new CircularCollisionDetectionSystem());
    world.addSystem(new BulletSpawningSystem());
    world.addSystem(new SplittingDestructionSystem());
    world.addSystem(new DisapperearingDestructionSystem());
    world.addSystem(new PlayerDestructionSystem());
    world.addSystem(new ExpirationSystem());
    world.addSystem(new CameraSystem());
    world.addSystem(new BackgroundRenderSystem(gameContext));
    world.addSystem(new SpatialRenderingSystem(gameContext));
    world.addSystem(new MiniMapRenderSystem(hudContext));
    world.addSystem(new HudRenderSystem(hudContext));
    world.addSystem(new SoundSystem(audioManager));
    world.addSystem(new DebugSystem());

    world.initialize();
    world.delta = 16;
    world.process();

    gameLoop(16);
  }

  void gameLoop(num time) {
    world.delta = time - lastTime;
    lastTime = time;
    world.process();

    requestRedraw();
  }

  void requestRedraw() {
    window.requestAnimationFrame(gameLoop);
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

    AudioClip clip = audioManager.makeClip('shoot_sound', 'resources/shoot.ogg');
    clip.load();

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