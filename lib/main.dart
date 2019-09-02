import 'package:kt_dart/kt.dart';
import 'package:listic/ecs/components.dart';
import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  final entityManager = EntityManager();

  final mainTag = Tag('All tasks');

  entityManager.setUnique(Root())..set(mainTag)..set(Owns([]));

  entityManager.setUnique(SelectedFolder(null));

  /* entityManager.createEntity()
    ..set(Tag('Smart lists'))
    ..set(Owns([
      Tag('Completed Work'),
      Tag('Todo Study'),
      Tag('Today'),
      Tag('Tomorrow')
    ]));

  entityManager.createEntity()..set(Tag('Work'))..set(Owns([]));
  entityManager.createEntity()..set(Tag('Study'))..set(Owns([]));
  entityManager.createEntity()..set(Tag('Fun'))..set(Owns([]));

  entityManager.createEntity()
    ..set(Tag('Completed Work'))
    ..set(Owns([]))
    ..set(MustHave({Toggle: Toggle(true), Tag: Tag('Work')}));
  entityManager.createEntity()
    ..set(Tag('Todo Study'))
    ..set(Owns([]))
    ..set(MustHave({Toggle: Toggle(false), Tag: Tag('Study')}));
  entityManager.createEntity()..set(Tag('Today'))..set(Owns([]));
  entityManager.createEntity()
    ..set(Tag('Tomorrow'))
    ..set(Owns([Tag('Raining')]));

  entityManager.createEntity()..set(Tag('Raining'))..set(Owns([Tag('Acid')]));

  entityManager.createEntity()..set(Tag('Acid'))..set(Owns([]));

  entityManager.createEntity()
    ..set(Tag('Acid'))
    ..set(Toggle(false))
    ..set(Contents(value: 'Buy a iron umbrella'));

  for (final task in [
    'Setup project',
    'Manage dependencies',
    'Assign teams',
    'Test',
    'Ship'
  ])
    entityManager.createEntity()
      ..set(Tag('Work'))
      ..set(Toggle(false))
      ..set(Contents(value: task));

  for (final task in [
    'Find books',
    'Make notes',
    'Rehearsal',
  ])
    entityManager.createEntity()
      ..set(Tag('Study'))
      ..set(Toggle(false))
      ..set(Contents(value: task));

  for (final task in [
    'Grab a movie',
    'Make popcorn',
    'Chill',
  ])
    entityManager.createEntity()
      ..set(Tag('Fun'))
      ..set(Toggle(false))
      ..set(Contents(value: task)); */

  runApp(EntityManagerProvider(
    entityManager: entityManager,
    child: MaterialApp(
      title: 'Listic',
      home: MainApp(),
      theme: ThemeData(platform: TargetPlatform.fuchsia, fontFamily: 'Roboto'),
    ),
    system: RootSystem(entityManager: entityManager, systems: []),
  ));
}

class SmartList = TagComponent with ComponentMixin;

class SkipMatch = TagComponent with ComponentMixin;

class Root = TagComponent with UniqueMixin;

