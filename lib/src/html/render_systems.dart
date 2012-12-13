part of html;

class SpatialRenderingSystem extends OnScreenEntityProcessingSystem {

  CanvasRenderingContext2D context2d;
  ComponentMapper<Spatial> spatialMapper;
  ComponentMapper<ExpirationTimer> timerMapper;
  CameraPosition cameraPos;

  SpatialRenderingSystem(this.context2d) : super(Aspect.getAspectForAllOf(new Spatial.hack().runtimeType,[new Transform.hack().runtimeType]).exclude(new Background.hack().runtimeType));

  void initialize() {
    super.initialize();
    spatialMapper = new ComponentMapper<Spatial>(new Spatial.hack().runtimeType, world);
    timerMapper = new ComponentMapper<ExpirationTimer>(new ExpirationTimer.hack().runtimeType, world);
  }

  void begin() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    cameraPos = cameraPositionMapper.get(camera);
  }

  void processEntityOnScreen(Entity entity) {
    Spatial spatial = spatialMapper.get(entity);
    ImageCache.withImage(spatial.resource, (image) => drawImage(image, entity, spatial));
  }

  void drawImage(ImageElement image, Entity entity, Spatial spatial) {
    Transform transform = transformMapper.get(entity);
    ExpirationTimer timer = timerMapper.getSafe(entity);

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
      if (null != timer) {
        context2d.globalAlpha = timer.percentLeft;
      }
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

class NormalSpaceBackgroundRenderSystem extends PlayerStatusProcessingSystem {
  CanvasRenderingContext2D context2d;
  ComponentMapper<CameraPosition> cameraPositionMapper;

  NormalSpaceBackgroundRenderSystem(this.context2d);

  void initialize() {
    super.initialize();
    cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    renderNormalSpace(cameraPos);
  }

  void renderNormalSpace(CameraPosition cameraPos) {
    context2d.setTransform(1, 0, 0, 1, 0, 0);
    context2d.translate(-cameraPos.x, -cameraPos.y);
    context2d..fillStyle = "black"
        ..beginPath()
        ..rect(cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT)
        ..fill()
        ..stroke()
        ..closePath();
  }

  bool checkProcessing() => !status.leaveLevel || status.destroyed;
}

class HyperSpaceBackgroundRenderSystem extends NormalSpaceBackgroundRenderSystem {
  double hyperspaceMod = 0.0;

  HyperSpaceBackgroundRenderSystem(context2d) : super(context2d);

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    hyperspaceMod += 0.01 + hyperspaceMod * 0.005;
    if (hyperspaceMod > 0.5) {
      double stretch = hyperspaceMod - 0.5;
      context2d.setTransform(1/(1+stretch/50), 0, 0, 1+stretch, MAX_WIDTH / 2 - (MAX_WIDTH / (2 *(1+stretch/50))), 0);
      context2d.translate(-cameraPos.x, -cameraPos.y - (20 * stretch));
    }
    if (hyperspaceMod < 0.5) {
      renderNormalSpace(cameraPos);
    }
  }

  bool checkProcessing() => status.leaveLevel && !status.destroyed;
}

class BackgroundStarsRenderingSystem extends VoidEntitySystem {
  const int OVERLAP_WIDTH = 50;
  const int OVERLAP_HEIGHT = 50;

  CanvasElement bgCanvas;
  CanvasRenderingContext2D context2d;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  BackgroundStarsRenderingSystem(this.context2d);

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
      ImageCache.withImage(spatial.resource, (image) {
        bgContext.beginPath();
        bgContext.drawImage(image, transform.x - image.width ~/ 2, transform.y - image.height ~/ 2, image.width, image.height);
        bgContext.closePath();
      });
      entity.deleteFromWorld();
    });
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

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

class ParticleRenderSystem extends EntityProcessingSystem {
  CanvasRenderingContext2D context2d;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Particle> particleMapper;
  CameraPosition cameraPos;

