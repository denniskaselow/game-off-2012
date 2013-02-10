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
    entity.removeComponent(sound);
    entity.changedInWorld();
  }
}
