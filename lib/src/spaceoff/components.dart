part of spaceoff;

class Transform extends PooledComponent {
  num _x, _y, angle, rotationRate;
  Transform._();
  static Transform _constructor() => new Transform._();
  factory Transform(num x, num y, {num angle : 0, num rotationRate : 0}) {
    Transform transform = new Pooled.of(Transform, _constructor);
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

class CameraPosition extends PooledComponent{
  num _x, _y;

  CameraPosition._();
  static CameraPosition _constructor() => new CameraPosition._();
  factory CameraPosition({num x: 0, num y: 0}) {
    CameraPosition cameraPos = new Pooled.of(CameraPosition, _constructor);
    cameraPos.x = x;
    cameraPos.y = y;
    return cameraPos;
  }

  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class Velocity extends PooledComponent {
  double x, y;
  Velocity._();
  static Velocity _constructor() => new Velocity._();
  factory Velocity(double x, double y) {
    Velocity velocity = new Pooled.of(Velocity, _constructor);
    velocity.x = x;
    velocity.y = y;
    return velocity;
  }
  double get absolute => sqrt(x * x + y * y);
  double get angle => atan2(y, x);
}

class Thruster extends PooledComponent {
  static const TURN_NONE = 0;
  static const TURN_LEFT = -1;
  static const TURN_RIGHT = 1;
  bool active;
  double thrust;
  int turn;
  Thruster._();
  static Thruster _constructor() => new Thruster._();
  factory Thruster({double thrust: 0.0002}) {
    Thruster thruster = new Pooled.of(Thruster, _constructor);
    thruster.thrust = thrust;
    thruster.active = false;
    thruster.turn = TURN_NONE;
    return thruster;
  }
}

class Turbo extends PooledComponent with Cooldown {
  bool enabled, active;
  double timeActive, maxTimeActive;
  double oldVelocityX, oldVelocity, oldVelocityY, turboVelocity;
  Turbo._();
  static Turbo _constructor() => new Turbo._();
  factory Turbo({double cooldownTime: 5000.0, double maxTimeActive : 400.0}) {
    Turbo turbo = new Pooled.of(Turbo, _constructor);
    turbo.enabled = true;
    turbo.active = false;
    turbo.timeActive = 0.0;
    turbo.maxTimeActive = maxTimeActive;
    turbo.cooldownTime = cooldownTime;
    turbo.cooldownTimer = 0.0;
    turbo.oldVelocity = null;
    turbo.oldVelocityX = null;
    turbo.oldVelocityY = null;
    turbo.turboVelocity = null;
    return turbo;
  }

  bool get canTurboActivate {
    if (enabled && cooledDown) return true;
    return false;
  }
}

class Spatial extends PooledComponent {
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
    Spatial spatial = new Pooled.of(Spatial, _constructor);
    spatial.resources = resources;
    spatial.scale = scale;
    spatial.isAnimated = isAnimated;
    return spatial;
  }
}

class Status extends PooledComponent {
  num health, maxHealth, maxVelocity;
  bool destroyed = false;
  Status._();
  static Status _constructor() => new Status._();
  factory Status({num maxHealth : 100, num maxVelocity : 20}) {
    Status status = new Pooled.of(Status, _constructor);
    status.maxHealth = maxHealth;
    status.maxVelocity = maxVelocity;
    status.health = maxHealth;
    return status;
  }
}

class CircularBody extends PooledComponent {
  num radius;
  CircularBody._();
  static CircularBody _constructor() => new CircularBody._();
  factory CircularBody(num radius) {
    CircularBody body = new Pooled.of(CircularBody, _constructor);
    body.radius = radius;
    return body;
  }
}

class Mass extends PooledComponent {
  double value;
  Mass._();
  static Mass _constructor() => new Mass._();
  factory Mass(double value) {
    Mass mass = new Pooled.of(Mass, _constructor);
    mass.value = value;
    return mass;
  }
}

class Cannon extends PooledComponent with Cooldown {
  bool shoot;
  double bulletSpeed, bulletMass, bulletDamage;
  int amount;
  Cannon._();
  static Cannon _constructor() => new Cannon._();
  factory Cannon({double cooldownTime : 200.0, double bulletSpeed: 0.5, double bulletMass : 0.1, double bulletDamage : 5.0, int amount: 1}) {
    Cannon cannon = new Pooled.of(Cannon, _constructor);
    cannon.bulletSpeed = bulletSpeed;
    cannon.bulletMass = bulletMass;
    cannon.bulletDamage = bulletDamage;
    cannon.amount = amount;
    cannon.shoot = false;
    cannon.cooldownTime = cooldownTime;
    cannon.cooldownTimer = 0.0;
    return cannon;
  }

  bool get canShoot {
    if (shoot && cooledDown) return true;
    return false;
  }
}

class ExpirationTimer extends PooledComponent {
  num maxTime, timeLeft;
  ExpirationTimer._();
  static ExpirationTimer _constructor() => new ExpirationTimer._();
  factory ExpirationTimer(num maxTime) {
    ExpirationTimer timer = new Pooled.of(ExpirationTimer, _constructor);
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

class MiniMapRenderable extends PooledComponent {
  String color;
  MiniMapRenderable._();
  static MiniMapRenderable _constructor() => new MiniMapRenderable._();
  factory MiniMapRenderable(String color) {
    MiniMapRenderable renderable = new Pooled.of(MiniMapRenderable, _constructor);
    renderable.color = color;
    return renderable;
  }
}

class Upgrade extends PooledComponent {
  String name;
  bool fillHealth;
  bool enableHyperDrive;
  int healthGain, massGain;
  int bullets;
  double bulletDamageGain, thrustGain;
  Upgrade._();
  static Upgrade _constructor() => new Upgrade._();
  factory Upgrade(String name,
                {int healthGain : 0, int massGain : 0, bool fillHealth : false,
                 int bullets : 0, double bulletDamageGain: 0.0, double thrustGain: 0.0,
                 bool enableHyperDrive : false}) {
    Upgrade upgrade = new Pooled.of(Upgrade, _constructor);
    upgrade.name = name;
    upgrade.healthGain = healthGain;
    upgrade.fillHealth = fillHealth;
    upgrade.bullets = bullets;
    upgrade.enableHyperDrive = enableHyperDrive;
    upgrade.bulletDamageGain = bulletDamageGain;
    upgrade.massGain = massGain;
    upgrade.thrustGain = thrustGain;
    return upgrade;
  }
}

class Damage extends PooledComponent {
  num value, maxValue;
  Damage._();
  static Damage _constructor() => new Damage._();
  factory Damage(num maxValue) {
    Damage damage = new Pooled.of(Damage, _constructor);
    damage.maxValue = maxValue;
    damage.value = maxValue;
    return damage;
  }
}

class SplitsOnDestruction extends PooledComponent {
  int parts;
  SplitsOnDestruction._();
  static SplitsOnDestruction _constructor() => new SplitsOnDestruction._();
  factory SplitsOnDestruction(int parts) {
    SplitsOnDestruction sod = new Pooled.of(SplitsOnDestruction, _constructor);
    sod.parts = parts;
    return sod;
  }
}

class DisappearsOnDestruction extends PooledComponent {
  DisappearsOnDestruction._();
  static DisappearsOnDestruction _constructor() => new DisappearsOnDestruction._();
  factory DisappearsOnDestruction() => new Pooled.of(DisappearsOnDestruction, _constructor);
}

class Sound extends PooledComponent {
  String source, clip;
  Sound._();
  static Sound _constructor() => new Sound._();
  factory Sound(String source, String clip) {
    Sound sound = new Pooled.of(Sound, _constructor);
    sound.source = source;
    sound.clip = clip;
    return sound;
  }
}

class Particle extends PooledComponent {
  String color;
  Particle._();
  static Particle _constructor() => new Particle._();
  factory Particle(String color) {
    Particle particle = new Pooled.of(Particle, _constructor);
    particle.color = color;
    return particle;
  }
}

class AutoPilot extends PooledComponent {
  num angle, velocity;
  AutoPilot._();
  static AutoPilot _constructor() => new AutoPilot._();
  factory AutoPilot({num angle, num velocity}) {
    AutoPilot autoPilot = new Pooled.of(AutoPilot, _constructor);
    autoPilot.angle = angle;
    autoPilot.velocity = velocity;
    return autoPilot;
  }
}

class HyperDrive extends PooledComponent {
  bool enabled, active, shuttingDown;
  double hyperSpaceMod;
  HyperDrive._();
  static HyperDrive _constructor() => new HyperDrive._();
  factory HyperDrive() {
    HyperDrive component = new Pooled.of(HyperDrive, _constructor);
    component.enabled = false;
    component.active = false;
    component.shuttingDown = false;
    component.hyperSpaceMod = 0.0;
    return component;
  }
}

class ScoreComponent extends PooledComponent {
  num damageScore, killScore;
  ScoreComponent._();
  static ScoreComponent _constructor() => new ScoreComponent._();
  factory ScoreComponent(num damageScore, num killScore) {
    ScoreComponent component = new Pooled.of(ScoreComponent, _constructor);
    component.damageScore = damageScore;
    component.killScore = killScore;
    return component;
  }
}

class ScoreCollector extends PooledComponent {
  ScoreCollector._();
  factory ScoreCollector() => new Pooled.of(ScoreCollector, () => new ScoreCollector._());
}


// Mixins
abstract class Cooldown {
  double cooldownTimer, cooldownTime;
  bool get cooledDown => cooldownTimer <= 0;
  void resetCooldown() {
    cooldownTimer = cooldownTime;
  }
}