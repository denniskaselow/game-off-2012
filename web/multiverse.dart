library multiverse;

import 'dart:html' hide Entity;
import 'dart:math';
import 'package:dartemis/dartemis.dart';

part 'components/components.dart';
part 'systems/game_logic_systems.dart';
part 'systems/render_systems.dart';
part 'systems/input_systems.dart';

const int MAX_WIDTH = 800;
const int MAX_HEIGHT = 400;
const int HUD_HEIGHT = 100;
const int UNIVERSE_HEIGHT = 10000;
const int UNIVERSE_WIDTH = 10000;
const String TAG_CAMERA = "CAMERA";
const String TAG_PLAYER = "PLAYER";
const String GROUP_BACKGROUND = "GROUP_BACKGROUND";

final Random random = new Random();

void main() {
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
    world = new World();

    Entity player = world.createEntity();
    player.addComponent(new Transform(UNIVERSE_WIDTH - 100, UNIVERSE_HEIGHT - 100));
    player.addComponent(new Velocity(0, 0));
    player.addComponent(new Spatial('resources/spaceship_dummy.png', scale: 0.5));
    player.addToWorld();

    Entity camera = world.createEntity();
    camera.addComponent(new CameraPosition());
    camera.addToWorld();

    GroupManager groupManager = new GroupManager();
    for (int i = 0; i < 10000; i++) {
      Entity star = world.createEntity();
      star.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
      star.addComponent(new Spatial('resources/star_0${random.nextInt(6)}.png'));
      star.addComponent(new Background());
      star.addToWorld();
      groupManager.add(star, GROUP_BACKGROUND);
    }

    for (int i = 0; i < 500; i++) {
      Entity asteroid = world.createEntity();
      asteroid.addComponent(new Transform(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT, angle: random.nextDouble() * FastMath.TWO_PI, rotationRate: generateRandom(0.15, 0.20)));
      asteroid.addComponent(generateRandomVelocity(0.5, 1.5));
      asteroid.addComponent(new Spatial.asSprite('resources/asteroid_strip64.png', 0, 0, 128, 128, scale : generateRandom(0.2, 0.5)));
      asteroid.addToWorld();
    }

    TagManager tagManager = new TagManager();
    tagManager.register(TAG_CAMERA, camera);
    tagManager.register(TAG_PLAYER, player);
    world.addManager(tagManager);
    world.addManager(groupManager);

    world.addSystem(new PlayerControlSystem(gameCanvas));
    world.addSystem(new MovementSystem());
    world.addSystem(new CameraSystem());
    world.addSystem(new BackgroundRenderSystem(gameContext));
    world.addSystem(new SpatialRenderingSystem(gameContext));
    world.addSystem(new HudRenderSystem(hudContext));
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

Velocity generateRandomVelocity(num minSpeed, num maxSpeed) {
  num velx = generateRandom(minSpeed, maxSpeed);
  velx = velx * (random.nextBool() ? 1 : -1);
  num vely = generateRandom(minSpeed, maxSpeed);
  vely = vely * (random.nextBool() ? 1 : -1);
  return new Velocity(velx, vely);
}

num generateRandom(num min, num max) {
  num randomNumber = min + max * random.nextDouble();
  return randomNumber;
}

class DebugSystem extends VoidEntitySystem {
  SpanElement fpsElement = query("#fps");
  SpanElement playerPosElement = query("#playerPos");
  SpanElement cameraPosElement = query("#cameraPos");
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
  }
}
