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

  Map<int, bool> keyPressed = new Map<int, bool>();

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
    if (keyPressed[ACCELERATE] == true) {
      velocity.x += 0.0025 * TrigUtil.cos(transform.angle);
      velocity.y += 0.0025 * TrigUtil.sin(transform.angle);
      spatial.resource = 'spaceship_thrusters.png';
    } else {
      spatial.resource = 'spaceship.png';
    }
    if (keyPressed[LEFT] == true) {
      transform.angle = (transform.angle - 0.05) % FastMath.TWO_PI;
    } else if (keyPressed[RIGHT] ==  true) {
      transform.angle = (transform.angle + 0.05) % FastMath.TWO_PI;
    }
    cannon.shoot = keyPressed[SHOOT] == true;
    if (keyPressed[LEAVE_LEVEL] == true) {
      status.leaveLevel = keyPressed[LEAVE_LEVEL] == true;
      spatial.resource = 'spaceship.png';
      cannon.shoot = false;
      window.on.keyDown.remove(keyDownListener);
      window.on.keyUp.remove(keyUpListener);
    }
  }

  void handleKeyDown(KeyboardEvent e) {
    keyPressed[e.keyCode] = true;
  }

  void handleKeyUp(KeyboardEvent e) {
    keyPressed[e.keyCode] = false;
  }

  bool checkProcessing() => status.health > 0 && !status.leaveLevel && !status.enterLevel;
}
