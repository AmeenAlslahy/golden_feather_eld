class DvirDto {
  final int id;
  final DvirDriverDto? driver;
  final String? uniqueId;
  final String? vehicleName;
  final String? trailerNumber;
  final String? companyName;
  final String? inspectionType;
  final String? inspectionTime;
  final String? formattedTime;
  final String? location;
  final double? odometer;
  final String? status;
  final bool hasDefects;
  final int defectsCount;
  final String? defectsSummary;
  final bool outOfService;
  final List<DvirDefectDto> defects;
  final String? remarks;
  final bool certified;
  final String? signatureData;
  final String? mechanicName;
  final String? repairStatus;
  final String? repairNotes;
  final String? reviewingDriverName;
  final bool nextDriverReviewed;
  final int? retentionDaysRemaining;
  final String? createdAt;

  const DvirDto({
    required this.id,
    this.driver,
    this.uniqueId,
    this.vehicleName,
    this.trailerNumber,
    this.companyName,
    this.inspectionType,
    this.inspectionTime,
    this.formattedTime,
    this.location,
    this.odometer,
    this.status,
    this.hasDefects = false,
    this.defectsCount = 0,
    this.defectsSummary,
    this.outOfService = false,
    this.defects = const [],
    this.remarks,
    this.certified = false,
    this.signatureData,
    this.mechanicName,
    this.repairStatus,
    this.repairNotes,
    this.reviewingDriverName,
    this.nextDriverReviewed = false,
    this.retentionDaysRemaining,
    this.createdAt,
  });

  factory DvirDto.fromJson(Map<String, dynamic> json) {
    return DvirDto(
      id: (json['id'] as num).toInt(),
      driver: json['driver'] == null
          ? null
          : DvirDriverDto.fromJson(json['driver'] as Map<String, dynamic>),
      uniqueId: json['uniqueId']?.toString(),
      vehicleName: json['vehicleName']?.toString(),
      trailerNumber: json['trailerNumber']?.toString(),
      companyName: json['companyName']?.toString(),
      inspectionType: json['inspectionType']?.toString(),
      inspectionTime: json['inspectionTime']?.toString(),
      formattedTime: json['formattedTime']?.toString(),
      location: json['location']?.toString(),
      odometer: (json['odometer'] as num?)?.toDouble(),
      status: json['status']?.toString(),
      hasDefects: json['hasDefects'] == true,
      defectsCount: (json['defectsCount'] as num?)?.toInt() ?? 0,
      defectsSummary: json['defectsSummary']?.toString(),
      outOfService: json['outOfService'] == true,
      defects: (json['defects'] as List<dynamic>?)
              ?.map((e) => DvirDefectDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      remarks: json['remarks']?.toString(),
      certified: json['certified'] == true,
      signatureData: json['signatureData']?.toString(),
      mechanicName: json['mechanicName']?.toString(),
      repairStatus: json['repairStatus']?.toString(),
      repairNotes: json['repairNotes']?.toString(),
      reviewingDriverName: json['reviewingDriverName']?.toString(),
      nextDriverReviewed: json['nextDriverReviewed'] == true,
      retentionDaysRemaining: (json['retentionDaysRemaining'] as num?)?.toInt(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver': driver?.toJson(),
      'uniqueId': uniqueId,
      'vehicleName': vehicleName,
      'trailerNumber': trailerNumber,
      'companyName': companyName,
      'inspectionType': inspectionType,
      'inspectionTime': inspectionTime,
      'formattedTime': formattedTime,
      'location': location,
      'odometer': odometer,
      'status': status,
      'hasDefects': hasDefects,
      'defectsCount': defectsCount,
      'defectsSummary': defectsSummary,
      'outOfService': outOfService,
      'defects': defects.map((e) => e.toJson()).toList(),
      'remarks': remarks,
      'certified': certified,
      'signatureData': signatureData,
      'mechanicName': mechanicName,
      'repairStatus': repairStatus,
      'repairNotes': repairNotes,
      'reviewingDriverName': reviewingDriverName,
      'nextDriverReviewed': nextDriverReviewed,
      'retentionDaysRemaining': retentionDaysRemaining,
      'createdAt': createdAt,
    };
  }
}

class DvirDriverDto {
  final int id;
  final String? name;
  final String? email;
  final String? uniqueId;
  final String? licenseNumber;
  final String? licenseState;
  final String? carrierName;
  final String? carrierUsdot;
  final String? status;

  const DvirDriverDto({
    required this.id,
    this.name,
    this.email,
    this.uniqueId,
    this.licenseNumber,
    this.licenseState,
    this.carrierName,
    this.carrierUsdot,
    this.status,
  });

  factory DvirDriverDto.fromJson(Map<String, dynamic> json) {
    return DvirDriverDto(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      uniqueId: json['uniqueId']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      licenseState: json['licenseState']?.toString(),
      carrierName: json['carrierName']?.toString(),
      carrierUsdot: json['carrierUsdot']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'uniqueId': uniqueId,
      'licenseNumber': licenseNumber,
      'licenseState': licenseState,
      'carrierName': carrierName,
      'carrierUsdot': carrierUsdot,
      'status': status,
    };
  }
}

class DvirDefectDto {
  final String? itemCode;
  final String? itemName;
  final String? category;
  final bool safetyAffecting;
  final bool outOfService;
  final String? description;
  final String? correctionStatus;
  final String? correctionNotes;
  final String? correctedBy;
  final String? correctedAt;
  final String? severity;
  final String? stage;

  const DvirDefectDto({
    this.itemCode,
    this.itemName,
    this.category,
    this.safetyAffecting = false,
    this.outOfService = false,
    this.description,
    this.correctionStatus,
    this.correctionNotes,
    this.correctedBy,
    this.correctedAt,
    this.severity,
    this.stage,
  });

  factory DvirDefectDto.fromJson(Map<String, dynamic> json) {
    return DvirDefectDto(
      itemCode: json['itemCode']?.toString(),
      itemName: json['itemName']?.toString(),
      category: json['category']?.toString(),
      safetyAffecting: json['safetyAffecting'] == true,
      outOfService: json['outOfService'] == true,
      description: json['description']?.toString(),
      correctionStatus: json['correctionStatus']?.toString(),
      correctionNotes: json['correctionNotes']?.toString(),
      correctedBy: json['correctedBy']?.toString(),
      correctedAt: json['correctedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'category': category,
      'safetyAffecting': safetyAffecting,
      'outOfService': outOfService,
      'description': description,
      'correctionStatus': correctionStatus,
      'correctionNotes': correctionNotes,
      'correctedBy': correctedBy,
      'correctedAt': correctedAt,
    };
  }
}

class CreateDvirRequestDto {
  final int driverId;
  final String uniqueId;
  final String? vehicleName;
  final String inspectionType;
  final String inspectionTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double? odometer;
  final String? trailerNumber;
  final String? companyName;
  final String? remarks;
  final String status;
  final List<DvirDefectDto> defects;
  final String signatureData;
  final List<String> photos;
  final bool passengerCarrying;

  const CreateDvirRequestDto({
    required this.driverId,
    required this.uniqueId,
    this.vehicleName,
    required this.inspectionType,
    required this.inspectionTime,
    this.location,
    this.latitude,
    this.longitude,
    this.odometer,
    this.trailerNumber,
    this.companyName,
    this.remarks,
    required this.status,
    this.defects = const [],
    required this.signatureData,
    this.photos = const [],
    this.passengerCarrying = false,
  });

  factory CreateDvirRequestDto.fromJson(Map<String, dynamic> json) {
    return CreateDvirRequestDto(
      driverId: (json['driverId'] as num).toInt(),
      uniqueId: json['uniqueId'].toString(),
      vehicleName: json['vehicleName']?.toString(),
      inspectionType: json['inspectionType'].toString(),
      inspectionTime: json['inspectionTime'].toString(),
      location: json['location']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      odometer: (json['odometer'] as num?)?.toDouble(),
      trailerNumber: json['trailerNumber']?.toString(),
      companyName: json['companyName']?.toString(),
      remarks: json['remarks']?.toString(),
      status: json['status'].toString(),
      defects: (json['defects'] as List<dynamic>?)
              ?.map((e) => DvirDefectDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      signatureData: json['signatureData'].toString(),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      passengerCarrying: json['passengerCarrying'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'uniqueId': uniqueId,
      'vehicleName': vehicleName,
      'inspectionType': inspectionType,
      'inspectionTime': inspectionTime,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'odometer': odometer,
      'trailerNumber': trailerNumber,
      'companyName': companyName,
      'remarks': remarks,
      'status': status,
      'defects': defects.map((e) => e.toJson()).toList(),
      'signatureData': signatureData,
      'photos': photos,
      'passengerCarrying': passengerCarrying,
    };
  }
}



class ReviewDvirRequestDto {
  final int reviewingDriverId;
  final String reviewingDriverName;
  final String signatureData;
  final bool driverAgreed;
  final String? reviewNotes;

  const ReviewDvirRequestDto({
    required this.reviewingDriverId,
    required this.reviewingDriverName,
    required this.signatureData,
    required this.driverAgreed,
    this.reviewNotes,
  });

  factory ReviewDvirRequestDto.fromJson(Map<String, dynamic> json) {
    return ReviewDvirRequestDto(
      reviewingDriverId: (json['reviewingDriverId'] as num).toInt(),
      reviewingDriverName: json['reviewingDriverName'].toString(),
      signatureData: json['signatureData'].toString(),
      driverAgreed: json['driverAgreed'] == true,
      reviewNotes: json['reviewNotes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewingDriverId': reviewingDriverId,
      'reviewingDriverName': reviewingDriverName,
      'signatureData': signatureData,
      'driverAgreed': driverAgreed,
      'reviewNotes': reviewNotes,
    };
  }
}
