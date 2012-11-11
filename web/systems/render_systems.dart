part of multiverse;

abstract class OnScreenProcessingSystem extends EntityProcessingSystem {

  static final num MAX_RENDER_DISTANCE_X = MAXWIDTH + 50;
  static final num MAX_RENDER_DISTANCE_Y = MAXHEIGHT + 50;
  static final num MIN_RENDER_DISTANCE_X_BORDER = UNIVERSE_WIDTH - MAX_RENDER_DISTANCE_X;
  static final num MIN_RENDER_DISTANCE_Y_BORDER = UNIVERSE_HEIGHT - MAX_RENDER_DISTANCE_Y;

  ComponentMapper<Transform> positionMapper;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  OnScreenProcessingSystem(Aspect aspect) : super(aspect.allOf(new Transform.hack().runtimeType));

  void initialize() {
    positionMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
  }

  void processEntity(Entity entity) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Transform pos = positionMapper.get(entity);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    if (isWithtinXRange(pos, cameraPos) && isWithtinYRange(pos, cameraPos)) {
      processEntityOnScreen(entity);
    }
  }

  bool isWithtinXRange(Transform pos, CameraPosition camPos) {
    num distanceX = (camPos.x - pos.x).abs();
    return (distanceX < MAX_RENDER_DISTANCE_X || distanceX > MIN_RENDER_DISTANCE_X_BORDER);
  }

  bool isWithtinYRange(Transform pos, CameraPosition camPos) {
    num distanceY = (camPos.y - pos.y).abs();
    return (distanceY < MAX_RENDER_DISTANCE_Y || distanceY > MIN_RENDER_DISTANCE_Y_BORDER);
  }

  void processEntityOnScreen(Entity entity);

}

class PositionalRenderingSystem extends OnScreenProcessingSystem {

  CanvasRenderingContext2D context2d;

  PositionalRenderingSystem(this.context2d) : super(Aspect.getAspectForAllOf(new Transform.hack().runtimeType));

  void processEntityOnScreen(Entity entity) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Transform pos = positionMapper.get(entity);
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

  void drawCirle(Transform pos, CameraPosition cameraPos) {
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

class SpatialRenderingSystem extends OnScreenProcessingSystem {

  CanvasRenderingContext2D context2d;
  Map<String, ImageElement> loadedImages = new Map<String, ImageElement>();
  ComponentMapper<Spatial> spatialMapper;

  SpatialRenderingSystem(this.context2d) : super(Aspect.getAspectForAllOf(new Spatial.hack().runtimeType,[new Transform.hack().runtimeType]));

  void initialize() {
    super.initialize();
    spatialMapper = new ComponentMapper<Spatial>(new Spatial.hack().runtimeType, world);
  }

  void processEntityOnScreen(Entity entity) {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    Transform pos = positionMapper.get(entity);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);
    Spatial spatial = spatialMapper.get(entity);
    ImageElement image = loadedImages[spatial.resource];
    if (null == image) {
      image = new ImageElement();
      image.on.load.add((event) {
        loadedImages[spatial.resource] = image;
        drawSpatial(pos, cameraPos, image, spatial);
      });
      image.src = spatial.resource;
    } else {
      drawSpatial(pos, cameraPos, image, spatial);
    }
  }

  void drawSpatial(Transform pos, CameraPosition cameraPos, ImageElement image, Spatial spatial) {
    context2d.save();

    try {
      context2d.lineWidth = 0.5;
      context2d.fillStyle = "white";
      context2d.strokeStyle = "white";

      context2d.beginPath();

      if (cameraPos.x > UNIVERSE_WIDTH - MAXWIDTH && pos.x < MAXWIDTH) {
        context2d.translate(UNIVERSE_WIDTH, 0);
      }
      if (cameraPos.y > UNIVERSE_HEIGHT - MAXHEIGHT && pos.y < MAXHEIGHT) {
        context2d.translate(0, UNIVERSE_HEIGHT);
      }
      context2d.translate(pos.x, pos.y);
      if (spatial.isSprite) {
        num width = spatial.width * spatial.scale;
        num height = spatial.height * spatial.scale;
        context2d.drawImage(image, spatial.x + (pos.angle.round() * 128) % 8192, spatial.y, spatial.width, spatial.height, -width ~/2, -height ~/ 2, width, height);
      } else {
        context2d.drawImage(image, -image.width ~/2, -image.height ~/ 2, image.width, image.height);
      }

      context2d.closePath();
      context2d.fill();

      context2d.stroke();
    } finally {
      context2d.restore();
    }
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