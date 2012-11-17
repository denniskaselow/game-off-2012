part of multiverse;

class SpatialRenderingSystem extends OnScreenEntityProcessingSystem {

  CanvasRenderingContext2D context2d;
  Map<String, ImageElement> loadedImages = new Map<String, ImageElement>();
  ComponentMapper<Spatial> spatialMapper;

  SpatialRenderingSystem(this.context2d) : super(Aspect.getAspectForAllOf(new Spatial.hack().runtimeType,[new Transform.hack().runtimeType]).exclude(new Background.hack().runtimeType));

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

  void drawSpatial(Transform transform, CameraPosition cameraPos, ImageElement image, Spatial spatial) {
    context2d.save();

    try {
      context2d.lineWidth = 0.5;
      context2d.fillStyle = "white";
      context2d.strokeStyle = "white";

      context2d.beginPath();

      if (cameraPos.x > UNIVERSE_WIDTH - MAX_WIDTH && transform.x < MAX_WIDTH) {
        context2d.translate(UNIVERSE_WIDTH, 0);
      }
      if (cameraPos.y > UNIVERSE_HEIGHT - MAX_HEIGHT && transform.y < MAX_HEIGHT) {
        context2d.translate(0, UNIVERSE_HEIGHT);
      }
      context2d.translate(transform.x, transform.y);
      if (spatial.isSprite) {
        num width = spatial.width * spatial.scale;
        num height = spatial.height * spatial.scale;
        context2d.drawImage(image, spatial.x + (transform.angle.round() * 128) % 8192, spatial.y, spatial.width, spatial.height, -width ~/2, -height ~/ 2, width, height);
      } else {
        num width = image.width * spatial.scale;
        num height = image.height * spatial.scale;
        context2d.rotate(transform.angle);
        context2d.drawImage(image, -width ~/2, -height ~/ 2, width, height);
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
  const int OVERLAP_WIDTH = 50;
  const int OVERLAP_HEIGHT = 50;

  CanvasElement bgCanvas;
  CanvasRenderingContext2D context2d;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  BackgroundRenderSystem(this.context2d);

  void initialize() {
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    tagManager = world.getManager(new TagManager().runtimeType);
    initBackground();
  }

  void initBackground() {
    GroupManager groupManager = world.getManager(new GroupManager().runtimeType);
    ComponentMapper<Spatial> spatialMapper = new ComponentMapper<Spatial>(new Spatial.hack().runtimeType, world);
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    bgCanvas = new CanvasElement(width: UNIVERSE_WIDTH + OVERLAP_WIDTH * 2, height: UNIVERSE_HEIGHT + OVERLAP_HEIGHT * 2);
    var bgContext = bgCanvas.context2d;

    bgContext.setTransform(1, 0, 0, 1, 0, 0);
    bgContext.translate(OVERLAP_WIDTH, OVERLAP_HEIGHT);

    groupManager.getEntities(GROUP_BACKGROUND).forEach((entity) {
      Transform transform = transformMapper.get(entity);
      Spatial spatial = spatialMapper.get(entity);
      ImageLoader.withImage(spatial.resource, (image) {
        bgContext.beginPath();
        bgContext.drawImage(image, transform.x - image.width ~/ 2, transform.y - image.height ~/ 2, image.width, image.height);
        bgContext.closePath();
      });
    });
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    context2d.setTransform(1, 0, 0, 1, 0, 0);
    context2d.translate(-cameraPos.x, -cameraPos.y);
    context2d..fillStyle = "black"
        ..beginPath()
        ..rect(cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT)
        ..fill()
        ..stroke()
        ..closePath();

    context2d.save();
    try {
      context2d.beginPath();
      num srcX = cameraPos.x + OVERLAP_WIDTH;
      num srcY = cameraPos.y + OVERLAP_HEIGHT;
      if (cameraPos.x < UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y < UNIVERSE_HEIGHT - MAX_HEIGHT) {
        context2d.drawImage(bgCanvas, srcX, srcY, MAX_WIDTH, MAX_HEIGHT, cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT);
      } else if (cameraPos.x > UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y < UNIVERSE_HEIGHT - MAX_HEIGHT) {
        num overlapWidthLeft = UNIVERSE_WIDTH - cameraPos.x + OVERLAP_WIDTH;
        num overlapWidthRight = MAX_WIDTH - (UNIVERSE_WIDTH - cameraPos.x) + OVERLAP_WIDTH;
        num overlapDestX = UNIVERSE_WIDTH - OVERLAP_WIDTH;
        context2d.drawImage(bgCanvas, srcX, srcY, overlapWidthLeft, MAX_HEIGHT, cameraPos.x, cameraPos.y, overlapWidthLeft, MAX_HEIGHT);
        context2d.drawImage(bgCanvas, 0, srcY, overlapWidthRight, MAX_HEIGHT, overlapDestX, cameraPos.y, overlapWidthRight, MAX_HEIGHT);
      } else if (cameraPos.x < UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y > UNIVERSE_HEIGHT - MAX_HEIGHT) {
        num overlapHeightTop = UNIVERSE_HEIGHT - cameraPos.y + OVERLAP_HEIGHT;
        num overlapHeightBottom = MAX_HEIGHT - (UNIVERSE_HEIGHT - cameraPos.y) + OVERLAP_HEIGHT;
        num overlapDestY = UNIVERSE_HEIGHT - OVERLAP_HEIGHT;
        context2d.drawImage(bgCanvas, srcX, srcY, MAX_WIDTH, overlapHeightTop, cameraPos.x, cameraPos.y, MAX_WIDTH, overlapHeightTop);
        context2d.drawImage(bgCanvas, srcX, 0, MAX_WIDTH, overlapHeightBottom, cameraPos.x, overlapDestY, MAX_WIDTH, overlapHeightBottom);
      } else {
        num overlapWidthLeft = UNIVERSE_WIDTH - cameraPos.x + OVERLAP_WIDTH;
        num overlapWidthRight = MAX_WIDTH - (UNIVERSE_WIDTH - cameraPos.x) + OVERLAP_WIDTH;
        num overlapHeightTop = UNIVERSE_HEIGHT - cameraPos.y + OVERLAP_HEIGHT;
        num overlapHeightBottom = MAX_HEIGHT - (UNIVERSE_HEIGHT - cameraPos.y) + OVERLAP_HEIGHT;
        num overlapDestX = UNIVERSE_WIDTH - OVERLAP_WIDTH;
        num overlapDestY = UNIVERSE_HEIGHT - OVERLAP_HEIGHT;
        context2d.drawImage(bgCanvas, srcX, srcY, overlapWidthLeft, overlapHeightTop, cameraPos.x, cameraPos.y, overlapWidthLeft, overlapHeightTop);
        context2d.drawImage(bgCanvas, 0, srcY, overlapWidthRight, overlapHeightTop, overlapDestX, cameraPos.y, overlapWidthRight, overlapHeightTop);
        context2d.drawImage(bgCanvas, srcX, 0, overlapWidthLeft, overlapHeightBottom, cameraPos.x, overlapDestY, overlapWidthLeft, overlapHeightBottom);
        context2d.drawImage(bgCanvas, 0, 0, overlapWidthRight, overlapHeightBottom, overlapDestX, overlapDestY, overlapWidthRight, overlapHeightBottom);
      }
      context2d.closePath();
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
      context2d.rect(0, 0, MAX_WIDTH, HUD_HEIGHT);
      context2d.closePath();

      context2d.fill();

    } finally {
      context2d.restore();
    }
  }
}

class ImageLoader {
  static final Map<String, ImageElement> loadedImages = new Map<String, ImageElement>();

  static void withImage(String imagePath, void action(ImageElement image)) {
    ImageElement image = loadedImages[imagePath];
    if (null == image) {
      image = new ImageElement();
      image.on.load.add((event) {
        action(image);
        loadedImages[imagePath] = image;
      });
      image.src = imagePath;
    } else {
      action(image);
    }
  }

}