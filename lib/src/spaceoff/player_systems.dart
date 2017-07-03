part of spaceoff;

abstract class PlayerStatusProcessingSystem extends VoidEntitySystem {

  TagManager tagManager;
  Entity player;
  Status status;

  void initialize() {
    var statusMapper = new Mapper<Status>(Status, world);
    player = tagManager.getEntity(TAG_PLAYER);
    status = statusMapper[player];
  }
}

class PlayerDestructionSystem extends PlayerStatusProcessingSystem {
  Cannon cannon;
  Transform transform;
  Spatial spatial;
  Thruster thruster;

  void initialize() {
    super.initialize();
    var cannonMapper = new Mapper<Cannon>(Cannon, world);
    var transformMapper = new Mapper<Transform>(Transform, world);
    var spatialMapper = new Mapper<Spatial>(Spatial, world);
    var thrusterMapper = new Mapper<Thruster>(Thruster, world);
    cannon = cannonMapper[player];
    transform = transformMapper[player];
    spatial = spatialMapper[player];
    thruster = thrusterMapper[player];
  }

  void processSystem() {
    if (!status.destroyed && status.health < 0) {
      cannon.shoot = false;
      thruster.active = false;
      thruster.turn = Thruster.TURN_NONE;
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
  Mapper<AutoPilot> autoPilotMapper;
  Mapper<Transform> transformMapper;
  Mapper<Velocity> velocityMapper;

  AutoPilotControlSystem() : super(new Aspect.forAllOf([AutoPilot, Transform, Velocity]));

  void processEntity(Entity e) {
    AutoPilot autoPilot = autoPilotMapper[e];
    Transform transform = transformMapper[e];

    double angleDiff = (autoPilot.angle - transform.angle) % (2 * PI);
    if (angleDiff > PI) {
      angleDiff -= 2 * PI;
    }
    if (angleDiff.abs() > 0.001) {
      transform.angle += angleDiff * 0.08;
    } else {
      Velocity velocity = velocityMapper[e];
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
    var hdMapper = new Mapper<HyperDrive>(HyperDrive, world);
    hyperDrive = hdMapper[player];
  }

  void processSystem() {
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