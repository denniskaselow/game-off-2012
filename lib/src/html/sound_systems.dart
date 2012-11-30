part of html;

class SoundSystem extends EntityProcessingSystem {

  AudioManager audioManager;

  ComponentMapper<Sound> soundMapper;

  SoundSystem(this.audioManager) : super(Aspect.getAspectForAllOf(new Sound.hack().runtimeType));

  void initialize() {
    soundMapper = new ComponentMapper<Sound>(new Sound.hack().runtimeType, world);
  }

  void processEntity(Entity entity) {
    Sound sound = soundMapper.get(entity);
    audioManager.playClipFromSource(sound.source, sound.clip);
    entity.removeComponent(sound);
    entity.changedInWorld();
  }
}
