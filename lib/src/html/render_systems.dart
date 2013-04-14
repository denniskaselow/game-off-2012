part of html;

class SpatialRenderingSystem extends OnScreenEntityProcessingSystem {

  CanvasRenderingContext2D context2d;
  Atlas atlas;
  ComponentMapper<Spatial> spatialMapper;
  ComponentMapper<ExpirationTimer> timerMapper;
  CameraPosition cameraPos;

  SpatialRenderingSystem(this.context2d, this.atlas) : super(Aspect.getAspectForAllOf([Spatial, Transform]));

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
      num scale = spatial.scale;
      if (spatial.isAnimated) {
        int index = (transform.angle.round() % spatial.resources.length).toInt();
        Sprite sprite = atlas.sprites[spatial.resources[index]];
        drawSprite(sprite, scale);
      } else {
        context2d.rotate(transform.angle);
        spatial.resources.forEach((resource) {
          Sprite sprite = atlas.sprites[resource];
          drawSprite(sprite, scale);
        });
      }

      context2d.closePath();
      context2d.fill();

      context2d.stroke();
    } finally {
      context2d.restore();
    }
  }

  void drawSprite(Sprite sprite, num scale) {
    // TODO scale when createing spatial
    Rect dest = new Rect(sprite.dst.left * scale, sprite.dst.top * scale, sprite.dst.width * scale, sprite.dst.height * scale);
    context2d.drawImageToRect(atlas.image, dest, sourceRect : sprite.src);
  }
}

class NormalSpaceBackgroundRenderSystem extends PlayerStatusProcessingSystem {
  CanvasRenderingContext2D context2d;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  HyperDrive hyperDrive;

  NormalSpaceBackgroundRenderSystem(this.context2d);

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
    context2d.setTransform(1, 0, 0, 1, 0, 0);
    context2d.translate(-cameraPos.x, -cameraPos.y);
    context2d..fillStyle = "black"
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

  HyperSpaceBackgroundRenderSystem(context2d) : super(context2d);

  void initialize() {
    super.initialize();
    var hdMapper = new ComponentMapper<HyperDrive>(HyperDrive, world);
    hyperDrive = hdMapper.get(player);
  }

  void processSystem() {
    var camera = tagManager.getEntity(TAG_CAMERA);
    var cameraPos = cameraPositionMapper.get(camera);

    var mod = hyperDrive.hyperSpaceMod;
    context2d.setTransform(1/(1+mod/50), 0, 0, 1+mod, MAX_WIDTH / 2 - (MAX_WIDTH / (2 *(1+mod/50))), 0);
    context2d.translate(-cameraPos.x, -cameraPos.y - (20 * mod));

    context2d.globalAlpha = max(0.05, 1 - (mod));
    context2d..fillStyle = "black"
        ..beginPath()
        ..rect(cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT)
        ..fill()
        ..stroke()
        ..closePath();
    context2d.globalAlpha = 1;
  }

  bool checkProcessing() => hyperDrive.active && !status.destroyed;
}

class BackgroundStarsRenderingSystem extends VoidEntitySystem {
  const int OVERLAP_WIDTH = 50;
  const int OVERLAP_HEIGHT = 50;

  CanvasElement bgCanvas;
  Atlas atlas;
  CanvasRenderingContext2D context2d;
  ComponentMapper<CameraPosition> cameraPositionMapper;
  TagManager tagManager;

  BackgroundStarsRenderingSystem(this.context2d, this.atlas);

  void initialize() {
    cameraPositionMapper = new ComponentMapper<CameraPosition>(CameraPosition, world);
    tagManager = world.getManager(new TagManager().runtimeType);
    initBackground();
  }

