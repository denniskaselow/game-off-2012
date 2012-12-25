part of spaceoff;

class Transform extends Component {
  static Type get type => new Transform._hack().runtimeType;
  Transform._hack();
  num _x, _y, angle, rotationRate;
  Transform(num x, num y, {this.angle : 0, this.rotationRate : 0}) : _x = x % UNIVERSE_WIDTH, _y = y % UNIVERSE_HEIGHT;
  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class CameraPosition extends Transform {
  static Type get type => new CameraPosition._hack().runtimeType;
  CameraPosition._hack() : super._hack();
  CameraPosition({num x: 0, num y: 0}) : super(x, y);
}

class Velocity extends Component {
  static Type get type => new Velocity._hack().runtimeType;
  Velocity._hack();
  num x, y;
  Velocity(this.x, this.y);  
  double get absolute => FastMath.sqrt(x * x + y * y);
  double get angle => atan2(y, x);
}

class Spatial extends Component {
  static Type get type => new Spatial._hack().runtimeType;
  Spatial._hack();

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
  static Type get type => new Background._hack().runtimeType;
  Background._hack();
  Background();
}

class Status extends Component {
  static Type get type => new Status._hack().runtimeType;
  num health;
  num maxHealth;
  num maxVelocity;
  bool destroyed = false;
  bool leaveLevel = false;
  bool enterLevel = false;

  Status._hack();
  Status({this.maxHealth : 100, this.maxVelocity : 20}) {
    health = maxHealth;
  }
}

class CircularBody extends Component {
  static Type get type => new CircularBody._hack().runtimeType;
  num radius;

  CircularBody._hack();
  CircularBody(this.radius);
}

class Mass extends Component {
  static Type get type => new Mass._hack().runtimeType;
  num value;

  Mass._hack();
  Mass(this.value);
}

class Cannon extends Component {
  static Type get type => new Cannon._hack().runtimeType;
  Cannon._hack() : cooldownTime = 0;

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
  static Type get type => new ExpirationTimer._hack().runtimeType;
  ExpirationTimer._hack() : maxTime = 0;

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
  static Type get type => new MiniMapRenderable._hack().runtimeType;
  MiniMapRenderable._hack();

  String color;
  MiniMapRenderable(this.color);
}

class Upgrade extends Component {
  static Type get type => new Upgrade._hack().runtimeType;
  Upgrade._hack();
  String name;
  bool fillHealth = false;
  num healthGain;
  num bullets;
  Upgrade(this.name, {this.healthGain : 0, this.fillHealth : false, this.bullets : 0});
}

class Damage extends Component {
  static Type get type => new Damage._hack().runtimeType;
  Damage._hack();
  num value;
  num maxValue;
  Damage(this.maxValue) {
    value = maxValue;
  }
}

class SplitsOnDestruction extends Component {
  static Type get type => new SplitsOnDestruction._hack().runtimeType;
  SplitsOnDestruction._hack();
  int parts;
  SplitsOnDestruction(this.parts);
}

class DisappearsOnDestruction extends Component {
  static Type get type => new DisappearsOnDestruction._hack().runtimeType;
  DisappearsOnDestruction._hack();
  DisappearsOnDestruction();
}

class Sound extends Component {
  static Type get type => new Sound._hack().runtimeType;
  Sound._hack();
  String source;
  String clip;
  Sound(this.source, this.clip);
}

class Particle extends Component {
  static Type get type => new Particle._hack().runtimeType;
  Particle._hack();
  String color;
  Particle(this.color);
}

class AutoPilot extends Component {
  static Type get type => new AutoPilot._hack().runtimeType; 
  AutoPilot._hack();
  num angle;
  num velocity;
  AutoPilot({this.angle, this.velocity});
}

class HyperDrive extends Component {
  static Type get type => new HyperDrive._hack().runtimeType; 
  HyperDrive._hack();
  double hyperSpaceMod = 0.0;
  HyperDrive();
}