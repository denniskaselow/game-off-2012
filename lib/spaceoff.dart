library spaceoff;

import 'dart:math';
import 'package:dartemis/dartemis.dart';
export 'package:dartemis/dartemis.dart';

part 'src/spaceoff/components.dart';
part 'src/spaceoff/game_logic_systems.dart';
part 'src/spaceoff/player_systems.dart';

const int MAX_WIDTH = 800;
const int MAX_HEIGHT = 400;
const int HUD_HEIGHT = 100;
const int UNIVERSE_HEIGHT = MAX_HEIGHT * 4;
const int UNIVERSE_WIDTH = MAX_WIDTH * 2;
const int MAX_BULLETS = 11;
const String TAG_CAMERA = "CAMERA";
const String TAG_PLAYER = "PLAYER";
const String GROUP_BACKGROUND = "GROUP_BACKGROUND";
const String GROUP_MENU = "GROUP_MENU";

final Random random = new Random();
final GameState gameState = new GameState();

class GameState {
  int currentLevel = 0;
  double levelMod = 1.0;
  bool nextLevelIsBeingPrepared = false;
  bool paused = false;
  bool started = false;
  bool highScoreSaved = false;
  double score = 0.0;
  bool get running => started && !paused;
}

Velocity generateRandomVelocity(num minSpeed, num maxSpeed) {
  num vel = generateRandom(minSpeed, maxSpeed);
  num angle = generateRandom(0, 2 * PI);
  num velx = vel * sin(angle);
  num vely = vel * cos(angle);
  return new Velocity(velx, vely);
}

num generateRandom(num min, num max) {
  num randomNumber = min + (max - min) * random.nextDouble();
  return randomNumber;
}

void createParticles(World world, Transform transform, num radius, int amount, Velocity velocity) {
  for (int i = 0; i < amount; i++) {
    Entity particle = world.createEntity();

    double offsetX = random.nextDouble() * radius * sin(2 * PI * random.nextDouble());
    double offsetY = random.nextDouble() * radius * sin(2 * PI * random.nextDouble());
    particle.addComponent(new Transform(transform.x + offsetX, transform.y + offsetY));

    double vAbs = velocity.absolute;
    double vAngle = velocity.angle;
    double factor = generateRandom(0.8, 2);
    double stretchX = vAbs * factor;
    double diff;
    if (factor < 1) {
      diff = (factor - 0.8) * 5;
    } else {
      diff =  2 - factor;
    }
    double stretchY = 0.05 * generateRandom(-diff, diff);
    double vx = cos(vAngle) * stretchX + cos(vAngle + PI/2) * stretchY;
    double vy = sin(vAngle) * stretchX + sin(vAngle + PI/2) * stretchY;
    particle.addComponent(new Velocity(vx, vy));
    particle.addComponent(new Particle("grey"));
    particle.addComponent(new ExpirationTimer(250 + random.nextInt(500)));
    particle.addToWorld();
  }
}

bool doCirclesCollide(num x1, num y1, num radius1, num x2, num y2, num radius2) {
  var dx = x2 - x1;
  var dy = y2 - y1;
  var dist = sqrt(dx * dx + dy * dy);
  return radius1 + radius2 > dist;
}