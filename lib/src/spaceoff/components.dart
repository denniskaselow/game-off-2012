part of spaceoff;

class Transform extends Component {
  num _x, _y, angle, rotationRate;
  Transform(num x, num y, {this.angle : 0, this.rotationRate : 0}) : _x = x % UNIVERSE_WIDTH, _y = y % UNIVERSE_HEIGHT;
  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class CameraPosition extends Transform {
  CameraPosition({num x: 0, num y: 0}) : super(x, y);
}

class Velocity extends Component {
  num x, y;
  Velocity(this.x, this.y);
  double get absolute => sqrt(x * x + y * y);
  double get angle => atan2(y, x);
}

class Spatial extends Component {
  String resource;
  bool isSprite;
  num width, height, x, y;
  num scale;
  Spatial(this.resource, {this.scale : 1}) {
    isSprite = false;
  }
  Spatial.asSprite(this.resource, this.x, this.y, this.width, this.height, {this.scale : 1}) {
    isSprite = true;
  }
  Spatial.fromSpatial(Spatial spatial, this.scale) : resource = spatial.resource,
                                                     isSprite = spatial.isSprite,
                                                     width = spatial.width,
                                                     height = spatial.height,
                                                     x = spatial.x,
                                                     y = spatial.y;
}

class Background extends Component {
  Background();
}

class Status extends Component {
  num health;
  num maxHealth;
  num maxVelocity;
  bool destroyed = false;
  Status({this.maxHealth : 100, this.maxVelocity : 20}) {
    health = maxHealth;
  }
}

class CircularBody extends Component {
  num radius;

  CircularBody(this.radius);
}

class Mass extends Component {
  num value;

  Mass(this.value);
}

class Cannon extends Component {
  bool shoot = false;
  num cooldownTimer = 0;
  final num cooldownTime;
  num bulletSpeed;
  num bulletMass;
  num bulletDamage;
  int amount;

  Cannon({this.cooldownTime : 1000, this.bulletSpeed: 0.05, this.bulletMass : 0.1, this.bulletDamage : 5, this.amount: 1});

  bool get canShoot {
    if (shoot && cooldownTimer <= 0) return true;
    return false;
  }

  void resetCooldown() {
    cooldownTimer = cooldownTime;
  }
}

class ExpirationTimer extends Component {
  final num maxTime;
  num timeLeft;
  ExpirationTimer(this.maxTime) {
    timeLeft = maxTime;
  }

  void expireBy(num delta) {
    timeLeft -= delta;
    if (expired) {
      timeLeft = 0;
    }
  }

  bool get expired => timeLeft <= 0;

  num get percentLeft => timeLeft / maxTime;
}

class MiniMapRenderable extends Component {
  String color;
  MiniMapRenderable(this.color);
}

class Upgrade extends Component {
  String name;
  bool fillHealth;
  bool enableHyperDrive;
  num healthGain;
  num bullets;
  Upgrade(this.name, {this.healthGain : 0, this.fillHealth : false, this.bullets : 0, this.enableHyperDrive : false});
}

class Damage extends Component {
  num value;
  num maxValue;
  Damage(this.maxValue) {
    value = maxValue;
  }
}

class SplitsOnDestruction extends Component {
  int parts;
  SplitsOnDestruction(this.parts);
}

class DisappearsOnDestruction extends Component {
  DisappearsOnDestruction();
}

class Sound extends Component {
  String source;
  String clip;
  Sound(this.source, this.clip);
}

class Particle extends Component {
  String color;
  Particle(this.color);
}

class AutoPilot extends Component {
  num angle;
  num velocity;
  AutoPilot({this.angle, this.velocity});
}

class HyperDrive extends Component {
  bool enabled = false;
  bool active = false;
  bool shuttingDown = false;
  double hyperSpaceMod = 0.0;
  HyperDrive();
}