import "package:equatable/equatable.dart";

enum AnomalySeverity { error, warning, info }

enum AnomalyType {
  parentTooYoung,
  parentTooOld,
  childrenBornTooClose,
  marriageAfterDeath,
  loopDetected,
  deathBeforeBirth,
  childBornAfterFatherDeath,
  childBornAfterMotherDeath,
  impossibleMovement,
  unknownTag,
  invalidDateFormat,
  invalidLocationFormat,
  other,
}

/// Represents a specific issue or inconsistency found in a GEDCOM dataset.
class GedcomAnomaly extends Equatable {
  /// The severity of the anomaly (error, warning, or info).
  final AnomalySeverity severity;

  /// The category of the anomaly.
  final AnomalyType type;

  /// A human-readable description of the issue.
  final String description;

  /// The ID of the [Person] or [Family] where the anomaly was detected.
  final String? entityId; // ID of the Person or Family involved

  /// Additional IDs related to the anomaly (e.g., children involved in a gap).
  final List<String> relatedIds;

  const GedcomAnomaly({
    required this.severity,
    required this.type,
    required this.description,
    this.entityId,
    this.relatedIds = const [],
  });

  @override
  List<Object?> get props => [
        severity,
        type,
        description,
        entityId,
        relatedIds,
      ];
}

/// A comprehensive report on the data quality and consistency of a GEDCOM dataset.
class GedcomHealthReport extends Equatable {
  /// List of all anomalies detected during the scan.
  final List<GedcomAnomaly> anomalies;

  /// When the report was generated.
  final DateTime generatedAt;

  /// Total number of persons analyzed.
  final int totalPersonsScanned;

  /// Total number of families analyzed.
  final int totalFamiliesScanned;

  const GedcomHealthReport({
    required this.anomalies,
    required this.generatedAt,
    required this.totalPersonsScanned,
    required this.totalFamiliesScanned,
  });

  @override
  List<Object?> get props => [
        anomalies,
        generatedAt,
        totalPersonsScanned,
        totalFamiliesScanned,
      ];

  List<GedcomAnomaly> get errors =>
      anomalies.where((a) => a.severity == AnomalySeverity.error).toList();
  List<GedcomAnomaly> get warnings =>
      anomalies.where((a) => a.severity == AnomalySeverity.warning).toList();
  List<GedcomAnomaly> get infos =>
      anomalies.where((a) => a.severity == AnomalySeverity.info).toList();
}
