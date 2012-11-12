part of multiverse;

class PlayerControlSystem extends VoidEntitySystem {
  const int UP = 87;
  const int DOWN = 83;
  const int LEFT = 65;
  const int RIGHT = 68;

  bool moveUp = false;
  bool moveDown = false;
  bool moveLeft = false;
  bool moveRight = false;
  bool shoot = false;

  num targetX = 0;
  num targetY = 0;

  ComponentMapper<Velocity> velocityMapper;
  TagManager tagManager;

  CanvasElement canvas;

  PlayerControlSystem(this.canvas) : super();

  void initialize() {
    velocityMapper = new ComponentMapper<Velocity>(new Velocity.hack().runtimeType, world);

    tagManager = world.getManager(new TagManager().runtimeType);
    window.on.keyDown.add(handleKeyDown);
    window.on.keyUp.add(handleKeyUp);
    canvas.on.mouseDown.add(handleMouseDown);
    canvas.on.mouseUp.add(handleMouseUp);
  }

  void processEntities(ImmutableBag<Entity> entities) {
    Entity player = tagManager.getEntity(TAG_PLAYER);
    Velocity velocity = velocityMapper.get(player);

    if (moveUp) {
      velocity.y -= 0.1;
    } else if (moveDown) {
      velocity.y += 0.1;
    }
    if (moveLeft) {
      velocity.x -= 0.1;
    } else if(moveRight) {
      velocity.x += 0.1;
    }
  }

  void handleKeyDown(KeyboardEvent e) {
    int keyCode = e.keyCode;
    if (keyCode == UP) {
      moveUp = true;
      moveDown = false;
    } else if (keyCode == DOWN) {
      moveUp = false;
      moveDown = true;
    } else if (keyCode == LEFT) {
      moveLeft = true;
      moveRight = false;
    } else if (keyCode == RIGHT) {
      moveLeft = false;
      moveRight = true;
    }
  }

  void handleKeyUp(KeyboardEvent e) {
    int keyCode = e.keyCode;
    if (keyCode == UP) {
      moveUp = false;
    } else if (keyCode == DOWN) {
      moveDown = false;
    } else if (keyCode == LEFT) {
      moveLeft = false;
    } else if (keyCode == RIGHT) {
      moveRight = false;
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
