library multiverse;

import 'dart:html' hide Entity;

import 'package:dartemis/dartemis.dart';

const int MAXWIDTH = 600;
const int MAXHEIGHT = 600;
const int HUDHEIGHT = 100;


void main() {
  CanvasElement canvas = query('#gamecontainer');
  canvas.parent.rect.then((ElementRect rect) {
    canvas.width = MAXWIDTH;
    canvas.height = MAXHEIGHT + HUDHEIGHT;

    Game game = new Game(canvas);
    game.start();
  });
}

class Game {
  CanvasElement canvas;
  CanvasRenderingContext2D context2d;
  num lastTime = 0;
  World world;

  Game(this.canvas) {
    context2d = canvas.context2d;
  }

  void start() {
    world = new World();


    world.initialize();

    gameLoop(0);
  }

  void gameLoop(num time) {
    world.delta = time - lastTime;
    lastTime = time;
    world.process();

    requestRedraw();
  }

  void requestRedraw() {
    window.requestAnimationFrame(gameLoop);
  }
}
