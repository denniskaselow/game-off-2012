part of spaceoff;

class Transform extends ComponentPoolable {
  num _x, _y, angle, rotationRate;
  Transform._();
  static Transform _constructor() => new Transform._();
  factory Transform(num x, num y, {num angle : 0, num rotationRate : 0}) {
    Transform transform = new Poolable.of(Transform, _constructor);
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

class CameraPosition extends ComponentPoolable{
  num _x, _y;

  CameraPosition._();
  static CameraPosition _constructor() => new CameraPosition._();
  factory CameraPosition({num x: 0, num y: 0}) {
    CameraPosition cameraPos = new Poolable.of(CameraPosition, _constructor);
    cameraPos.x = x;
    cameraPos.y = y;
    return cameraPos;
  }

  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class Velocity extends ComponentPoolable {
  num x, y;
  Velocity._();
  static Velocity _constructor() => new Velocity._();
  factory Velocity(num x, num y) {
    Velocity velocity = new Poolable.of(Velocity, _constructor);
    velocity.x = x;
    velocity.y = y;
    return velocity;
  }
  double get absolute => sqrt(x * x + y * y);
  double get angle => atan2(y, x);
}

class Spatial extends ComponentPoolable {
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
    Spatial spatial = new Poolable.of(Spatial, _constructor);
    spatial.resources = resources;
    spatial.scale = scale;
    spatial.isAnimated = isAnimated;
    return spatial;
  }
}

class Status extends ComponentPoolable {
  num health, maxHealth, maxVelocity;
  bool destroyed = false;
  Status._();
  static Status _constructor() => new Status._();
  factory Status({num maxHealth : 100, num maxVelocity : 20}) {
    Status status = new Poolable.of(Status, _constructor);
    status.maxHealth = maxHealth;
    status.maxVelocity = maxVelocity;
    status.health = maxHealth;
    return status;
  }
}

class CircularBody extends ComponentPoolable {
  num radius;
  CircularBody._();
  static CircularBody _constructor() => new CircularBody._();
  factory CircularBody(num radius) {
    CircularBody body = new Poolable.of(CircularBody, _constructor);
    body.radius = radius;
    return body;
  }
}

class Mass extends ComponentPoolable {
  double value;
  Mass._();
  static Mass _constructor() => new Mass._();
  factory Mass(double value) {
    Mass mass = new Poolable.of(Mass, _constructor);
    mass.value = value;
    return mass;
  }
}

class Cannon extends ComponentPoolable {
  bool shoot;
  num cooldownTimer, cooldownTime, bulletSpeed, bulletMass, bulletDamage;
  int amount;
  Cannon._();
  static Cannon _constructor() => new Cannon._();
  factory Cannon({num cooldownTime : 1000, num bulletSpeed: 0.05, num bulletMass : 0.1, num bulletDamage : 5, int amount: 1}) {
    Cannon cannon = new Poolable.of(Cannon, _constructor);
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

class ExpirationTimer extends ComponentPoolable {
  num maxTime, timeLeft;
  ExpirationTimer._();
  static ExpirationTimer _constructor() => new ExpirationTimer._();
  factory ExpirationTimer(num maxTime) {
    ExpirationTimer timer = new Poolable.of(ExpirationTimer, _constructor);
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

class MiniMapRenderable extends ComponentPoolable {
  String color;
  MiniMapRenderable._();
  static MiniMapRenderable _constructor() => new MiniMapRenderable._();
  factory MiniMapRenderable(String color) {
    MiniMapRenderable renderable = new Poolable.of(MiniMapRenderable, _constructor);
    renderable.color = color;
    return renderable;
  }
}

class Upgrade extends ComponentPoolable {
  String name;
  bool fillHealth;
  bool enableHyperDrive;
  int healthGain, massGain;
  int bullets;
  double bulletDamageGain;
  Upgrade._();
  static Upgrade _constructor() => new Upgrade._();
  factory Upgrade(String name, {int healthGain : 0, int massGain : 0, bool fillHealth : false, int bullets : 0, double bulletDamageGain: 0.0, bool enableHyperDrive : false}) {
    Upgrade upgrade = new Poolable.of(Upgrade, _constructor);
    upgrade.name = name;
    upgrade.healthGain = healthGain;
    upgrade.fillHealth = fillHealth;
    upgrade.bullets = bullets;
    upgrade.enableHyperDrive = enableHyperDrive;
    upgrade.bulletDamageGain = bulletDamageGain;
    upgrade.massGain = massGain;
    return upgrade;
  }
}

class Damage extends ComponentPoolable {
  num value, maxValue;
  Damage._();
  static Damage _constructor() => new Damage._();
  factory Damage(num maxValue) {
    Damage damage = new Poolable.of(Damage, _constructor);
    damage.maxValue = maxValue;
    damage.value = maxValue;
    return damage;
  }
}

class SplitsOnDestruction extends ComponentPoolable {
  int parts;
  SplitsOnDestruction._();
  static SplitsOnDestruction _constructor() => new SplitsOnDestruction._();
  factory SplitsOnDestruction(int parts) {
    SplitsOnDestruction sod = new Poolable.of(SplitsOnDestruction, _constructor);
    sod.parts = parts;
    return sod;
  }
}

class DisappearsOnDestruction extends ComponentPoolable {
  DisappearsOnDestruction._();
  static DisappearsOnDestruction _constructor() => new DisappearsOnDestruction._();
  factory DisappearsOnDestruction() => new Poolable.of(DisappearsOnDestruction, _constructor);
}

class Sound extends ComponentPoolable {
  String source, clip;
  Sound._();
  static Sound _constructor() => new Sound._();
  factory Sound(String source, String clip) {
    Sound sound = new Poolable.of(Sound, _constructor);
    sound.source = source;
    sound.clip = clip;
    return sound;
  }
}

class Particle extends ComponentPoolable {
  String color;
  Particle._();
  static Particle _constructor() => new Particle._();
  factory Particle(String color) {
    Particle particle = new Poolable.of(Particle, _constructor);
    particle.color = color;
    return particle;
  }
}

class AutoPilot extends ComponentPoolable {
  num angle, velocity;
  AutoPilot._();
  static AutoPilot _constructor() => new AutoPilot._();
  factory AutoPilot({num angle, num velocity}) {
    AutoPilot autoPilot = new Poolable.of(AutoPilot, _constructor);
    autoPilot.angle = angle;
    autoPilot.velocity = velocity;
    return autoPilot;
  }
}

class HyperDrive extends ComponentPoolable {
  bool enabled, active, shuttingDown;
  double hyperSpaceMod;
  HyperDrive._();
  static HyperDrive _constructor() => new HyperDrive._();
  factory HyperDrive() {
    HyperDrive component = new Poolable.of(HyperDrive, _constructor);
    component.enabled = false;
    component.active = false;
    component.shuttingDown = false;
    component.hyperSpaceMod = 0.0;
    return component;
  }
}

class ScoreComponent extends ComponentPoolable {
  num damageScore, killScore;
  ScoreComponent._();
  static ScoreComponent _constructor() => new ScoreComponent._();
  factory ScoreComponent(num damageScore, num killScore) {
    ScoreComponent component = new Poolable.of(ScoreComponent, _constructor);
    component.damageScore = damageScore;
    component.killScore = killScore;
    return component;
  }
}

class ScoreCollector extends ComponentPoolable {
  ScoreCollector._();
  factory ScoreCollector() => new Poolable.of(ScoreCollector, () => new ScoreCollector._());
}