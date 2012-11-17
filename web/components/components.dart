part of multiverse;

class Transform extends Component {
  Transform.hack();
  num _x, _y, angle, rotationRate;
  Transform(this._x, this._y, {this.angle : 0, this.rotationRate : 0});
  num get x => _x;
  num get y => _y;
  set x(num x) => _x = x % UNIVERSE_WIDTH;
  set y(num y) => _y = y % UNIVERSE_HEIGHT;
}

class CameraPosition extends Transform {
  CameraPosition.hack() : super.hack();
  CameraPosition({num x: 0, num y: 0}) : super(x, y);
}

class Velocity extends Component {
  Velocity.hack();
  num x, y;
  Velocity(this.x, this.y);
}

class Spatial extends Component {
  Spatial.hack();

  String resource;
  bool isSprite;
  num width, height, x, y;
  num scale;
  Spatial(this.resource, {this.scale : 1}) {
    isSprite = false;
  }
  Spatial.asSprite(this.resource, this.x, this.y, this.width, this.height, {this.scale : 1}) {
    isSprite = true;
  }
}

class Background extends Component {
  Background.hack();
  Background();
}

class Status extends Component {
  num health;
  num maxVelocity;

  Status.hack();
  Status({this.health : 100, this.maxVelocity : 20});
}

class CircularBody extends Component {
  num radius;

  CircularBody.hack();
  CircularBody(this.radius);
}

class Mass extends Component {
  num mass;

  Mass.hack();
  Mass(this.mass);
}