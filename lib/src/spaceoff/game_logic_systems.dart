part of spaceoff;


abstract class OnScreenProcessingSystem extends EntitySystem {

  static final num MAX_RENDER_DISTANCE_X = MAX_WIDTH + 50;
  static final num MAX_RENDER_DISTANCE_Y = MAX_HEIGHT + 50;
  static final num MIN_RENDER_DISTANCE_X_BORDER = UNIVERSE_WIDTH - MAX_RENDER_DISTANCE_X;
  static final num MIN_RENDER_DISTANCE_Y_BORDER = UNIVERSE_HEIGHT - MAX_RENDER_DISTANCE_Y;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  OnScreenProcessingSystem(Aspect aspect) : super(aspect.allOf(new Transform.hack().runtimeType));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processEntities(ImmutableBag<Entity> entities) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    Bag<Entity> entitiesOnScreen = new Bag<Entity>();

    entities.forEach((entity) {
      Transform pos = transformMapper.get(entity);

      if (isWithtinXRange(pos, cameraPos) && isWithtinYRange(pos, cameraPos)) {
        entitiesOnScreen.add(entity);
      }
    });
    processEntitiesOnScreen(entitiesOnScreen);
  }

  bool isWithtinXRange(Transform pos, CameraPosition camPos) {
    num distanceX = (camPos.x - pos.x).abs();
    return (distanceX < MAX_RENDER_DISTANCE_X || distanceX > MIN_RENDER_DISTANCE_X_BORDER);
  }

  bool isWithtinYRange(Transform pos, CameraPosition camPos) {
    num distanceY = (camPos.y - pos.y).abs();
    return (distanceY < MAX_RENDER_DISTANCE_Y || distanceY > MIN_RENDER_DISTANCE_Y_BORDER);
  }

  void processEntitiesOnScreen(ImmutableBag<Entity> entities);

  bool checkProcessing() => true;
}

abstract class OnScreenEntityProcessingSystem extends OnScreenProcessingSystem {

  OnScreenEntityProcessingSystem(Aspect aspect) : super(aspect);

  void initialize() {
    super.initialize();
  }

  void processEntitiesOnScreen(ImmutableBag<Entity> entities) {
    entities.forEach((entity) => processEntityOnScreen(entity));
  }

  void processEntityOnScreen(Entity entity);

}

class MovementSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> positionMapper;
  ComponentMapper<Velocity> velocityMapper;

  MovementSystem() : super(Aspect.getAspectForAllOf(new Transform.hack().runtimeType, [new Velocity.hack().runtimeType]));

  void initialize() {
    positionMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    Transform transform = positionMapper.get(entity);
    Velocity vel = velocityMapper.get(entity);

    transform.x += vel.x * world.delta;
    transform.y += vel.y * world.delta;
    transform.angle += transform.rotationRate;
  }
}

class CameraSystem extends VoidEntitySystem {
  ComponentMapper<Transform> positionMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  CameraSystem();

  void initialize() {
    positionMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processSystem() {
    Entity player = tagManager.getEntity(TAG_PLAYER);
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Transform playerPos = positionMapper.get(player);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    cameraPos.x = playerPos.x - MAX_WIDTH ~/ 2;
    cameraPos.y = playerPos.y - MAX_HEIGHT ~/ 2;
  }
}

class UpgradeCollectionSystem extends OnScreenEntityProcessingSystem {
  const int MAX_BULLETS = 11;

  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Upgrade> upgradeMapper;
  Status status;
  Transform transform;
  CircularBody body;
  Cannon cannon;

  UpgradeCollectionSystem() : super(Aspect.getAspectForAllOf(new Upgrade.hack().runtimeType, [new Transform.hack().runtimeType, new CircularBody.hack().runtimeType]));

  void initialize() {
    super.initialize();
    bodyMapper = new ComponentMapper<CircularBody>(new CircularBody.hack().runtimeType, world);
    upgradeMapper = new ComponentMapper<Upgrade>(new Upgrade.hack().runtimeType, world);
    var cannonMapper = new ComponentMapper<Cannon>(new Cannon.hack().runtimeType, world);

    var statusMapper = new ComponentMapper<Status>(new Status.hack().runtimeType, world);
    TagManager tagManager = world.getManager(new TagManager().runtimeType);
    Entity player = tagManager.getEntity(TAG_PLAYER);
    status = statusMapper.get(player);
    transform = transformMapper.get(player);
    body = bodyMapper.get(player);
    cannon = cannonMapper.get(player);
  }

