part of spaceoff;


abstract class OnScreenProcessingSystem extends EntitySystem {

  static final num MAX_RENDER_DISTANCE_X = MAX_WIDTH + 50;
  static final num MAX_RENDER_DISTANCE_Y = MAX_HEIGHT + 50;
  static final num MIN_RENDER_DISTANCE_X_BORDER = UNIVERSE_WIDTH - MAX_RENDER_DISTANCE_X;
  static final num MIN_RENDER_DISTANCE_Y_BORDER = UNIVERSE_HEIGHT - MAX_RENDER_DISTANCE_Y;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  OnScreenProcessingSystem(Aspect aspect) : super(aspect.allOf([Transform]));

  void processEntities(ReadOnlyBag<Entity> entities) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    Bag<Entity> entitiesOnScreen = new Bag<Entity>();

    entities.forEach((entity) {
      Transform pos = transformMapper.get(entity);

      if (isWithtinXRange(pos, cameraPos) && isWithtinYRange(pos, cameraPos)) {
        entitiesOnScreen.add(entity);
      }
    });
    processEntitiesOnScreen(entitiesOnScreen.readOnly);
  }

  bool isWithtinXRange(Transform pos, CameraPosition camPos) {
    num distanceX = (camPos.x - pos.x).abs();
    return (distanceX < MAX_RENDER_DISTANCE_X || distanceX > MIN_RENDER_DISTANCE_X_BORDER);
  }

  bool isWithtinYRange(Transform pos, CameraPosition camPos) {
    num distanceY = (camPos.y - pos.y).abs();
    return (distanceY < MAX_RENDER_DISTANCE_Y || distanceY > MIN_RENDER_DISTANCE_Y_BORDER);
  }

  void processEntitiesOnScreen(ReadOnlyBag<Entity> entities);

  bool checkProcessing() => true;
}

abstract class OnScreenEntityProcessingSystem extends OnScreenProcessingSystem {

  OnScreenEntityProcessingSystem(Aspect aspect) : super(aspect);

  void processEntitiesOnScreen(ReadOnlyBag<Entity> entities) {
    entities.forEach((entity) => processEntityOnScreen(entity));
  }

  void processEntityOnScreen(Entity entity);

}

class ThrusterSystem extends EntityProcessingSystem {
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;
  ComponentMapper<Thruster> thrusterMapper;
  ComponentMapper<Turbo> turboMapper;
  ComponentMapper<Transform> transformMapper;

  ThrusterSystem() : super(Aspect.getAspectForAllOf([Thruster, Velocity, Mass, Transform, Turbo]));

  void processEntity(Entity e) {
    Thruster thruster = thrusterMapper.get(e);
    Turbo turbo = turboMapper.get(e);

    if (thruster.active || thruster.turn != Thruster.TURN_NONE || turbo.active) {
      Transform transform = transformMapper.get(e);
      Velocity vel = velocityMapper.get(e);
      Mass mass = massMapper.get(e);

      var change = sqrt(2 * thruster.thrust / mass.value);
      if (thruster.turn != Thruster.TURN_NONE) {
        transform.angle = (transform.angle + change * thruster.turn * 15) % FastMath.TWO_PI;
      }
      if (turbo.active) {
        turbo.resetCooldown();
        if (turbo.oldVelocity == null) {
          turbo.oldVelocity = sqrt(vel.x * vel.x + vel.y * vel.y);
          turbo.oldVelocityX = vel.x;
          turbo.oldVelocityY = vel.y;
          turbo.turboVelocity = 500 * change;
        }
        var ratio = turbo.timeActive / turbo.maxTimeActive;
        var mod = pow(1-(2*(-0.5 + ratio).abs()), 1.5);
        var baseVelX = turbo.oldVelocityX * (1 - ratio) + turbo.oldVelocity * FastMath.cos(transform.angle) * ratio;
        var baseVelY = turbo.oldVelocityY * (1 - ratio) + turbo.oldVelocity * FastMath.sin(transform.angle) * ratio;
        vel.x = baseVelX + mod * turbo.turboVelocity * FastMath.cos(transform.angle);
        vel.y = baseVelY + mod * turbo.turboVelocity * FastMath.sin(transform.angle);
        turbo.timeActive += world.delta;
        if (turbo.timeActive > turbo.maxTimeActive) {
          turbo.active = false;
          turbo.timeActive = 0.0;
          vel.x = turbo.oldVelocity * FastMath.cos(transform.angle);
          vel.y = turbo.oldVelocity * FastMath.sin(transform.angle);
          turbo.oldVelocity = null;
          turbo.turboVelocity = null;
        }
      } else {
        turbo.cooldownTimer -= world.delta;
        if (thruster.active) {
          vel.x += change * FastMath.cos(transform.angle);
          vel.y += change * FastMath.sin(transform.angle);
        }
      }
    }
  }

