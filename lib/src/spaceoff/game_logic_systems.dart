part of spaceoff;


abstract class OnScreenProcessingSystem extends EntitySystem {

  static final num MAX_RENDER_DISTANCE_X = MAX_WIDTH + 50;
  static final num MAX_RENDER_DISTANCE_Y = MAX_HEIGHT + 50;
  static final num MIN_RENDER_DISTANCE_X_BORDER = UNIVERSE_WIDTH - MAX_RENDER_DISTANCE_X;
  static final num MIN_RENDER_DISTANCE_Y_BORDER = UNIVERSE_HEIGHT - MAX_RENDER_DISTANCE_Y;

  Mapper<Transform> transformMapper;
  Mapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  OnScreenProcessingSystem(Aspect aspect) : super(aspect..allOf([Transform]));

  void processEntities(Iterable<Entity> entities) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper[camera];

    Bag<Entity> entitiesOnScreen = new Bag<Entity>();

    entities.forEach((entity) {
      Transform pos = transformMapper[entity];

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

  void processEntitiesOnScreen(Iterable<Entity> entities);

  bool checkProcessing() => true;
}

abstract class OnScreenEntityProcessingSystem extends OnScreenProcessingSystem {

  OnScreenEntityProcessingSystem(Aspect aspect) : super(aspect);

  void processEntitiesOnScreen(Iterable<Entity> entities) {
    entities.forEach((entity) => processEntityOnScreen(entity));
  }

  void processEntityOnScreen(Entity entity);

}

class ThrusterSystem extends EntityProcessingSystem {
  Mapper<Velocity> velocityMapper;
  Mapper<Mass> massMapper;
  Mapper<Thruster> thrusterMapper;
  Mapper<Turbo> turboMapper;
  Mapper<Transform> transformMapper;

  ThrusterSystem() : super(new Aspect.forAllOf([Thruster, Velocity, Mass, Transform, Turbo]));

  void processEntity(Entity e) {
    Thruster thruster = thrusterMapper[e];
    Turbo turbo = turboMapper[e];

    if (thruster.active || thruster.turn != Thruster.TURN_NONE || turbo.active) {
      Transform transform = transformMapper[e];
      Velocity vel = velocityMapper[e];
      Mass mass = massMapper[e];

      var change = sqrt(2 * thruster.thrust / mass.value);
      if (thruster.turn != Thruster.TURN_NONE) {
        transform.angle = (transform.angle + change * thruster.turn * 15) % (2 * PI);
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
        var baseVelX = turbo.oldVelocityX * (1 - ratio) + turbo.oldVelocity * cos(transform.angle) * ratio;
        var baseVelY = turbo.oldVelocityY * (1 - ratio) + turbo.oldVelocity * sin(transform.angle) * ratio;
        vel.x = baseVelX + mod * turbo.turboVelocity * cos(transform.angle);
        vel.y = baseVelY + mod * turbo.turboVelocity * sin(transform.angle);
        turbo.timeActive += world.delta;
        if (turbo.timeActive > turbo.maxTimeActive) {
          turbo.active = false;
          turbo.timeActive = 0.0;
          vel.x = turbo.oldVelocity * cos(transform.angle);
          vel.y = turbo.oldVelocity * sin(transform.angle);
          turbo.oldVelocity = null;
          turbo.turboVelocity = null;
        }
      } else {
        turbo.cooldownTimer -= world.delta;
        if (thruster.active) {
          vel.x += change * cos(transform.angle);
          vel.y += change * sin(transform.angle);
        }
      }
    }
  }

  bool checkProcessing() => gameState.running;
}

class MovementSystem extends EntityProcessingSystem {
  Mapper<Transform> transformMapper;
  Mapper<Velocity> velocityMapper;

  MovementSystem() : super(new Aspect.forAllOf([Transform, Velocity]));

  void processEntity(Entity entity) {
    Transform transform = transformMapper[entity];
    Velocity vel = velocityMapper[entity];

    transform.x += vel.x * world.delta;
    transform.y += vel.y * world.delta;
    transform.angle += transform.rotationRate;
  }

  bool checkProcessing() => gameState.running;
}

class CameraSystem extends VoidEntitySystem {
  Mapper<Transform> positionMapper;
  Mapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  CameraSystem();

  void processSystem() {
    Entity player = tagManager.getEntity(TAG_PLAYER);
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Transform playerPos = positionMapper[player];
    CameraPosition cameraPos = cameraPositionMapper[camera];

    cameraPos.x = playerPos.x - MAX_WIDTH ~/ 2;
    cameraPos.y = playerPos.y - MAX_HEIGHT ~/ 2;
  }
}

class UpgradeCollectionSystem extends OnScreenEntityProcessingSystem {
  Mapper<CircularBody> bodyMapper;
  Mapper<Upgrade> upgradeMapper;
  Status status;
  Transform transform;
  CircularBody body;
  Cannon cannon;
  HyperDrive hyperDrive;
  Mass mass;
  Thruster thruster;

  UpgradeCollectionSystem() : super(new Aspect.forAllOf([Upgrade, Transform, CircularBody]));

  void initialize() {
    super.initialize();
    TagManager tagManager = world.getManager(new TagManager().runtimeType);
    Entity player = tagManager.getEntity(TAG_PLAYER);

    var cannonMapper = new Mapper<Cannon>(Cannon, world);
    var hyperDriveMapper = new Mapper<HyperDrive>(HyperDrive, world);
    var statusMapper = new Mapper<Status>(Status, world);
    var massMapper = new Mapper<Mass>(Mass, world);
    var thrusterMapper = new Mapper<Thruster>(Thruster, world);

    status = statusMapper[player];
    transform = transformMapper[player];
    body = bodyMapper[player];
    cannon = cannonMapper[player];
    hyperDrive = hyperDriveMapper[player];
    thruster = thrusterMapper[player];
    mass = massMapper[player];
  }

  void processEntityOnScreen(Entity entity) {
    Transform upgradeTransform = transformMapper[entity];
    CircularBody upgradeBody = bodyMapper[entity];

    if (doCirclesCollide(transform.x, transform.y, body.radius, upgradeTransform.x, upgradeTransform.y, upgradeBody.radius)) {
      Upgrade upgrade = upgradeMapper[entity];

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
  Mapper<Transform> transformMapper;
  Mapper<CircularBody> bodyMapper;
  Mapper<Velocity> velocityMapper;
  Mapper<Mass> massMapper;
  Mapper<Status> statusMapper;
  Mapper<Damage> damageMapper;
  Mapper<ExpirationTimer> expirationMapper;
  Mapper<ScoreCollector> scoreCollectorMapper;
  Mapper<ScoreComponent> scoreMapper;

  CircularCollisionDetectionSystem() : super(new Aspect.forAllOf([CircularBody, Transform, Velocity, Mass]));

  void processEntitiesOnScreen(Iterable<Entity> entities) {
    if (entities.length > 1) {
      var i = 0;
      entities.take(entities.length - 1).forEach((e1) {
        Transform t1 = transformMapper[e1];
        CircularBody c1 = bodyMapper[e1];
        entities.skip(++i).forEach((e2) {
          Transform t2 = transformMapper[e2];
          CircularBody c2 = bodyMapper[e2];

          if (doCirclesCollide(t1.x, t1.y, c1.radius, t2.x, t2.y, c2.radius)) {
            Velocity v1 = velocityMapper[e1];
            Velocity v2 = velocityMapper[e2];
            Mass m1 = massMapper[e1];
            Mass m2 = massMapper[e2];

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
        });
      });
    }
  }

  void processDamage(Entity e1, Entity e2, num p1, num p2) {
    Status s1 = statusMapper.getSafe(e1);
    Status s2 = statusMapper.getSafe(e2);
    Damage d1 = damageMapper.getSafe(e1);
    Damage d2 = damageMapper.getSafe(e2);
    ScoreCollector collect1 = scoreCollectorMapper.getSafe(e1);
    ScoreCollector collect2 = scoreCollectorMapper.getSafe(e2);
    ScoreComponent score1 = scoreMapper.getSafe(e1);
    ScoreComponent score2 = scoreMapper.getSafe(e2);

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

  Mapper<Transform> transformMapper;
  Mapper<Cannon> cannonMapper;
  Mapper<Velocity> velocityMapper;
  Mapper<Mass> massMapper;

  BulletSpawningSystem() : super(new Aspect.forAllOf([Cannon, Transform, Velocity, Mass]));

  void processEntity(Entity entity) {
    Cannon cannon = cannonMapper[entity];

    if (cannon.canShoot) {
      fireBullet(entity, cannon);
    } else if (cannon.cooldownTimer > 0){
      cannon.cooldownTimer -= world.delta;
    }
  }

  void fireBullet(Entity shooter, Cannon cannon) {
    Transform transform = transformMapper[shooter];
    Velocity shooterVel = velocityMapper[shooter];
    Mass shooterMass = massMapper[shooter];
    cannon.resetCooldown();

    num cosx = cos(transform.angle);
    num siny = sin(transform.angle);
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
  Mapper<ExpirationTimer> timerMapper;
  Mapper<Damage> damageMapper;

  ExpirationSystem() : super(new Aspect.forAllOf([ExpirationTimer]));

  void initialize() {
    timerMapper = new Mapper<ExpirationTimer>(ExpirationTimer, world);
    damageMapper = new Mapper<Damage>(Damage, world);

  }

  void processEntity(Entity entity) {
    ExpirationTimer timer = timerMapper[entity];
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

  Mapper<Status> statusMapper;
  Mapper<SplitsOnDestruction> splitterMapper;
  Mapper<CircularBody> bodyMapper;
  Mapper<Velocity> velocityMapper;
  Mapper<Mass> massMapper;
  Mapper<Spatial> spatialMapper;

  SplittingDestructionSystem() : super(new Aspect.forAllOf([SplitsOnDestruction, CircularBody, Status, Velocity, Mass, Spatial]));

  void processEntityOnScreen(Entity entity) {
    Status status = statusMapper[entity];
    if (status.health <= 0) {
      Transform transform = transformMapper[entity];
      SplitsOnDestruction splitter = splitterMapper[entity];
      Mass mass = massMapper[entity];
      Velocity velocity = velocityMapper[entity];
      CircularBody body = bodyMapper[entity];
      Spatial spatial = spatialMapper[entity];
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
        asteroid.addComponent(new Transform(transform.x + distanceToCenter * cos(angle), transform.y + distanceToCenter * sin(angle), angle: random.nextDouble() * 2 * PI, rotationRate: generateRandom(0.15, 0.35)));
        asteroid.addComponent(new Velocity(absVelocity * cos(directionAngle + spread * i), absVelocity * sin(directionAngle + spread * i)));
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

  Mapper<Status> statusMapper;
  Mapper<CircularBody> bodyMapper;
  Mapper<Velocity> velocityMapper;

  DisapperearingDestructionSystem() : super(new Aspect.forAllOf([DisappearsOnDestruction, Status, Transform, CircularBody, Velocity]));

  void processEntityOnScreen(Entity entity) {
    Status status = statusMapper[entity];
    if (status.health <= 0) {
      Transform transform = transformMapper[entity];
      CircularBody body = bodyMapper[entity];
      Velocity vel = velocityMapper[entity];
      createParticles(world, transform, body.radius, (PI * body.radius * body.radius).toInt(), vel);
      entity.deleteFromWorld();
    }
  }

}
