part of html;

class SpatialRenderingSystem extends OnScreenEntityProcessingSystem {

  CanvasRenderingContext2D context;
  Atlas atlas;
  ComponentMapper<Spatial> spatialMapper;
  ComponentMapper<ExpirationTimer> timerMapper;
  CameraPosition cameraPos;

  SpatialRenderingSystem(this.context, this.atlas) : super(Aspect.getAspectForAllOf([Spatial, Transform]));

  void initialize() {
    super.initialize();
    spatialMapper = new ComponentMapper<Spatial>(Spatial, world);
    timerMapper = new ComponentMapper<ExpirationTimer>(ExpirationTimer, world);
  }

  void begin() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    cameraPos = cameraPositionMapper.get(camera);
  }

  void processEntityOnScreen(Entity entity) {
    Spatial spatial = spatialMapper.get(entity);
    drawImage(entity, spatial);
  }

  void drawImage(Entity entity, Spatial spatial) {
    Transform transform = transformMapper.get(entity);
    ExpirationTimer timer = timerMapper.getSafe(entity);

    context.save();

    try {
      context.lineWidth = 0.5;
      context.fillStyle = "white";
      context.strokeStyle = "white";

      context.beginPath();

      if (cameraPos.x > UNIVERSE_WIDTH - MAX_WIDTH && transform.x < MAX_WIDTH) {
        context.translate(UNIVERSE_WIDTH, 0);
      }
      if (cameraPos.y > UNIVERSE_HEIGHT - MAX_HEIGHT && transform.y < MAX_HEIGHT) {
        context.translate(0, UNIVERSE_HEIGHT);
      }
      context.translate(transform.x, transform.y);
      if (null != timer) {
        context.globalAlpha = timer.percentLeft;
      }
      num scale = spatial.scale;
      if (spatial.isAnimated) {
        int index = (transform.angle.round() % spatial.resources.length).toInt();
        Sprite sprite = atlas.sprites[spatial.resources[index]];
        drawSprite(sprite, scale);
      } else {
        context.rotate(transform.angle);
        spatial.resources.forEach((resource) {
          Sprite sprite = atlas.sprites[resource];
          drawSprite(sprite, scale);
        });
      }

      context.closePath();
      context.fill();

      context.stroke();
    } finally {
      context.restore();
    }
  }

  void drawSprite(Sprite sprite, num scale) {
    // TODO scale when createing spatial
    Rect dest = new Rect(sprite.dst.left * scale, sprite.dst.top * scale, sprite.dst.width * scale, sprite.dst.height * scale);
    context.drawImageToRect(atlas.image, dest, sourceRect : sprite.src);
  }
}

class NormalSpaceBackgroundRenderSystem extends PlayerStatusProcessingSystem {
  CanvasRenderingContext2D context;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  HyperDrive hyperDrive;

  NormalSpaceBackgroundRenderSystem(this.context);

  void initialize() {
    super.initialize();
    cameraPositionMapper = new ComponentMapper<CameraPosition>(CameraPosition, world);
    var hdMapper = new ComponentMapper<HyperDrive>(HyperDrive, world);
    hyperDrive = hdMapper.get(player);
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    renderNormalSpace(cameraPos);
  }

  void renderNormalSpace(CameraPosition cameraPos) {
    context.setTransform(1, 0, 0, 1, 0, 0);
    context.translate(-cameraPos.x, -cameraPos.y);
    context..fillStyle = "black"
        ..beginPath()
        ..rect(cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT)
        ..fill()
        ..stroke()
        ..closePath();
  }

  bool checkProcessing() => !hyperDrive.active || status.destroyed;
}

class HyperSpaceBackgroundRenderSystem extends NormalSpaceBackgroundRenderSystem {
  HyperDrive hyperDrive;

  HyperSpaceBackgroundRenderSystem(context) : super(context);

  void initialize() {
    super.initialize();
    var hdMapper = new ComponentMapper<HyperDrive>(HyperDrive, world);
    hyperDrive = hdMapper.get(player);
  }

