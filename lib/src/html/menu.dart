part of html;

class MenuItem {
  const MENU_ITEM_X = MAX_WIDTH - 350;
  const MENU_ITEM_Y = 50;
  const MENU_ITEM_WIDTH = 300;
  const MENU_ITEM_HEIGHT = 50;
  const MENU_ITEM_DELTA_Y = 70;
  static int _idx = 0;
  String label, content;
  Rect rect;
  bool hover = false;
  MenuItem(this.label, {this.content}) {
    rect = new Rect(MENU_ITEM_X, MENU_ITEM_Y + _idx * MENU_ITEM_DELTA_Y, MENU_ITEM_WIDTH, MENU_ITEM_HEIGHT);
    _idx++;
  }
}

class MenuSystem extends VoidEntitySystem with CameraPosMixin {

  CanvasElement canvas;
  CanvasRenderingContext2D context;
  CqWrapper overlay;
  List<MenuItem> menu = [new MenuItem('START GAME'), new MenuItem('INSTRUCTIONS'), new MenuItem('CREDITS')];

  MenuSystem(this.canvas) {
    context = canvas.context2D;
  }

  initialize() {
    overlay = cq(MAX_WIDTH, MAX_HEIGHT)
                ..textBaseline = 'top'
                ..font = '20px D3Radicalism'
                ..globalAlpha = 0.5;
    canvas.onMouseMove.listen((event) {
      var pos = CqTools.mousePosition(event);
      menu.forEach((MenuItem item) {
        if (item.rect.containsPoint(pos)) {
          item.hover = true;
        } else {
          item.hover = false;
        }
      });
    });
    canvas.onMouseDown.listen((event) {
      var pos = CqTools.mousePosition(event);
      if (menu[0].rect.containsPoint(pos)) {
        if (!gameState.started) gameState.started = true;
        if (!gameState.paused) gameState.paused = false;
      }
    });
  }

  void processSystem() {
    context.save();
    try {
      overlay..clear()
        ..fillStyle = 'gray'
        ..fillRect(0, 0, MAX_WIDTH, MAX_HEIGHT)
        ..roundRect(10, 10, MAX_WIDTH - 20, MAX_HEIGHT - 20, 50, strokeStyle: 'blue', fillStyle: 'red');

      menu.forEach((MenuItem item) {
        var fillStyle = item.hover ? 'gold' : 'white';
        var bounds = overlay.textBoundaries(item.label);
        overlay..roundRect(item.rect.left, item.rect.top, item.rect.width, item.rect.height, 20, strokeStyle: 'green', fillStyle: fillStyle)
               ..gradientText(item.label, item.rect.left + (item.rect.width - bounds.width) ~/ 2,
                                      item.rect.top + (item.rect.height - bounds.height) ~/ 2,
                                      [0, 'black', 1, 'blue']);
      });

      context.translate(getCameraPos(world).x, getCameraPos(world).y);
      context.drawImage(overlay.canvas, 0, 0);
    } finally {
      context.restore();
    }
  }

  bool checkProcessing() => !gameState.running;
}