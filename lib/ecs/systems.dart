import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:kt_dart/kt.dart';
import 'package:listic/ecs/components.dart';
import 'package:listic/ecs/matchers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';

bool _compactIf(int entries, int deletedEntries) => deletedEntries > 50;

Future<String> _getValidPath() async {
  if (Platform.isFuchsia || Platform.isWindows || Platform.isLinux)
    return './Files/';
  else
    return (await getExternalStorageDirectory()).path;
}

/* void _populateNote(EntityManager entityManager, Entity noteEntity,
    EntityGroup tagMap, Map<String, dynamic> snapshotData) {
  noteEntity
    ..set(Contents(snapshotData['contents']))
    ..set(DueDate(snapshotData['timestamp']));

  final List<String> tagItems = List<String>.from(snapshotData['tags']);
  final noteTags =
      KtList<String>.from(tagItems ?? <String>[]).map((tag) => tag.trim());
  final tags = KtList<ObservableEntity>.from(tagMap.entities);

  noteEntity.set(Tags(noteTags.asList()));

  for (var noteTag in noteTags.iter) {
    if (tags.none((e) => e.get<TagData>().value == noteTag))
      entityManager.createEntity().set(TagData(noteTag));
  }

  final List<Map<String, dynamic>> todoItems = List.from(snapshotData['todo'])
      .map((data) => Map<String, dynamic>.from(data))
      .toList();
  final todo = List<Map<String, dynamic>>.from(todoItems)
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  noteEntity
      .set(Todo(value: todo.map((json) => ListItem.fromJson(json)).toList()));

  if (snapshotData['picFile'] != null)
    noteEntity.set(Picture(snapshotData['picFile']));

  if (snapshotData['archived'] != null && snapshotData['archived'] == true) {
    noteEntity.set(Archived());
  }
} */

/* class BackupSystem extends TriggeredSystem {
  static const backupPath = '/storage/emulated/0/backup.json';

  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  @override
  EntityMatcher get matcher =>
      EntityMatcher(any: [ImportNotesEvent, ExportNotesEvent]);

  @override
  void executeOnChange() async {
    if (entityManager.getUnique<ImportNotesEvent>() != null)
      importBackup();
    else if (entityManager.getUnique<ExportNotesEvent>() != null)
      exportBackup();

    entityManager
      ..removeUnique<ImportNotesEvent>()
      ..removeUnique<ExportNotesEvent>();
  }

  void exportBackup() {
    final mapFile = File(backupPath);
    final noteGroup = entityManager.groupMatching(Matchers.note);
    final reminderGroup = entityManager.groupMatching(Matchers.reminder);
    try {
      final notes = noteGroup.entities;
      final reminders = reminderGroup.entities;
      final settings = entityManager.getUniqueEntity<AppSettingsTag>();
      final map = <String, dynamic>{};

      map['notes'] = notes
          .map((e) => {
                'contents': e.get<Contents>().value,
                'timestamp': e.get<DueDate>().value.toIso8601String(),
                'tags': e.get<Tags>()?.value?.toList() ?? [],
                'todo': e
                        .get<Todo>()
                        ?.value
                        ?.map((item) => item.toJson())
                        ?.toList() ??
                    [],
                'archived': e.hasT<Archived>(),
                'picFile': e.get<Picture>()?.value?.path
              })
          .toList();

      map['reminders'] = reminders
          .map((e) => {
                'contents': e.get<Contents>().value,
                'timestamp': e.get<DueDate>().value.toIso8601String(),
                'priority': e.get<Priority>()?.value?.index ?? 0,
                'completed': e.hasT<Toggle>()
              })
          .toList();

      map['settings'] = {
        'darkTheme':
            settings.get<AppTheme>().value.brightness == Brightness.dark,
      };

      mapFile.writeAsStringSync(jsonEncode(map));
    } on FileSystemException catch (e) {
      print(e);
    } finally {
      final localization =
          entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();
      entityManager.getUniqueEntity<DisplayStatusTag>()
        ..set(Contents(localization.exportedAlert))
        ..set(WaitForUser())
        ..set(Toggle());
    }
  }

  void importBackup() {
    final backupFile = File(backupPath);

    if (backupFile.existsSync()) {
      try {
        final Map<String, dynamic> map =
            jsonDecode(backupFile.readAsStringSync() ?? '{}');
        final snapshotData = Map<String, dynamic>.from(map);

        final tagMap = entityManager.groupMatching(Matchers.tag);

        final darkTheme = snapshotData['settings']['darkTheme'] ?? false;

        entityManager
            .getUniqueEntity<AppSettingsTag>()
            .set(AppTheme(darkTheme ? DarkTheme() : LightTheme()));

        for (final noteData in snapshotData['notes']) {
          final noteEntity = entityManager.createEntity();

          _populateNote(entityManager, noteEntity, tagMap,
              Map<String, dynamic>.from(noteData));
        }

        for (final reminderData in snapshotData['reminders']) {
          final reminderEntity = entityManager.createEntity();

          _populateReminder(entityManager, reminderEntity,
              Map<String, dynamic>.from(reminderData));
        }
      } on FileSystemException catch (e) {
        print(e);
      } finally {
        final noteGroup = entityManager.groupMatching(Matchers.note
            .copyWith(all: [Contents, DueDate], none: [DatabaseKey]));
        final reminderGroup = entityManager.groupMatching(Matchers.note
            .copyWith(
                all: [Contents, DueDate, Priority], none: [DatabaseKey]));

        for (final e in [...noteGroup.entities, ...reminderGroup.entities])
          e.set(PersistMe());

        entityManager.setUnique(PersistUserSettingsEvent());

        final localization =
            entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();
        entityManager.getUniqueEntity<DisplayStatusTag>()
          ..set(Contents(localization.importedAlert))
          ..set(WaitForUser())
          ..set(Toggle());
      }
    }
  }
} */

