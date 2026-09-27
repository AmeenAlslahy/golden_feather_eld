// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dot_inspection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DotInspectionScreen {

 String get screenTitle; String get guidanceText; String get handOverDeviceNotice; String get carrierComplianceStatement; String get carrierName; String get usdotNumber; String get eldIdentifier; String get eldRegistrationId; DriverId get driverId; String get driverName; DateTime get inspectionDate; int get cycleDaysCovered; bool get canStartInspection; bool get canSendLogs; bool get canEmailLogs; bool get canViewInformationPacket; bool get inspectionActive; bool get readOnlyMode; int? get activeInspectionId; String? get inspectorName;
/// Create a copy of DotInspectionScreen
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DotInspectionScreenCopyWith<DotInspectionScreen> get copyWith => _$DotInspectionScreenCopyWithImpl<DotInspectionScreen>(this as DotInspectionScreen, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DotInspectionScreen&&(identical(other.screenTitle, screenTitle) || other.screenTitle == screenTitle)&&(identical(other.guidanceText, guidanceText) || other.guidanceText == guidanceText)&&(identical(other.handOverDeviceNotice, handOverDeviceNotice) || other.handOverDeviceNotice == handOverDeviceNotice)&&(identical(other.carrierComplianceStatement, carrierComplianceStatement) || other.carrierComplianceStatement == carrierComplianceStatement)&&(identical(other.carrierName, carrierName) || other.carrierName == carrierName)&&(identical(other.usdotNumber, usdotNumber) || other.usdotNumber == usdotNumber)&&(identical(other.eldIdentifier, eldIdentifier) || other.eldIdentifier == eldIdentifier)&&(identical(other.eldRegistrationId, eldRegistrationId) || other.eldRegistrationId == eldRegistrationId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.inspectionDate, inspectionDate) || other.inspectionDate == inspectionDate)&&(identical(other.cycleDaysCovered, cycleDaysCovered) || other.cycleDaysCovered == cycleDaysCovered)&&(identical(other.canStartInspection, canStartInspection) || other.canStartInspection == canStartInspection)&&(identical(other.canSendLogs, canSendLogs) || other.canSendLogs == canSendLogs)&&(identical(other.canEmailLogs, canEmailLogs) || other.canEmailLogs == canEmailLogs)&&(identical(other.canViewInformationPacket, canViewInformationPacket) || other.canViewInformationPacket == canViewInformationPacket)&&(identical(other.inspectionActive, inspectionActive) || other.inspectionActive == inspectionActive)&&(identical(other.readOnlyMode, readOnlyMode) || other.readOnlyMode == readOnlyMode)&&(identical(other.activeInspectionId, activeInspectionId) || other.activeInspectionId == activeInspectionId)&&(identical(other.inspectorName, inspectorName) || other.inspectorName == inspectorName));
}


@override
int get hashCode => Object.hashAll([runtimeType,screenTitle,guidanceText,handOverDeviceNotice,carrierComplianceStatement,carrierName,usdotNumber,eldIdentifier,eldRegistrationId,driverId,driverName,inspectionDate,cycleDaysCovered,canStartInspection,canSendLogs,canEmailLogs,canViewInformationPacket,inspectionActive,readOnlyMode,activeInspectionId,inspectorName]);

@override
String toString() {
  return 'DotInspectionScreen(screenTitle: $screenTitle, guidanceText: $guidanceText, handOverDeviceNotice: $handOverDeviceNotice, carrierComplianceStatement: $carrierComplianceStatement, carrierName: $carrierName, usdotNumber: $usdotNumber, eldIdentifier: $eldIdentifier, eldRegistrationId: $eldRegistrationId, driverId: $driverId, driverName: $driverName, inspectionDate: $inspectionDate, cycleDaysCovered: $cycleDaysCovered, canStartInspection: $canStartInspection, canSendLogs: $canSendLogs, canEmailLogs: $canEmailLogs, canViewInformationPacket: $canViewInformationPacket, inspectionActive: $inspectionActive, readOnlyMode: $readOnlyMode, activeInspectionId: $activeInspectionId, inspectorName: $inspectorName)';
}


}

/// @nodoc
abstract mixin class $DotInspectionScreenCopyWith<$Res>  {
  factory $DotInspectionScreenCopyWith(DotInspectionScreen value, $Res Function(DotInspectionScreen) _then) = _$DotInspectionScreenCopyWithImpl;
@useResult
$Res call({
 String screenTitle, String guidanceText, String handOverDeviceNotice, String carrierComplianceStatement, String carrierName, String usdotNumber, String eldIdentifier, String eldRegistrationId, DriverId driverId, String driverName, DateTime inspectionDate, int cycleDaysCovered, bool canStartInspection, bool canSendLogs, bool canEmailLogs, bool canViewInformationPacket, bool inspectionActive, bool readOnlyMode, int? activeInspectionId, String? inspectorName
});


$DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class _$DotInspectionScreenCopyWithImpl<$Res>
    implements $DotInspectionScreenCopyWith<$Res> {
  _$DotInspectionScreenCopyWithImpl(this._self, this._then);

  final DotInspectionScreen _self;
  final $Res Function(DotInspectionScreen) _then;

/// Create a copy of DotInspectionScreen
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenTitle = null,Object? guidanceText = null,Object? handOverDeviceNotice = null,Object? carrierComplianceStatement = null,Object? carrierName = null,Object? usdotNumber = null,Object? eldIdentifier = null,Object? eldRegistrationId = null,Object? driverId = null,Object? driverName = null,Object? inspectionDate = null,Object? cycleDaysCovered = null,Object? canStartInspection = null,Object? canSendLogs = null,Object? canEmailLogs = null,Object? canViewInformationPacket = null,Object? inspectionActive = null,Object? readOnlyMode = null,Object? activeInspectionId = freezed,Object? inspectorName = freezed,}) {
  return _then(_self.copyWith(
screenTitle: null == screenTitle ? _self.screenTitle : screenTitle // ignore: cast_nullable_to_non_nullable
as String,guidanceText: null == guidanceText ? _self.guidanceText : guidanceText // ignore: cast_nullable_to_non_nullable
as String,handOverDeviceNotice: null == handOverDeviceNotice ? _self.handOverDeviceNotice : handOverDeviceNotice // ignore: cast_nullable_to_non_nullable
as String,carrierComplianceStatement: null == carrierComplianceStatement ? _self.carrierComplianceStatement : carrierComplianceStatement // ignore: cast_nullable_to_non_nullable
as String,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,usdotNumber: null == usdotNumber ? _self.usdotNumber : usdotNumber // ignore: cast_nullable_to_non_nullable
as String,eldIdentifier: null == eldIdentifier ? _self.eldIdentifier : eldIdentifier // ignore: cast_nullable_to_non_nullable
as String,eldRegistrationId: null == eldRegistrationId ? _self.eldRegistrationId : eldRegistrationId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,inspectionDate: null == inspectionDate ? _self.inspectionDate : inspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime,cycleDaysCovered: null == cycleDaysCovered ? _self.cycleDaysCovered : cycleDaysCovered // ignore: cast_nullable_to_non_nullable
as int,canStartInspection: null == canStartInspection ? _self.canStartInspection : canStartInspection // ignore: cast_nullable_to_non_nullable
as bool,canSendLogs: null == canSendLogs ? _self.canSendLogs : canSendLogs // ignore: cast_nullable_to_non_nullable
as bool,canEmailLogs: null == canEmailLogs ? _self.canEmailLogs : canEmailLogs // ignore: cast_nullable_to_non_nullable
as bool,canViewInformationPacket: null == canViewInformationPacket ? _self.canViewInformationPacket : canViewInformationPacket // ignore: cast_nullable_to_non_nullable
as bool,inspectionActive: null == inspectionActive ? _self.inspectionActive : inspectionActive // ignore: cast_nullable_to_non_nullable
as bool,readOnlyMode: null == readOnlyMode ? _self.readOnlyMode : readOnlyMode // ignore: cast_nullable_to_non_nullable
as bool,activeInspectionId: freezed == activeInspectionId ? _self.activeInspectionId : activeInspectionId // ignore: cast_nullable_to_non_nullable
as int?,inspectorName: freezed == inspectorName ? _self.inspectorName : inspectorName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DotInspectionScreen
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}


/// @nodoc


class _DotInspectionScreen implements DotInspectionScreen {
  const _DotInspectionScreen({required this.screenTitle, required this.guidanceText, required this.handOverDeviceNotice, required this.carrierComplianceStatement, required this.carrierName, required this.usdotNumber, required this.eldIdentifier, required this.eldRegistrationId, required this.driverId, required this.driverName, required this.inspectionDate, required this.cycleDaysCovered, required this.canStartInspection, required this.canSendLogs, required this.canEmailLogs, required this.canViewInformationPacket, required this.inspectionActive, required this.readOnlyMode, this.activeInspectionId, this.inspectorName});
  

@override final  String screenTitle;
@override final  String guidanceText;
@override final  String handOverDeviceNotice;
@override final  String carrierComplianceStatement;
@override final  String carrierName;
@override final  String usdotNumber;
@override final  String eldIdentifier;
@override final  String eldRegistrationId;
@override final  DriverId driverId;
@override final  String driverName;
@override final  DateTime inspectionDate;
@override final  int cycleDaysCovered;
@override final  bool canStartInspection;
@override final  bool canSendLogs;
@override final  bool canEmailLogs;
@override final  bool canViewInformationPacket;
@override final  bool inspectionActive;
@override final  bool readOnlyMode;
@override final  int? activeInspectionId;
@override final  String? inspectorName;

/// Create a copy of DotInspectionScreen
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DotInspectionScreenCopyWith<_DotInspectionScreen> get copyWith => __$DotInspectionScreenCopyWithImpl<_DotInspectionScreen>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DotInspectionScreen&&(identical(other.screenTitle, screenTitle) || other.screenTitle == screenTitle)&&(identical(other.guidanceText, guidanceText) || other.guidanceText == guidanceText)&&(identical(other.handOverDeviceNotice, handOverDeviceNotice) || other.handOverDeviceNotice == handOverDeviceNotice)&&(identical(other.carrierComplianceStatement, carrierComplianceStatement) || other.carrierComplianceStatement == carrierComplianceStatement)&&(identical(other.carrierName, carrierName) || other.carrierName == carrierName)&&(identical(other.usdotNumber, usdotNumber) || other.usdotNumber == usdotNumber)&&(identical(other.eldIdentifier, eldIdentifier) || other.eldIdentifier == eldIdentifier)&&(identical(other.eldRegistrationId, eldRegistrationId) || other.eldRegistrationId == eldRegistrationId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.inspectionDate, inspectionDate) || other.inspectionDate == inspectionDate)&&(identical(other.cycleDaysCovered, cycleDaysCovered) || other.cycleDaysCovered == cycleDaysCovered)&&(identical(other.canStartInspection, canStartInspection) || other.canStartInspection == canStartInspection)&&(identical(other.canSendLogs, canSendLogs) || other.canSendLogs == canSendLogs)&&(identical(other.canEmailLogs, canEmailLogs) || other.canEmailLogs == canEmailLogs)&&(identical(other.canViewInformationPacket, canViewInformationPacket) || other.canViewInformationPacket == canViewInformationPacket)&&(identical(other.inspectionActive, inspectionActive) || other.inspectionActive == inspectionActive)&&(identical(other.readOnlyMode, readOnlyMode) || other.readOnlyMode == readOnlyMode)&&(identical(other.activeInspectionId, activeInspectionId) || other.activeInspectionId == activeInspectionId)&&(identical(other.inspectorName, inspectorName) || other.inspectorName == inspectorName));
}


