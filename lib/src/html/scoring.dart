part of html;

//class HighscoreSavingSystem extends VoidEntitySystem {
//  GameState gameState;
//  Status playerStatus;
//  Store<String> store;
//  HighscoreSavingSystem(this.gameState);
//
//  void initialize() {
//    TagManager tm = world.getManager(TagManager);
//    var player = tm.getEntity(TAG_PLAYER);
//    playerStatus = player.getComponentByClass(Status);
//  }
//
//  void processSystem() {
//    var score = new Highscore(gameState.currentLevel, gameState.score.toInt());
//    store = new Store<String>('space-off', 'highscore');
//    store.open().then((_) => store.save(JSON.encode(score), score.dateTime.toString()));
//    gameState.highScoreSaved = true;
//  }
//  bool checkProcessing() => playerStatus.destroyed && !gameState.highScoreSaved;
//}

class Highscore {
  final DateTime dateTime;
  final int score, level;
  Highscore(this.level, this.score) : dateTime = new DateTime.now();
  dynamic toJson() => {'score': score, 'level': level, 'ms': dateTime.millisecondsSinceEpoch, 'utc': dateTime.isUtc};
}
