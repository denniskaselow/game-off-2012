part of spaceoff;

abstract class PlayerStatusProcessingSystem extends VoidEntitySystem {

  Entity player;
  Status status;

  void initialize() {
    var statusMapper = new ComponentMapper<Status>(new Status.hack().runtimeType, world);
    TagManager tagManager = world.getManager(new TagManager().runtimeType);
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
    var cannonMapper = new ComponentMapper<Cannon>(new Cannon.hack().runtimeType, world);
    var transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    var spatialMapper = new ComponentMapper<Spatial>(new Spatial.hack().runtimeType, world);
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
    }
  }

  bool checkProcessing() => !status.destroyed;

}