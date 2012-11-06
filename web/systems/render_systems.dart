part of multiverse;

class PositionalRenderingSystem extends EntityProcessingSystem {

  CanvasRenderingContext2D context2d;

  ComponentMapper<Position> positionMapper;

  PositionalRenderingSystem(this.context2d) : super(Aspect.getAspectForAllOf(new Position.hack().runtimeType));

  void initialize() {
    positionMapper = new ComponentMapper<Position>(new Position.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    Position pos = positionMapper.get(entity);

    context2d.save();

    try {
      context2d.lineWidth = 0.5;
      context2d.fillStyle = "white";
      context2d.strokeStyle = "white";

      drawCirle(pos);

      context2d.stroke();
    } finally {
      context2d.restore();
    }
  }

  void drawCirle(Position pos) {
    context2d.beginPath();

    context2d.arc(pos.x, pos.y, 25, 0, FastMath.TWO_PI, false);

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