class SelectedFolder = ComponentData<Entity> with UniqueMixin;

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;

    return Scaffold(
      appBar: AppBar(
        title: Text('Listic'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: EntityObservingWidget(
                  provider: (em) => em.getUniqueEntity<Root>(),
                  builder: (root, context) {
                    final folders = entityManager.groupMatching(
                        EntityMatcher.strict(all: [
                      Tag,
                      Owns
                    ], none: [
                      Root
                    ], values: {
                      Tag: ComponentInList(root.get<Owns>()?.value?.value ?? [])
                    }));

                    root.set(SearchResult());

                    return SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          ListTile(title: Text('Lists')),
                          FlatButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add folder'),
                            onPressed: () async {
                              final folderName = await showDialog(
                                  context: context,
                                  builder: (_) => CreateFolderDialog(
                                      folder: root.get<Tag>().value));

                              if (folderName != null) {
                                entityManager.createEntity()
                                  ..set(Tag(folderName))
                                  ..set(Owns([]));

                                root.update<Owns>((old) => Owns(
                                    [...old.value.value, Tag(folderName)]));
                              }
                            },
                          ),
                          FlatButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add smart list'),
                            onPressed: () async {
                              final props = await showDialog(
                                  context: context,
                                  builder: (_) => CreateSmartListDialog(
                                      folder: root.get<Tag>().value));

                              final listName = props['listName'];

                              if (listName != null) {
                                final e = entityManager.createEntity()
                                  ..set(Tag(listName))
                                  ..set(SmartList());

                                final folder = entityManager
                                    .groupMatching(EntityMatcher.strict(all: [
                                      Tag,
                                      Owns
                                    ], values: {
                                      Tag: EqualComponents(Tag(props['tag']))
                                    }))
                                    .entities
                                    .first;

                                e.set(Owns([
                                  if (props['includeSub'] == true)
                                    ...folder.get<Owns>().value.value,
                                  folder.get<Tag>()
                                ]));

                                e.set(Toggle(props['toggle']));

                                root.update<Owns>((old) =>
                                    Owns([...old.value.value, Tag(listName)]));
                              }
                            },
                          ),
                          for (final folder in folders.entities)
                            FolderView(
                              folder: folder,
                              level: 1,
                            )
                        ],
                      ),
                      primary: true,
                    );
                  },
                ),
              ),
              Expanded(
                child: EntityObservingWidget(
                  provider: (em) => em.getUniqueEntity<SelectedFolder>(),
                  builder: (e, context) {
                    final selected = e.get<SelectedFolder>().value;

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          if (selected != null) ...[
                            ListTile(
                              title:
                                  Text('Tasks - ${selected.get<Tag>().value}'),
                            ),
                            TaskView(
                              folder: selected,
                            ),
                          ] else
                            ListTile(
                              title: Text('No list selected'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FolderView extends StatelessWidget {
  final ObservableEntity folder;
  final int level;

  const FolderView({Key key, this.folder, this.level = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;
    return EntityObservingWidget(
      provider: (_) => folder,
      builder: (_, __) => GroupObservingWidget(
        matcher: EntityMatcher.strict(all: [
          Tag,
          Owns
        ], none: [
          SmartList
        ], values: {
          Tag: ComponentInList(folder.get<Owns>()?.value?.value ?? []),
        }),
        builder: (group, context) {
          final folders = group.entities;

          return Padding(
            padding: EdgeInsets.only(left: level * 4.0),
            child: ListView(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: <Widget>[
                  InkWell(
                      onTap: () {
                        entityManager.setUnique(SelectedFolder(folder));
                      },
                      child: ListTile(
                        title: Text('${folder.get<Tag>().value}'),
                        subtitle: folder.hasT<SmartList>()
                            ? Text('Smart list')
                            : Text('Folder'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            final tasks = entityManager
                                .groupMatching(EntityMatcher.strict(all: [
                                  Tag,
                                  Contents,
                                  Toggle
                                ], values: {
                                  Tag: EqualComponents(folder.get<Tag>())
                                }))
                                .entities;

                            for (final task in tasks) task.destroy();

                            entityManager.getUniqueEntity<Root>().update<Owns>(
                                (old) =>
                                    old..value.value.remove(folder.get<Tag>()));

                            folder.destroy();
                          },
                        ),
                        leading: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            final folderName = await showDialog(
                                context: context,
                                builder: (_) => CreateFolderDialog(
                                      folder: '',
                                      folderName: folder.get<Tag>().value,
                                    ));

                            if (folderName != null) {
                              final group = entityManager
                                  .groupMatching(EntityMatcher.strict(all: [
                                    Tag,
                                    Contents,
                                    Toggle
                                  ], values: {
                                    Tag: EqualComponents(folder.get<Tag>())
                                  }))
                                  .entities;

                              for (final e in group) e.set(Tag(folderName));

                              final group2 = entityManager
                                  .groupMatching(
                                      EntityMatcher.strict(all: [Tag, Owns]))
                                  .entities;

                              for (final e in group2) {
                                final owns =
                                    KtList.from(e.get<Owns>().value.value);

                                if (owns.contains(folder.get<Tag>()))
                                  e.set(Owns(owns
                                      .minusElement(folder.get<Tag>())
                                      .plusElement(Tag(folderName))
                                      .asList()));
                              }

                              folder.set(Tag(folderName));
                            }
                          },
                        ),
                      )),
                  FlatButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add folder'),
                    onPressed: () async {
                      final folderName = await showDialog(
                          context: context,
                          builder: (_) => CreateFolderDialog(
                              folder: folder.get<Tag>().value));

                      if (folderName != null) {
                        entityManager.createEntity()
                          ..set(Tag(folderName))
                          ..set(Owns([]));

                        folder.update<Owns>((old) =>
                            Owns([...old.value.value, Tag(folderName)]));

                        final smartLists = entityManager
                            .groupMatching(EntityMatcher.strict(
                              all: [Tag, SmartList, Owns],
                            ))
                            .entities;

                        for (final list in smartLists) {
                          list.set(Owns([
                            ...folder.get<Owns>().value.value,
                            folder.get<Tag>()
                          ]));
                        }
                      }
                    },
                  ),
                  if (!folder.hasT<SmartList>())
                    for (final sub in folders)
                      FolderView(
                        folder: sub,
                        level: 1,
                      )
                ]),
          );
        },
      ),
    );
  }
}

class TaskView extends StatelessWidget {
  final ObservableEntity folder;

  const TaskView({Key key, this.folder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;
    Map<Type, ComponentMatcher> match = {};

    if (folder.hasT<SmartList>()) {
      match[Tag] = ComponentInList(folder.get<Owns>()?.value?.value ?? []);
      match[Toggle] = EqualComponents(folder.get<Toggle>());
    } else {
      match[Tag] = EqualComponents(folder.get<Tag>());
    }

    return GroupObservingWidget(
      matcher:
          EntityMatcher.strict(all: [Tag, Contents, Toggle], values: match),
      builder: (group, context) {
        final tasks = group.entities;

        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: <Widget>[
              if (!folder.hasT<SmartList>())
                FlatButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add task'),
                  onPressed: () async {
                    final taskName = await showDialog(
                        context: context,
                        builder: (_) =>
                            CreateTaskDialog(folder: folder.get<Tag>().value));

                    if (taskName != null) {
                      entityManager.createEntity()
                        ..set(folder.get<Tag>())
                        ..set(Contents(value: taskName))
                        ..set(Toggle());
                    }
                  },
                ),
              for (final task in tasks)
                ListTile(
                  title: Text("Task: ${task.get<Contents>().value}"),
                  leading: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      final taskName = await showDialog(
                          context: context,
                          builder: (_) => CreateTaskDialog(
                                taskName: task.get<Contents>().value,
                              ));

                      if (taskName != null) {
                        task.set(Contents(value: taskName));
                      }
                    },
                  ),
                  trailing: Checkbox(
                      value: task.get<Toggle>().value,
                      onChanged: (active) => task.set(Toggle(active))),
                )
            ],
          ),
        );
      },
    );
  }
}

