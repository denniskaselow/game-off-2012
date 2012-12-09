part of spaceoff;

class Transform extends Component {
  Transform.hack();
  num _x, _y, angle, rotationRate;
  Transform(num x, num y, {this.angle : 0, this.rotationRate : 0}) : _x = x % UNIVERSE_WIDTH, _y = y % UNIVERSE_HEIGHT;
  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class CameraPosition extends Transform {
  CameraPosition.hack() : super.hack();
  CameraPosition({num x: 0, num y: 0}) : super(x, y);
}

class Velocity extends Component {
  Velocity.hack();
  num x, y;
  Velocity(this.x, this.y);
}

class Spatial extends Component {

  Spatial.hack();

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
  Background.hack();
  Background();
}

class Status extends Component {
  num health;
  num maxHealth;
  num maxVelocity;
  bool destroyed = false;

  Status.hack();
  Status({this.maxHealth : 100, this.maxVelocity : 20}) {
    health = maxHealth;
  }
}

class CircularBody extends Component {
  num radius;

  CircularBody.hack();
  CircularBody(this.radius);
}

class Mass extends Component {
  num value;

  Mass.hack();
  Mass(this.value);
}

class Cannon extends Component {
  Cannon.hack() : cooldownTime = 0;

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
  ExpirationTimer.hack() : maxTime = 0;

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
  MiniMapRenderable.hack();

  String color;
  MiniMapRenderable(this.color);
}

class Upgrade extends Component {
  Upgrade.hack();
  String name;
  num maxHealth;
  num bullets;
  Upgrade(this.name, {this.maxHealth : 0, this.bullets : 0});

  void applyToStatus(Status status) {
    status.maxHealth += maxHealth;
    status.health = status.maxHealth;
  }

  void applyToCannon(Cannon cannon) {
    cannon.amount += bullets;
  }
}

class Damage extends Component {
  Damage.hack();
  num value;
  num maxValue;
  Damage(this.maxValue) {
    value = maxValue;
  }
}

class SplitsOnDestruction extends Component {
  SplitsOnDestruction.hack();
  int parts;
  SplitsOnDestruction(this.parts);
}

class DisappearsOnDestruction extends Component {
  DisappearsOnDestruction.hack();
  DisappearsOnDestruction();
}

class Sound extends Component {
  Sound.hack();
  String source;
  String clip;
  Sound(this.source, this.clip);
}