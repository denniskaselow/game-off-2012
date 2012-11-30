library spaceoff;

import 'dart:math';
import 'package:dartemis/dartemis.dart';
export 'package:dartemis/dartemis.dart';

part 'src/spaceoff/components.dart';
part 'src/spaceoff/game_logic_systems.dart';

const int MAX_WIDTH = 800;
const int MAX_HEIGHT = 400;
const int HUD_HEIGHT = 100;
const int UNIVERSE_HEIGHT = MAX_HEIGHT * 4;
const int UNIVERSE_WIDTH = MAX_WIDTH * 2;
const String TAG_CAMERA = "CAMERA";
const String TAG_PLAYER = "PLAYER";
const String GROUP_BACKGROUND = "GROUP_BACKGROUND";

final Random random = new Random();


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
