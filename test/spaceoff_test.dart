import "package:unittest/mock.dart";
import "package:unittest/unittest.dart";
import "package:spaceoff/spaceoff.dart";

main() {
  group('Collision Tests', () {
    CircularCollisionDetectionSystem system;

    EntityMock entityA;
    Transform transformA;
    EntityMock entityB;
    Transform transformB;
    ComponentMapperMock transformMapper;
    ComponentMapper<CircularBody> bodyMapper;

    setUp(() {
      World world = new WorldMock();
      entityA = new EntityMock();
      entityB = new EntityMock();
      transformMapper = new ComponentMapperMock();
      transformMapper.when(callsTo('get', entityA)).alwaysReturn(transformA);
      transformMapper.when(callsTo('get', entityB)).alwaysReturn(transformB);
      bodyMapper = new ComponentMapperMock();

      system = new CircularCollisionDetectionSystem();
      system.world = world;
      system.transformMapper = transformMapper;
      system.bodyMapper = bodyMapper;
    });
    test('perfect collision in 1D space on x-axis', () {

      Bag<Entity> entities = new Bag<Entity>();
      entities.add(entityA);
      entities.add(entityB);

      // wait for https://code.google.com/p/dart/issues/detail?id=7039
//      system.processEntitiesOnScreen(entities);
    });
  });
}


class WorldMock extends Mock implements World {}
class EntityMock extends Mock implements Entity {}
class ComponentMapperMock extends Mock implements ComponentMapper {}