  void processEntityOnScreen(Entity entity) {
    Transform upgradeTransform = transformMapper.get(entity);
    CircularBody upgradeBody = bodyMapper.get(entity);

    if (Utils.doCirclesCollide(transform.x, transform.y, body.radius, upgradeTransform.x, upgradeTransform.y, upgradeBody.radius)) {
      Upgrade upgrade = upgradeMapper.get(entity);

      status.maxHealth += upgrade.healthGain;
      if (upgrade.fillHealth) {
        status.health = status.maxHealth;
      }
      cannon.amount = cannon.amount == MAX_BULLETS ? MAX_BULLETS : cannon.amount + upgrade.bullets;

      entity.deleteFromWorld();
    }
  }

  void end() {
    // no collision with collected upgrades wanted
    world.processEntityChanges();
  }

  bool checkProcessing() => status.health > 0;
}

class CircularCollisionDetectionSystem extends OnScreenProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;
  ComponentMapper<Status> statusMapper;
  ComponentMapper<Damage> damageMapper;
  ComponentMapper<ExpirationTimer> expirationMapper;

  CircularCollisionDetectionSystem() : super(Aspect.getAspectForAllOf(new CircularBody.hack().runtimeType, [new Transform.hack().runtimeType, new Velocity.hack().runtimeType, new Mass.hack().runtimeType]));

  void initialize() {
    super.initialize();
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    bodyMapper = new ComponentMapper<CircularBody>(new CircularBody.hack().runtimeType, world);
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
    massMapper = new ComponentMapper<Mass>(new Mass.hack().runtimeType, world);
    statusMapper = new ComponentMapper<Status>(new Status.hack().runtimeType, world);
    damageMapper = new ComponentMapper<Damage>(new Damage.hack().runtimeType, world);
    expirationMapper = new ComponentMapper<ExpirationTimer>(new ExpirationTimer.hack().runtimeType, world);
  }

  void processEntitiesOnScreen(ImmutableBag<Entity> entities) {
    if (entities.size > 1) {
      for (int i = 0; i < entities.size - 1; i++) {
        Entity e1 = entities[i];
        Transform t1 = transformMapper.get(e1);
        CircularBody c1 = bodyMapper.get(e1);
        for (int j = i+1; j < entities.size; j++) {
          Entity e2 = entities[j];
          Transform t2 = transformMapper.get(e2);
          CircularBody c2 = bodyMapper.get(e2);

          if (Utils.doCirclesCollide(t1.x, t1.y, c1.radius, t2.x, t2.y, c2.radius)) {
            Velocity v1 = velocityMapper.get(e1);
            Velocity v2 = velocityMapper.get(e2);
            Mass m1 = massMapper.get(e1);
            Mass m2 = massMapper.get(e2);

            num dx = t2.x - t1.x;
            num dy = t2.y - t1.y;

            num distance = sqrt(dx*dx + dy*dy);
            num radiusTotal = c1.radius + c2.radius;
            num overlap = radiusTotal - distance;

            if (overlap > 0) {
              num dvx = v2.x - v1.x;
              num dvy = v2.y - v1.y;

              num time = (distance - radiusTotal) / sqrt(dvx*dvx + dvy*dvy);

              t1.x += time * v1.x;
              t1.y += time * v1.y;
              t2.x += time * v2.x;
              t2.y += time * v2.y;

              dx = t2.x - t1.x;
              dy = t2.y - t1.y;
            }
            // calculate collision angle
            num phi = atan2(dy, dx);

            num v1i = sqrt(v1.x * v1.x + v1.y * v1.y);
            num v2i = sqrt(v2.x * v2.x + v2.y * v2.y);

            num ang1 = atan2(v1.y, v1.x);
            num ang2 = atan2(v2.y, v2.x);

            // transforming velocities in a coordinate system where both circles have an equal y-coordinate
            // thus allowing 1D elastic collision calculations
            num v1xr = v1i * cos(ang1 - phi);
            num v1yr = v1i * sin(ang1 - phi);
            num v2xr = v2i * cos(ang2 - phi);
            num v2yr = v2i * sin(ang2 - phi);

            // calculate momentums
            num p1 = v1xr * m1.value;
            num p2 = v2xr * m2.value;
            num mTotal = m1.value + m2.value;

            // elastic collision
            num v1fxr = (p1 + 2 * p2 - m2.value * v1xr) / mTotal;
            num v2fxr = (p2 + 2 * p1 - m1.value * v2xr) / mTotal;
            num v1fyr = v1yr;
            num v2fyr = v2yr;

            // transform back to original coordinate system
            v1.x = cos(phi) * v1fxr + cos(phi + PI/2) * v1fyr;
            v1.y = sin(phi) * v1fxr + sin(phi + PI/2) * v1fyr;
            v2.x = cos(phi) * v2fxr + cos(phi + PI/2) * v2fyr;
            v2.y = sin(phi) * v2fxr + sin(phi + PI/2) * v2fyr;

            Status s1 = statusMapper.getSafe(e1);
            Status s2 = statusMapper.getSafe(e2);
            Damage d1 = damageMapper.getSafe(e1);
            Damage d2 = damageMapper.getSafe(e2);

            if (null != s1) {
              s1.health -= (p2.abs() + p1.abs()) / 5;
              if (null != d2) s1.health -= d2.value;
            }
            if (null != s2) {
              s2.health -= (p2.abs() + p1.abs()) / 5;
              if (null != d1) s2.health -= d1.value;
            }

            ExpirationTimer timer1 = expirationMapper.getSafe(e1);
            ExpirationTimer timer2 = expirationMapper.getSafe(e2);
            if (null != timer1) {
              timer1.timeLeft *= 0.8;
            }
            if (null != timer2) {
              timer2.timeLeft *= 0.8;
            }
          }
        }
      }
    }
  }
}

