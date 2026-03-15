import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

enum TriggerType { home, work, tonight, custom, routine }

class Note {
  final String id;
  final String content;
  final TriggerType triggerType;
  final String? triggerValue; // e.g., '2026-10-31T20:00:00', or geofence lat/lng if we track coords, else null for predefined home/work
  final String category; // 'Personal' or 'Business'
  final bool isActive;
  final DateTime createdAt;

  Note({
    String? id,
    required this.content,
    required this.triggerType,
    this.triggerValue,
    this.category = 'Personal',
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Note copyWith({
    String? content,
    TriggerType? triggerType,
    String? triggerValue,
    String? category,
    bool? isActive,
  }) {
    return Note(
      id: id,
      content: content ?? this.content,
      triggerType: triggerType ?? this.triggerType,
      triggerValue: triggerValue ?? this.triggerValue,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Custom TypeAdapter for Hive to avoid requiring build_runner code generation
class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      content: fields[1] as String,
      triggerType: TriggerType.values[fields[2] as int],
      triggerValue: fields[3] as String?,
      category: fields[4] as String? ?? 'Personal', // Migration fallback
      isActive: fields[5] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(7) // Increased to 7
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.triggerType.index)
      ..writeByte(3)
      ..write(obj.triggerValue)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }
}
