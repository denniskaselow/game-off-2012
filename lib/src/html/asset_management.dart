part of html;

class Atlas {
  ImageElement image;
  Map<String, Sprite> sprites;
  Atlas(this.image, this.sprites);
}

class Sprite {
  Rectangle src;
  Rectangle dst;
  int x, y, w, h, cx, cy;
  Sprite(Map<String, dynamic> singleAsset) {
    _Asset asset = new _Asset(singleAsset);
    var frame = asset.frame;
    var cx, cy;
    if (asset.trimmed) {
      cx = -(asset.sourceSize.w ~/ 2 - asset.spriteSourceSize.x);
      cy = -(asset.sourceSize.h ~/ 2 - asset.spriteSourceSize.y);
    } else {
      cx = -asset.frame.w ~/ 2;
      cy = -asset.frame.h ~/ 2;
    }

    src = new Rectangle(frame.x, frame.y, frame.w, frame.h);
    dst = new Rectangle(cx, cy, frame.w, frame.h);
  }
}

class _Asset {
  _Rect frame;
  bool trimmed;
  _Rect spriteSourceSize;
  _Size sourceSize;
  _Asset(Map<String, dynamic> asset) : frame = new _Rect(asset["frame"]),
                                      trimmed = asset["trimmed"],
                                      spriteSourceSize = new _Rect(asset["spriteSourceSize"]),
                                      sourceSize = new _Size(asset["sourceSize"]);
}

class _Rect {
  int x, y, w, h;
  _Rect(Map<String, int> rect) : x = rect["x"].toInt(),
                                y = rect["y"].toInt(),
                                w = rect["w"].toInt(),
                                h = rect["h"].toInt();
}

class _Size {
  int w, h;
  _Size(Map<String, int> rect) : w = rect["w"].toInt(),
                                h = rect["h"].toInt();
}