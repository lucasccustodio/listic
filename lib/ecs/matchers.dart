import 'package:entitas_ff/entitas_ff.dart';
import 'package:listic/ecs/components.dart';

//A valid Note Entity has timestamp, contents and possible tags & todo items.
mixin Matchers {
  static EntityMatcher tag = EntityMatcher(all: [TagData], maybe: [Toggle]);
  static EntityMatcher searchResult = EntityMatcher(all: [SearchResult]);
}