class DatabaseSystem extends TriggeredSystem implements InitSystem {
  EntityGroup tagMap, noteMap, reminderMap;
  StreamSubscription reminderListener, noteListener;

  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  @override
  EntityMatcher get matcher =>
      EntityMatcher(any: [SetupDatabaseEvent, RefreshDatabaseEvent]);

  @override
  void executeOnChange() {
    if (entityManager.getUnique<StoragePermission>() == null &&
        entityManager.getUnique<SetupDatabaseEvent>() != null) {
      return setupDatabase();
    }

    entityManager.removeUnique<RefreshDatabaseEvent>();
  }

  @override
  void init() {
    tagMap = entityManager.groupMatching(Matchers.tag);

    setupDatabase();
  }

  /* void refreshNotes() async {
    final noteStore = !Hive.isBoxOpen('notes')
        ? await Hive.openBox('notes', compactionStrategy: _compactIf)
        : Hive.box('notes');
    final snapshot = noteStore.toMap();

    for (final snapshot in snapshot.entries) {
      final snapshotData = Map<String, dynamic>.from(snapshot.value);
      final noteEntity = entityManager.createEntity()
        ..set(DatabaseKey(snapshot.key));

      _populateNote(entityManager, noteEntity, tagMap, snapshotData);
    }

    await noteListener?.cancel();
    noteListener = noteStore.watch().listen(updateNotes);
  } */

  void setupDatabase() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status =
          await Permission.getPermissionsStatus([PermissionName.Storage]);

      if (status.first.permissionStatus == PermissionStatus.deny ||
          status.first.permissionStatus == PermissionStatus.notDecided ||
          status.first.permissionStatus == PermissionStatus.notAgain) {
        final status =
            (await Permission.requestPermissions([PermissionName.Storage]))
                .first
                .permissionStatus;

        if (status != PermissionStatus.allow) return;
      }
    }

    final path = await _getValidPath();
    Hive.init(path);

    entityManager
      ..removeUnique<SetupDatabaseEvent>()
      ..setUnique(StoragePermission())
      ..setUnique(RefreshDatabaseEvent());
  }

  /* void updateNotes(BoxEvent event) {
    final noteEntity = KtList.from(noteMap.entities)
            .singleOrNull((e) => e.get<DatabaseKey>().value == event.key) ??
        entityManager.createEntity()
      ..set(DatabaseKey(event.key));

    if (event.deleted) {
      noteEntity.destroy();
    } else {
      final snapshotData = Map<String, dynamic>.from(event.value);

      _populateNote(entityManager, noteEntity, tagMap, snapshotData);
    }
  } */
}