@override
int get hashCode => Object.hashAll([runtimeType,screenTitle,guidanceText,handOverDeviceNotice,carrierComplianceStatement,carrierName,usdotNumber,eldIdentifier,eldRegistrationId,driverId,driverName,inspectionDate,cycleDaysCovered,canStartInspection,canSendLogs,canEmailLogs,canViewInformationPacket,inspectionActive,readOnlyMode,activeInspectionId,inspectorName]);

@override
String toString() {
  return 'DotInspectionScreen(screenTitle: $screenTitle, guidanceText: $guidanceText, handOverDeviceNotice: $handOverDeviceNotice, carrierComplianceStatement: $carrierComplianceStatement, carrierName: $carrierName, usdotNumber: $usdotNumber, eldIdentifier: $eldIdentifier, eldRegistrationId: $eldRegistrationId, driverId: $driverId, driverName: $driverName, inspectionDate: $inspectionDate, cycleDaysCovered: $cycleDaysCovered, canStartInspection: $canStartInspection, canSendLogs: $canSendLogs, canEmailLogs: $canEmailLogs, canViewInformationPacket: $canViewInformationPacket, inspectionActive: $inspectionActive, readOnlyMode: $readOnlyMode, activeInspectionId: $activeInspectionId, inspectorName: $inspectorName)';
}


}