  void processSystem() {
    var camera = tagManager.getEntity(TAG_CAMERA);
    var cameraPos = cameraPositionMapper.get(camera);

    var mod = hyperDrive.hyperSpaceMod;
    context.setTransform(1/(1+mod/50), 0, 0, 1+mod, MAX_WIDTH / 2 - (MAX_WIDTH / (2 *(1+mod/50))), 0);
    context.translate(-cameraPos.x, -cameraPos.y - (20 * mod));

    context.globalAlpha = max(0.05, 1 - (mod));
    context..fillStyle = "black"
        ..beginPath()
        ..rect(cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT)
        ..fill()
        ..stroke()
        ..closePath();
    context.globalAlpha = 1;
  }

  bool checkProcessing() => hyperDrive.active && !status.destroyed;
}

class BackgroundStarsRenderingSystem extends VoidEntitySystem {
  const int OVERLAP_WIDTH = 50;
  const int OVERLAP_HEIGHT = 50;

  CanvasElement bgCanvas;
  Atlas atlas;
  CanvasRenderingContext2D context;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  BackgroundStarsRenderingSystem(this.context, this.atlas);

  void initialize() {
    cameraPositionMapper = new ComponentMapper<CameraPosition>(CameraPosition, world);
    tagManager = world.getManager(new TagManager().runtimeType);
    initBackground();
  }

  void initBackground() {
    GroupManager groupManager = world.getManager(new GroupManager().runtimeType);
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform, world);
    bgCanvas = new CanvasElement(width: UNIVERSE_WIDTH + OVERLAP_WIDTH * 2, height: UNIVERSE_HEIGHT + OVERLAP_HEIGHT * 2);
    var bgContext = bgCanvas.context2D;

    bgContext.setTransform(1, 0, 0, 1, 0, 0);
    bgContext.translate(OVERLAP_WIDTH, OVERLAP_HEIGHT);
    Sprite sprite = atlas.sprites['star_00.png'];
    var star = cq(100, 100)..translate(50, 50)..drawImageToRect(atlas.image, sprite.dst, sourceRect: sprite.src);
    List<CanvasElement> stars = new List<CanvasElement>(20);
    for (int i = 0; i < 20; i++) {
      star.setHsl(hue: random.nextDouble(), saturation: 0.5+random.nextDouble() / 2, lightness: 0.5 + random.nextDouble() / 2);
      stars[i] = star.copy();
    }

