part of spaceoff;

class Transform implements Component {
  num _x, _y, angle, rotationRate;
  Transform._();
  static Transform _constructor() => new Transform._();
  factory Transform(num x, num y, {num angle : 0, num rotationRate : 0}) {
    Transform transform = new Component(Transform, _constructor);
    transform.x = x;
    transform.y = y;
    transform.angle = angle;
    transform.rotationRate = rotationRate;
    return transform;
  }
  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class CameraPosition implements Component{
  num _x, _y;

  CameraPosition._();
  static CameraPosition _constructor() => new CameraPosition._();
  factory CameraPosition({num x: 0, num y: 0}) {
    CameraPosition cameraPos = new Component(CameraPosition, _constructor);
    cameraPos.x = x;
    cameraPos.y = y;
    return cameraPos;
  }

  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class Velocity implements Component {
  num x, y;
  Velocity._();
  static Velocity _constructor() => new Velocity._();
  factory Velocity(num x, num y) {
    Velocity velocity = new Component(Velocity, _constructor);
    velocity.x = x;
    velocity.y = y;
    return velocity;
  }
  double get absolute => sqrt(x * x + y * y);
  double get angle => atan2(y, x);
}

class Spatial implements Component {
  List<String> resources;
  num scale;
  bool isAnimated;
  Spatial._();
  static Spatial _constructor() => new Spatial._();
  factory Spatial(String resource, {num scale : 1}) {
    return _create([resource], scale, false);
  }
  factory Spatial.animated(List<String> resources, {num scale : 1}) {
    return _create(resources, scale, true);
  }
  factory Spatial.fromSpatial(Spatial otherSpatial, num scale) {
    return _create(otherSpatial.resources, scale, otherSpatial.isAnimated);
  }
  static Spatial _create(List<String> resources, num scale, bool isAnimated) {
    Spatial spatial = new Component(Spatial, _constructor);
    spatial.resources = resources;
    spatial.scale = scale;
    spatial.isAnimated = isAnimated;
    return spatial;
  }
}

class Status implements Component {
  num health, maxHealth, maxVelocity;
  bool destroyed = false;
  Status._();
  static Status _constructor() => new Status._();
  factory Status({num maxHealth : 100, num maxVelocity : 20}) {
    Status status = new Component(Status, _constructor);
    status.maxHealth = maxHealth;
    status.maxVelocity = maxVelocity;
    status.health = maxHealth;
    return status;
  }
}

class CircularBody implements Component {
  num radius;
  CircularBody._();
  static CircularBody _constructor() => new CircularBody._();
  factory CircularBody(num radius) {
    CircularBody body = new Component(CircularBody, _constructor);
    body.radius = radius;
    return body;
  }
}

class Mass implements Component {
  num value;
  Mass._();
  static Mass _constructor() => new Mass._();
  factory Mass(num value) {
    Mass mass = new Component(Mass, _constructor);
    mass.value = value;
    return mass;
  }
}

class Cannon implements Component {
  bool shoot;
  num cooldownTimer, cooldownTime, bulletSpeed, bulletMass, bulletDamage;
  int amount;
  Cannon._();
  static Cannon _constructor() => new Cannon._();
  factory Cannon({num cooldownTime : 1000, num bulletSpeed: 0.05, num bulletMass : 0.1, num bulletDamage : 5, int amount: 1}) {
    Cannon cannon = new Component(Cannon, _constructor);
    cannon.cooldownTime = cooldownTime;
    cannon.bulletSpeed = bulletSpeed;
    cannon.bulletMass = bulletMass;
    cannon.bulletDamage = bulletDamage;
    cannon.amount = amount;
    cannon.shoot = false;
    cannon.cooldownTimer = 0;
    return cannon;
  }

  bool get canShoot {
    if (shoot && cooldownTimer <= 0) return true;
    return false;
  }

  void resetCooldown() {
    cooldownTimer = cooldownTime;
  }
}

class ExpirationTimer implements Component {
  num maxTime, timeLeft;
  ExpirationTimer._();
  static ExpirationTimer _constructor() => new ExpirationTimer._();
  factory ExpirationTimer(num maxTime) {
    ExpirationTimer timer = new Component(ExpirationTimer, _constructor);
    timer.maxTime = maxTime;
    timer.timeLeft = maxTime;
    return timer;
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

class MiniMapRenderable implements Component {
  String color;
  MiniMapRenderable._();
  static MiniMapRenderable _constructor() => new MiniMapRenderable._();
  factory MiniMapRenderable(String color) {
    MiniMapRenderable renderable = new Component(MiniMapRenderable, _constructor);
    renderable.color = color;
    return renderable;
  }
}

class Upgrade implements Component {
  String name;
  bool fillHealth;
  bool enableHyperDrive;
  num healthGain;
  int bullets;
  Upgrade._();
  static Upgrade _constructor() => new Upgrade._();
  factory Upgrade(String name, {num healthGain : 0, bool fillHealth : false, int bullets : 0, bool enableHyperDrive : false}) {
    Upgrade upgrade = new Component(Upgrade, _constructor);
    upgrade.name = name;
    upgrade.healthGain = healthGain;
    upgrade.fillHealth = fillHealth;
    upgrade.bullets = bullets;
    upgrade.enableHyperDrive = enableHyperDrive;
    return upgrade;
  }
}

class Damage implements Component {
  num value, maxValue;
  Damage._();
  static Damage _constructor() => new Damage._();
  factory Damage(num maxValue) {
    Damage damage = new Component(Damage, _constructor);
    damage.maxValue = maxValue;
    damage.value = maxValue;
    return damage;
  }
}

class SplitsOnDestruction implements Component {
  int parts;
  SplitsOnDestruction._();
  static SplitsOnDestruction _constructor() => new SplitsOnDestruction._();
  factory SplitsOnDestruction(int parts) {
    SplitsOnDestruction sod = new Component(SplitsOnDestruction, _constructor);
    sod.parts = parts;
    return sod;
  }
}

class DisappearsOnDestruction implements Component {
  DisappearsOnDestruction._();
  static DisappearsOnDestruction _constructor() => new DisappearsOnDestruction._();
  factory DisappearsOnDestruction() => new Component(DisappearsOnDestruction, _constructor);
}

class Sound implements Component {
  String source, clip;
  Sound._();
  static Sound _constructor() => new Sound._();
  factory Sound(String source, String clip) {
    Sound sound = new Component(Sound, _constructor);
    sound.source = source;
    sound.clip = clip;
    return sound;
  }
}

class Particle implements Component {
  String color;
  Particle._();
  static Particle _constructor() => new Particle._();
  factory Particle(String color) {
    Particle particle = new Component(Particle, _constructor);
    particle.color = color;
    return particle;
  }
}

class AutoPilot implements Component {
  num angle, velocity;
  AutoPilot._();
  static AutoPilot _constructor() => new AutoPilot._();
  factory AutoPilot({num angle, num velocity}) {
    AutoPilot autoPilot = new Component(AutoPilot, _constructor);
    autoPilot.angle = angle;
    autoPilot.velocity = velocity;
    return autoPilot;
  }
}

class HyperDrive implements Component {
  bool enabled, active, shuttingDown;
  double hyperSpaceMod;
  HyperDrive._();
  static HyperDrive _constructor() => new HyperDrive._();
  factory HyperDrive() {
    HyperDrive component = new Component(HyperDrive, _constructor);
    component.enabled = false;
    component.active = false;
    component.shuttingDown = false;
    component.hyperSpaceMod = 0.0;
    return component;
  }
}

typedef void MenuAction();
class MenuItem implements Component {
  int x, y, width, height;
  String text;
  bool hover;
  MenuAction action;
  MenuItem._();
  static MenuItem _constructor() => new MenuItem._();
  factory MenuItem(int x, int y, int width, int height, String text, MenuAction action) {
    MenuItem component = new Component(MenuItem, _constructor);
    component..x = x
             ..y = y
             ..width = width
             ..height = height
             ..text = text
             ..action = action
             ..hover = false;
    return component;
  }
}

class ScoreComponent implements Component {
  num damageScore, killScore;
  ScoreComponent._();
  static ScoreComponent _constructor() => new ScoreComponent._();
  factory ScoreComponent(num damageScore, num killScore) {
    ScoreComponent component = new Component(ScoreComponent, _constructor);
    component.damageScore = damageScore;
    component.killScore = killScore;
    return component;
  }
}

class ScoreCollector implements Component {
  ScoreCollector._();
  factory ScoreCollector() => new Component(ScoreCollector, () => new ScoreCollector._());
}