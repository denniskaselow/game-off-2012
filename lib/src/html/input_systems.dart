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
  GameState state;

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

  bool checkProcessing() => gameState.running && status.health > 0 && !hyperDrive.active;
}

class MenuInputSystem extends VoidEntitySystem {
  CanvasElement canvas;

  MenuInputSystem(this.canvas);

  initialize() {
    GroupManager groupManager = world.getManager(new GroupManager().runtimeType);
    var miMapper = new ComponentMapper<MenuItem>(MenuItem, world);
    var items = new List<MenuItem>();
    groupManager.getEntities(GROUP_MENU).forEach((entity) => items.add(miMapper.get(entity)));
    canvas.onMouseMove.listen((event) {
      var pos = CqTools.mousePosition(event);
      items.forEach((item) {
        if (pos.x >= item.x && pos.x <= item.x + item.width &&
            pos.y >= item.y && pos.y <= item.y + item.height) {
          item.hover = true;
        } else {
          item.hover = false;
        }
      });
    });
    canvas.onMouseDown.listen((event) {
      var pos = CqTools.mousePosition(event);
      items.forEach((item) {
        if (pos.x >= item.x && pos.x <= item.x + item.width &&
            pos.y >= item.y && pos.y <= item.y + item.height) {
          item.action();
        }
      });
    });
  }

  processSystem() {
    ;
  }
}