    groupManager.getEntities(GROUP_BACKGROUND).forEach((entity) {
      Transform transform = transformMapper.get(entity);
      bgContext.drawImage(stars[random.nextInt(20)], transform.x - star.canvas.width ~/ 2, transform.y - star.canvas.height ~/ 2);
      entity.deleteFromWorld();
    });
  }

  void processSystem() {
    Entity camera = tagManager.getEntity(TAG_CAMERA);
    CameraPosition cameraPos = cameraPositionMapper.get(camera);

    context.save();
    try {
      context.beginPath();
      num srcX = cameraPos.x + OVERLAP_WIDTH;
      num srcY = cameraPos.y + OVERLAP_HEIGHT;
      if (cameraPos.x < UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y < UNIVERSE_HEIGHT - MAX_HEIGHT) {
        context.drawImageScaledFromSource(bgCanvas, srcX, srcY, MAX_WIDTH, MAX_HEIGHT, cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT);
      } else if (cameraPos.x > UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y < UNIVERSE_HEIGHT - MAX_HEIGHT) {
        num overlapWidthLeft = UNIVERSE_WIDTH - cameraPos.x + OVERLAP_WIDTH;
        num overlapWidthRight = MAX_WIDTH - (UNIVERSE_WIDTH - cameraPos.x) + OVERLAP_WIDTH;
        num overlapDestX = UNIVERSE_WIDTH - OVERLAP_WIDTH;
        context.drawImageScaledFromSource(bgCanvas, srcX, srcY, overlapWidthLeft, MAX_HEIGHT, cameraPos.x, cameraPos.y, overlapWidthLeft, MAX_HEIGHT);
        context.drawImageScaledFromSource(bgCanvas, 0, srcY, overlapWidthRight, MAX_HEIGHT, overlapDestX, cameraPos.y, overlapWidthRight, MAX_HEIGHT);
      } else if (cameraPos.x < UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y > UNIVERSE_HEIGHT - MAX_HEIGHT) {
        num overlapHeightTop = UNIVERSE_HEIGHT - cameraPos.y + OVERLAP_HEIGHT;
        num overlapHeightBottom = MAX_HEIGHT - (UNIVERSE_HEIGHT - cameraPos.y) + OVERLAP_HEIGHT;
        num overlapDestY = UNIVERSE_HEIGHT - OVERLAP_HEIGHT;
        context.drawImageScaledFromSource(bgCanvas, srcX, srcY, MAX_WIDTH, overlapHeightTop, cameraPos.x, cameraPos.y, MAX_WIDTH, overlapHeightTop);
        context.drawImageScaledFromSource(bgCanvas, srcX, 0, MAX_WIDTH, overlapHeightBottom, cameraPos.x, overlapDestY, MAX_WIDTH, overlapHeightBottom);
      } else {
        num overlapWidthLeft = UNIVERSE_WIDTH - cameraPos.x + OVERLAP_WIDTH;
        num overlapWidthRight = MAX_WIDTH - (UNIVERSE_WIDTH - cameraPos.x) + OVERLAP_WIDTH;
        num overlapHeightTop = UNIVERSE_HEIGHT - cameraPos.y + OVERLAP_HEIGHT;
        num overlapHeightBottom = MAX_HEIGHT - (UNIVERSE_HEIGHT - cameraPos.y) + OVERLAP_HEIGHT;
        num overlapDestX = UNIVERSE_WIDTH - OVERLAP_WIDTH;
        num overlapDestY = UNIVERSE_HEIGHT - OVERLAP_HEIGHT;
        context.drawImageScaledFromSource(bgCanvas, srcX, srcY, overlapWidthLeft, overlapHeightTop, cameraPos.x, cameraPos.y, overlapWidthLeft, overlapHeightTop);
        context.drawImageScaledFromSource(bgCanvas, 0, srcY, overlapWidthRight, overlapHeightTop, overlapDestX, cameraPos.y, overlapWidthRight, overlapHeightTop);
        context.drawImageScaledFromSource(bgCanvas, srcX, 0, overlapWidthLeft, overlapHeightBottom, cameraPos.x, overlapDestY, overlapWidthLeft, overlapHeightBottom);
        context.drawImageScaledFromSource(bgCanvas, 0, 0, overlapWidthRight, overlapHeightBottom, overlapDestX, overlapDestY, overlapWidthRight, overlapHeightBottom);
      }
      context.closePath();
    } finally {
      context.restore();
    }
  }
}

class ParticleRenderSystem extends EntityProcessingSystem {
  CanvasRenderingContext2D context;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<Particle> particleMapper;
  CameraPosition cameraPos;

  ParticleRenderSystem(this.context) : super(Aspect.getAspectForAllOf([Particle, Transform]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    particleMapper = new ComponentMapper<Particle>(Particle, world);
    ComponentMapper<CameraPosition> cameraPositionMapper = new ComponentMapper<CameraPosition>(CameraPosition, world);
    TagManager tagManager = world.getManager(new TagManager().runtimeType);

    Entity camera = tagManager.getEntity(TAG_CAMERA);
    cameraPos = cameraPositionMapper.get(camera);
  }

  void processEntity(Entity e) {

    Transform t = transformMapper.get(e);
    Particle p = particleMapper.get(e);

    context.save();
    try {
      if (cameraPos.x > UNIVERSE_WIDTH - MAX_WIDTH && t.x < MAX_WIDTH) {
        context.translate(UNIVERSE_WIDTH, 0);
      }
      if (cameraPos.y > UNIVERSE_HEIGHT - MAX_HEIGHT && t.y < MAX_HEIGHT) {
        context.translate(0, UNIVERSE_HEIGHT);
      }
      context.translate(t.x, t.y);

      context.fillStyle = p.color;
      context.fillRect(0, 0, 1, 1);
    } finally {
      context.restore();
    }
  }
}

class HudRenderSystem extends PlayerStatusProcessingSystem {
  const LABEL_SCORE = "Score:";
  const LABEL_LEVEL = "Level:";
  CanvasRenderingContext2D context;
  num scoreX, levelX;

