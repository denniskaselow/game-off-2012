part of html;

class PlayerControlSystem extends PlayerStatusProcessingSystem {
  static const int ACCELERATE = KeyCode.W;
  static const int LEFT = KeyCode.A;
  static const int RIGHT = KeyCode.D;
  static const int SHOOT = KeyCode.J;
  static const int HYPERDRIVE = KeyCode.H;
  static const int TURBO = KeyCode.E;

  static const int ACCELERATE_2 = KeyCode.UP;
  static const int LEFT_2 = KeyCode.LEFT;
  static const int RIGHT_2 = KeyCode.RIGHT;
  static const int SHOOT_2= KeyCode.CTRL;
  static const int HYPERDRIVE_2 = KeyCode.SHIFT;
  static const int TURBO_2 = KeyCode.SPACE;

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
    var velocityMapper = new Mapper<Velocity>(Velocity, world);
    var cannonMapper = new Mapper<Cannon>(Cannon, world);
    var spatialMapper = new Mapper<Spatial>(Spatial, world);
    var hyperDriveMapper = new Mapper<HyperDrive>(HyperDrive, world);
    var thrusterMapper = new Mapper<Thruster>(Thruster, world);
    var turboMapper = new Mapper<Turbo>(Turbo, world);

    spatial = spatialMapper[player];
    velocity = velocityMapper[player];
    cannon = cannonMapper[player];
    hyperDrive = hyperDriveMapper[player];
    thruster = thrusterMapper[player];
    turbo = turboMapper[player];

    keyDownSubscription = canvas.onKeyDown.listen(handleKeyDown);
    keyUpSubscription = canvas.onKeyUp.listen(handleKeyUp);
  }

  void processSystem() {
    if (activateHyperdrive) {
      hyperDrive.active = true;
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
        turbo.active = true;
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

  bool get accelerate => keyPressed[ACCELERATE] == true || keyPressed[ACCELERATE_2] == true;
  bool get turnLeft => keyPressed[LEFT] == true || keyPressed[LEFT_2] == true;
  bool get turnRight => keyPressed[RIGHT] == true || keyPressed[RIGHT_2] == true;
  bool get activateHyperdrive => (keyPressed[HYPERDRIVE] == true  || keyPressed[HYPERDRIVE_2] == true) && hyperDrive.enabled;
  bool get shoot => keyPressed[SHOOT] == true || keyPressed[SHOOT_2] == true;
  bool get activateTurbo => (keyPressed[TURBO] == true || keyPressed[TURBO_2] == true) && turbo.canTurboActivate;

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
