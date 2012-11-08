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
    return ((camPos.x - pos.x).abs() < (MAXWIDTH * 2) || (camPos.x - pos.x).abs() > UNIVERSE_WIDTH - (MAXWIDTH * 2));
  }

  bool isWithtinYRange(Position pos, CameraPosition camPos) {
    return ((camPos.y - pos.y).abs() < (MAXHEIGHT * 2) || (camPos.y - pos.y).abs() > UNIVERSE_HEIGHT - (MAXHEIGHT * 2));
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

    if (cameraPos.x - UNIVERSE_WIDTH > -MAXWIDTH && pos.x < MAXWIDTH) {
      x = pos.x + (UNIVERSE_WIDTH - cameraPos.x);
    } else {
      x = pos.x - cameraPos.x;
    }
    if (cameraPos.y - UNIVERSE_WIDTH > -MAXHEIGHT && pos.y < MAXHEIGHT) {
      y = pos.y + (UNIVERSE_HEIGHT - cameraPos.y);
    } else {
      y = pos.y - cameraPos.y;
    }
    context2d.arc(x, y, 10, 0, FastMath.TWO_PI, false);

    context2d.closePath();
    context2d.fill();
  }
}

class BackgroundRenderSystem extends VoidEntitySystem {
  CanvasRenderingContext2D context2d;

  BackgroundRenderSystem(this.context2d);

  void processSystem() {
    context2d.save();
    try {
      context2d.fillStyle = "black";

      context2d.beginPath();
      context2d.rect(0, 0, MAXWIDTH, MAXHEIGHT + HUDHEIGHT);
      context2d.closePath();

      context2d.fill();
    } finally {
      context2d.restore();
    }
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
      context2d.rect(0, MAXHEIGHT, MAXWIDTH, MAXHEIGHT + HUDHEIGHT);
      context2d.closePath();

      context2d.fill();

    } finally {
      context2d.restore();
    }
  }
}