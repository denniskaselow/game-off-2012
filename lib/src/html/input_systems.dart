part of html;

class PlayerControlSystem extends PlayerStatusProcessingSystem {
  /** W. */
  const int ACCELERATE = 87;
  /** A. */
  const int LEFT = 65;
  /** D. */
  const int RIGHT = 68;
  /** J. */
  const int SHOOT = 74;
  /** L. */
  const int LEAVE_LEVEL = 76;

  bool accelerate = false;
  bool turnLeft = false;
  bool turnRight = false;
  bool shoot = false;
  bool leaveLevel = false;

  num targetX = 0;
  num targetY = 0;

  Spatial spatial;
  Velocity velocity;
  Transform transform;
  Cannon cannon;

  CanvasElement canvas;

  EventListener keyDownListener;
  EventListener keyUpListener;

  PlayerControlSystem(this.canvas) : super() {
    keyDownListener = handleKeyDown;
    keyUpListener = handleKeyUp;
  }

  void initialize() {
    super.initialize();
    ComponentMapper<Velocity> velocityMapper = new ComponentMapper<Velocity>(Velocity.type, world);
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform.type, world);
    ComponentMapper<Cannon> cannonMapper = new ComponentMapper<Cannon>(Cannon.type, world);
    ComponentMapper<Spatial> spatialMapper = new ComponentMapper<Spatial>(Spatial.type, world);

    spatial = spatialMapper.get(player);
    velocity = velocityMapper.get(player);
    transform = transformMapper.get(player);
    cannon = cannonMapper.get(player);

    window.on.keyDown.add(keyDownListener);
    window.on.keyUp.add(keyUpListener);
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
    cannon.shoot = shoot;
    if (leaveLevel) {
      status.leaveLevel = leaveLevel;
      spatial.resource = 'spaceship.png';
      cannon.shoot = false;
      window.on.keyDown.remove(keyDownListener);
      window.on.keyUp.remove(keyUpListener);
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
    } else if (keyCode == LEAVE_LEVEL) {
      leaveLevel = true;
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

  bool checkProcessing() => status.health > 0 && !status.leaveLevel && !status.enterLevel;
}