  void initBackground() {
    GroupManager groupManager = world.getManager(new GroupManager().runtimeType);
    ComponentMapper<Transform> transformMapper = new ComponentMapper<Transform>(Transform, world);
    bgCanvas = new CanvasElement(width: UNIVERSE_WIDTH + OVERLAP_WIDTH * 2, height: UNIVERSE_HEIGHT + OVERLAP_HEIGHT * 2);
    var bgContext = bgCanvas.context2d;

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

    context2d.save();
    try {
      context2d.beginPath();
      num srcX = cameraPos.x + OVERLAP_WIDTH;
      num srcY = cameraPos.y + OVERLAP_HEIGHT;
      if (cameraPos.x < UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y < UNIVERSE_HEIGHT - MAX_HEIGHT) {
        context2d.drawImageScaledFromSource(bgCanvas, srcX, srcY, MAX_WIDTH, MAX_HEIGHT, cameraPos.x, cameraPos.y, MAX_WIDTH, MAX_HEIGHT);
      } else if (cameraPos.x > UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y < UNIVERSE_HEIGHT - MAX_HEIGHT) {
        num overlapWidthLeft = UNIVERSE_WIDTH - cameraPos.x + OVERLAP_WIDTH;
        num overlapWidthRight = MAX_WIDTH - (UNIVERSE_WIDTH - cameraPos.x) + OVERLAP_WIDTH;
        num overlapDestX = UNIVERSE_WIDTH - OVERLAP_WIDTH;
        context2d.drawImageScaledFromSource(bgCanvas, srcX, srcY, overlapWidthLeft, MAX_HEIGHT, cameraPos.x, cameraPos.y, overlapWidthLeft, MAX_HEIGHT);
        context2d.drawImageScaledFromSource(bgCanvas, 0, srcY, overlapWidthRight, MAX_HEIGHT, overlapDestX, cameraPos.y, overlapWidthRight, MAX_HEIGHT);
      } else if (cameraPos.x < UNIVERSE_WIDTH - MAX_WIDTH && cameraPos.y > UNIVERSE_HEIGHT - MAX_HEIGHT) {
        num overlapHeightTop = UNIVERSE_HEIGHT - cameraPos.y + OVERLAP_HEIGHT;
        num overlapHeightBottom = MAX_HEIGHT - (UNIVERSE_HEIGHT - cameraPos.y) + OVERLAP_HEIGHT;
        num overlapDestY = UNIVERSE_HEIGHT - OVERLAP_HEIGHT;
        context2d.drawImageScaledFromSource(bgCanvas, srcX, srcY, MAX_WIDTH, overlapHeightTop, cameraPos.x, cameraPos.y, MAX_WIDTH, overlapHeightTop);
        context2d.drawImageScaledFromSource(bgCanvas, srcX, 0, MAX_WIDTH, overlapHeightBottom, cameraPos.x, overlapDestY, MAX_WIDTH, overlapHeightBottom);
      } else {
        num overlapWidthLeft = UNIVERSE_WIDTH - cameraPos.x + OVERLAP_WIDTH;
        num overlapWidthRight = MAX_WIDTH - (UNIVERSE_WIDTH - cameraPos.x) + OVERLAP_WIDTH;
        num overlapHeightTop = UNIVERSE_HEIGHT - cameraPos.y + OVERLAP_HEIGHT;
        num overlapHeightBottom = MAX_HEIGHT - (UNIVERSE_HEIGHT - cameraPos.y) + OVERLAP_HEIGHT;
        num overlapDestX = UNIVERSE_WIDTH - OVERLAP_WIDTH;
        num overlapDestY = UNIVERSE_HEIGHT - OVERLAP_HEIGHT;
        context2d.drawImageScaledFromSource(bgCanvas, srcX, srcY, overlapWidthLeft, overlapHeightTop, cameraPos.x, cameraPos.y, overlapWidthLeft, overlapHeightTop);
        context2d.drawImageScaledFromSource(bgCanvas, 0, srcY, overlapWidthRight, overlapHeightTop, overlapDestX, cameraPos.y, overlapWidthRight, overlapHeightTop);
        context2d.drawImageScaledFromSource(bgCanvas, srcX, 0, overlapWidthLeft, overlapHeightBottom, cameraPos.x, overlapDestY, overlapWidthLeft, overlapHeightBottom);
        context2d.drawImageScaledFromSource(bgCanvas, 0, 0, overlapWidthRight, overlapHeightBottom, overlapDestX, overlapDestY, overlapWidthRight, overlapHeightBottom);
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

  ParticleRenderSystem(this.context2d) : super(Aspect.getAspectForAllOf([Particle, Transform]));

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
  const LABEL_SCORE = "Score:";
  const LABEL_LEVEL = "Level:";
  CanvasRenderingContext2D context2d;
  num scoreX, levelX;

  HudRenderSystem(this.context2d);

  void initialize() {
    super.initialize();
    var bounds = context2d.measureText(LABEL_SCORE);
    scoreX = 550 - bounds.width;
    bounds = context2d.measureText(LABEL_LEVEL);
    levelX = 550 - bounds.width;
  }

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

    ImageCache.withImage("hud_dummy.png", (image) => context2d.drawImage(image, 0, 0));
    String score = "${gameState.score.toStringAsFixed(0)}";
    String level = "${(gameState.currentLevel+1).toString()}";
    context2d.fillText(LABEL_LEVEL, levelX, 11);
    context2d.fillText(LABEL_SCORE, scoreX, 31);
    var bounds = context2d.measureText(level);
    context2d.fillText(level, 680 - bounds.width, 11);
    bounds = context2d.measureText(score);
    context2d.fillText(score, 680 - bounds.width, 31);
  }
}

class MiniMapRenderSystem extends EntitySystem {
  CanvasRenderingContext2D context2d;

  ComponentMapper<Transform> transformMapper;
  ComponentMapper<MiniMapRenderable> renderableMapper;
  ComponentMapper<CircularBody> bodyMapper;

  MiniMapRenderSystem(this.context2d) : super(Aspect.getAspectForAllOf([MiniMapRenderable, Transform, CircularBody]));

  void initialize() {
    transformMapper = new ComponentMapper<Transform>(Transform, world);
    renderableMapper = new ComponentMapper<MiniMapRenderable>(MiniMapRenderable, world);
    bodyMapper = new ComponentMapper<CircularBody>(CircularBody, world);
  }

  void processEntities(ReadOnlyBag<Entity> entities) {
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
        context2d.fillRect(transform.x - body.radius, transform.y - body.radius, body.radius*2, body.radius*2);
        context2d.closePath();
      });
    } finally {
      context2d.restore();
    }
  }

  bool checkProcessing() => true;
}

