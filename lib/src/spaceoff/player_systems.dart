part of spaceoff;

abstract class PlayerStatusProcessingSystem extends VoidEntitySystem {

  TagManager tagManager;
  Entity player;
  Status status;

  void initialize() {
    var statusMapper = new ComponentMapper<Status>(Status.type, world);
    tagManager = world.getManager(new TagManager().runtimeType);
    player = tagManager.getEntity(TAG_PLAYER);
    status = statusMapper.get(player);
  }
}

class PlayerDestructionSystem extends PlayerStatusProcessingSystem {
  Cannon cannon;
  Transform transform;
  Spatial spatial;

  void initialize() {
    super.initialize();
    var cannonMapper = new ComponentMapper<Cannon>(Cannon.type, world);
    var transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    var spatialMapper = new ComponentMapper<Spatial>(Spatial.type, world);
    cannon = cannonMapper.get(player);
    transform = transformMapper.get(player);
    spatial = spatialMapper.get(player);
  }

  void processSystem() {
    if (!status.destroyed && status.health < 0) {
      cannon.shoot = false;
      status.destroyed = true;
      spatial.resource = 'spaceship.png';
      transform.rotationRate = 0.1;
      player.removeComponent(new AutoPilot._hack());
      player.changedInWorld();
    }
  }

  bool checkProcessing() => !status.destroyed;
}

class AutoPilotControlSystem extends EntityProcessingSystem {
  ComponentMapper<AutoPilot> autoPilotMapper;
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Velocity> velocityMapper;

  AutoPilotControlSystem() : super(Aspect.getAspectForAllOf(AutoPilot.type, [Transform.type, Velocity.type]));

  void initialize() {
    autoPilotMapper = new ComponentMapper<AutoPilot>(AutoPilot.type, world);
    transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    velocityMapper = new ComponentMapper<Velocity>(Velocity.type, world);
  }

  void processEntity(Entity e) {
    AutoPilot autoPilot = autoPilotMapper.get(e);
    Transform transform = transformMapper.get(e);

    double angleDiff = (autoPilot.angle - transform.angle) % FastMath.TWO_PI;
    if (angleDiff > PI) {
      angleDiff -= FastMath.TWO_PI;
    }
    if (angleDiff.abs() > 0.001) {
      transform.angle += angleDiff * 0.08;
    } else {
      Velocity velocity = velocityMapper.get(e);
      velocity.x = autoPilot.velocity * cos(autoPilot.angle);
      velocity.y = autoPilot.velocity * sin(autoPilot.angle);
    }
  }
}