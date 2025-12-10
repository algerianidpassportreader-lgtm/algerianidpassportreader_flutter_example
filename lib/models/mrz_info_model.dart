class MrzInfoModel {
  final String documentNumber;
  final String dateOfBirth;
  final String dateOfExpiry;
  final String? nationality;
  final String? gender;
  final String? issuingState;
  final String? primaryIdentifier;
  final String? secondaryIdentifier;
  final String? documentCode;

  MrzInfoModel({
    required this.documentNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.nationality,
    this.gender,
    this.issuingState,
    this.primaryIdentifier,
    this.secondaryIdentifier,
    this.documentCode,
  });

  factory MrzInfoModel.fromJson(Map<dynamic, dynamic> json) {
    return MrzInfoModel(
      documentNumber: json['documentNumber'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      dateOfExpiry: json['dateOfExpiry'] ?? '',
      gender: json['gender'] ?? '',
      documentCode: json['documentCode'] ?? '', //P or ID
      issuingState: json['issuingState'] ?? 'DZA',
      nationality: json['nationality'] ?? 'DZA',
      primaryIdentifier: json['primaryIdentifier'] ?? '',
      secondaryIdentifier: json['secondaryIdentifier'] ?? '',
    );
  }

  Map<String, String> toJson() {
    return {
      'documentNumber': documentNumber,
      'dateOfBirth': dateOfBirth,
      'dateOfExpiry': dateOfExpiry,
      'gender': gender ?? '',
      'documentCode': documentCode ?? '',
      'issuingState': issuingState ?? '',
      'nationality': nationality ?? '',
      'primaryIdentifier': primaryIdentifier ?? '',
      'secondaryIdentifier': secondaryIdentifier ?? '',
    };
  }
}