class MenuRenderingSystem extends VoidEntitySystem with CameraPosMixin {
  CanvasRenderingContext2D context;
  CqWrapper menu;
  ComponentMapper<MenuItem> miMapper;
  GroupManager groupManager;

  MenuRenderingSystem(this.context);

  void initialize() {
    groupManager = world.getManager(new GroupManager().runtimeType);
    miMapper = new ComponentMapper<MenuItem>(MenuItem, world);
    menu = cq(MAX_WIDTH, MAX_HEIGHT)
             ..textBaseline = 'top'
             ..font = '20px D3Radicalism'
             ..globalAlpha = 0.5;
  }

  void processSystem() {
    context.save();
    try {
      menu..clear()
        ..fillStyle = 'gray'
        ..fillRect(0, 0, MAX_WIDTH, MAX_HEIGHT)
        ..roundRect(10, 10, MAX_WIDTH - 20, MAX_HEIGHT - 20, 50, strokeStyle: 'blue', fillStyle: 'red');

      groupManager.getEntities(GROUP_MENU).forEach((entity) {
        var item = miMapper.get(entity);
        var bounds = menu.textBoundaries(item.text);
        var fillStyle = item.hover ? 'gold' : 'white';
        menu..roundRect(item.x, item.y, item.width, item.height, 20, strokeStyle: 'green', fillStyle: fillStyle)
            ..gradientText(item.text, item.x + (item.width - bounds.width) ~/ 2,
                                      item.y + (item.height - bounds.height) ~/ 2,
                                      [0, 'black', 1, 'blue']);
      });

      context.translate(getCameraPos(world).x, getCameraPos(world).y);
      context.drawImage(menu.canvas, 0, 0);
    } finally {
      context.restore();
    }
  }

  bool checkProcessing() => !gameState.running;
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