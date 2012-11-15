part of multiverse;

class PlayerControlSystem extends VoidEntitySystem {
  const int ACCELERATE = 87;
  const int DECELERATE = 83;
  const int LEFT = 65;
  const int RIGHT = 68;

  bool accelerate = false;
  bool decelerate = false;
  bool turnLeft = false;
  bool turnRight = false;
  bool shoot = false;

  num targetX = 0;
  num targetY = 0;

  ComponentMapper<Velocity> velocityMapper;
  ComponentMapper<Transform> transformMapper;
  TagManager tagManager;

  CanvasElement canvas;

  PlayerControlSystem(this.canvas) : super();

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);

    tagManager = world.getManager(new TagManager().runtimeType);
    window.on.keyDown.add(handleKeyDown);
    window.on.keyUp.add(handleKeyUp);
    canvas.on.mouseDown.add(handleMouseDown);
    canvas.on.mouseUp.add(handleMouseUp);
  }

  void processEntities(ImmutableBag<Entity> entities) {
    Entity player = tagManager.getEntity(TAG_PLAYER);
    Velocity velocity = velocityMapper.get(player);
    Transform transform = transformMapper.get(player);

    if (accelerate) {
      velocity.x += 0.05 * TrigUtil.cos(transform.angle);
      velocity.y += 0.05 * TrigUtil.sin(transform.angle);
    } else if (decelerate) {
      velocity.x *= 0.98;
      velocity.y *= 0.98;
    }
    if (turnLeft) {
      transform.angle = (transform.angle - 0.05) % FastMath.TWO_PI;
    } else if(turnRight) {
      transform.angle = (transform.angle + 0.05) % FastMath.TWO_PI;
    }
  }

  void handleKeyDown(KeyboardEvent e) {
    int keyCode = e.keyCode;
    if (keyCode == ACCELERATE) {
      accelerate = true;
      decelerate = false;
    } else if (keyCode == DECELERATE) {
      accelerate = false;
      decelerate = true;
    } else if (keyCode == LEFT) {
      turnLeft = true;
      turnRight = false;
    } else if (keyCode == RIGHT) {
      turnLeft = false;
      turnRight = true;
    }
  }

  void handleKeyUp(KeyboardEvent e) {
    int keyCode = e.keyCode;
    if (keyCode == ACCELERATE) {
      accelerate = false;
    } else if (keyCode == DECELERATE) {
      decelerate = false;
    } else if (keyCode == LEFT) {
      turnLeft = false;
    } else if (keyCode == RIGHT) {
      turnRight = false;
    }
  }

  void handleMouseDown(MouseEvent e) {
    targetX = e.offsetX;
    targetY = e.offsetY;
    shoot = true;
  }

  void handleMouseUp(MouseEvent e) {
    shoot = false;
  }
}