class CreateFolderDialog extends StatefulWidget {
  final String folder, folderName;

  const CreateFolderDialog({Key key, this.folderName, this.folder})
      : super(key: key);

  @override
  _CreateFolderDialogState createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  TextEditingController folderController;

  @override
  void initState() {
    super.initState();
    folderController = TextEditingController(text: widget.folderName);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
          '${widget.folderName != null ? 'Editing' : 'New'} folder on ${widget.folder}'),
      children: <Widget>[
        Form(
          child: Column(
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                controller: folderController,
                validator: (value) => value.isEmpty ? 'Can\'t be blank' : null,
              )
            ],
          ),
        ),
        SimpleDialogOption(
          child: Text('Okay'),
          onPressed: () => Navigator.of(context).pop(folderController.text),
        ),
        SimpleDialogOption(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }
}

class CreateSmartListDialog extends StatefulWidget {
  final String folder, listName;

  const CreateSmartListDialog({Key key, this.listName, this.folder})
      : super(key: key);

  @override
  _CreateSmartListDialogState createState() => _CreateSmartListDialogState();
}

class _CreateSmartListDialogState extends State<CreateSmartListDialog> {
  TextEditingController listController;
  String selectedTag;
  bool toggle, includeSub;
  List<String> tags;

  @override
  void initState() {
    super.initState();
    listController = TextEditingController(text: widget.listName);
    toggle = false;
    includeSub = false;
    selectedTag = '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entityManager = EntityManagerProvider.of(context).entityManager;
    tags = entityManager
        .group(all: [Tag, Owns], none: [SmartList])
        .entities
        .map((e) => e.get<Tag>().value)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('${widget.listName != null ? 'Editing' : 'New'} smart list'),
      children: <Widget>[
        Form(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  controller: listController,
                  validator: (value) =>
                      value.isEmpty ? 'Can\'t be blank' : null,
                ),
                CheckboxListTile(
                  title: Text('Only completed tasks?'),
                  value: toggle,
                  onChanged: (value) => setState(() {
                    toggle = value;
                  }),
                ),
                CheckboxListTile(
                  title: Text('Include sub folders?'),
                  value: includeSub,
                  onChanged: (value) => setState(() {
                    includeSub = value;
                  }),
                ),
                for (final tag in tags)
                  RadioListTile<String>(
                    title: Text(tag),
                    value: tag,
                    groupValue: selectedTag,
                    onChanged: (tag) => setState(() {
                      selectedTag = tag;
                    }),
                  )
              ],
            ),
          ),
        ),
        SimpleDialogOption(
          child: Text('Okay'),
          onPressed: () => Navigator.of(context).pop({
            'listName': listController.text,
            'tag': selectedTag,
            'includeSub': includeSub,
            'toggle': toggle
          }),
        ),
        SimpleDialogOption(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop({}),
        )
      ],
    );
  }
}

class CreateTaskDialog extends StatefulWidget {
  final String folder, taskName;

  const CreateTaskDialog({Key key, this.folder, this.taskName})
      : super(key: key);

  @override
  _CreateTaskDialogState createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  TextEditingController taskController;

  @override
  void initState() {
    super.initState();
    taskController = TextEditingController(text: widget.taskName);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
          '${widget.taskName != null ? 'Editing' : 'New'} task on ${widget.folder}'),
      children: <Widget>[
        Form(
          child: Column(
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                controller: taskController,
                validator: (value) => value.isEmpty ? 'Can\'t be blank' : null,
              )
            ],
          ),
        ),
        SimpleDialogOption(
          child: Text('Okay'),
          onPressed: () => Navigator.of(context).pop(taskController.text),
        ),
        SimpleDialogOption(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }
}