/// @nodoc
abstract mixin class _$DotInspectionScreenCopyWith<$Res> implements $DotInspectionScreenCopyWith<$Res> {
  factory _$DotInspectionScreenCopyWith(_DotInspectionScreen value, $Res Function(_DotInspectionScreen) _then) = __$DotInspectionScreenCopyWithImpl;
@override @useResult
$Res call({
 String screenTitle, String guidanceText, String handOverDeviceNotice, String carrierComplianceStatement, String carrierName, String usdotNumber, String eldIdentifier, String eldRegistrationId, DriverId driverId, String driverName, DateTime inspectionDate, int cycleDaysCovered, bool canStartInspection, bool canSendLogs, bool canEmailLogs, bool canViewInformationPacket, bool inspectionActive, bool readOnlyMode, int? activeInspectionId, String? inspectorName
});


@override $DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class __$DotInspectionScreenCopyWithImpl<$Res>
    implements _$DotInspectionScreenCopyWith<$Res> {
  __$DotInspectionScreenCopyWithImpl(this._self, this._then);

  final _DotInspectionScreen _self;
  final $Res Function(_DotInspectionScreen) _then;

/// Create a copy of DotInspectionScreen
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenTitle = null,Object? guidanceText = null,Object? handOverDeviceNotice = null,Object? carrierComplianceStatement = null,Object? carrierName = null,Object? usdotNumber = null,Object? eldIdentifier = null,Object? eldRegistrationId = null,Object? driverId = null,Object? driverName = null,Object? inspectionDate = null,Object? cycleDaysCovered = null,Object? canStartInspection = null,Object? canSendLogs = null,Object? canEmailLogs = null,Object? canViewInformationPacket = null,Object? inspectionActive = null,Object? readOnlyMode = null,Object? activeInspectionId = freezed,Object? inspectorName = freezed,}) {
  return _then(_DotInspectionScreen(
screenTitle: null == screenTitle ? _self.screenTitle : screenTitle // ignore: cast_nullable_to_non_nullable
as String,guidanceText: null == guidanceText ? _self.guidanceText : guidanceText // ignore: cast_nullable_to_non_nullable
as String,handOverDeviceNotice: null == handOverDeviceNotice ? _self.handOverDeviceNotice : handOverDeviceNotice // ignore: cast_nullable_to_non_nullable
as String,carrierComplianceStatement: null == carrierComplianceStatement ? _self.carrierComplianceStatement : carrierComplianceStatement // ignore: cast_nullable_to_non_nullable
as String,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,usdotNumber: null == usdotNumber ? _self.usdotNumber : usdotNumber // ignore: cast_nullable_to_non_nullable
as String,eldIdentifier: null == eldIdentifier ? _self.eldIdentifier : eldIdentifier // ignore: cast_nullable_to_non_nullable
as String,eldRegistrationId: null == eldRegistrationId ? _self.eldRegistrationId : eldRegistrationId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,inspectionDate: null == inspectionDate ? _self.inspectionDate : inspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime,cycleDaysCovered: null == cycleDaysCovered ? _self.cycleDaysCovered : cycleDaysCovered // ignore: cast_nullable_to_non_nullable
as int,canStartInspection: null == canStartInspection ? _self.canStartInspection : canStartInspection // ignore: cast_nullable_to_non_nullable
as bool,canSendLogs: null == canSendLogs ? _self.canSendLogs : canSendLogs // ignore: cast_nullable_to_non_nullable
as bool,canEmailLogs: null == canEmailLogs ? _self.canEmailLogs : canEmailLogs // ignore: cast_nullable_to_non_nullable
as bool,canViewInformationPacket: null == canViewInformationPacket ? _self.canViewInformationPacket : canViewInformationPacket // ignore: cast_nullable_to_non_nullable
as bool,inspectionActive: null == inspectionActive ? _self.inspectionActive : inspectionActive // ignore: cast_nullable_to_non_nullable
as bool,readOnlyMode: null == readOnlyMode ? _self.readOnlyMode : readOnlyMode // ignore: cast_nullable_to_non_nullable
as bool,activeInspectionId: freezed == activeInspectionId ? _self.activeInspectionId : activeInspectionId // ignore: cast_nullable_to_non_nullable
as int?,inspectorName: freezed == inspectorName ? _self.inspectorName : inspectorName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DotInspectionScreen
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}

/// @nodoc
mixin _$DotInspectionCycleDay {

 DriverId get driverId; String get driverName; DateTime get logDate; String get displayDate; String get displayLocation; bool get certified; DateTime? get certifiedAt; String get eldRegistrationId; String get eldIdentifier; String get eldProvider; String get vehicleNumber; String get uniqueId; String get vin; double get startOdometerKm; double get endOdometerKm; double get totalDistanceKm; double get engineHours; String get trailers; String get shippingDocuments; String get carrierName; String get usdotNumber; String get mainOfficeAddress; String get homeTerminalAddress; List<String> get activeDataDiagnostics; List<String> get activeDeviceMalfunctions; bool get exemptDriver; String? get exemptReason; bool get hasUnidentifiedDriving; int get unidentifiedDrivingCount;
/// Create a copy of DotInspectionCycleDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DotInspectionCycleDayCopyWith<DotInspectionCycleDay> get copyWith => _$DotInspectionCycleDayCopyWithImpl<DotInspectionCycleDay>(this as DotInspectionCycleDay, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DotInspectionCycleDay&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.logDate, logDate) || other.logDate == logDate)&&(identical(other.displayDate, displayDate) || other.displayDate == displayDate)&&(identical(other.displayLocation, displayLocation) || other.displayLocation == displayLocation)&&(identical(other.certified, certified) || other.certified == certified)&&(identical(other.certifiedAt, certifiedAt) || other.certifiedAt == certifiedAt)&&(identical(other.eldRegistrationId, eldRegistrationId) || other.eldRegistrationId == eldRegistrationId)&&(identical(other.eldIdentifier, eldIdentifier) || other.eldIdentifier == eldIdentifier)&&(identical(other.eldProvider, eldProvider) || other.eldProvider == eldProvider)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.uniqueId, uniqueId) || other.uniqueId == uniqueId)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.startOdometerKm, startOdometerKm) || other.startOdometerKm == startOdometerKm)&&(identical(other.endOdometerKm, endOdometerKm) || other.endOdometerKm == endOdometerKm)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.trailers, trailers) || other.trailers == trailers)&&(identical(other.shippingDocuments, shippingDocuments) || other.shippingDocuments == shippingDocuments)&&(identical(other.carrierName, carrierName) || other.carrierName == carrierName)&&(identical(other.usdotNumber, usdotNumber) || other.usdotNumber == usdotNumber)&&(identical(other.mainOfficeAddress, mainOfficeAddress) || other.mainOfficeAddress == mainOfficeAddress)&&(identical(other.homeTerminalAddress, homeTerminalAddress) || other.homeTerminalAddress == homeTerminalAddress)&&const DeepCollectionEquality().equals(other.activeDataDiagnostics, activeDataDiagnostics)&&const DeepCollectionEquality().equals(other.activeDeviceMalfunctions, activeDeviceMalfunctions)&&(identical(other.exemptDriver, exemptDriver) || other.exemptDriver == exemptDriver)&&(identical(other.exemptReason, exemptReason) || other.exemptReason == exemptReason)&&(identical(other.hasUnidentifiedDriving, hasUnidentifiedDriving) || other.hasUnidentifiedDriving == hasUnidentifiedDriving)&&(identical(other.unidentifiedDrivingCount, unidentifiedDrivingCount) || other.unidentifiedDrivingCount == unidentifiedDrivingCount));
}


@override
int get hashCode => Object.hashAll([runtimeType,driverId,driverName,logDate,displayDate,displayLocation,certified,certifiedAt,eldRegistrationId,eldIdentifier,eldProvider,vehicleNumber,uniqueId,vin,startOdometerKm,endOdometerKm,totalDistanceKm,engineHours,trailers,shippingDocuments,carrierName,usdotNumber,mainOfficeAddress,homeTerminalAddress,const DeepCollectionEquality().hash(activeDataDiagnostics),const DeepCollectionEquality().hash(activeDeviceMalfunctions),exemptDriver,exemptReason,hasUnidentifiedDriving,unidentifiedDrivingCount]);

@override
String toString() {
  return 'DotInspectionCycleDay(driverId: $driverId, driverName: $driverName, logDate: $logDate, displayDate: $displayDate, displayLocation: $displayLocation, certified: $certified, certifiedAt: $certifiedAt, eldRegistrationId: $eldRegistrationId, eldIdentifier: $eldIdentifier, eldProvider: $eldProvider, vehicleNumber: $vehicleNumber, uniqueId: $uniqueId, vin: $vin, startOdometerKm: $startOdometerKm, endOdometerKm: $endOdometerKm, totalDistanceKm: $totalDistanceKm, engineHours: $engineHours, trailers: $trailers, shippingDocuments: $shippingDocuments, carrierName: $carrierName, usdotNumber: $usdotNumber, mainOfficeAddress: $mainOfficeAddress, homeTerminalAddress: $homeTerminalAddress, activeDataDiagnostics: $activeDataDiagnostics, activeDeviceMalfunctions: $activeDeviceMalfunctions, exemptDriver: $exemptDriver, exemptReason: $exemptReason, hasUnidentifiedDriving: $hasUnidentifiedDriving, unidentifiedDrivingCount: $unidentifiedDrivingCount)';
}


}

/// @nodoc
abstract mixin class $DotInspectionCycleDayCopyWith<$Res>  {
  factory $DotInspectionCycleDayCopyWith(DotInspectionCycleDay value, $Res Function(DotInspectionCycleDay) _then) = _$DotInspectionCycleDayCopyWithImpl;
@useResult
$Res call({
 DriverId driverId, String driverName, DateTime logDate, String displayDate, String displayLocation, bool certified, DateTime? certifiedAt, String eldRegistrationId, String eldIdentifier, String eldProvider, String vehicleNumber, String uniqueId, String vin, double startOdometerKm, double endOdometerKm, double totalDistanceKm, double engineHours, String trailers, String shippingDocuments, String carrierName, String usdotNumber, String mainOfficeAddress, String homeTerminalAddress, List<String> activeDataDiagnostics, List<String> activeDeviceMalfunctions, bool exemptDriver, String? exemptReason, bool hasUnidentifiedDriving, int unidentifiedDrivingCount
});


$DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class _$DotInspectionCycleDayCopyWithImpl<$Res>
    implements $DotInspectionCycleDayCopyWith<$Res> {
  _$DotInspectionCycleDayCopyWithImpl(this._self, this._then);

  final DotInspectionCycleDay _self;
  final $Res Function(DotInspectionCycleDay) _then;

/// Create a copy of DotInspectionCycleDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? driverName = null,Object? logDate = null,Object? displayDate = null,Object? displayLocation = null,Object? certified = null,Object? certifiedAt = freezed,Object? eldRegistrationId = null,Object? eldIdentifier = null,Object? eldProvider = null,Object? vehicleNumber = null,Object? uniqueId = null,Object? vin = null,Object? startOdometerKm = null,Object? endOdometerKm = null,Object? totalDistanceKm = null,Object? engineHours = null,Object? trailers = null,Object? shippingDocuments = null,Object? carrierName = null,Object? usdotNumber = null,Object? mainOfficeAddress = null,Object? homeTerminalAddress = null,Object? activeDataDiagnostics = null,Object? activeDeviceMalfunctions = null,Object? exemptDriver = null,Object? exemptReason = freezed,Object? hasUnidentifiedDriving = null,Object? unidentifiedDrivingCount = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,logDate: null == logDate ? _self.logDate : logDate // ignore: cast_nullable_to_non_nullable
as DateTime,displayDate: null == displayDate ? _self.displayDate : displayDate // ignore: cast_nullable_to_non_nullable
as String,displayLocation: null == displayLocation ? _self.displayLocation : displayLocation // ignore: cast_nullable_to_non_nullable
as String,certified: null == certified ? _self.certified : certified // ignore: cast_nullable_to_non_nullable
as bool,certifiedAt: freezed == certifiedAt ? _self.certifiedAt : certifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,eldRegistrationId: null == eldRegistrationId ? _self.eldRegistrationId : eldRegistrationId // ignore: cast_nullable_to_non_nullable
as String,eldIdentifier: null == eldIdentifier ? _self.eldIdentifier : eldIdentifier // ignore: cast_nullable_to_non_nullable
as String,eldProvider: null == eldProvider ? _self.eldProvider : eldProvider // ignore: cast_nullable_to_non_nullable
as String,vehicleNumber: null == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String,uniqueId: null == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String,vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,startOdometerKm: null == startOdometerKm ? _self.startOdometerKm : startOdometerKm // ignore: cast_nullable_to_non_nullable
as double,endOdometerKm: null == endOdometerKm ? _self.endOdometerKm : endOdometerKm // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,engineHours: null == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double,trailers: null == trailers ? _self.trailers : trailers // ignore: cast_nullable_to_non_nullable
as String,shippingDocuments: null == shippingDocuments ? _self.shippingDocuments : shippingDocuments // ignore: cast_nullable_to_non_nullable
as String,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,usdotNumber: null == usdotNumber ? _self.usdotNumber : usdotNumber // ignore: cast_nullable_to_non_nullable
as String,mainOfficeAddress: null == mainOfficeAddress ? _self.mainOfficeAddress : mainOfficeAddress // ignore: cast_nullable_to_non_nullable
as String,homeTerminalAddress: null == homeTerminalAddress ? _self.homeTerminalAddress : homeTerminalAddress // ignore: cast_nullable_to_non_nullable
as String,activeDataDiagnostics: null == activeDataDiagnostics ? _self.activeDataDiagnostics : activeDataDiagnostics // ignore: cast_nullable_to_non_nullable
as List<String>,activeDeviceMalfunctions: null == activeDeviceMalfunctions ? _self.activeDeviceMalfunctions : activeDeviceMalfunctions // ignore: cast_nullable_to_non_nullable
as List<String>,exemptDriver: null == exemptDriver ? _self.exemptDriver : exemptDriver // ignore: cast_nullable_to_non_nullable
as bool,exemptReason: freezed == exemptReason ? _self.exemptReason : exemptReason // ignore: cast_nullable_to_non_nullable
as String?,hasUnidentifiedDriving: null == hasUnidentifiedDriving ? _self.hasUnidentifiedDriving : hasUnidentifiedDriving // ignore: cast_nullable_to_non_nullable
as bool,unidentifiedDrivingCount: null == unidentifiedDrivingCount ? _self.unidentifiedDrivingCount : unidentifiedDrivingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of DotInspectionCycleDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}


/// @nodoc


class _DotInspectionCycleDay implements DotInspectionCycleDay {
  const _DotInspectionCycleDay({required this.driverId, required this.driverName, required this.logDate, required this.displayDate, required this.displayLocation, required this.certified, required this.certifiedAt, required this.eldRegistrationId, required this.eldIdentifier, required this.eldProvider, required this.vehicleNumber, required this.uniqueId, required this.vin, required this.startOdometerKm, required this.endOdometerKm, required this.totalDistanceKm, required this.engineHours, required this.trailers, required this.shippingDocuments, required this.carrierName, required this.usdotNumber, required this.mainOfficeAddress, required this.homeTerminalAddress, required final  List<String> activeDataDiagnostics, required final  List<String> activeDeviceMalfunctions, required this.exemptDriver, this.exemptReason, required this.hasUnidentifiedDriving, required this.unidentifiedDrivingCount}): _activeDataDiagnostics = activeDataDiagnostics,_activeDeviceMalfunctions = activeDeviceMalfunctions;
  

@override final  DriverId driverId;
@override final  String driverName;
@override final  DateTime logDate;
@override final  String displayDate;
@override final  String displayLocation;
@override final  bool certified;
@override final  DateTime? certifiedAt;
@override final  String eldRegistrationId;
@override final  String eldIdentifier;
@override final  String eldProvider;
@override final  String vehicleNumber;
@override final  String uniqueId;
@override final  String vin;
@override final  double startOdometerKm;
@override final  double endOdometerKm;
@override final  double totalDistanceKm;
@override final  double engineHours;
@override final  String trailers;
@override final  String shippingDocuments;
@override final  String carrierName;
@override final  String usdotNumber;
@override final  String mainOfficeAddress;
@override final  String homeTerminalAddress;
 final  List<String> _activeDataDiagnostics;
@override List<String> get activeDataDiagnostics {
  if (_activeDataDiagnostics is EqualUnmodifiableListView) return _activeDataDiagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeDataDiagnostics);
}

 final  List<String> _activeDeviceMalfunctions;
@override List<String> get activeDeviceMalfunctions {
  if (_activeDeviceMalfunctions is EqualUnmodifiableListView) return _activeDeviceMalfunctions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeDeviceMalfunctions);
}

@override final  bool exemptDriver;
@override final  String? exemptReason;
@override final  bool hasUnidentifiedDriving;
@override final  int unidentifiedDrivingCount;

/// Create a copy of DotInspectionCycleDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DotInspectionCycleDayCopyWith<_DotInspectionCycleDay> get copyWith => __$DotInspectionCycleDayCopyWithImpl<_DotInspectionCycleDay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DotInspectionCycleDay&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.logDate, logDate) || other.logDate == logDate)&&(identical(other.displayDate, displayDate) || other.displayDate == displayDate)&&(identical(other.displayLocation, displayLocation) || other.displayLocation == displayLocation)&&(identical(other.certified, certified) || other.certified == certified)&&(identical(other.certifiedAt, certifiedAt) || other.certifiedAt == certifiedAt)&&(identical(other.eldRegistrationId, eldRegistrationId) || other.eldRegistrationId == eldRegistrationId)&&(identical(other.eldIdentifier, eldIdentifier) || other.eldIdentifier == eldIdentifier)&&(identical(other.eldProvider, eldProvider) || other.eldProvider == eldProvider)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.uniqueId, uniqueId) || other.uniqueId == uniqueId)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.startOdometerKm, startOdometerKm) || other.startOdometerKm == startOdometerKm)&&(identical(other.endOdometerKm, endOdometerKm) || other.endOdometerKm == endOdometerKm)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.trailers, trailers) || other.trailers == trailers)&&(identical(other.shippingDocuments, shippingDocuments) || other.shippingDocuments == shippingDocuments)&&(identical(other.carrierName, carrierName) || other.carrierName == carrierName)&&(identical(other.usdotNumber, usdotNumber) || other.usdotNumber == usdotNumber)&&(identical(other.mainOfficeAddress, mainOfficeAddress) || other.mainOfficeAddress == mainOfficeAddress)&&(identical(other.homeTerminalAddress, homeTerminalAddress) || other.homeTerminalAddress == homeTerminalAddress)&&const DeepCollectionEquality().equals(other._activeDataDiagnostics, _activeDataDiagnostics)&&const DeepCollectionEquality().equals(other._activeDeviceMalfunctions, _activeDeviceMalfunctions)&&(identical(other.exemptDriver, exemptDriver) || other.exemptDriver == exemptDriver)&&(identical(other.exemptReason, exemptReason) || other.exemptReason == exemptReason)&&(identical(other.hasUnidentifiedDriving, hasUnidentifiedDriving) || other.hasUnidentifiedDriving == hasUnidentifiedDriving)&&(identical(other.unidentifiedDrivingCount, unidentifiedDrivingCount) || other.unidentifiedDrivingCount == unidentifiedDrivingCount));
}


