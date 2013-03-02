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
  /** H. */
  const int HYPERDRIVE = 72;

  Map<int, bool> keyPressed = new Map<int, bool>();

  num targetX = 0;
  num targetY = 0;

  Spatial spatial;
  Velocity velocity;
  Transform transform;
  Cannon cannon;
  HyperDrive hyperDrive;

  CanvasElement canvas;

  StreamSubscription<KeyboardEvent> keyDownSubscription;
  StreamSubscription<KeyboardEvent> keyUpSubscription;

  PlayerControlSystem(this.canvas);

  void initialize() {
    super.initialize();
    var velocityMapper = new ComponentMapper<Velocity>(Velocity, world);
    var transformMapper = new ComponentMapper<Transform>(Transform, world);
    var cannonMapper = new ComponentMapper<Cannon>(Cannon, world);
    var spatialMapper = new ComponentMapper<Spatial>(Spatial, world);
    var hyperDriveMapper = new ComponentMapper<HyperDrive>(HyperDrive, world);

    spatial = spatialMapper.get(player);
    velocity = velocityMapper.get(player);
    transform = transformMapper.get(player);
    cannon = cannonMapper.get(player);
    hyperDrive = hyperDriveMapper.get(player);


    keyDownSubscription = canvas.onKeyDown.listen(handleKeyDown);
    keyUpSubscription = canvas.onKeyUp.listen(handleKeyUp);
  }

  void processSystem() {
    if (keyPressed[ACCELERATE] == true) {
      velocity.x += 0.0025 * FastMath.cos(transform.angle);
      velocity.y += 0.0025 * FastMath.sin(transform.angle);
      spatial.resources = ['spaceship.png', 'spaceship_thrusters.png'];
    } else {
      spatial.resources = ['spaceship.png'];
    }
    if (keyPressed[LEFT] == true) {
      transform.angle = (transform.angle - 0.05) % FastMath.TWO_PI;
    } else if (keyPressed[RIGHT] ==  true) {
      transform.angle = (transform.angle + 0.05) % FastMath.TWO_PI;
    }
    cannon.shoot = keyPressed[SHOOT] == true;
    if (keyPressed[HYPERDRIVE] == true && hyperDrive.enabled) {
      hyperDrive.active = keyPressed[HYPERDRIVE] == true;
      spatial.resources = ['spaceship.png'];
      cannon.shoot = false;
      keyDownSubscription.cancel();
      keyUpSubscription.cancel();
    }
  }

  void releaseAllKeys() {
    keyPressed.keys.forEach((key) => keyPressed[key] = false);
  }

  void handleKeyDown(KeyboardEvent e) {
    keyPressed[e.keyCode] = true;
  }

  void handleKeyUp(KeyboardEvent e) {
    keyPressed[e.keyCode] = false;
  }

  bool checkProcessing() => status.health > 0 && !hyperDrive.active;
}
