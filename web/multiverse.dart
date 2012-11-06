library multiverse;

import 'dart:html' hide Entity;

import 'package:dartemis/dartemis.dart';

part 'systems/render_systems.dart';

const int MAXWIDTH = 800;
const int MAXHEIGHT = 400;
const int HUDHEIGHT = 100;
const int PIXEL_PER_METER = 100;

void main() {
  CanvasElement canvas = query('#gamecontainer');
  canvas.parent.rect.then((ElementRect rect) {
    canvas.width = MAXWIDTH;
    canvas.height = MAXHEIGHT + HUDHEIGHT;

    Game game = new Game(canvas);
    game.start();
  });
}

class Game {
  CanvasElement canvas;
  CanvasRenderingContext2D context2d;
  num lastTime = 0;
  World world;

  Game(this.canvas) {
    context2d = canvas.context2d;
  }

  void start() {
    world = new World();

    Entity player = world.createEntity();

    player.addComponent(new Position(MAXWIDTH ~/ 2, MAXHEIGHT ~/ 2));
    player.addComponent(new Velocity(0, 0));

    player.addToWorld();

    world.addSystem(new GravitationalSystem());
    world.addSystem(new MovementSystem());
    world.addSystem(new BackgroundRenderSystem(context2d));
    world.addSystem(new PositionalRenderingSystem(context2d));
    world.addSystem(new HudRenderSystem(context2d));


    world.initialize();

    gameLoop(0);
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

class Position extends Component {
  Position.hack();
  num x, y;
  Position(this.x, this.y);
}

class Velocity extends Component {
  Velocity.hack();
  num x, y;
  Velocity(this.x, this.y);
}