@override
int get hashCode => Object.hashAll([runtimeType,driverId,driverName,logDate,displayDate,displayLocation,certified,certifiedAt,eldRegistrationId,eldIdentifier,eldProvider,vehicleNumber,uniqueId,vin,startOdometerKm,endOdometerKm,totalDistanceKm,engineHours,trailers,shippingDocuments,carrierName,usdotNumber,mainOfficeAddress,homeTerminalAddress,const DeepCollectionEquality().hash(_activeDataDiagnostics),const DeepCollectionEquality().hash(_activeDeviceMalfunctions),exemptDriver,exemptReason,hasUnidentifiedDriving,unidentifiedDrivingCount]);

@override
String toString() {
  return 'DotInspectionCycleDay(driverId: $driverId, driverName: $driverName, logDate: $logDate, displayDate: $displayDate, displayLocation: $displayLocation, certified: $certified, certifiedAt: $certifiedAt, eldRegistrationId: $eldRegistrationId, eldIdentifier: $eldIdentifier, eldProvider: $eldProvider, vehicleNumber: $vehicleNumber, uniqueId: $uniqueId, vin: $vin, startOdometerKm: $startOdometerKm, endOdometerKm: $endOdometerKm, totalDistanceKm: $totalDistanceKm, engineHours: $engineHours, trailers: $trailers, shippingDocuments: $shippingDocuments, carrierName: $carrierName, usdotNumber: $usdotNumber, mainOfficeAddress: $mainOfficeAddress, homeTerminalAddress: $homeTerminalAddress, activeDataDiagnostics: $activeDataDiagnostics, activeDeviceMalfunctions: $activeDeviceMalfunctions, exemptDriver: $exemptDriver, exemptReason: $exemptReason, hasUnidentifiedDriving: $hasUnidentifiedDriving, unidentifiedDrivingCount: $unidentifiedDrivingCount)';
}


}