  bool checkProcessing() => gameState.running;
}

class MovementSystem extends EntityProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Velocity> velocityMapper;

  MovementSystem() : super(Aspect.getAspectForAllOf([Transform, Velocity]));

  void processEntity(Entity entity) {
    Transform transform = transformMapper.get(entity);
    Velocity vel = velocityMapper.get(entity);

    transform.x += vel.x * world.delta;
    transform.y += vel.y * world.delta;
    transform.angle += transform.rotationRate;
  }

  bool checkProcessing() => gameState.running;
}

class CameraSystem extends VoidEntitySystem {
  ComponentMapper<Transform> positionMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  CameraSystem();

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
  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Upgrade> upgradeMapper;
  Status status;
  Transform transform;
  CircularBody body;
  Cannon cannon;
  HyperDrive hyperDrive;
  Mass mass;
  Thruster thruster;

  UpgradeCollectionSystem() : super(Aspect.getAspectForAllOf([Upgrade, Transform, CircularBody]));

  void initialize() {
    super.initialize();
    TagManager tagManager = world.getManager(new TagManager().runtimeType);
    Entity player = tagManager.getEntity(TAG_PLAYER);

    var cannonMapper = new ComponentMapper<Cannon>(Cannon, world);
    var hyperDriveMapper = new ComponentMapper<HyperDrive>(HyperDrive, world);
    var statusMapper = new ComponentMapper<Status>(Status, world);
    var massMapper = new ComponentMapper<Mass>(Mass, world);
    var thrusterMapper = new ComponentMapper<Thruster>(Thruster, world);

    status = statusMapper.get(player);
    transform = transformMapper.get(player);
    body = bodyMapper.get(player);
    cannon = cannonMapper.get(player);
    hyperDrive = hyperDriveMapper.get(player);
    thruster = thrusterMapper.get(player);
    mass = massMapper.get(player);
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
      cannon.bulletDamage += upgrade.bulletDamageGain;
      if (upgrade.enableHyperDrive) {
        hyperDrive.enabled = true;
      }
      mass.value += upgrade.massGain;
      thruster.thrust += upgrade.thrustGain;

      entity.deleteFromWorld();
    }
  }

  void end() {
    // no collision with collected upgrades wanted
    world.processEntityChanges();
  }

  bool checkProcessing() => !gameState.paused && status.health > 0;
}

class CircularCollisionDetectionSystem extends OnScreenProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;
  ComponentMapper<Status> statusMapper;
  ComponentMapper<Damage> damageMapper;
  ComponentMapper<ExpirationTimer> expirationMapper;
  ComponentMapper<ScoreCollector> scoreCollectorMapper;
  ComponentMapper<ScoreComponent> scoreComponentMapper;

  CircularCollisionDetectionSystem() : super(Aspect.getAspectForAllOf([CircularBody, Transform, Velocity, Mass]));

  void processEntitiesOnScreen(ReadOnlyBag<Entity> entities) {
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

            processDamage(e1, e2, p1, p2);
            updateExpirationTimers(e1, e2);
          }
        }
      }
    }
  }

  void processDamage(Entity e1, Entity e2, num p1, num p2) {
    Status s1 = statusMapper.getSafe(e1);
    Status s2 = statusMapper.getSafe(e2);
    Damage d1 = damageMapper.getSafe(e1);
    Damage d2 = damageMapper.getSafe(e2);
    ScoreCollector collect1 = scoreCollectorMapper.getSafe(e1);
    ScoreCollector collect2 = scoreCollectorMapper.getSafe(e2);
    ScoreComponent score1 = scoreComponentMapper.getSafe(e1);
    ScoreComponent score2 = scoreComponentMapper.getSafe(e2);

    calculateHealth(s1, d2, p1, p2);
    calculateHealth(s2, d1, p1, p2);

    calcuateScore(collect1, score2, s2);
    calcuateScore(collect2, score1, s1);
  }

  void calculateHealth(Status status, Damage damage, num p1, num p2) {
    if (null != status) {
      status.health -= (p2.abs() + p1.abs()) / 5;
      if (null != damage) status.health -= damage.value;
    }
  }

  void calcuateScore(ScoreCollector collect, ScoreComponent score, Status status) {
    if (null != collect && null != score) {
      if (null != status && status.health < 0) {
        gameState.score += score.killScore;
      } else {
        gameState.score += score.damageScore;
      }
    }
  }

  void updateExpirationTimers(Entity e1, Entity e2) {
    ExpirationTimer timer1 = expirationMapper.getSafe(e1);
    ExpirationTimer timer2 = expirationMapper.getSafe(e2);
    if (null != timer1) {
      timer1.timeLeft *= 0.8;
    }
    if (null != timer2) {
      timer2.timeLeft *= 0.8;
    }
  }

  bool checkProcessing() => gameState.running;
}

