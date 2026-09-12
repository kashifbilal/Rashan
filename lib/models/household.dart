/// Represents one surveyed household.
///
/// Section 1 (identification & composition) plus, as of this update,
/// GPS coordinates captured at survey time and a photo of the household /
/// head of household. Later steps will add livelihood questions, the
/// eligibility score, and delivery-confirmation fields.
class Household {
  final int? id; // null until saved to the database, then auto-assigned
  final String surveyorName;
  final DateTime surveyDate;
  final String headOfHouseholdName;
  final String cnic; // format: 12345-1234567-1
  final String phoneNumber;
  final String address;
  final int totalFamilyMembers;
  final int childrenUnder18;
  final int elderlyOver60;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String? photoPath; // local file path to the captured photo

  Household({
    this.id,
    required this.surveyorName,
    required this.surveyDate,
    required this.headOfHouseholdName,
    required this.cnic,
    required this.phoneNumber,
    required this.address,
    required this.totalFamilyMembers,
    required this.childrenUnder18,
    required this.elderlyOver60,
    this.notes,
    this.latitude,
    this.longitude,
    this.photoPath,
  });

  /// Converts this object into a Map for storage in SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surveyorName': surveyorName,
      'surveyDate': surveyDate.toIso8601String(),
      'headOfHouseholdName': headOfHouseholdName,
      'cnic': cnic,
      'phoneNumber': phoneNumber,
      'address': address,
      'totalFamilyMembers': totalFamilyMembers,
      'childrenUnder18': childrenUnder18,
      'elderlyOver60': elderlyOver60,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'photoPath': photoPath,
    };
  }

  /// Rebuilds a Household object from a database row.
  factory Household.fromMap(Map<String, dynamic> map) {
    return Household(
      id: map['id'] as int?,
      surveyorName: map['surveyorName'] as String,
      surveyDate: DateTime.parse(map['surveyDate'] as String),
      headOfHouseholdName: map['headOfHouseholdName'] as String,
      cnic: map['cnic'] as String,
      phoneNumber: map['phoneNumber'] as String,
      address: map['address'] as String,
      totalFamilyMembers: map['totalFamilyMembers'] as int,
      childrenUnder18: map['childrenUnder18'] as int,
      elderlyOver60: map['elderlyOver60'] as int,
      notes: map['notes'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      photoPath: map['photoPath'] as String?,
    );
  }
}