/// @nodoc
abstract mixin class _$DotInspectionCycleDayCopyWith<$Res> implements $DotInspectionCycleDayCopyWith<$Res> {
  factory _$DotInspectionCycleDayCopyWith(_DotInspectionCycleDay value, $Res Function(_DotInspectionCycleDay) _then) = __$DotInspectionCycleDayCopyWithImpl;
@override @useResult
$Res call({
 DriverId driverId, String driverName, DateTime logDate, String displayDate, String displayLocation, bool certified, DateTime? certifiedAt, String eldRegistrationId, String eldIdentifier, String eldProvider, String vehicleNumber, String uniqueId, String vin, double startOdometerKm, double endOdometerKm, double totalDistanceKm, double engineHours, String trailers, String shippingDocuments, String carrierName, String usdotNumber, String mainOfficeAddress, String homeTerminalAddress, List<String> activeDataDiagnostics, List<String> activeDeviceMalfunctions, bool exemptDriver, String? exemptReason, bool hasUnidentifiedDriving, int unidentifiedDrivingCount
});


@override $DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class __$DotInspectionCycleDayCopyWithImpl<$Res>
    implements _$DotInspectionCycleDayCopyWith<$Res> {
  __$DotInspectionCycleDayCopyWithImpl(this._self, this._then);

  final _DotInspectionCycleDay _self;
  final $Res Function(_DotInspectionCycleDay) _then;

/// Create a copy of DotInspectionCycleDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? driverName = null,Object? logDate = null,Object? displayDate = null,Object? displayLocation = null,Object? certified = null,Object? certifiedAt = freezed,Object? eldRegistrationId = null,Object? eldIdentifier = null,Object? eldProvider = null,Object? vehicleNumber = null,Object? uniqueId = null,Object? vin = null,Object? startOdometerKm = null,Object? endOdometerKm = null,Object? totalDistanceKm = null,Object? engineHours = null,Object? trailers = null,Object? shippingDocuments = null,Object? carrierName = null,Object? usdotNumber = null,Object? mainOfficeAddress = null,Object? homeTerminalAddress = null,Object? activeDataDiagnostics = null,Object? activeDeviceMalfunctions = null,Object? exemptDriver = null,Object? exemptReason = freezed,Object? hasUnidentifiedDriving = null,Object? unidentifiedDrivingCount = null,}) {
  return _then(_DotInspectionCycleDay(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,logDate: null == logDate ? _self.logDate : logDate // ignore: cast_nullable_to_non_nullable
as DateTime,displayDate: null == displayDate ? _self.displayDate : displayDate // ignore: cast_nullable_to_non_nullable
as String,displayLocation: null == displayLocation ? _self.displayLocation : displayLocation // ignore: cast_nullable_to_non_nullable
as String,certified: null == certified ? _self.certified : certified // ignore: cast_nullable_to_non_nullable
as bool,certifiedAt: freezed == certifiedAt ? _self.certifiedAt : certifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,eldRegistrationId: null == eldRegistrationId ? _self.eldRegistrationId : eldRegistrationId // ignore: cast_nullable_to_non_nullable
as String,eldIdentifier: null == eldIdentifier ? _self.eldIdentifier : eldIdentifier // ignore: cast_nullable_to_non_nullable
as String,eldProvider: null == eldProvider ? _self.eldProvider : eldProvider // ignore: cast_nullable_to_non_nullable
as String,vehicleNumber: null == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String,uniqueId: null == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String,vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,startOdometerKm: null == startOdometerKm ? _self.startOdometerKm : startOdometerKm // ignore: cast_nullable_to_non_nullable
as double,endOdometerKm: null == endOdometerKm ? _self.endOdometerKm : endOdometerKm // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,engineHours: null == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double,trailers: null == trailers ? _self.trailers : trailers // ignore: cast_nullable_to_non_nullable
as String,shippingDocuments: null == shippingDocuments ? _self.shippingDocuments : shippingDocuments // ignore: cast_nullable_to_non_nullable
as String,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,usdotNumber: null == usdotNumber ? _self.usdotNumber : usdotNumber // ignore: cast_nullable_to_non_nullable
as String,mainOfficeAddress: null == mainOfficeAddress ? _self.mainOfficeAddress : mainOfficeAddress // ignore: cast_nullable_to_non_nullable
as String,homeTerminalAddress: null == homeTerminalAddress ? _self.homeTerminalAddress : homeTerminalAddress // ignore: cast_nullable_to_non_nullable
as String,activeDataDiagnostics: null == activeDataDiagnostics ? _self._activeDataDiagnostics : activeDataDiagnostics // ignore: cast_nullable_to_non_nullable
as List<String>,activeDeviceMalfunctions: null == activeDeviceMalfunctions ? _self._activeDeviceMalfunctions : activeDeviceMalfunctions // ignore: cast_nullable_to_non_nullable
as List<String>,exemptDriver: null == exemptDriver ? _self.exemptDriver : exemptDriver // ignore: cast_nullable_to_non_nullable
as bool,exemptReason: freezed == exemptReason ? _self.exemptReason : exemptReason // ignore: cast_nullable_to_non_nullable
as String?,hasUnidentifiedDriving: null == hasUnidentifiedDriving ? _self.hasUnidentifiedDriving : hasUnidentifiedDriving // ignore: cast_nullable_to_non_nullable
as bool,unidentifiedDrivingCount: null == unidentifiedDrivingCount ? _self.unidentifiedDrivingCount : unidentifiedDrivingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of DotInspectionCycleDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}

/// @nodoc
mixin _$DotInspectionLog {

 DriverId get driverId; String get driverName; DateTime get logDate; String get displayDate; String get displayLocation; bool get certified; DateTime? get certifiedAt; String get eldRegistrationId; String get eldIdentifier; String get eldProvider; String get vehicleNumber; String get uniqueId; String get vin; double get startOdometerKm; double get endOdometerKm; double get totalDistanceKm; double get engineHours; String get trailers; String get shippingDocuments; String get carrierName; String get usdotNumber; String get mainOfficeAddress; String get homeTerminalAddress; List<String> get activeDataDiagnostics; List<String> get activeDeviceMalfunctions; List<DotInspectionEvent> get events; bool get readOnly;/// Home-terminal 24-hour period start (`period24HourStartTime`, `HH:mm`).
/// Optional in the wire contract; `null` renders as "—".
 String? get period24HourStartTime;/// From the log's own `driver` / `coDriver` (`DriverResponse`) — the
/// roadside header must come from the record, not the live account.
 String? get driverLicenseNumber; String? get driverLicenseState; String? get coDriverName; int? get coDriverId;
/// Create a copy of DotInspectionLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DotInspectionLogCopyWith<DotInspectionLog> get copyWith => _$DotInspectionLogCopyWithImpl<DotInspectionLog>(this as DotInspectionLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DotInspectionLog&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.logDate, logDate) || other.logDate == logDate)&&(identical(other.displayDate, displayDate) || other.displayDate == displayDate)&&(identical(other.displayLocation, displayLocation) || other.displayLocation == displayLocation)&&(identical(other.certified, certified) || other.certified == certified)&&(identical(other.certifiedAt, certifiedAt) || other.certifiedAt == certifiedAt)&&(identical(other.eldRegistrationId, eldRegistrationId) || other.eldRegistrationId == eldRegistrationId)&&(identical(other.eldIdentifier, eldIdentifier) || other.eldIdentifier == eldIdentifier)&&(identical(other.eldProvider, eldProvider) || other.eldProvider == eldProvider)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.uniqueId, uniqueId) || other.uniqueId == uniqueId)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.startOdometerKm, startOdometerKm) || other.startOdometerKm == startOdometerKm)&&(identical(other.endOdometerKm, endOdometerKm) || other.endOdometerKm == endOdometerKm)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.trailers, trailers) || other.trailers == trailers)&&(identical(other.shippingDocuments, shippingDocuments) || other.shippingDocuments == shippingDocuments)&&(identical(other.carrierName, carrierName) || other.carrierName == carrierName)&&(identical(other.usdotNumber, usdotNumber) || other.usdotNumber == usdotNumber)&&(identical(other.mainOfficeAddress, mainOfficeAddress) || other.mainOfficeAddress == mainOfficeAddress)&&(identical(other.homeTerminalAddress, homeTerminalAddress) || other.homeTerminalAddress == homeTerminalAddress)&&const DeepCollectionEquality().equals(other.activeDataDiagnostics, activeDataDiagnostics)&&const DeepCollectionEquality().equals(other.activeDeviceMalfunctions, activeDeviceMalfunctions)&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.period24HourStartTime, period24HourStartTime) || other.period24HourStartTime == period24HourStartTime)&&(identical(other.driverLicenseNumber, driverLicenseNumber) || other.driverLicenseNumber == driverLicenseNumber)&&(identical(other.driverLicenseState, driverLicenseState) || other.driverLicenseState == driverLicenseState)&&(identical(other.coDriverName, coDriverName) || other.coDriverName == coDriverName)&&(identical(other.coDriverId, coDriverId) || other.coDriverId == coDriverId));
}


@override
int get hashCode => Object.hashAll([runtimeType,driverId,driverName,logDate,displayDate,displayLocation,certified,certifiedAt,eldRegistrationId,eldIdentifier,eldProvider,vehicleNumber,uniqueId,vin,startOdometerKm,endOdometerKm,totalDistanceKm,engineHours,trailers,shippingDocuments,carrierName,usdotNumber,mainOfficeAddress,homeTerminalAddress,const DeepCollectionEquality().hash(activeDataDiagnostics),const DeepCollectionEquality().hash(activeDeviceMalfunctions),const DeepCollectionEquality().hash(events),readOnly,period24HourStartTime,driverLicenseNumber,driverLicenseState,coDriverName,coDriverId]);

@override
String toString() {
  return 'DotInspectionLog(driverId: $driverId, driverName: $driverName, logDate: $logDate, displayDate: $displayDate, displayLocation: $displayLocation, certified: $certified, certifiedAt: $certifiedAt, eldRegistrationId: $eldRegistrationId, eldIdentifier: $eldIdentifier, eldProvider: $eldProvider, vehicleNumber: $vehicleNumber, uniqueId: $uniqueId, vin: $vin, startOdometerKm: $startOdometerKm, endOdometerKm: $endOdometerKm, totalDistanceKm: $totalDistanceKm, engineHours: $engineHours, trailers: $trailers, shippingDocuments: $shippingDocuments, carrierName: $carrierName, usdotNumber: $usdotNumber, mainOfficeAddress: $mainOfficeAddress, homeTerminalAddress: $homeTerminalAddress, activeDataDiagnostics: $activeDataDiagnostics, activeDeviceMalfunctions: $activeDeviceMalfunctions, events: $events, readOnly: $readOnly, period24HourStartTime: $period24HourStartTime, driverLicenseNumber: $driverLicenseNumber, driverLicenseState: $driverLicenseState, coDriverName: $coDriverName, coDriverId: $coDriverId)';
}


}

/// @nodoc
abstract mixin class $DotInspectionLogCopyWith<$Res>  {
  factory $DotInspectionLogCopyWith(DotInspectionLog value, $Res Function(DotInspectionLog) _then) = _$DotInspectionLogCopyWithImpl;
@useResult
$Res call({
 DriverId driverId, String driverName, DateTime logDate, String displayDate, String displayLocation, bool certified, DateTime? certifiedAt, String eldRegistrationId, String eldIdentifier, String eldProvider, String vehicleNumber, String uniqueId, String vin, double startOdometerKm, double endOdometerKm, double totalDistanceKm, double engineHours, String trailers, String shippingDocuments, String carrierName, String usdotNumber, String mainOfficeAddress, String homeTerminalAddress, List<String> activeDataDiagnostics, List<String> activeDeviceMalfunctions, List<DotInspectionEvent> events, bool readOnly, String? period24HourStartTime, String? driverLicenseNumber, String? driverLicenseState, String? coDriverName, int? coDriverId
});


$DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class _$DotInspectionLogCopyWithImpl<$Res>
    implements $DotInspectionLogCopyWith<$Res> {
  _$DotInspectionLogCopyWithImpl(this._self, this._then);

  final DotInspectionLog _self;
  final $Res Function(DotInspectionLog) _then;

/// Create a copy of DotInspectionLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? driverName = null,Object? logDate = null,Object? displayDate = null,Object? displayLocation = null,Object? certified = null,Object? certifiedAt = freezed,Object? eldRegistrationId = null,Object? eldIdentifier = null,Object? eldProvider = null,Object? vehicleNumber = null,Object? uniqueId = null,Object? vin = null,Object? startOdometerKm = null,Object? endOdometerKm = null,Object? totalDistanceKm = null,Object? engineHours = null,Object? trailers = null,Object? shippingDocuments = null,Object? carrierName = null,Object? usdotNumber = null,Object? mainOfficeAddress = null,Object? homeTerminalAddress = null,Object? activeDataDiagnostics = null,Object? activeDeviceMalfunctions = null,Object? events = null,Object? readOnly = null,Object? period24HourStartTime = freezed,Object? driverLicenseNumber = freezed,Object? driverLicenseState = freezed,Object? coDriverName = freezed,Object? coDriverId = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,logDate: null == logDate ? _self.logDate : logDate // ignore: cast_nullable_to_non_nullable
as DateTime,displayDate: null == displayDate ? _self.displayDate : displayDate // ignore: cast_nullable_to_non_nullable
as String,displayLocation: null == displayLocation ? _self.displayLocation : displayLocation // ignore: cast_nullable_to_non_nullable
as String,certified: null == certified ? _self.certified : certified // ignore: cast_nullable_to_non_nullable
as bool,certifiedAt: freezed == certifiedAt ? _self.certifiedAt : certifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,eldRegistrationId: null == eldRegistrationId ? _self.eldRegistrationId : eldRegistrationId // ignore: cast_nullable_to_non_nullable
as String,eldIdentifier: null == eldIdentifier ? _self.eldIdentifier : eldIdentifier // ignore: cast_nullable_to_non_nullable
as String,eldProvider: null == eldProvider ? _self.eldProvider : eldProvider // ignore: cast_nullable_to_non_nullable
as String,vehicleNumber: null == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String,uniqueId: null == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String,vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,startOdometerKm: null == startOdometerKm ? _self.startOdometerKm : startOdometerKm // ignore: cast_nullable_to_non_nullable
as double,endOdometerKm: null == endOdometerKm ? _self.endOdometerKm : endOdometerKm // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,engineHours: null == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double,trailers: null == trailers ? _self.trailers : trailers // ignore: cast_nullable_to_non_nullable
as String,shippingDocuments: null == shippingDocuments ? _self.shippingDocuments : shippingDocuments // ignore: cast_nullable_to_non_nullable
as String,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,usdotNumber: null == usdotNumber ? _self.usdotNumber : usdotNumber // ignore: cast_nullable_to_non_nullable
as String,mainOfficeAddress: null == mainOfficeAddress ? _self.mainOfficeAddress : mainOfficeAddress // ignore: cast_nullable_to_non_nullable
as String,homeTerminalAddress: null == homeTerminalAddress ? _self.homeTerminalAddress : homeTerminalAddress // ignore: cast_nullable_to_non_nullable
as String,activeDataDiagnostics: null == activeDataDiagnostics ? _self.activeDataDiagnostics : activeDataDiagnostics // ignore: cast_nullable_to_non_nullable
as List<String>,activeDeviceMalfunctions: null == activeDeviceMalfunctions ? _self.activeDeviceMalfunctions : activeDeviceMalfunctions // ignore: cast_nullable_to_non_nullable
as List<String>,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<DotInspectionEvent>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,period24HourStartTime: freezed == period24HourStartTime ? _self.period24HourStartTime : period24HourStartTime // ignore: cast_nullable_to_non_nullable
as String?,driverLicenseNumber: freezed == driverLicenseNumber ? _self.driverLicenseNumber : driverLicenseNumber // ignore: cast_nullable_to_non_nullable
as String?,driverLicenseState: freezed == driverLicenseState ? _self.driverLicenseState : driverLicenseState // ignore: cast_nullable_to_non_nullable
as String?,coDriverName: freezed == coDriverName ? _self.coDriverName : coDriverName // ignore: cast_nullable_to_non_nullable
as String?,coDriverId: freezed == coDriverId ? _self.coDriverId : coDriverId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of DotInspectionLog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}


/// @nodoc


class _DotInspectionLog implements DotInspectionLog {
  const _DotInspectionLog({required this.driverId, required this.driverName, required this.logDate, required this.displayDate, required this.displayLocation, required this.certified, required this.certifiedAt, required this.eldRegistrationId, required this.eldIdentifier, required this.eldProvider, required this.vehicleNumber, required this.uniqueId, required this.vin, required this.startOdometerKm, required this.endOdometerKm, required this.totalDistanceKm, required this.engineHours, required this.trailers, required this.shippingDocuments, required this.carrierName, required this.usdotNumber, required this.mainOfficeAddress, required this.homeTerminalAddress, required final  List<String> activeDataDiagnostics, required final  List<String> activeDeviceMalfunctions, required final  List<DotInspectionEvent> events, required this.readOnly, this.period24HourStartTime, this.driverLicenseNumber, this.driverLicenseState, this.coDriverName, this.coDriverId}): _activeDataDiagnostics = activeDataDiagnostics,_activeDeviceMalfunctions = activeDeviceMalfunctions,_events = events;
  

@override final  DriverId driverId;
@override final  String driverName;
@override final  DateTime logDate;
@override final  String displayDate;
@override final  String displayLocation;
@override final  bool certified;
@override final  DateTime? certifiedAt;
@override final  String eldRegistrationId;
@override final  String eldIdentifier;
@override final  String eldProvider;
@override final  String vehicleNumber;
@override final  String uniqueId;
@override final  String vin;
@override final  double startOdometerKm;
@override final  double endOdometerKm;
@override final  double totalDistanceKm;
@override final  double engineHours;
@override final  String trailers;
@override final  String shippingDocuments;
@override final  String carrierName;
@override final  String usdotNumber;
@override final  String mainOfficeAddress;
@override final  String homeTerminalAddress;
 final  List<String> _activeDataDiagnostics;
@override List<String> get activeDataDiagnostics {
  if (_activeDataDiagnostics is EqualUnmodifiableListView) return _activeDataDiagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeDataDiagnostics);
}

 final  List<String> _activeDeviceMalfunctions;
@override List<String> get activeDeviceMalfunctions {
  if (_activeDeviceMalfunctions is EqualUnmodifiableListView) return _activeDeviceMalfunctions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeDeviceMalfunctions);
}

 final  List<DotInspectionEvent> _events;
@override List<DotInspectionEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override final  bool readOnly;
/// Home-terminal 24-hour period start (`period24HourStartTime`, `HH:mm`).
/// Optional in the wire contract; `null` renders as "—".
@override final  String? period24HourStartTime;
/// From the log's own `driver` / `coDriver` (`DriverResponse`) — the
/// roadside header must come from the record, not the live account.
@override final  String? driverLicenseNumber;
@override final  String? driverLicenseState;
@override final  String? coDriverName;
@override final  int? coDriverId;

/// Create a copy of DotInspectionLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DotInspectionLogCopyWith<_DotInspectionLog> get copyWith => __$DotInspectionLogCopyWithImpl<_DotInspectionLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DotInspectionLog&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.logDate, logDate) || other.logDate == logDate)&&(identical(other.displayDate, displayDate) || other.displayDate == displayDate)&&(identical(other.displayLocation, displayLocation) || other.displayLocation == displayLocation)&&(identical(other.certified, certified) || other.certified == certified)&&(identical(other.certifiedAt, certifiedAt) || other.certifiedAt == certifiedAt)&&(identical(other.eldRegistrationId, eldRegistrationId) || other.eldRegistrationId == eldRegistrationId)&&(identical(other.eldIdentifier, eldIdentifier) || other.eldIdentifier == eldIdentifier)&&(identical(other.eldProvider, eldProvider) || other.eldProvider == eldProvider)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.uniqueId, uniqueId) || other.uniqueId == uniqueId)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.startOdometerKm, startOdometerKm) || other.startOdometerKm == startOdometerKm)&&(identical(other.endOdometerKm, endOdometerKm) || other.endOdometerKm == endOdometerKm)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.trailers, trailers) || other.trailers == trailers)&&(identical(other.shippingDocuments, shippingDocuments) || other.shippingDocuments == shippingDocuments)&&(identical(other.carrierName, carrierName) || other.carrierName == carrierName)&&(identical(other.usdotNumber, usdotNumber) || other.usdotNumber == usdotNumber)&&(identical(other.mainOfficeAddress, mainOfficeAddress) || other.mainOfficeAddress == mainOfficeAddress)&&(identical(other.homeTerminalAddress, homeTerminalAddress) || other.homeTerminalAddress == homeTerminalAddress)&&const DeepCollectionEquality().equals(other._activeDataDiagnostics, _activeDataDiagnostics)&&const DeepCollectionEquality().equals(other._activeDeviceMalfunctions, _activeDeviceMalfunctions)&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.period24HourStartTime, period24HourStartTime) || other.period24HourStartTime == period24HourStartTime)&&(identical(other.driverLicenseNumber, driverLicenseNumber) || other.driverLicenseNumber == driverLicenseNumber)&&(identical(other.driverLicenseState, driverLicenseState) || other.driverLicenseState == driverLicenseState)&&(identical(other.coDriverName, coDriverName) || other.coDriverName == coDriverName)&&(identical(other.coDriverId, coDriverId) || other.coDriverId == coDriverId));
}


@override
int get hashCode => Object.hashAll([runtimeType,driverId,driverName,logDate,displayDate,displayLocation,certified,certifiedAt,eldRegistrationId,eldIdentifier,eldProvider,vehicleNumber,uniqueId,vin,startOdometerKm,endOdometerKm,totalDistanceKm,engineHours,trailers,shippingDocuments,carrierName,usdotNumber,mainOfficeAddress,homeTerminalAddress,const DeepCollectionEquality().hash(_activeDataDiagnostics),const DeepCollectionEquality().hash(_activeDeviceMalfunctions),const DeepCollectionEquality().hash(_events),readOnly,period24HourStartTime,driverLicenseNumber,driverLicenseState,coDriverName,coDriverId]);

@override
String toString() {
  return 'DotInspectionLog(driverId: $driverId, driverName: $driverName, logDate: $logDate, displayDate: $displayDate, displayLocation: $displayLocation, certified: $certified, certifiedAt: $certifiedAt, eldRegistrationId: $eldRegistrationId, eldIdentifier: $eldIdentifier, eldProvider: $eldProvider, vehicleNumber: $vehicleNumber, uniqueId: $uniqueId, vin: $vin, startOdometerKm: $startOdometerKm, endOdometerKm: $endOdometerKm, totalDistanceKm: $totalDistanceKm, engineHours: $engineHours, trailers: $trailers, shippingDocuments: $shippingDocuments, carrierName: $carrierName, usdotNumber: $usdotNumber, mainOfficeAddress: $mainOfficeAddress, homeTerminalAddress: $homeTerminalAddress, activeDataDiagnostics: $activeDataDiagnostics, activeDeviceMalfunctions: $activeDeviceMalfunctions, events: $events, readOnly: $readOnly, period24HourStartTime: $period24HourStartTime, driverLicenseNumber: $driverLicenseNumber, driverLicenseState: $driverLicenseState, coDriverName: $coDriverName, coDriverId: $coDriverId)';
}


}

