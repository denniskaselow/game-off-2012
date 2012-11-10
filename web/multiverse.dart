library multiverse;

import 'dart:math';
import 'dart:html' hide Entity;

import 'package:dartemis/dartemis.dart';

part 'systems/render_systems.dart';
part 'systems/input_systems.dart';

const int MAXWIDTH = 800;
const int MAXHEIGHT = 400;
const int HUDHEIGHT = 100;
const int UNIVERSE_HEIGHT = 8000;
const int UNIVERSE_WIDTH = 8000;
const String TAG_CAMERA = "CAMERA";
const String TAG_PLAYER = "PLAYER";

final Random random = new Random();

void main() {
  CanvasElement gameContainer = query('#gamecontainer');
  CanvasElement hudContainer = query('#hudcontainer');
  window.requestLayoutFrame(() {
    gameContainer.width = MAXWIDTH;
    gameContainer.height = MAXHEIGHT;
    hudContainer.width = MAXWIDTH;
    hudContainer.height = HUDHEIGHT;

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
    player.addComponent(new Position(100, 4000));
    player.addComponent(new Velocity(0, 0));
    player.addToWorld();

    Entity camera = world.createEntity();
    camera.addComponent(new CameraPosition());
    camera.addToWorld();

    for (int i = 0; i < 10000; i++) {
      Entity star = world.createEntity();
      star.addComponent(new Position(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
      star.addToWorld();
    }

    for (int i = 0; i < 500; i++) {
      Entity asteroid = world.createEntity();
      asteroid.addComponent(new Position(random.nextDouble() * UNIVERSE_WIDTH, random.nextDouble() * UNIVERSE_HEIGHT));
      asteroid.addComponent(generateRandomVelocity(0.5, 1.5));
      asteroid.addToWorld();
    }

    TagManager tagManager = new TagManager();
    tagManager.register(TAG_CAMERA, camera);
    tagManager.register(TAG_PLAYER, player);
    world.addManager(tagManager);

//    world.addSystem(new GravitationalSystem());
    world.addSystem(new PlayerControlSystem(gameCanvas));
    world.addSystem(new MovementSystem());
    world.addSystem(new CameraSystem());
    world.addSystem(new BackgroundRenderSystem(gameContext));
    world.addSystem(new PositionalRenderingSystem(gameContext));
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
  return new Velocity(generateRandom(minSpeed, maxSpeed), generateRandom(minSpeed, maxSpeed));
}

num generateRandom(num min, num max) {
  num randomNumber = min + max * random.nextDouble();
  randomNumber = randomNumber * (random.nextBool() ? 1 : -1);
  return randomNumber;
}

class GravitationalSystem extends EntityProcessingSystem {
  var velocityMapper;

  GravitationalSystem() : super(Aspect.getAspectForAllOf(new Velocity.hack().runtimeType));

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    Velocity vel = velocityMapper.get(entity);
    vel.y += 0.00981 * world.delta;
  }
}

class MovementSystem extends EntityProcessingSystem {
  ComponentMapper<Position> positionMapper;
  ComponentMapper<Velocity> velocityMapper;

  MovementSystem() : super(Aspect.getAspectForAllOf(new Position.hack().runtimeType, [new Velocity.hack().runtimeType]));

  void initialize() {
    positionMapper = new ComponentMapper<Position>(new Position.hack().runtimeType, world);
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    Position pos = positionMapper.get(entity);
    Velocity vel = velocityMapper.get(entity);

    pos.x += vel.x;
    pos.y += vel.y;
  }
}

class CameraSystem extends VoidEntitySystem {
  ComponentMapper<Position> positionMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  CameraSystem();

  void initialize() {
    positionMapper = new ComponentMapper<Position>(new Position.hack().runtimeType, world);
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processSystem() {
    Entity player = tagManager.getEntity(TAG_PLAYER);
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Position playerPos = positionMapper.get(player);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    cameraPos.x = playerPos.x - MAXWIDTH ~/ 2;
    cameraPos.y = playerPos.y - MAXHEIGHT ~/ 2;
  }
}

class DebugSystem extends VoidEntitySystem {
  SpanElement fpsElement = query("#fps");
  SpanElement playerPosElement = query("#playerPos");
  SpanElement cameraPosElement = query("#cameraPos");
  ComponentMapper<CameraPosition> cameraPositionMapper;
  ComponentMapper<Position> positionMapper;
  TagManager tagManager;

  void initialize() {
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    positionMapper = new ComponentMapper<Position>(new Position.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Entity player = tagManager.getEntity(TAG_PLAYER);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);
    Position playerPos = positionMapper.get(player);

    num fps = 1000 ~/ world.delta;
    fpsElement.text = "${fps}";
    cameraPosElement.text = "x: ${cameraPos.x}; y: ${cameraPos.y}";
    playerPosElement.text = "x: ${playerPos.x}; y: ${playerPos.y}";
  }
}


class Position extends Component {
  Position.hack();
  num _x, _y;
  Position(this._x, this._y);
  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class CameraPosition extends Position {
  CameraPosition.hack() : super.hack();
  CameraPosition([num x = 0, num y = 0]) : super(x, y);
}

class Velocity extends Component {
  Velocity.hack();
  num x, y;
  Velocity(this.x, this.y);
}
