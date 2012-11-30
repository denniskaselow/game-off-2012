part of html;

class PlayerControlSystem extends PlayerStatusProcessingSystem {
  const int ACCELERATE = 87;
  const int LEFT = 65;
  const int RIGHT = 68;
  const int SHOOT = 74;

  bool accelerate = false;
  bool turnLeft = false;
  bool turnRight = false;
  bool shoot = false;

  num targetX = 0;
  num targetY = 0;

  Spatial spatial;
  Velocity velocity;
  Transform transform;
  Cannon cannon;

  CanvasElement canvas;

  PlayerControlSystem(this.canvas) : super();

  void initialize() {
    super.initialize();
    ComponentMapper<Velocity> velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    ComponentMapper<Cannon> cannonMapper = new ComponentMapper<Cannon>(new Cannon.hack().runtimeType, world);
    ComponentMapper<Spatial> spatialMapper = new ComponentMapper<Spatial>(new Spatial.hack().runtimeType, world);

    spatial = spatialMapper.get(player);
    velocity = velocityMapper.get(player);
    transform = transformMapper.get(player);
    cannon = cannonMapper.get(player);

    window.on.keyDown.add(handleKeyDown);
    window.on.keyUp.add(handleKeyUp);
  }

  void processSystem() {
    if (accelerate) {
      velocity.x += 0.0025 * TrigUtil.cos(transform.angle);
      velocity.y += 0.0025 * TrigUtil.sin(transform.angle);
      spatial.resource = 'spaceship_thrusters.png';
    } else {
      spatial.resource = 'spaceship.png';
    }
    if (turnLeft) {
      transform.angle = (transform.angle - 0.05) % FastMath.TWO_PI;
    } else if(turnRight) {
      transform.angle = (transform.angle + 0.05) % FastMath.TWO_PI;
    }
    if (shoot) {
      cannon.shoot = true;
    } else {
      cannon.shoot = false;
    }
  }

  void handleKeyDown(KeyboardEvent e) {
    int keyCode = e.keyCode;
    if (keyCode == ACCELERATE) {
      accelerate = true;
    } else if (keyCode == LEFT) {
      turnLeft = true;
      turnRight = false;
    } else if (keyCode == RIGHT) {
      turnLeft = false;
      turnRight = true;
    } else if (keyCode == SHOOT) {
      shoot = true;
    }
  }

  void handleKeyUp(KeyboardEvent e) {
    int keyCode = e.keyCode;
    if (keyCode == ACCELERATE) {
      accelerate = false;
    } else if (keyCode == LEFT) {
      turnLeft = false;
    } else if (keyCode == RIGHT) {
      turnRight = false;
    } else if (keyCode == SHOOT) {
      shoot = false;
    }
  }

  bool checkProcessing() => status.health > 0;
}