/// @nodoc
abstract mixin class _$DotInspectionLogCopyWith<$Res> implements $DotInspectionLogCopyWith<$Res> {
  factory _$DotInspectionLogCopyWith(_DotInspectionLog value, $Res Function(_DotInspectionLog) _then) = __$DotInspectionLogCopyWithImpl;
@override @useResult
$Res call({
 DriverId driverId, String driverName, DateTime logDate, String displayDate, String displayLocation, bool certified, DateTime? certifiedAt, String eldRegistrationId, String eldIdentifier, String eldProvider, String vehicleNumber, String uniqueId, String vin, double startOdometerKm, double endOdometerKm, double totalDistanceKm, double engineHours, String trailers, String shippingDocuments, String carrierName, String usdotNumber, String mainOfficeAddress, String homeTerminalAddress, List<String> activeDataDiagnostics, List<String> activeDeviceMalfunctions, List<DotInspectionEvent> events, bool readOnly, String? period24HourStartTime, String? driverLicenseNumber, String? driverLicenseState, String? coDriverName, int? coDriverId
});


@override $DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class __$DotInspectionLogCopyWithImpl<$Res>
    implements _$DotInspectionLogCopyWith<$Res> {
  __$DotInspectionLogCopyWithImpl(this._self, this._then);

  final _DotInspectionLog _self;
  final $Res Function(_DotInspectionLog) _then;

/// Create a copy of DotInspectionLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? driverName = null,Object? logDate = null,Object? displayDate = null,Object? displayLocation = null,Object? certified = null,Object? certifiedAt = freezed,Object? eldRegistrationId = null,Object? eldIdentifier = null,Object? eldProvider = null,Object? vehicleNumber = null,Object? uniqueId = null,Object? vin = null,Object? startOdometerKm = null,Object? endOdometerKm = null,Object? totalDistanceKm = null,Object? engineHours = null,Object? trailers = null,Object? shippingDocuments = null,Object? carrierName = null,Object? usdotNumber = null,Object? mainOfficeAddress = null,Object? homeTerminalAddress = null,Object? activeDataDiagnostics = null,Object? activeDeviceMalfunctions = null,Object? events = null,Object? readOnly = null,Object? period24HourStartTime = freezed,Object? driverLicenseNumber = freezed,Object? driverLicenseState = freezed,Object? coDriverName = freezed,Object? coDriverId = freezed,}) {
  return _then(_DotInspectionLog(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,logDate: null == logDate ? _self.logDate : logDate // ignore: cast_nullable_to_non_nullable
as DateTime,displayDate: null == displayDate ? _self.displayDate : displayDate // ignore: cast_nullable_to_non_nullable
as String,displayLocation: null == displayLocation ? _self.displayLocation : displayLocation // ignore: cast_nullable_to_non_nullable
as String,certified: null == certified ? _self.certified : certified // ignore: cast_nullable_to_non_nullable
as bool,certifiedAt: freezed == certifiedAt ? _self.certifiedAt : certifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,eldRegistrationId: null == eldRegistrationId ? _self.eldRegistrationId : eldRegistrationId // ignore: cast_nullable_to_non_nullable
as String,eldIdentifier: null == eldIdentifier ? _self.eldIdentifier : eldIdentifier // ignore: cast_nullable_to_non_nullable
as String,eldProvider: null == eldProvider ? _self.eldProvider : eldProvider // ignore: cast_nullable_to_non_nullable
as String,vehicleNumber: null == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String,uniqueId: null == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String,vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,startOdometerKm: null == startOdometerKm ? _self.startOdometerKm : startOdometerKm // ignore: cast_nullable_to_non_nullable
as double,endOdometerKm: null == endOdometerKm ? _self.endOdometerKm : endOdometerKm // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,engineHours: null == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double,trailers: null == trailers ? _self.trailers : trailers // ignore: cast_nullable_to_non_nullable
as String,shippingDocuments: null == shippingDocuments ? _self.shippingDocuments : shippingDocuments // ignore: cast_nullable_to_non_nullable
as String,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,usdotNumber: null == usdotNumber ? _self.usdotNumber : usdotNumber // ignore: cast_nullable_to_non_nullable
as String,mainOfficeAddress: null == mainOfficeAddress ? _self.mainOfficeAddress : mainOfficeAddress // ignore: cast_nullable_to_non_nullable
as String,homeTerminalAddress: null == homeTerminalAddress ? _self.homeTerminalAddress : homeTerminalAddress // ignore: cast_nullable_to_non_nullable
as String,activeDataDiagnostics: null == activeDataDiagnostics ? _self._activeDataDiagnostics : activeDataDiagnostics // ignore: cast_nullable_to_non_nullable
as List<String>,activeDeviceMalfunctions: null == activeDeviceMalfunctions ? _self._activeDeviceMalfunctions : activeDeviceMalfunctions // ignore: cast_nullable_to_non_nullable
as List<String>,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<DotInspectionEvent>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,period24HourStartTime: freezed == period24HourStartTime ? _self.period24HourStartTime : period24HourStartTime // ignore: cast_nullable_to_non_nullable
as String?,driverLicenseNumber: freezed == driverLicenseNumber ? _self.driverLicenseNumber : driverLicenseNumber // ignore: cast_nullable_to_non_nullable
as String?,driverLicenseState: freezed == driverLicenseState ? _self.driverLicenseState : driverLicenseState // ignore: cast_nullable_to_non_nullable
as String?,coDriverName: freezed == coDriverName ? _self.coDriverName : coDriverName // ignore: cast_nullable_to_non_nullable
as String?,coDriverId: freezed == coDriverId ? _self.coDriverId : coDriverId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of DotInspectionLog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}

/// @nodoc
mixin _$DotInspectionEvent {

 int get sequenceNumber; String get timeEt; String get eventCode; String get eventType; String get description; String get location; double get odometer; double get engineHours; String get origin; String get notes; bool get certificationEvent;
/// Create a copy of DotInspectionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DotInspectionEventCopyWith<DotInspectionEvent> get copyWith => _$DotInspectionEventCopyWithImpl<DotInspectionEvent>(this as DotInspectionEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DotInspectionEvent&&(identical(other.sequenceNumber, sequenceNumber) || other.sequenceNumber == sequenceNumber)&&(identical(other.timeEt, timeEt) || other.timeEt == timeEt)&&(identical(other.eventCode, eventCode) || other.eventCode == eventCode)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.odometer, odometer) || other.odometer == odometer)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.certificationEvent, certificationEvent) || other.certificationEvent == certificationEvent));
}


@override
int get hashCode => Object.hash(runtimeType,sequenceNumber,timeEt,eventCode,eventType,description,location,odometer,engineHours,origin,notes,certificationEvent);

@override
String toString() {
  return 'DotInspectionEvent(sequenceNumber: $sequenceNumber, timeEt: $timeEt, eventCode: $eventCode, eventType: $eventType, description: $description, location: $location, odometer: $odometer, engineHours: $engineHours, origin: $origin, notes: $notes, certificationEvent: $certificationEvent)';
}


}

/// @nodoc
abstract mixin class $DotInspectionEventCopyWith<$Res>  {
  factory $DotInspectionEventCopyWith(DotInspectionEvent value, $Res Function(DotInspectionEvent) _then) = _$DotInspectionEventCopyWithImpl;
@useResult
$Res call({
 int sequenceNumber, String timeEt, String eventCode, String eventType, String description, String location, double odometer, double engineHours, String origin, String notes, bool certificationEvent
});




}
/// @nodoc
class _$DotInspectionEventCopyWithImpl<$Res>
    implements $DotInspectionEventCopyWith<$Res> {
  _$DotInspectionEventCopyWithImpl(this._self, this._then);

  final DotInspectionEvent _self;
  final $Res Function(DotInspectionEvent) _then;

/// Create a copy of DotInspectionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sequenceNumber = null,Object? timeEt = null,Object? eventCode = null,Object? eventType = null,Object? description = null,Object? location = null,Object? odometer = null,Object? engineHours = null,Object? origin = null,Object? notes = null,Object? certificationEvent = null,}) {
  return _then(_self.copyWith(
sequenceNumber: null == sequenceNumber ? _self.sequenceNumber : sequenceNumber // ignore: cast_nullable_to_non_nullable
as int,timeEt: null == timeEt ? _self.timeEt : timeEt // ignore: cast_nullable_to_non_nullable
as String,eventCode: null == eventCode ? _self.eventCode : eventCode // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,odometer: null == odometer ? _self.odometer : odometer // ignore: cast_nullable_to_non_nullable
as double,engineHours: null == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,certificationEvent: null == certificationEvent ? _self.certificationEvent : certificationEvent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc


class _DotInspectionEvent implements DotInspectionEvent {
  const _DotInspectionEvent({required this.sequenceNumber, required this.timeEt, required this.eventCode, required this.eventType, required this.description, required this.location, required this.odometer, required this.engineHours, required this.origin, required this.notes, required this.certificationEvent});
  

@override final  int sequenceNumber;
@override final  String timeEt;
@override final  String eventCode;
@override final  String eventType;
@override final  String description;
@override final  String location;
@override final  double odometer;
@override final  double engineHours;
@override final  String origin;
@override final  String notes;
@override final  bool certificationEvent;

/// Create a copy of DotInspectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DotInspectionEventCopyWith<_DotInspectionEvent> get copyWith => __$DotInspectionEventCopyWithImpl<_DotInspectionEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DotInspectionEvent&&(identical(other.sequenceNumber, sequenceNumber) || other.sequenceNumber == sequenceNumber)&&(identical(other.timeEt, timeEt) || other.timeEt == timeEt)&&(identical(other.eventCode, eventCode) || other.eventCode == eventCode)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.odometer, odometer) || other.odometer == odometer)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.certificationEvent, certificationEvent) || other.certificationEvent == certificationEvent));
}


@override
int get hashCode => Object.hash(runtimeType,sequenceNumber,timeEt,eventCode,eventType,description,location,odometer,engineHours,origin,notes,certificationEvent);

@override
String toString() {
  return 'DotInspectionEvent(sequenceNumber: $sequenceNumber, timeEt: $timeEt, eventCode: $eventCode, eventType: $eventType, description: $description, location: $location, odometer: $odometer, engineHours: $engineHours, origin: $origin, notes: $notes, certificationEvent: $certificationEvent)';
}


}

/// @nodoc
abstract mixin class _$DotInspectionEventCopyWith<$Res> implements $DotInspectionEventCopyWith<$Res> {
  factory _$DotInspectionEventCopyWith(_DotInspectionEvent value, $Res Function(_DotInspectionEvent) _then) = __$DotInspectionEventCopyWithImpl;
@override @useResult
$Res call({
 int sequenceNumber, String timeEt, String eventCode, String eventType, String description, String location, double odometer, double engineHours, String origin, String notes, bool certificationEvent
});




}
/// @nodoc
class __$DotInspectionEventCopyWithImpl<$Res>
    implements _$DotInspectionEventCopyWith<$Res> {
  __$DotInspectionEventCopyWithImpl(this._self, this._then);

  final _DotInspectionEvent _self;
  final $Res Function(_DotInspectionEvent) _then;

/// Create a copy of DotInspectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sequenceNumber = null,Object? timeEt = null,Object? eventCode = null,Object? eventType = null,Object? description = null,Object? location = null,Object? odometer = null,Object? engineHours = null,Object? origin = null,Object? notes = null,Object? certificationEvent = null,}) {
  return _then(_DotInspectionEvent(
sequenceNumber: null == sequenceNumber ? _self.sequenceNumber : sequenceNumber // ignore: cast_nullable_to_non_nullable
as int,timeEt: null == timeEt ? _self.timeEt : timeEt // ignore: cast_nullable_to_non_nullable
as String,eventCode: null == eventCode ? _self.eventCode : eventCode // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,odometer: null == odometer ? _self.odometer : odometer // ignore: cast_nullable_to_non_nullable
as double,engineHours: null == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,certificationEvent: null == certificationEvent ? _self.certificationEvent : certificationEvent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
