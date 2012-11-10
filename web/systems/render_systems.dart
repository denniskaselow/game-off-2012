part of multiverse;

abstract class OnScreenProcessingSystem extends EntityProcessingSystem {

  ComponentMapper<Position> positionMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  OnScreenProcessingSystem(Aspect aspect) : super(aspect.allOf(new Position.hack().runtimeType));

  void initialize() {
    positionMapper = new ComponentMapper<Position>(new Position.hack().runtimeType, world);
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processEntity(Entity entity) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Position pos = positionMapper.get(entity);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    if (isWithtinXRange(pos, cameraPos) && isWithtinYRange(pos, cameraPos)) {
      processEntityOnScreen(entity);
    }
  }

  bool isWithtinXRange(Position pos, CameraPosition camPos) {
    return ((camPos.x - pos.x).abs() < (MAXWIDTH + 50) || (camPos.x - pos.x).abs() > UNIVERSE_WIDTH - (MAXWIDTH + 50));
  }

  bool isWithtinYRange(Position pos, CameraPosition camPos) {
    return ((camPos.y - pos.y).abs() < (MAXHEIGHT + 50) || (camPos.y - pos.y).abs() > UNIVERSE_HEIGHT - (MAXHEIGHT + 50 ));
  }

  void processEntityOnScreen(Entity entity);

}

class PositionalRenderingSystem extends OnScreenProcessingSystem {

  CanvasRenderingContext2D context2d;

  PositionalRenderingSystem(this.context2d) : super(Aspect.getAspectForAllOf(new Position.hack().runtimeType));

  void processEntityOnScreen(Entity entity) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Position pos = positionMapper.get(entity);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    context2d.save();

    try {
      context2d.lineWidth = 0.5;
      context2d.fillStyle = "white";
      context2d.strokeStyle = "white";

      drawCirle(pos, cameraPos);

      context2d.stroke();
    } finally {
      context2d.restore();
    }
  }

  void drawCirle(Position pos, CameraPosition cameraPos) {
    context2d.beginPath();
    num x, y;

    if (cameraPos.x > UNIVERSE_WIDTH - MAXWIDTH && pos.x < MAXWIDTH) {
      context2d.translate(UNIVERSE_WIDTH, 0);
    }
    if (cameraPos.y > UNIVERSE_HEIGHT - MAXHEIGHT && pos.y < MAXHEIGHT) {
      context2d.translate(0, UNIVERSE_HEIGHT);
    }
    context2d.arc(pos.x, pos.y, 10, 0, FastMath.TWO_PI, false);

    context2d.closePath();
    context2d.fill();
  }
}

class BackgroundRenderSystem extends VoidEntitySystem {
  CanvasRenderingContext2D context2d;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  BackgroundRenderSystem(this.context2d);

  void initialize() {
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    context2d.setTransform(1, 0, 0, 1, 0, 0);

    context2d.save();
    try {
      context2d.fillStyle = "black";

      context2d.beginPath();
      context2d.rect(0, 0, UNIVERSE_WIDTH, UNIVERSE_HEIGHT);
      context2d.closePath();

      context2d.fill();
    } finally {
      context2d.restore();
    }

    context2d.translate(-cameraPos.x, -cameraPos.y);
  }
}

class HudRenderSystem extends VoidEntitySystem {
  CanvasRenderingContext2D context2d;

  HudRenderSystem(this.context2d);

  void initialize() {
  }

  void processSystem() {
    context2d.save();
    try {
      context2d.fillStyle = "#555";

      context2d.beginPath();
      context2d.rect(0, 0, MAXWIDTH, HUDHEIGHT);
      context2d.closePath();

      context2d.fill();

    } finally {
      context2d.restore();
    }
  }
}