class BulletSpawningSystem extends EntityProcessingSystem {

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Cannon> cannonMapper;
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;

  BulletSpawningSystem() : super(Aspect.getAspectForAllOf(new Cannon.hack().runtimeType, [new Transform.hack().runtimeType, new Velocity.hack().runtimeType, new Mass.hack().runtimeType]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
    massMapper = new ComponentMapper<Mass>(new Mass.hack().runtimeType, world);
    cannonMapper = new ComponentMapper<Cannon>(new Cannon.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    Cannon cannon = cannonMapper.get(entity);

    if (cannon.canShoot) {
      fireBullet(entity, cannon);
    } else if (cannon.cooldownTimer > 0){
      cannon.cooldownTimer -= world.delta;
    }
  }

  void fireBullet(Entity shooter, Cannon cannon) {
    Transform transform = transformMapper.get(shooter);
    Velocity shooterVel = velocityMapper.get(shooter);
    Mass shooterMass = massMapper.get(shooter);
    cannon.resetCooldown();

    num cosx = TrigUtil.cos(transform.angle);
    num siny = TrigUtil.sin(transform.angle);
    for (int i = 0; i < cannon.amount; i++) {
      num anglechange;
      if (cannon.amount == 1) {
        anglechange = transform.angle;
      } else {
        anglechange = transform.angle + PI/4 - ((PI/(2*(cannon.amount-1))) * i);
      }
      Entity bullet = world.createEntity();
      bullet.addComponent(new Transform(transform.x + cos(anglechange) * 26, transform.y + sin(anglechange) * 26));
      bullet.addComponent(new Velocity(shooterVel.x + cannon.bulletSpeed * cosx, shooterVel.y + cannon.bulletSpeed * siny));
      bullet.addComponent(new CircularBody(2));
      bullet.addComponent(new Mass(cannon.bulletMass));
      bullet.addComponent(new Spatial('bullet_dummy.png'));
      bullet.addComponent(new ExpirationTimer(2500));
      bullet.addComponent(new Damage(cannon.bulletDamage));
      bullet.addComponent(new Sound('non-positional', 'shoot'));
      bullet.addToWorld();
    }

    num getVelocityAfterRecoil(num shooterVel, num bulletVelMultiplier) {
      num p1 = shooterVel * shooterMass.value;
      num p2 = cannon.bulletSpeed * bulletVelMultiplier * cannon.bulletMass * cannon.amount;
      p1 = p1 - p2;
      return p1 / shooterMass.value;
    }
    shooterVel.x = getVelocityAfterRecoil(shooterVel.x, cosx);
    shooterVel.y = getVelocityAfterRecoil(shooterVel.y, siny);
  }
}

class ExpirationSystem extends EntityProcessingSystem {
  ComponentMapper<ExpirationTimer> timerMapper;
  ComponentMapper<Damage> damageMapper;

  ExpirationSystem() : super(Aspect.getAspectForAllOf(new ExpirationTimer.hack().runtimeType));

  void initialize() {
    timerMapper = new ComponentMapper<ExpirationTimer>(new ExpirationTimer.hack().runtimeType, world);
    damageMapper = new ComponentMapper<Damage>(new Damage.hack().runtimeType, world);

  }

  void processEntity(Entity entity) {
    ExpirationTimer timer = timerMapper.get(entity);
    if (timer.expired) {
      entity.deleteFromWorld();
    } else {
      timer.expireBy(world.delta);
      Damage damage = damageMapper.getSafe(entity);
      if (null != damage) {
        damage.value = damage.maxValue * timer.percentLeft;
      }
    }
  }
}


class SplittingDestructionSystem extends OnScreenEntityProcessingSystem {

  ComponentMapper<Status> statusMapper;
  ComponentMapper<SplitsOnDestruction> splitterMapper;
  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;
  ComponentMapper<Spatial> spatialMapper;

  SplittingDestructionSystem() : super(Aspect.getAspectForAllOf(new SplitsOnDestruction.hack().runtimeType, [new CircularBody.hack().runtimeType, new Status.hack().runtimeType, new Velocity.hack().runtimeType, new Mass.hack().runtimeType, new Spatial.hack().runtimeType]));

  void initialize() {
    super.initialize();
    statusMapper = new ComponentMapper<Status>(new Status.hack().runtimeType, world);
    splitterMapper = new ComponentMapper<SplitsOnDestruction>(new SplitsOnDestruction.hack().runtimeType, world);
    bodyMapper = new ComponentMapper<CircularBody>(new CircularBody.hack().runtimeType, world);
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
    massMapper = new ComponentMapper<Mass>(new Mass.hack().runtimeType, world);
    spatialMapper = new ComponentMapper<Spatial>(new Spatial.hack().runtimeType, world);
  }

  void processEntityOnScreen(Entity entity) {
    Status status = statusMapper.get(entity);
    if (status.health <= 0) {
      Transform transform = transformMapper.get(entity);
      SplitsOnDestruction splitter = splitterMapper.get(entity);
      Mass mass = massMapper.get(entity);
      Velocity velocity = velocityMapper.get(entity);
      CircularBody body = bodyMapper.get(entity);
      Spatial spatial = spatialMapper.get(entity);
      num volume = PI * body.radius * body.radius;

      num anglePerPart = 2 * PI / splitter.parts;
      num sqrtparts = sqrt(splitter.parts);
      num radius = body.radius / sqrtparts;
      num spread = (2 * PI / 3) / ((splitter.parts - 1) * anglePerPart);
      for (int i = 0; i < splitter.parts; i++) {
        num angle = i * anglePerPart;
        Entity asteroid = world.createEntity();
        asteroid.addComponent(new Transform(transform.x + body.radius * sin(angle), transform.y + body.radius * cos(angle), angle: random.nextDouble() * FastMath.TWO_PI, rotationRate: generateRandom(0.15, 0.20)));
        double changeOfVelocity = sin(PI/6 + angle * spread);
        asteroid.addComponent(new Velocity(velocity.x * changeOfVelocity, velocity.y * changeOfVelocity));
        num scale = generateRandom(0.2, 0.5);
        asteroid.addComponent(new Spatial.fromSpatial(spatial, spatial.scale / sqrtparts));
        asteroid.addComponent(new Mass(mass.value / splitter.parts));
        asteroid.addComponent(new MiniMapRenderable("#333"));
        asteroid.addComponent(new Status(maxHealth : status.maxHealth / sqrtparts));
        asteroid.addComponent(new CircularBody(radius));
        if (radius > 10) {
          asteroid.addComponent(new SplitsOnDestruction(generateRandom(2, 4).round().toInt()));
        } else {
          asteroid.addComponent(new DisappearsOnDestruction());
        }
        asteroid.addToWorld();
      }
      createParticles(world, transform);

      entity.deleteFromWorld();
    }
  }
}

class DisapperearingDestructionSystem extends OnScreenEntityProcessingSystem {

  ComponentMapper<Status> statusMapper;

  DisapperearingDestructionSystem() : super(Aspect.getAspectForAllOf(new DisappearsOnDestruction.hack().runtimeType, [new Status.hack().runtimeType, new Transform.hack().runtimeType]));

  void initialize() {
    super.initialize();
    statusMapper = new ComponentMapper<Status>(new Status.hack().runtimeType, world);
  }

  void processEntityOnScreen(Entity entity) {
    Status status = statusMapper.get(entity);
    if (status.health <= 0) {
      Transform transform = transformMapper.get(entity);
      createParticles(world, transform);
      entity.deleteFromWorld();
    }
  }

}