class NavigationSystem extends TriggeredSystem {
  final GlobalKey<NavigatorState> _key;

  NavigationSystem(this._key);

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [NavigationEvent]);

  @override
  void executeOnChange() {
    final routeName = entityManager.getUnique<NavigationEvent>().routeName;
    final routeOp = entityManager.getUnique<NavigationEvent>().routeOp;

    switch (routeOp) {
      case NavigationOps.pop:
        _key.currentState.pop();
        break;
      case NavigationOps.push:
        _key.currentState.pushNamed(routeName);
        break;
      case NavigationOps.replace:
        _key.currentState.pushReplacementNamed(routeName);
        break;
      default:
    }
  }
}

class PersistanceSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [PersistMe]);

  @override
  void executeWith(List<ObservableEntity> entities) async {
    if (Hive.path == null) {
      return;
    }

    for (var e in entities) {
      final contents = e.get<Contents>()?.value;
      final tags = e.get<Tags>()?.value ?? [];
      final items = e.get<Todo>()?.value ?? [];
      final dbKey = e.get<PersistMe>()?.key;
      final date = e.get<DueDate>()?.value ?? DateTime.now();
      final priority = e.get<Priority>()?.value;
      final completed = e.hasT<Toggle>();

      e.destroy();

      if (priority != null) {
        final reminderStore = !Hive.isBoxOpen('reminders')
            ? await Hive.openBox('reminders', compactionStrategy: _compactIf)
            : Hive.box('reminders');

        final reminder = {
          'contents': contents,
          'timestamp': date.toIso8601String(),
          'priority': priority.index,
          'completed': completed
        };

        if (dbKey != null)
          await reminderStore.put(dbKey, reminder);
        else
          await reminderStore.add(reminder);
        continue;
      }
    }
  }
}

class SearchSystem extends EntityManagerSystem implements ExecuteSystem {
  @override
  void execute() {
    final searchEntity = entityManager.getUniqueEntity<SearchBarTag>();
    final searchTerm = searchEntity.get<SearchTerm>()?.value;
    final tags = entityManager.groupMatching(Matchers.tag);

    for (var tag in tags.entities) {
      tag.remove<SearchResult>();
    }

    if (searchTerm == null || searchTerm.isEmpty || searchTerm.length < 2) {
      return;
    }

    final mainTick =
        entityManager.getUniqueEntity<MainTickTag>().get<Tick>().value;
    final searchTick = searchEntity.get<Tick>()?.value ?? 0;

    if (searchTick + 20 > mainTick) {
      return;
    }

    for (var tag in tags.entities) {
      if (!tag.hasT<Tags>()) {
        continue;
      }

      final tags = tag.get<Tags>().value;

      if (tags.contains(searchTerm))
        tag.set(SearchResult());
      else {
        for (var tagName in tags) {
          for (final term in searchTerm.split(' '))
            if (RegExp('\^$term', caseSensitive: false)
                .hasMatch(tagName.value)) {
              tag.set(SearchResult());
            }
        }
      }
    }

    searchEntity.remove<Tick>();
  }
}

class TickSystem extends EntityManagerSystem
    implements InitSystem, ExecuteSystem {
  @override
  void execute() {
    entityManager
        .getUniqueEntity<MainTickTag>()
        .update<Tick>((old) => Tick(old.value + 1));
  }

  @override
  void init() {
    entityManager.setUnique(MainTickTag()).set(Tick(0));
  }
}
