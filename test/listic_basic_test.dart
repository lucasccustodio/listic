import 'package:flutter/material.dart';
import 'package:listic/ecs/components.dart';
import 'package:entitas_ff/entitas_ff.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

//An UniqueComponent can only be held by a single entity at a time
class TestComponent extends ComponentData<int> with UniqueMixin {
  TestComponent([int counter = 0]) : super(counter);
}

class NavigatorData extends Equatable {
  final String routeName;
  final int routeOp;

  NavigatorData({this.routeName, this.routeOp}) : super([routeName, routeOp]);
}

class NavigationComponent extends ComponentData<NavigatorData> with ComponentMixin {
  NavigationComponent({NavigatorData value}) : super(value);
}

class CounterComponent extends ComponentData<int> {
  const CounterComponent(int value) : super(value);
}

class ModifiableTag extends TagComponent {}

void main() async {
  testWidgets('Should update counter when fab is tapped', (widgetTester) async {
    //Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));
    //Instantiate TestComponent and set counter to 0

    await widgetTester.pumpWidget(
        //InheritedWidget that will provide our EntityManager to the subtree
        EntityManagerProvider(
      entityManager: testEntityManager,
      child: TestApp(),
    ));

    //By default counter should be at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    //Tap to increase counter
    await widgetTester.tap(find.text('Increase counter'));

    //Trigger a frame
    await widgetTester.pump();

    //Now counter should be at 1
    expect(find.text('Counter: 1'), findsOneWidget);
  });

  test('Modified component class', () {
    final counter = CounterComponent(0);
    final counter2 = CounterComponent(2);

    expect(counter != counter2, true);
  });

  test('Classify by tag', () {
    final mainTag = Tag('main');
    final subTag = Tag('sub');

    final entityManager = EntityManager();
    final mainFolder = entityManager.createEntity()
      ..set(mainTag)
      ..set(Owns([subTag]));

    final mainTaskMatcher = EntityMatcher.strict(
        all: [Tag, Toggle], values: {Tag: EqualComponents(mainTag)});
    final subTaskMatcher = EntityMatcher.strict(
        all: [Tag, Toggle], values: {Tag: EqualComponents(subTag)});
    final mainMatcher = EntityMatcher.strict(all: [
      Tag,
      Owns
    ], values: {
      Tag: EqualComponents(mainTag),
      Owns: EqualComponents(Owns([subTag]))
    });
    final subMatcher = EntityMatcher.strict(
        all: [Tag, Owns], values: {Tag: EqualComponents(subTag)});

    final mainGroup = entityManager.groupMatching(mainMatcher);
    final mainTasks = entityManager.groupMatching(mainTaskMatcher);
    final subTasks = entityManager.groupMatching(subTaskMatcher);
    final subGroup = entityManager.groupMatching(subMatcher);

    for (var i = 0; i < 3; i++)
      entityManager.createEntity()..set(subTag)..set(Owns(null));

    for (var i = 0; i < 5; i++)
      entityManager.createEntity()..set(mainTag)..set(Toggle(false));

    for (var i = 0; i < 20; i++)
      entityManager.createEntity()..set(subTag)..set(Toggle(false));

    expect(mainGroup.entities.length, 1);
    expect(subGroup.entities.length, 3);
    expect(mainTasks.entities.length, 5);
    expect(subTasks.entities.length, 20);

    print(subGroup.entities);
  });
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Testing'),
        ),
        body: Center(
          //An reactive widget that will rebuild when the provided Entity's components are modified
          child: EntityObservingWidget(
            //getUniqueEntity will retrieve the entity which is currently holding the corresponding UniqueComponent, not that component itself as EntityObservingWidget is expecting an Entity, if the UniqueComponent isn't currently set it will return null.
            provider: (entityManager) =>
                entityManager.getUniqueEntity<TestComponent>(),
            //The builder function must always return a Widget
            builder: (entity, context) =>
                Text('Counter: ${entity.get<TestComponent>().value}'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Text('Increase counter'),
          onPressed: () {
            //Retrieve the underlying EntityManager
            final entityManager =
                EntityManagerProvider.of(context).entityManager;
            //Retrieve the UniqueComponent, not it's owner Entity, and the current counter value
            final counter = entityManager.getUnique<TestComponent>().value;
            //Update the UniqueComponent  by creating a new instance with counter incremented, which will rebuild all EntityObservingWidgets currently observing for changes on this UniqueComponent
            entityManager.setUnique(TestComponent(counter + 1));
          },
        ),
      ),
    );
  }
}