  HudRenderSystem(this.context);

  void initialize() {
    super.initialize();
    var bounds = context.measureText(LABEL_SCORE);
    scoreX = 550 - bounds.width;
    bounds = context.measureText(LABEL_LEVEL);
    levelX = 550 - bounds.width;
  }

  void processSystem() {
    context.save();
    context.transform(1, 0, 0, 1, 90, 12);
    try {
      context.beginPath();
      context.fillStyle = "black";
      context.fillRect(0, 0, 200, 15);
      context.fillStyle = "green";
      context.fillRect(0, 0, 200 * status.health / status.maxHealth, 15);
      context.closePath();
    } finally {
      context.restore();
    }

    ImageCache.withImage("hud_dummy.png", (image) => context.drawImage(image, 0, 0));
    String score = "${gameState.score.toStringAsFixed(0)}";
    String level = "${(gameState.currentLevel+1).toString()}";
    context.fillText(LABEL_LEVEL, levelX, 11);
    context.fillText(LABEL_SCORE, scoreX, 31);
    var bounds = context.measureText(level);
    context.fillText(level, 680 - bounds.width, 11);
    bounds = context.measureText(score);
    context.fillText(score, 680 - bounds.width, 31);
  }
}

class MiniMapRenderSystem extends EntitySystem {
  CanvasRenderingContext2D context;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<MiniMapRenderable> renderableMapper;
  ComponentMapper<CircularBody> bodyMapper;

  MiniMapRenderSystem(this.context) : super(Aspect.getAspectForAllOf([MiniMapRenderable, Transform, CircularBody]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    renderableMapper = new ComponentMapper<MiniMapRenderable>(MiniMapRenderable, world);
    bodyMapper = new ComponentMapper<CircularBody>(CircularBody, world);
  }

  void processEntities(ReadOnlyBag<Entity> entities) {
    context.save();
    context.transform(80/UNIVERSE_WIDTH, 0, 0, 80/UNIVERSE_HEIGHT, MAX_WIDTH - 90, 10);
    try {
      context.fillStyle = "black";
      context.beginPath();
      context.fillRect(0, 0, UNIVERSE_WIDTH, UNIVERSE_HEIGHT);
      context.closePath();

      entities.forEach((entity) {
        Transform transform = transformMapper.get(entity);
        MiniMapRenderable renderable = renderableMapper.get(entity);
        CircularBody body = bodyMapper.get(entity);

        context.fillStyle = renderable.color;
        context.strokeStyle = renderable.color;
        context.beginPath();
        context.fillRect(transform.x - body.radius, transform.y - body.radius, body.radius*2, body.radius*2);
        context.closePath();
      });
    } finally {
      context.restore();
    }
  }

  bool checkProcessing() => true;
}

abstract class CameraPosMixin {
  CameraPosition _cameraPos;
  CameraPosition getCameraPos(World world) {
    if (null == _cameraPos) {
      ComponentMapper<CameraPosition> cameraPositionMapper = new ComponentMapper<CameraPosition>(CameraPosition, world);
      TagManager tagManager = world.getManager(new TagManager().runtimeType);

      Entity camera = tagManager.getEntity(TAG_CAMERA);
      _cameraPos = cameraPositionMapper.get(camera);
    }
    return _cameraPos;
  }
}

class ImageCache {
  static final Map<String, ImageElement> loadedImages = new Map<String, ImageElement>();

  static void withImage(String imageName, void action(ImageElement image)) {
    ImageElement image = loadedImages[imageName];
    if (null == image) {
      image = new ImageElement();
      image.onLoad.listen((event) {
        loadedImages[imageName] = image;
        action(image);
      });
      image.src = "resources/img/${imageName}";
    } else {
      action(image);
    }
  }

}