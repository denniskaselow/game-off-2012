part of html;

class SoundSystem extends EntityProcessingSystem {

  AudioManager audioManager;

  ComponentMapper<Sound> soundMapper;

  SoundSystem(this.audioManager) : super(Aspect.getAspectForAllOf([Sound]));

  void initialize() {
    soundMapper = new ComponentMapper<Sound>(Sound, world);
  }

  void processEntity(Entity entity) {
    Sound sound = soundMapper.get(entity);
    audioManager.playClipFromSource(sound.source, sound.clip);
    entity.removeComponent(Sound);
    entity.changedInWorld();
  }
}

AudioManager createAudioManager(String location) {
  AudioManager audioManager;
  var url = 'resources/sfx/';
  int slashIndex = location.lastIndexOf('/');
  if (slashIndex < 0) {
    url = '/$url';
  } else {
    url = '${location.substring(0, slashIndex)}/$url';
  }
  try {
    audioManager = new AudioElementManager(url);
    AudioSource source = audioManager.makeSource('non-positional');
    source.positional = false;
  } catch (e) {
    audioManager = new AudioElementManager(url);
  }

  audioManager.makeClip('shoot', 'shoot.ogg').load();

  return audioManager;
}

class AudioElementManager implements AudioManager {
  String baseURL;
  AudioElementManager([this.baseURL = '/']);

  Map<String, AudiElementClip> _clips = new Map<String, AudiElementClip>();

  AudioClip makeClip(String name, String url) {
    AudioClip clip = _clips[name];
    if (clip != null) {
      return clip;
    }
    clip = new AudiElementClip._internal(this, name, "$baseURL$url");
    _clips[name] = clip;
    return clip;
  }

  AudioSound playClipFromSource(String sourceName, String clipName, [bool looped=false]) {
    _clips[clipName].play();
    return null;
  }

  dynamic noSuchMethod(Invocation im) {}
}

class AudiElementClip implements AudioClip {
  final AudioManager _manager;
  String _name;
  String _url;
  List<AudioElement> audioElements = new List();
  AudiElementClip._internal(this._manager, this._name, this._url);

  Future<AudioClip> load() {
    var audioElement = new AudioElement();
    var completer = new Completer<AudioClip>();
    audioElement.onLoad.listen((data) => completer.complete(this));
    audioElement.src = _url;
    audioElements.add(audioElement);
    return completer.future;
  }

  void play() {
    var playable = audioElements.where((element) => element.ended).iterator;
    var audioElement;
    if (playable.moveNext()) {
      audioElement = playable.current;
    } else {
      audioElement = audioElements[0].clone(false);
      audioElements.add(audioElement);
    }
    audioElement.play();
  }

  dynamic noSuchMethod(Invocation im) {}
}