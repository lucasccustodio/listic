import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';

class Toggle extends ComponentData<bool> with ComponentMixin {
  Toggle([bool value = false]) : super(value);
}

class Owns extends ComponentData<Tags> with ComponentMixin {
  Owns(List<Tag> value) : super(Tags(value));
}

class Tag = ComponentData<String> with ComponentMixin;

class Tags = ComponentData<List<Tag>> with ComponentMixin;

class Changed = ComponentData with ComponentMixin;

class Contents extends ComponentData<String> with ComponentMixin {
  Contents({String value}) : super(value);
}

class DatabaseKey extends ComponentData<int> with ComponentMixin {
  DatabaseKey({int value}) : super(value);
}

//System components
class FeatureEntityTag = TagComponent with UniqueMixin;

class ListItem {
  bool isChecked;

  String label;
  ListItem(this.label, {this.isChecked = false});
  ListItem.fromJson(Map<String, dynamic> map)
      : label = map['label'] ?? '',
        isChecked = map['isChecked'] ?? false;

  @override
  int get hashCode => label.hashCode ^ isChecked.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is ListItem && other.hashCode == hashCode;

  Map<String, dynamic> toJson() => {'label': label, 'isChecked': isChecked};

  @override
  String toString() => toJson().toString();
}

class MainTickTag = ComponentData<int> with UniqueMixin;

class NavigationEvent extends ComponentData with UniqueMixin {
  final String routeName;

  final NavigationOps routeOp;

  NavigationEvent(
      {@required this.routeName, this.routeOp = NavigationOps.push});

  NavigationEvent.pop()
      : routeName = '',
        routeOp = NavigationOps.pop;

  NavigationEvent.push(this.routeName) : routeOp = NavigationOps.push;

  NavigationEvent.replace(this.routeName) : routeOp = NavigationOps.replace;
  NavigationEvent.showDialog(this.routeName)
      : routeOp = NavigationOps.showDialog;
}

enum NavigationOps { push, pop, replace, showDialog }

class PerformSearchEvent = TagComponent with UniqueMixin;

class PersistMe extends ComponentData<int> with ComponentMixin {
  final int key;

  PersistMe([this.key]);
}

class Priority = ComponentData<TaskPriority> with ComponentMixin;

class RefreshDatabaseEvent = TagComponent with UniqueMixin;

enum TaskPriority { none, low, medium, high, maximum }

class SearchBarTag = TagComponent with UniqueMixin;

class SearchResult extends TagComponent with ComponentMixin {}

class SearchTerm = ComponentData<String> with ComponentMixin;

class Selected extends TagComponent with ComponentMixin {}

class SetupDatabaseEvent extends TagComponent with UniqueMixin {}

class StoragePermission = TagComponent with UniqueMixin;

class TagData extends ComponentData<String> with ComponentMixin {}

class Tick = ComponentData<int> with ComponentMixin;

class DueDate extends DateComponent {
  DueDate(String _timestamp) : super(DateTime.parse(_timestamp));
}

class CreationDate extends DateComponent {
  CreationDate(String _timestamp) : super(DateTime.parse(_timestamp));
}

class EditedDate extends DateComponent {
  EditedDate(String _timestamp) : super(DateTime.parse(_timestamp));
}

abstract class DateComponent = ComponentData<DateTime> with ComponentMixin;

class Todo extends ComponentData<List<ListItem>> with ComponentMixin {
  Todo({List<ListItem> value}) : super(value);
}

abstract class Condition extends ComponentData with ComponentMixin {}

class ConditionalEntityMatcher {
  final Map<Type, dynamic> values;
  final Set<Type> _all, _any, _none;

  ConditionalEntityMatcher(
    this.values,
    List<Type> all,
    List<Type> none,
    List<Type> any,
  )   : _all = Set.from(all ?? []),
        _none = Set.from(none ?? []),
        _any = Set.from(any ?? []);

  bool matches(ObservableEntity e) {
    for (var t in _all) {
      if (e.has(t) == false || values[t] != e.get()) {
        return false;
      }
    }
    for (var t in _none) {
      if (e.has(t)) {
        return false;
      }
    }
    if (_any.isEmpty) {
      return true;
    }
    for (var t in _any) {
      if (e.has(t)) {
        return true;
      }
    }
    return false;
  }
}