class BulletSpawningSystem extends EntityProcessingSystem {

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Cannon> cannonMapper;
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;

  BulletSpawningSystem() : super(Aspect.getAspectForAllOf([Cannon, Transform, Velocity, Mass]));

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

    num cosx = FastMath.cos(transform.angle);
    num siny = FastMath.sin(transform.angle);
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
      bullet.addComponent(new ScoreCollector());
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

  bool checkProcessing() => gameState.running;
}

class ExpirationSystem extends EntityProcessingSystem {
  ComponentMapper<ExpirationTimer> timerMapper;
  ComponentMapper<Damage> damageMapper;

  ExpirationSystem() : super(Aspect.getAspectForAllOf([ExpirationTimer]));

  void initialize() {
    timerMapper = new ComponentMapper<ExpirationTimer>(ExpirationTimer, world);
    damageMapper = new ComponentMapper<Damage>(Damage, world);

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

  bool checkProcessing() => gameState.running;
}


class SplittingDestructionSystem extends OnScreenEntityProcessingSystem {

  ComponentMapper<Status> statusMapper;
  ComponentMapper<SplitsOnDestruction> splitterMapper;
  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;
  ComponentMapper<Spatial> spatialMapper;

  SplittingDestructionSystem() : super(Aspect.getAspectForAllOf([SplitsOnDestruction, CircularBody, Status, Velocity, Mass, Spatial]));

  void processEntityOnScreen(Entity entity) {
    Status status = statusMapper.get(entity);
    if (status.health <= 0) {
      Transform transform = transformMapper.get(entity);
      SplitsOnDestruction splitter = splitterMapper.get(entity);
      Mass mass = massMapper.get(entity);
      Velocity velocity = velocityMapper.get(entity);
      CircularBody body = bodyMapper.get(entity);
      Spatial spatial = spatialMapper.get(entity);
      num area = PI * body.radius * body.radius;

      num anglePerPart = 2 * PI / splitter.parts;
      num sqrtparts = sqrt(splitter.parts);
      num radius = body.radius / sqrtparts;
      num spread = (1 * PI / 6) / ((splitter.parts - 1));
      num directionAngle = velocity.angle - PI/12;
      num absVelocity = velocity.absolute;
      num distanceToCenter;
      if (splitter.parts == 2) {
        distanceToCenter = radius;
      } else {
        distanceToCenter = sin((180-anglePerPart)/2) * radius / sin(anglePerPart);
      }
      distanceToCenter += 10;
      for (int i = 0; i < splitter.parts; i++) {
        num angle = i * anglePerPart;
        Entity asteroid = world.createEntity();
        asteroid.addComponent(new Transform(transform.x + distanceToCenter * cos(angle), transform.y + distanceToCenter * sin(angle), angle: random.nextDouble() * FastMath.TWO_PI, rotationRate: generateRandom(0.15, 0.35)));
        asteroid.addComponent(new Velocity(absVelocity * FastMath.cos(directionAngle + spread * i), absVelocity * FastMath.sin(directionAngle + spread * i)));
        num scale = generateRandom(0.2, 0.5);
        asteroid.addComponent(new Spatial.fromSpatial(spatial, spatial.scale / sqrtparts));
        asteroid.addComponent(new Mass(mass.value / splitter.parts));
        asteroid.addComponent(new MiniMapRenderable("#333"));
        asteroid.addComponent(new Status(maxHealth : status.maxHealth / sqrtparts));
        asteroid.addComponent(new CircularBody(radius));
        asteroid.addComponent(new ScoreComponent(10 * scale, 100 * scale * gameState.levelMod));
        if (radius > 10) {
          asteroid.addComponent(new SplitsOnDestruction(generateRandom(2, 4).round().toInt()));
        } else {
          asteroid.addComponent(new DisappearsOnDestruction());
        }
        asteroid.addToWorld();
      }
      createParticles(world, transform, body.radius, 15 * sqrt(area).toInt(), velocity);

      entity.deleteFromWorld();
    }
  }
}

class DisapperearingDestructionSystem extends OnScreenEntityProcessingSystem {

  ComponentMapper<Status> statusMapper;
  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Velocity> velocityMapper;

  DisapperearingDestructionSystem() : super(Aspect.getAspectForAllOf([DisappearsOnDestruction, Status, Transform, CircularBody, Velocity]));

  void processEntityOnScreen(Entity entity) {
    Status status = statusMapper.get(entity);
    if (status.health <= 0) {
      Transform transform = transformMapper.get(entity);
      CircularBody body = bodyMapper.get(entity);
      Velocity vel = velocityMapper.get(entity);
      createParticles(world, transform, body.radius, (PI * body.radius * body.radius).toInt(), vel);
      entity.deleteFromWorld();
    }
  }

}
