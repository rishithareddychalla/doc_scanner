// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScannedDocumentAdapter extends TypeAdapter<ScannedDocument> {
  @override
  final int typeId = 0;

  @override
  ScannedDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScannedDocument(
      id: fields[0] as String,
      title: fields[1] as String,
      imagePaths: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScannedDocument obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.imagePaths)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavedPdfAdapter extends TypeAdapter<SavedPdf> {
  @override
  final int typeId = 1;

  @override
  SavedPdf read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedPdf(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      createdAt: fields[3] as DateTime,
      sourceDocumentId: fields[4] as String?,
      pageCount: fields[5] as int,
      fileSize: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SavedPdf obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.sourceDocumentId)
      ..writeByte(5)
      ..write(obj.pageCount)
      ..writeByte(6)
      ..write(obj.fileSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPdfAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