  ParticleRenderSystem(this.context2d) : super(Aspect.getAspectForAllOf(new Particle.hack().runtimeType, [new Transform.hack().runtimeType]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    particleMapper = new ComponentMapper<Particle>(new Particle.hack().runtimeType, world);
    ComponentMapper<CameraPosition> cameraPositionMapper = new ComponentMapper<CameraPosition>(new CameraPosition.hack().runtimeType, world);
    TagManager tagManager = world.getManager(new TagManager().runtimeType);

    Entity camera = tagManager.getEntity(TAG_CAMERA);
    cameraPos = cameraPositionMapper.get(camera);
  }

  void processEntity(Entity e) {

    Transform t = transformMapper.get(e);
    Particle p = particleMapper.get(e);

    context2d.save();
    try {
      if (cameraPos.x > UNIVERSE_WIDTH - MAX_WIDTH && t.x < MAX_WIDTH) {
        context2d.translate(UNIVERSE_WIDTH, 0);
      }
      if (cameraPos.y > UNIVERSE_HEIGHT - MAX_HEIGHT && t.y < MAX_HEIGHT) {
        context2d.translate(0, UNIVERSE_HEIGHT);
      }
      context2d.translate(t.x, t.y);

      context2d.fillStyle = p.color;
      context2d.fillRect(0, 0, 1, 1);
    } finally {
      context2d.restore();
    }
  }
}

class HudRenderSystem extends PlayerStatusProcessingSystem {
  CanvasRenderingContext2D context2d;

  HudRenderSystem(this.context2d);

  void processSystem() {
    context2d.save();
    context2d.transform(1, 0, 0, 1, 90, 12);
    try {
      context2d.beginPath();
      context2d.fillStyle = "black";
      context2d.fillRect(0, 0, 200, 15);
      context2d.fillStyle = "green";
      context2d.fillRect(0, 0, 200 * status.health / status.maxHealth, 15);
      context2d.closePath();

    } finally {
      context2d.restore();
    }

    ImageCache.withImage("hud_dummy.png", (image) => context2d.drawImage(image, 0, 0, MAX_WIDTH, HUD_HEIGHT));
  }
}

class MiniMapRenderSystem extends EntitySystem {
  CanvasRenderingContext2D context2d;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<MiniMapRenderable> renderableMapper;
  ComponentMapper<CircularBody> bodyMapper;

  MiniMapRenderSystem(this.context2d) : super(Aspect.getAspectForAllOf(new MiniMapRenderable.hack().runtimeType, [new Transform.hack().runtimeType, new CircularBody.hack().runtimeType]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(new Transform.hack().runtimeType, world);
    renderableMapper = new ComponentMapper<MiniMapRenderable>(new MiniMapRenderable.hack().runtimeType, world);
    bodyMapper = new ComponentMapper<CircularBody>(new CircularBody.hack().runtimeType, world);
  }

  void processEntities(ImmutableBag<Entity> entities) {
    context2d.save();
    context2d.transform(80/UNIVERSE_WIDTH, 0, 0, 80/UNIVERSE_HEIGHT, MAX_WIDTH - 90, 10);
    try {
      context2d.fillStyle = "black";
      context2d.beginPath();
      context2d.fillRect(0, 0, UNIVERSE_WIDTH, UNIVERSE_HEIGHT);
      context2d.closePath();

      entities.forEach((entity) {
        Transform transform = transformMapper.get(entity);
        MiniMapRenderable renderable = renderableMapper.get(entity);
        CircularBody body = bodyMapper.get(entity);

        context2d.fillStyle = renderable.color;
        context2d.strokeStyle = renderable.color;
        context2d.beginPath();
        context2d.fillRect(transform.x - body.radius / 2, transform.y - body.radius / 2, body.radius, body.radius);
        context2d.closePath();
      });
    } finally {
      context2d.restore();
    }
  }

  bool checkProcessing() => true;
}

class ImageCache {
  static final Map<String, ImageElement> loadedImages = new Map<String, ImageElement>();

  static void withImage(String imageName, void action(ImageElement image)) {
    ImageElement image = loadedImages[imageName];
    if (null == image) {
      image = new ImageElement();
      image.on.load.add((event) {
        action(image);
        loadedImages[imageName] = image;
      });
      image.src = "resources/img/${imageName}";
    } else {
      action(image);
    }
  }

}