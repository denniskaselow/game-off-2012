part of multiverse;


abstract class OnScreenProcessingSystem extends EntityProcessingSystem {

  static final num MAX_RENDER_DISTANCE_X = MAX_WIDTH + 50;
  static final num MAX_RENDER_DISTANCE_Y = MAX_HEIGHT + 50;
  static final num MIN_RENDER_DISTANCE_X_BORDER = UNIVERSE_WIDTH - MAX_RENDER_DISTANCE_X;
  static final num MIN_RENDER_DISTANCE_Y_BORDER = UNIVERSE_HEIGHT - MAX_RENDER_DISTANCE_Y;

  ComponentMapper<Transform> positionMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  OnScreenProcessingSystem(Aspect aspect) : super(aspect.allOf(new Transform.hack().runtimeType));

  void initialize() {
    positionMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processEntities(ImmutableBag<Entity> entities) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    Bag<Entity> entitiesOnScreen = new Bag<Entity>();

    entities.forEach((entity) {
      Transform pos = positionMapper.get(entity);

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

    transform.x += vel.x;
    transform.y += vel.y;
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

class CircularCollisionDetectionSystem extends OnScreenProcessingSystem {
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<CircularBody> bodyMapper;
  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Mass> massMapper;

  CircularCollisionDetectionSystem() : super(Aspect.getAspectForAllOf(new CircularBody.hack().runtimeType, [new Transform.hack().runtimeType, new Velocity.hack().runtimeType, new Mass.hack().runtimeType]));

  void initialize() {
    super.initialize();
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    bodyMapper = new ComponentMapper<CircularBody>(new CircularBody.hack().runtimeType, world);
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
    massMapper = new ComponentMapper<Mass>(new Mass.hack().runtimeType, world);
  }

  void processEntitiesOnScreen(ImmutableBag<Entity> entities) {
    if (entities.size > 1) {
      for (int i = 0; i < entities.size - 1; i++) {
        for (int j = i+1; j < entities.size; j++) {
          Entity e1 = entities[i];
          Entity e2 = entities[j];
          Transform t1 = transformMapper.get(e1);
          Transform t2 = transformMapper.get(e2);
          CircularBody c1 = bodyMapper.get(e1);
          CircularBody c2 = bodyMapper.get(e2);

          if (Utils.doCirclesCollide(t1.x, t1.y, c1.radius, t2.x, t2.y, c2.radius)) {
            Velocity v1 = velocityMapper.get(e1);
            Velocity v2 = velocityMapper.get(e2);
            Mass m1 = massMapper.get(e1);
            Mass m2 = massMapper.get(e2);
            num p1 = v1.x * m1.mass;
            num p2 = v2.x * m2.mass;
            num mTotal = m1.mass + m2.mass;

            v1.x = (p1 + 2 * p2 - m2.mass * v1.x) / mTotal;
            v2.x = (p2 + 2 * p1 - m1.mass * v2.x) / mTotal;

            p1 = v1.y * m1.mass;
            p2 = v2.y * m2.mass;

            v1.y = (p1 + 2 * p2 - m2.mass * v1.y) / mTotal;
            v2.y = (p2 + 2 * p1 - m1.mass * v2.y) / mTotal;
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

  BulletSpawningSystem() : super(Aspect.getAspectForAllOf(new Cannon.hack().runtimeType, [new Transform.hack().runtimeType, new Velocity.hack().runtimeType]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
    cannonMapper = new ComponentMapper<Cannon>(new Cannon.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    Cannon cannon = cannonMapper.get(entity);

    if (cannon.canShoot) {
      Transform transform = transformMapper.get(entity);
      Velocity vel = velocityMapper.get(entity);
      fireBullet(transform, vel, cannon);
    } else if (cannon.cooldownTimer > 0){
      cannon.cooldownTimer -= world.delta;
    }
  }

  void fireBullet(Transform transform, Velocity shooterVel, Cannon cannon) {
    cannon.resetCooldown();
    Entity bullet = world.createEntity();
    num x = TrigUtil.cos(transform.angle);
    num y = TrigUtil.sin(transform.angle);
    bullet.addComponent(new Transform(transform.x + x * 26, transform.y + y * 26));
    bullet.addComponent(new Velocity(shooterVel.x + cannon.bulletSpeed * x, shooterVel.y + cannon.bulletSpeed * y));
    bullet.addComponent(new CircularBody(2));
    bullet.addComponent(new Mass(10));
    bullet.addComponent(new Spatial('bullet_dummy.png'));
    bullet.addComponent(new ExpirationTimer(5000));
    bullet.addToWorld();
  }
}

class ExpirationSystem extends EntityProcessingSystem {
  ComponentMapper<ExpirationTimer> timerMapper;

  ExpirationSystem() : super(Aspect.getAspectForAllOf(new ExpirationTimer.hack().runtimeType));

  void initialize() {
    timerMapper = new ComponentMapper<ExpirationTimer>(new ExpirationTimer.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    ExpirationTimer timer = timerMapper.get(entity);
    if (timer.expired) {
      entity.deleteFromWorld();
    } else {
      timer.expireBy(world.delta);
    }
  }
}