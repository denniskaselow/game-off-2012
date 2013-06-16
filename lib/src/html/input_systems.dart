part of html;

class PlayerControlSystem extends PlayerStatusProcessingSystem {
  static const int ACCELERATE = KeyCode.W;
  static const int LEFT = KeyCode.A;
  static const int RIGHT = KeyCode.D;
  static const int SHOOT = KeyCode.J;
  static const int HYPERDRIVE = KeyCode.H;
  static const int TURBO = KeyCode.SPACE;

  Map<int, bool> keyPressed = new Map<int, bool>();

  Spatial spatial;
  Velocity velocity;
  Cannon cannon;
  HyperDrive hyperDrive;
  Thruster thruster;
  Turbo turbo;

  CanvasElement canvas;
  GameState state;

  StreamSubscription<KeyboardEvent> keyDownSubscription;
  StreamSubscription<KeyboardEvent> keyUpSubscription;

  PlayerControlSystem(this.canvas);

  void initialize() {
    super.initialize();
    var velocityMapper = new ComponentMapper<Velocity>(Velocity, world);
    var cannonMapper = new ComponentMapper<Cannon>(Cannon, world);
    var spatialMapper = new ComponentMapper<Spatial>(Spatial, world);
    var hyperDriveMapper = new ComponentMapper<HyperDrive>(HyperDrive, world);
    var thrusterMapper = new ComponentMapper<Thruster>(Thruster, world);
    var turboMapper = new ComponentMapper<Turbo>(Turbo, world);

    spatial = spatialMapper.get(player);
    velocity = velocityMapper.get(player);
    cannon = cannonMapper.get(player);
    hyperDrive = hyperDriveMapper.get(player);
    thruster = thrusterMapper.get(player);
    turbo = turboMapper.get(player);

    keyDownSubscription = canvas.onKeyDown.listen(handleKeyDown);
    keyUpSubscription = canvas.onKeyUp.listen(handleKeyUp);
  }

  void processSystem() {
    if (activateHyperdrive) {
      hyperDrive.active = keyPressed[HYPERDRIVE] == true;
      spatial.resources = ['spaceship.png'];
      cannon.shoot = false;
      thruster.active = false;
      thruster.turn = Thruster.TURN_NONE;
      keyDownSubscription.cancel();
      keyUpSubscription.cancel();
    } else {
      if (accelerate) {
        if (!thruster.active) {
          thruster.active = true;
          spatial.resources = ['spaceship.png', 'spaceship_thrusters.png'];
        }
      } else {
        if (thruster.active) {
          thruster.active = false;
          spatial.resources = ['spaceship.png'];
        }
      }
      if (activateTurbo) {
        if (turbo.canTurboActivate) {
          turbo.active = true;
        }
      }
      if (turnLeft) {
        thruster.turn = Thruster.TURN_LEFT;
      } else if (turnRight) {
        thruster.turn = Thruster.TURN_RIGHT;
      } else {
        thruster.turn = Thruster.TURN_NONE;
      }
      cannon.shoot = shoot;
    }
  }

  void releaseAllKeys() => keyPressed.keys.forEach((key) => keyPressed[key] = false);

  bool get accelerate => keyPressed[ACCELERATE] == true;
  bool get turnLeft => keyPressed[LEFT] == true;
  bool get turnRight => keyPressed[RIGHT] == true;
  bool get activateHyperdrive => keyPressed[HYPERDRIVE] == true && hyperDrive.enabled;
  bool get shoot => keyPressed[SHOOT] == true;
  bool get activateTurbo => keyPressed[TURBO] == true;

  void handleKeyDown(KeyboardEvent e) {
    e.preventDefault();
    keyPressed[e.keyCode] = true;
  }
  void handleKeyUp(KeyboardEvent e) {
    e.preventDefault();
    keyPressed[e.keyCode] = false;
  }

  bool checkProcessing() => gameState.running && status.health > 0 && !hyperDrive.active;
}
