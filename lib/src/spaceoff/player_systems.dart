part of spaceoff;

abstract class PlayerStatusProcessingSystem extends VoidEntitySystem {

  TagManager tagManager;
  Entity player;
  Status status;

  void initialize() {
    var statusMapper = new ComponentMapper<Status>(Status, world);
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
    var cannonMapper = new ComponentMapper<Cannon>(Cannon, world);
    var transformMapper = new ComponentMapper<Transform>(Transform, world);
    var spatialMapper = new ComponentMapper<Spatial>(Spatial, world);
    cannon = cannonMapper.get(player);
    transform = transformMapper.get(player);
    spatial = spatialMapper.get(player);
  }

  void processSystem() {
    if (!status.destroyed && status.health < 0) {
      cannon.shoot = false;
      status.destroyed = true;
      spatial.resources = ['spaceship.png'];
      transform.rotationRate = 0.1;
      player.removeComponent(AutoPilot);
      player.changedInWorld();
    }
  }

  bool checkProcessing() => !status.destroyed;
}

class AutoPilotControlSystem extends EntityProcessingSystem  {
  ComponentMapper<AutoPilot> autoPilotMapper;
  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Velocity> velocityMapper;

  AutoPilotControlSystem() : super(Aspect.getAspectForAllOf([AutoPilot, Transform, Velocity]));

  void initialize() {
    autoPilotMapper = new ComponentMapper<AutoPilot>(AutoPilot, world);
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    velocityMapper = new ComponentMapper<Velocity>(Velocity, world);
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

  bool checkProcessing() => gameState.running;
}


class HyperDriveSystem extends PlayerStatusProcessingSystem {
  HyperDrive hyperDrive;
  bool inHyperSpace = false;

  HyperDriveSystem() : super();

  void initialize() {
    super.initialize();
    var hdMapper = new ComponentMapper<HyperDrive>(HyperDrive, world);
    hyperDrive = hdMapper.get(player);
  }

  void processSystem() {
    double stretch;
    if (!hyperDrive.shuttingDown) {
      hyperDrive.hyperSpaceMod += 0.01 + hyperDrive.hyperSpaceMod * 0.005;
    } else {
      hyperDrive.hyperSpaceMod -= 0.01 + hyperDrive.hyperSpaceMod * 0.005;
      if (hyperDrive.hyperSpaceMod < 0.001) {
        hyperDrive.active = false;
        hyperDrive.shuttingDown = false;
      }
    }
    if (hyperDrive.hyperSpaceMod > 0.5) {
      if (!inHyperSpace && !hyperDrive.shuttingDown) {
        inHyperSpace = true;
      }
    } else {
      if (inHyperSpace) {
        inHyperSpace = false;
      }
    }
  }

  bool checkProcessing() => hyperDrive.active && !status.destroyed && gameState.running;
}