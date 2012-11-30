import 'dart:html' hide Entity;

import 'package:spaceoff/html.dart';

void main() {
  initTabbedContent();
  loadImages();

  CanvasElement gameContainer = query('#gamecontainer');
  CanvasElement hudContainer = query('#hudcontainer');
  window.requestLayoutFrame(() {
    gameContainer.width = MAX_WIDTH;
    gameContainer.height = MAX_HEIGHT;
    hudContainer.width = MAX_WIDTH;
    hudContainer.height = HUD_HEIGHT;

    Game game = new Game(gameContainer, hudContainer);
    game.start();
  });
}

void loadImages() {
   // TODO use http://www.codeandweb.com/texturepacker
  List<String> images = ['spaceship.png', 'spaceship_thrusters.png', 'hud_dummy.png', 'bullet_dummy', 'star_00.png', 'star_01.png', 'star_02.png', 'star_03.png', 'star_04.png', 'star_05.png', 'upgrade_health.png'];
  images.forEach((image) => ImageCache.withImage(image, (element) {}));
}

void initTabbedContent() {
  Map<String, String> tabs = {"tabStory": "story", "tabControls": "controls", "tabCredits": "credits", "tabDebug": "debug"};
  String selectedTab = "tabStory";
  tabs.forEach((key, value) {
    Element tab = query("#$key");
    Element tabContent = query("#$value");

    tab.on.click.add((listener) {
      if (key != selectedTab) {
        tab.classes.add("selectedTab");
        tabContent.classes.remove("hidden");
        query("#$selectedTab").classes.remove("selectedTab");
        query("#${tabs[selectedTab]}").classes.add("hidden");
        selectedTab = key;
      }
    });
  });
}