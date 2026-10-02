// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get auditTrail => 'Trail de auditoría';

  @override
  String get auditTrailNote =>
      'Este registro confirma cada acción se mantiene con el usuario, el tiempo y los valores anteriores/nuevos. No puede ser editado o eliminado.';

  @override
  String get auditNoRecords => 'No Records';

  @override
  String get auditLoadFailed => 'No podía cargar la pista de auditoría.';

  @override
  String get vehicleStatusOutOfService => 'Out OF SERVICE';

  @override
  String get vehicleStatusRestricted => 'RESTRICTED';

  @override
  String get vehicleStatusAvailable => 'AVAILABLE';

  @override
  String get driverName => 'Nombre del conductor';

  @override
  String get driverId => 'ID del conductor';

  @override
  String get license => 'Licencia';

  @override
  String get licenseState => 'Licencia Estado';

  @override
  String get exemptDriver => 'Exempt Driver';

  @override
  String get unidentifiedDriving => 'Conducción no identificada';

  @override
  String get coDriverId => 'Co-Driver ID';

  @override
  String get logDate => 'Fecha';

  @override
  String get displayDate => 'Fecha de visualización';

  @override
  String get displayLocation => 'Mostrar ubicación';

  @override
  String get eldRegId => 'ELD Registro ID';

  @override
  String get eldIdentifier => 'ELD Identifier';

  @override
  String get provider => 'Proveedor';

  @override
  String get periodStart => 'Período de inicio';

  @override
  String get dataDiag => 'Diagn de datos.';

  @override
  String get deviceMalf => 'Device Malf.';

  @override
  String get vin => 'VIN';

  @override
  String get carrier => 'Carrier';

  @override
  String get mainOffice => 'Oficina Principal';

  @override
  String get homeTerminal => 'Home Terminal';

  @override
  String get insertDutyStatus => 'Insertar el estado del deber';

  @override
  String get addButton => 'ADD';

  @override
  String get eventAddedSuccess => 'Evento añadido con éxito';

  @override
  String get appName => 'Golden Feather ELD';

  @override
  String get appSlogan => 'Golden Feather - Field Compliance Tracking';

  @override
  String get trackingTitle => 'Seguimiento';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get statusTitle => 'Logs';

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get okButton => 'OK';

  @override
  String get deleteButton => 'Suprimir';

  @override
  String get retryButton => 'Retry';

  @override
  String get closeButton => 'Cerca';

  @override
  String get shareButton => 'Compartir';

  @override
  String get clearButton => 'Despejado';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get locationButton => 'Enviar ubicación';

  @override
  String get statusButton => 'Mostrar estado';

  @override
  String get settingsButton => 'Cambiar configuración';

  @override
  String get invalidValue => 'Valor inválido';

  @override
  String get disabledValue => 'Discapacitados';

  @override
  String get idLabel => 'Identificador de dispositivos';

  @override
  String get urlLabel => 'URL';

  @override
  String get accuracyLabel => 'Precisión de ubicación';

  @override
  String get highestAccuracyLabel => 'Más alto';

  @override
  String get highAccuracyLabel => 'Alto';

  @override
  String get mediumAccuracyLabel => 'Mediana';

  @override
  String get lowAccuracyLabel => 'Baja';

  @override
  String get intervalLabel => 'Interval (segundos)';

  @override
  String get fastestIntervalLabel => 'Intervalo más rápido (segundos)';

  @override
  String get distanceLabel => 'Distancia (metros)';

  @override
  String get angleLabel => 'Ángulo (de acuerdo)';

  @override
  String get heartbeatLabel => 'Latidos cardíacos estacionarios (segundos)';

  @override
  String get bufferLabel => 'Buffering sin conexión';

  @override
  String get wakelockLabel => 'Despierta.';

  @override
  String get stopDetectionLabel => 'Detección';

  @override
  String get preferPlatformProvidersLabel => 'Ubicación del sistema';

  @override
  String get serverNotConfigured => 'Servidor no configurado';

  @override
  String get trackingLabel => 'Seguimiento continuo';

  @override
  String get advancedLabel => 'Ajustes avanzados';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get optimizationMessage =>
      'Para asegurar un seguimiento fiable, por favor desactiva la optimización de la batería para esta aplicación.';

  @override
  String get passwordError => 'contraseña incorrecta';

  @override
  String get disclosureMessage =>
      'Esta aplicación recopila datos de ubicación y actividad en el fondo y lo envía al servidor configurado.';

  @override
  String get configurationMessage => '¿Aplicar nueva configuración?';

  @override
  String get startAction => 'Comienzo';

  @override
  String get stopAction => 'Servicio de parada';

  @override
  String get sosAction => 'Enviar SOS';

  @override
  String get home => 'Home';

  @override
  String get inspection => 'Inspección';

  @override
  String get checklist => 'Lista de verificación';

  @override
  String get reports => 'Informes';

  @override
  String get settings => 'Ajustes';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get register => 'Registro';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get rememberMe => 'Recuérdame';

  @override
  String get forgotPassword => '¿Olvidó la contraseña?';

  @override
  String get startInspection => 'Inspección inicial';

  @override
  String get stopInspection => 'Stop Inspection';

  @override
  String get pauseInspection => 'Pausa';

  @override
  String get resumeInspection => 'Resumen';

  @override
  String get submitReport => 'Informe presentado';

  @override
  String get saveDraft => 'Guardar como proyecto';

  @override
  String get discardDraft => 'Discard Draft';

  @override
  String get inspectionTitle => 'Título de inspección';

  @override
  String get inspectionLocation => 'Lugar de inspección';

  @override
  String get inspectionDate => 'Fecha de inspección';

  @override
  String get inspectionTime => 'Tiempo de inspección';

  @override
  String get inspectionDuration => 'Duración de la inspección';

  @override
  String get inspectorName => 'Nombre del Inspector';

  @override
  String get inspectionStatus => 'Estado de la inspección';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusInProgress => 'En progreso';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusRequiresReview => 'Requires Review';

  @override
  String get statusScheduled => 'Programado';

  @override
  String get statusCancelled => 'Cancelada';

  @override
  String get checklistTitle => 'Lista de verificación Título';

  @override
  String get checklistCategory => 'Lista de verificación Categoría';

  @override
  String get addChecklist => 'Agregar lista de verificación';

  @override
  String get editChecklist => 'Editar lista de verificación';

  @override
  String get deleteChecklist => 'Eliminar la lista de verificación';

  @override
  String get checklistItems => 'Lista de verificación Artículos';

  @override
  String get addItem => 'Add Item';

  @override
  String get removeItem => 'Quitar el artículo';

  @override
  String get itemTypeText => 'Texto';

  @override
  String get itemTypeNumber => 'Número';

  @override
  String get itemTypeYesNo => 'Sí / No';

  @override
  String get itemTypeMultipleChoice => 'Elección múltiple';

  @override
  String get itemTypePhoto => 'Foto';

  @override
  String get itemTypeSignature => 'Firma';

  @override
  String get itemTypeDate => 'Fecha';

  @override
  String get itemTypeTime => 'Hora';

  @override
  String get itemTypeBarcode => 'Código de barras';

  @override
  String get photoRequired => 'Foto requerida';

  @override
  String get signatureRequired => 'Firma requerida';

  @override
  String get notesRequired => 'Notas necesarias';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get chooseFromGallery => 'Elija de la galería';

  @override
  String get retakePhoto => 'Retoma foto';

  @override
  String get photoPreview => 'Vista previa de la foto';

  @override
  String get signHere => 'Firme aquí';

  @override
  String get clearSignature => 'Firma clara';

  @override
  String get signaturePreview => 'Vista previa de la firma';

  @override
  String get addNote => 'Nota';

  @override
  String get editNote => 'Editar la nota';

  @override
  String get deleteNote => 'Suprimir la nota';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get synced => 'Sin embargo';

  @override
  String get syncing => 'Sincronización...';

  @override
  String syncPending(String count) {
    return '$count pendiente';
  }

  @override
  String syncFailed(String count) {
    return '$count falló';
  }

  @override
  String get offline => 'Sin conexión';

  @override
  String get lastSync => 'Último Sync';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get errorMessage => 'Se produjo un error';

  @override
  String get successMessage => 'Operación terminada con éxito';

  @override
  String get warningMessage => 'Advertencia';

  @override
  String get infoMessage => 'Información';

  @override
  String get loading => 'Cargando...';

  @override
  String get noData => 'No hay datos';

  @override
  String get noInternet => 'Sin conexión a Internet';

  @override
  String get noResults => 'No se han encontrado resultados';

  @override
  String get permissionDenied => 'Permiso denegado';

  @override
  String get locationPermissionDenied =>
      'Por favor conceda permiso de ubicación';

  @override
  String get cameraPermissionDenied => 'Por favor conceda permiso de cámara';

  @override
  String get storagePermissionDenied =>
      'Por favor, conceda permiso de almacenamiento';

  @override
  String get confirmDelete => '¿Seguro que quieres borrar?';

  @override
  String get confirmLogout => '¿Estás seguro de que quieres logotipo?';

  @override
  String get confirmSubmit => '¿Seguro que quieres presentar el informe?';

  @override
  String get confirmDiscard => '¿Seguro que quieres descartar cambios?';

  @override
  String get unsavedChanges => 'Tienes cambios sin salvar';

  @override
  String get changesWillBeLost => 'Los cambios se perderán si continúas';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'Inglés';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get lightMode => 'Modo de luz';

  @override
  String get systemMode => 'Modo de sistema';

  @override
  String get themeLabel => 'Tema';

  @override
  String get aboutLabel => 'Acerca de';

  @override
  String get versionLabel => 'Versión';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get contactUs => 'Contáctenos';

  @override
  String get help => 'Ayuda';

  @override
  String get faq => 'FAQ';

  @override
  String get qrCodeScanner => 'QR Scanner';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get scanningInstructions => 'Ponga la cámara en un código QR';

  @override
  String get search => 'Búsqueda';

  @override
  String get filter => 'Filtro';

  @override
  String get sort => '#';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByDate => 'Fecha';

  @override
  String get sortByStatus => 'Situación';

  @override
  String get exportPDF => 'Exportar PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get print => 'Imprimir';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get newInspectionAssigned => 'Nueva inspección asignada';

  @override
  String get inspectionReminder => 'Recordatorio de inspección';

  @override
  String get inspectionOverdue => 'Inspección retrasada';

  @override
  String get syncComplete => 'Sincronización completa';

  @override
  String get yes => 'Sí.';

  @override
  String get no => 'No';

  @override
  String get na => 'N/A';

  @override
  String get pass => 'Paso';

  @override
  String get fail => 'Fail';

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get january => 'Enero';

  @override
  String get february => 'Febrero';

  @override
  String get march => 'Marzo';

  @override
  String get april => 'Abril';

  @override
  String get may => 'Mayo';

  @override
  String get june => 'Junio';

  @override
  String get july => 'Julio';

  @override
  String get august => 'Agosto';

  @override
  String get september => 'Septiembre';

  @override
  String get october => 'Octubre';

  @override
  String get november => 'Noviembre';

  @override
  String get december => 'Diciembre';

  @override
  String get unableToConnect => 'Incapaz de conectar con ELD con MAC';

  @override
  String get verifyFollowingItems =>
      'Por favor, compruebe los siguientes elementos:';

  @override
  String get macEnteredCorrectly =>
      'Dirección ELD MAC se introduce correctamente.';

  @override
  String get hardwareProperlyInstalled =>
      'El hardware ELD está instalado correctamente.';

  @override
  String get vehiclePowerOn => 'El poder del vehículo está encendido.';

  @override
  String get bluetoothEnabled =>
      'Bluetooth está habilitado en el dispositivo móvil.';

  @override
  String get gpsEnabled => 'El GPS está habilitado en el dispositivo móvil.';

  @override
  String get enterMacAddress =>
      'Introduzca la dirección ELD MAC listada en el dispositivo:';

  @override
  String get connect => 'CONNECT';

  @override
  String get continueDisconnected => 'CONTINUACIÓN CONTINUADA';

  @override
  String get usernameRequired => 'Se requiere el nombre de usuario';

  @override
  String get passwordRequired => 'Se requiere contraseña';

  @override
  String get hoursRecap => 'Horas Recap';

  @override
  String get suggestedEvents => 'Eventos sugeridos';

  @override
  String get unidentifiedEvents => 'Eventos no identificados';

  @override
  String get unclaimed => 'UNCLAIMED';

  @override
  String get rejected => 'REJECTED';

  @override
  String get noRecords => 'No Records';

  @override
  String get drawSignatureHere => 'Dibuja tu firma aquí';

  @override
  String get fillFormFirst =>
      'Necesitas rellenar y guardar el formulario primero.';

  @override
  String get formLabel => 'Formulario';

  @override
  String get certifyLabel => 'Certificar';

  @override
  String get editDutyStatus => 'Editar el estado del deber';

  @override
  String get startTime => 'Hora de inicio';

  @override
  String get duration => 'Duración';

  @override
  String get status => 'Situación';

  @override
  String get vehicle => 'Vehículo';

  @override
  String get location => 'Ubicación';

  @override
  String get manualLocation => 'Ubicación manual';

  @override
  String get events => 'Eventos';

  @override
  String get form => 'Formulario';

  @override
  String get certify => 'Certificar';

  @override
  String get driver => 'Conductor';

  @override
  String get vehicles => 'Vehículos';

  @override
  String get trailers => 'Remolques';

  @override
  String get shippingDocuments => 'Documentos de envío';

  @override
  String get coDriver => 'Co-Driver';

  @override
  String get imageNotAvailable => 'Imagen no disponible';

  @override
  String get certifyDeclaration =>
      'Por la presente certifico que mis entradas de datos y mi historial de estado de servicio para este período de 24 horas son verdaderas y correctas.';

  @override
  String get notReady => 'NO READY';

  @override
  String get agree => 'AGREE';

  @override
  String get timeline24h => 'Horario de 24 horas';

  @override
  String get settingsAppliedSuccess => 'Ajustes aplicados con éxito';

  @override
  String get deviceInformation => 'Información sobre dispositivos';

  @override
  String get confirmClearLogs =>
      '¿Seguro que quieres limpiar todos los registros?';

  @override
  String get trackingStatus => 'Situación de seguimiento';

  @override
  String get activeStatus => 'Activo';

  @override
  String get stoppedStatus => 'Detenido';

  @override
  String get coordinatesLabel => 'Coordinaciones';

  @override
  String get lastUpdateLabel => 'Última actualización';

  @override
  String get locationDisabled => 'Ubicación para discapacitados';

  @override
  String get openSettings => 'Configuración abierta';

  @override
  String get remainingLabel => 'Permaneciendo';

  @override
  String get available => 'Disponible';

  @override
  String get recap => 'Recap';

  @override
  String get changeStatus => 'Situación';

  @override
  String get errorCannotChangeStatusWhileMoving =>
      'No puede cambiar el estado mientras el vehículo se mueve.';

  @override
  String get customLocation => 'Ubicación personalizada';

  @override
  String get notes => 'Notas';

  @override
  String get updateButton => 'UPDATE';

  @override
  String get offDuty => 'Off Duty';

  @override
  String get sleeperBerth => 'Durmiente';

  @override
  String get drivingStatus => 'Conducción';

  @override
  String get onDuty => 'Sobre el deber';

  @override
  String get personalUse => 'Uso personal';

  @override
  String get yardMoves => 'Yard se mueve';

  @override
  String get confirmTitle => 'Confirmación';

  @override
  String get qrScannerTitle => 'Scan QR Code';

  @override
  String get qrScannerInstructions => 'Apunte la cámara en el código QR';

  @override
  String get logsTitle => 'Logs';

  @override
  String get total => 'Total';

  @override
  String get last7Days => 'Últimos 7 Días';

  @override
  String get hoursWorkedToday => 'Horas trabajadas hoy';

  @override
  String get hoursAvailableToday => 'Horas disponibles hoy';

  @override
  String get hoursAvailableTomorrow => 'Horas disponibles Mañana';

  @override
  String get registerAction => 'Registro';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get fullNameRequired => 'Nombre completo es necesario';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden';

  @override
  String get haveAccount => '¿Ya tienes una cuenta?';

  @override
  String get loginHere => 'Iniciar sesión aquí';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get email => 'Email';

  @override
  String get emailRequired => 'Se requiere correo electrónico';

  @override
  String get invalidEmailFormat => 'Formato de correo electrónico inválido';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Volver a Iniciar sesión';

  @override
  String get notImplemented => 'Esta característica aún no se ha aplicado';

  @override
  String get dvirTitle => 'Inspección de vehículos (DVIR)';

  @override
  String get inspectionType => 'Tipo de inspección';

  @override
  String get vehicleInfo => 'Información sobre vehículos';

  @override
  String get mechanicalChecklist => 'Lista de verificación mecánica';

  @override
  String get additionalNotes => 'Notas adicionales';

  @override
  String get vehicleCondition => 'Acondicionamiento del vehículo';

  @override
  String get driverSignature => 'Firma del conductor';

  @override
  String get saveReport => 'Save Report';

  @override
  String get updateReport => 'Informe de actualización';

  @override
  String get newReport => 'Nuevo informe de inspección';

  @override
  String get editReport => 'Editar informe';

  @override
  String get noDvirReports => 'No hay informes de inspección';

  @override
  String get createNewReport => 'Crear nuevo informe';

  @override
  String get reportSavedSuccess => 'Informe de inspección guardado con éxito';

  @override
  String get defectsFound => 'Defectos encontrados';

  @override
  String get submitted => 'Presentado';

  @override
  String get draft => 'Proyecto';

  @override
  String get trailer => 'Trailer';

  @override
  String get odometerReading => 'Lectura de olor';

  @override
  String get dtcCodes => 'Códigos de diagnóstico del motor (DTC)';

  @override
  String get notesHint =>
      'Cualquier nota adicional sobre la condición del vehículo...';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get selectVehicle => 'Seleccione el vehículo';

  @override
  String get searchVehicle => 'Vehículos de búsqueda...';

  @override
  String get noVehiclesFound => 'No hay vehículos disponibles';

  @override
  String get vehicleSelected => 'Vehículo seleccionado';

  @override
  String get unassigned => 'No asignados';

  @override
  String get underDevelopment => 'Bajo el desarrollo...';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get miles => 'millas';

  @override
  String get hour => 'hora';

  @override
  String get minute => 'minuto';

  @override
  String get newInspectionReport => 'Nuevo informe de inspección';

  @override
  String get editInspectionReport => 'Editar informe de inspección';

  @override
  String get active => 'Activo';

  @override
  String get inactive => 'Inactivo';

  @override
  String get notAvailable => 'N/A';

  @override
  String get deviceInfo => 'Información del dispositivo';

  @override
  String get account => 'Cuenta';

  @override
  String get rules => 'Reglas';

  @override
  String get infoPacket => 'Info Packet';

  @override
  String get odometer => 'Odometer';

  @override
  String get engineHours => 'Horas del motor';

  @override
  String get offlineMode => 'Modo sin conexión';

  @override
  String get dotInspection => 'DOT Inspection';

  @override
  String get setInspectionPin => 'Juego de inspección PIN';

  @override
  String get enter4DigitPin => 'Entrar PIN de 4 dígitos';

  @override
  String get confirmPin => 'Confirme PIN';

  @override
  String get enterPinToUnlock => 'Entra PIN para desbloquear';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get dotInspectionMode => 'Modo de inspección';

  @override
  String get screenLockedForOfficer =>
      'Pantalla bloqueada para revisión del oficial';

  @override
  String get unlockDriverOnly => 'Desbloquear (sólo conductor)';

  @override
  String get sendLogs => 'Enviar registros';

  @override
  String get emailLogs => 'Correo electrónico Logs';

  @override
  String get endInspection => 'Inspección final';

  @override
  String get certified => 'Certificado';

  @override
  String get eldReport => 'ELD Report';

  @override
  String get hosReport => 'HOS Report';

  @override
  String get compliant => 'Cumplido';

  @override
  String get nonCompliant => 'No compatible';

  @override
  String get work => 'Trabajo';

  @override
  String get rest => 'Descanso';

  @override
  String get break_ => 'Break';

  @override
  String get distance => 'Distancia';

  @override
  String get malfunctionAlerts => 'Alertas de mal funcionamiento';

  @override
  String get clearAll => 'Despejado';

  @override
  String get pdfExportedSuccess => 'PDF exportado con éxito';

  @override
  String get userManual => 'Manual de usuario';

  @override
  String get instructions => 'Instrucciones';

  @override
  String get malfunctionManual => 'Manual de mal funcionamiento';

  @override
  String get viewUserManual => 'Ver Manual de usuario';

  @override
  String get viewInstructions => 'Ver Instrucciones';

  @override
  String get viewMalfunctionManual => 'Ver Manual de mal funcionamiento';

  @override
  String get legalNotice =>
      'Estos documentos son requeridos por normas aprobadas de gestión de flotas. Deben estar disponibles en todo momento mientras operan un vehículo comercial.';

  @override
  String get gettingStarted => 'Comienzo';

  @override
  String get connectingToVehicle => 'Conexión al vehículo';

  @override
  String get changingDutyStatus => 'Estado del deber cambiante';

  @override
  String get viewingLogs => 'Viewing Logs &quot; Certification';

  @override
  String get vehicleInspection => 'Inspección de vehículos (DVIR)';

  @override
  String get roadsideInspection => 'Inspección de carreteras';

  @override
  String get continueWithout => 'Continuar sin';

  @override
  String get grant => 'Grant';

  @override
  String get time => 'Hora';

  @override
  String get odom => 'Odón.';

  @override
  String get eng => 'Eng.';

  @override
  String get src => 'Src';

  @override
  String get noManualModifications =>
      'No se han encontrado modificaciones manuales para esta fecha.';

  @override
  String get failedToLoadAudits => 'Failed to load audits';

  @override
  String get exportErods => 'Exportar como eRODS (XML/CSV)';

  @override
  String get requiredForFmcsa => 'Necesidad para la inspección de FMCSA';

  @override
  String changeStatusTo(String status) {
    return 'Estado de cambio a $status';
  }

  @override
  String get connected => 'Conectado';

  @override
  String get connecting => 'Conectando...';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get noRecordsToday => 'No hay registros para hoy';

  @override
  String get trackingNotStarted => 'El seguimiento aún no ha comenzado';

  @override
  String get gpsDisabled => 'GPS está desactivado';

  @override
  String get notConnectedToServer => 'No conectado al servidor';

  @override
  String get unexpectedError => 'Un error inesperado ocurrió';

  @override
  String get loadingRecords => 'Cargando registros...';

  @override
  String get defectsTitle => 'Defectos';

  @override
  String get vehicleConditionSatisfactory =>
      'Condición del vehículo Satisfactoria';

  @override
  String auditReason(String reason) {
    return 'Razón: $reason';
  }

  @override
  String auditStatusChange(String oldStatus, String newStatus) {
    return '$oldStatus - Propiedad $newStatus';
  }

  @override
  String get calculatingLocation => 'Calculando ubicación...';

  @override
  String get driveLimitTitle => 'DRIVE';

  @override
  String get driveLimitDesc => '11-Hour Driving Limit';

  @override
  String get shiftLimitTitle => 'SHIFT';

  @override
  String get shiftLimitDesc => '14-Hour on Duty Limit';

  @override
  String get breakLimitTitle => 'BREAK';

  @override
  String get breakLimitDesc => '30 minutos de descanso';

  @override
  String get cycleLimitTitle => 'CYCLE';

  @override
  String get cycleLimitDesc => 'USA 70/8';

  @override
  String get hoursOfService => 'HOURS OF SERVICE';

  @override
  String get sessionExpired =>
      'Sesión vencida, por favor vuelva a iniciar sesión';

  @override
  String get invalidConfiguration => 'Configuración del servidor inválido';

  @override
  String get invalidCredentials => 'Nombre de usuario o contraseña inválido';

  @override
  String get sessionMissing =>
      'Falta de sesión, por favor vuelva a iniciar sesión';

  @override
  String get interfaceLanguage => 'Lenguaje de interfaz';

  @override
  String get languageArabic => 'Árabe';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Luz';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get serverUrl => 'URL';

  @override
  String get enterServerUrl => 'Introduzca la URL del servidor.';

  @override
  String get invalidServerUrl =>
      'URL inválida. Ejemplo: https://server.example.com';

  @override
  String get serverUrlSaved => 'URL del servidor guardado.';

  @override
  String get formIncomplete =>
      'El formulario es incompleto, por favor llena todos los campos.';

  @override
  String get sixteenHourCondition =>
      'La excepción de 16 horas no puede ser habilitada a menos que se cumplan sus condiciones.';

  @override
  String get rulesUpdated => 'Reglas actualizadas con éxito';

  @override
  String get allowed => 'Permiso';

  @override
  String get forbidden => 'Forbidden';

  @override
  String get notProvidedByServer => 'No proporcionado por el servidor';

  @override
  String get ruleSource => 'Fuente';

  @override
  String get cycleRule => 'Regla del ciclo';

  @override
  String get cargoType => 'Tipo de carga';

  @override
  String get restartRule => 'Restart';

  @override
  String get restBreakRule => 'Descanso';

  @override
  String get sixteenHourException => '16-Hour Short-Haul Excepción';

  @override
  String get dailyLimits => 'Límites diarios';

  @override
  String get drivingLimit => 'Conducción';

  @override
  String get shiftWindowLimit => 'Cambio de ventana';

  @override
  String get cycleLimit => 'Ciclo';

  @override
  String get hourAbbr => 'h';

  @override
  String get minAbbr => 'm';

  @override
  String get contactFleetManager =>
      'Comuníquese con su gerente de flota para más información.';

  @override
  String get personalConveyance => 'Personal Conveyance';

  @override
  String get unlimitedTrailers => 'Remolques ilimitados';

  @override
  String get unlimitedShippingDocs => 'Documentos de envío ilimitados';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get applicationInfo => 'Aplicación';

  @override
  String get appNameLabel => 'Nombre';

  @override
  String get appVersionLabel => 'Versión';

  @override
  String get appPackageLabel => 'Paquete';

  @override
  String get deviceIdLabel => 'ID de dispositivo';

  @override
  String get diagnosticsAndConnection => 'Diagnósticos';

  @override
  String get centralServer => 'Servidor central';

  @override
  String get locationService => 'Servicio de localización (GPS)';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Discapacitados';

  @override
  String get hardwareAlerts => 'Alertas de hardware';

  @override
  String get noActiveAlerts => 'No hay alertas activas';

  @override
  String get activeAlerts => 'Alertas activas';

  @override
  String get technicalInfo => 'Información técnica';

  @override
  String get eldEngineVersion => 'ELD Engine Version';

  @override
  String get hardwareVersion => 'Versión de hardware';

  @override
  String get lastDataReceived => 'Últimos datos recibidos';

  @override
  String get eldConnectionStatus => 'ELD Connection Status';

  @override
  String get refresh => 'Refresh';

  @override
  String get supportText =>
      'Para soporte técnico, proporcione el ID del dispositivo y la versión mostrada anteriormente.';

  @override
  String get noVehiclesAssigned => 'No Vehículos asignados';

  @override
  String get vehiclesAssignedViaPortal =>
      'Los vehículos se asignan a través del portal.';

  @override
  String get viewMyVehicles => 'VER MIS VEHICLES';

  @override
  String get viewAllVehicles => 'VIEW ALL VEHICLES';

  @override
  String vehicleSelectedConnect(String name) {
    return '$name. Conectarse al ELD para operarlo. Las horas no fueron copiadas.';
  }

  @override
  String get inUse => 'En uso';

  @override
  String get viewOnly => 'Ver sólo';

  @override
  String get assignedToYou => 'Asignado a usted';

  @override
  String get errMotionUnknown =>
      'El movimiento del vehículo es desconocido. Eso no se trata como detenido.';

  @override
  String get errVehicleMoving =>
      'El vehículo no puede cambiarse mientras se mueve. Las horas no fueron copiadas.';

  @override
  String get errIdentifierMissing =>
      'El servidor no devolvió un identificador de vehículo. Uno no será inventado.';

  @override
  String get errThresholdMissing =>
      'El umbral de movimiento no está disponible.';

  @override
  String get errUnauthorized => 'No está autorizado para operar este vehículo.';

  @override
  String get errUnavailable => 'Vehículo no disponible.';

  @override
  String get errInUse => 'El vehículo está en uso.';

  @override
  String get errRejected => 'El servidor rechazó la operación del vehículo.';

  @override
  String get errListUnreadable => 'No se podía leer la lista de vehículos.';

  @override
  String get nA => 'N/A';

  @override
  String get email1 => 'Email';

  @override
  String get name => 'Nombre';

  @override
  String get phone => 'Teléfono';

  @override
  String get mainOfficeAddress => 'Dirección de la Oficina Principal';

  @override
  String get homeTerminalAddress => 'Home Terminal Address';

  @override
  String get timeZone => 'Zona horaria';

  @override
  String get language => 'Idioma';

  @override
  String get languageUpdatedSuccessfully => 'Idioma actualizado con éxito';

  @override
  String get odometerUnitUpdatedSuccessfull =>
      'Unidad de diámetro actualizada con éxito';

  @override
  String get pleaseContactYourFleetManagerT =>
      'Por favor, contacte con su gerente de flota para cambiar su información de \\naccount.';

  @override
  String get thePacketIsIncomplete => 'El paquete está incompleto.';

  @override
  String get inspectionMode => 'Modo de inspección';

  @override
  String get dataTransferInstructionSheet =>
      'Hoja de instrucciones de transferencia de datos';

  @override
  String get malfunctionManual39534 => 'Manual de mal funcionamiento (395.34)';

  @override
  String get goldenFeatherEldInspectionMode => 'Modo de inspección del ELD';

  @override
  String get tapDotInspectionInTheMenuPress =>
      'Pulsa \"Inspección de DOT\" en el menú &quot; presione \"Inspección inicial\". Deje que un oficial vea sus registros directamente desde su dispositivo móvil. Mostrar esta tarjeta de instrucción si se solicita.';

  @override
  String get anInspectorMayPressArrowsToVie =>
      'Un inspector puede presionar flechas para ver el día anterior o siguiente\\';

  @override
  String get theOfficerCannotLeaveInspectio =>
      'El oficial no puede dejar la inspección. El controlador sale con Driver Exit después de introducir la contraseña de la cuenta.';

  @override
  String get goldenFeatherEldIsCapableOfPro =>
      'Golden Feather ELD es capaz de producir y transferir los registros ELD a través de métodos de transferencia telemática: Servicios Web Inalámbricos y Correo electrónico. Para enviar los registros ELD a través de servicios Web, un controlador debe presionar el elemento del menú \"DOT Inspection\" y luego pulsar el botón \"Enviar Logs\". Para enviar los registros ELD a través de Email, un conductor debe presionar el menú \"DOT Inspection\", presionar \"Email Logs\", introducir un correo electrónico proporcionado por un oficial de seguridad autorizado y pulsar el botón \"Enviar\".';

  @override
  String get goldenFeatherEldMalfunctionMan =>
      'Golden Feather ELD Malfunction Manual';

  @override
  String get inAccordanceWithTheGuidelinesS =>
      'De conformidad con las directrices establecidas en 395.34';

  @override
  String get malfunctionIndication => 'Indicación de fallos';

  @override
  String get immediatelyContactTheSupportIf =>
      'Inmediatamente contacte con el soporte si la luz LED en el dispositivo está apagada cuando el dispositivo está conectado al puerto de diagnóstico o si el fallo reportado por la aplicación.';

  @override
  String get noteTheMalfunction => 'Tenga en cuenta el mal funcionamiento';

  @override
  String get noteTheMalfunctionAndProvideAW =>
      'Tenga en cuenta el mal funcionamiento y proporcione un aviso por escrito a su flota dentro de 24 horas.';

  @override
  String get switchToPaperLogs => 'Cambiar a registros de papel';

  @override
  String get k8DaysRule => '8 días de regla';

  @override
  String get contactTheSupportTeamAtTopceld =>
      'Contacta con el equipo de soporte en topceld@gmail.com';

  @override
  String get eldUserManual => 'ELD Manual de usuario';

  @override
  String get features => 'Características';

  @override
  String get installationAndSetup => 'Instalación y configuración';

  @override
  String get logManagement => 'Gestión de registros';

  @override
  String get roadsideInspections => 'Inspecciones por carretera';

  @override
  String get electronicDriverVehicleInspect =>
      'Informes electrónicos de inspección de vehículos conductores (DVIR)';

  @override
  String get fleetManagerPortal => 'Portal del administrador de flotas';

  @override
  String get electronicLoggingDeviceEld =>
      'Dispositivo electrónico de registro (ELD)';

  @override
  String get recordsOfNdutyStatus => 'Registros de \'nDuty Status';

  @override
  String get easilyManageYourDutyStatusChan =>
      'Gestione fácilmente los cambios de estado de su deber con nuestra aplicación ELD fácil de usar. Ver, editar y certificar sus registros para registros precisos y compatibles.';

  @override
  String get availableHoursAndNrequiredBrea =>
      'Horas disponibles y \'nRequired Breaks';

  @override
  String get stayInformedAboutYourAvailable =>
      'Manténgase informado sobre sus horas de conducción disponibles y descanso obligatorio para garantizar el cumplimiento de las regulaciones de HOS.';

  @override
  String get interAndIntrastateNhosRules => 'Reglas entre estados e institutos';

  @override
  String get ourAppSupportsBothInterAndIntr =>
      'Nuestra aplicación es compatible con las reglas de HOS inter- e intraestatale, dándole la flexibilidad para cumplir con las regulaciones específicas.';

  @override
  String get roadsideInspectionNfunction => 'Roadside Inspection\\nFunction';

  @override
  String get duringRoadsideInspectionsUseTh =>
      'Durante las inspecciones por carretera, utilice el modo de inspección DOT en la aplicación para compartir sus registros con facilidad.';

  @override
  String get vehicleInspectionNreports => 'Inspección del vehículo\\nInformes';

  @override
  String get generatePreOrPostTripDvirsWith =>
      'Generar DVIRs antes o después de la pista dentro de la aplicación, notificando la mecánica de cualquier defecto de vehículo rápidamente.';

  @override
  String get onlineFleetNmanagerPortal => 'Online Fleet\\nManager Portal';

  @override
  String get accessTheFleetManagerPortalToM =>
      'Acceda al Portal del Administrador de Flotas para supervisar el cumplimiento de HOS, ver datos en tiempo real sobre el estado de los derechos de conducir y recibir notificaciones sobre violaciones de HOS.';

  @override
  String get gpsTracking => 'GPS Tracking';

  @override
  String get trackYourVehicle => 'Seguimiento de su vehículo';

  @override
  String get iftaCalculations => 'Cálculos del TLC';

  @override
  String get automaticallyCalculateIftaData =>
      'Calcular automáticamente los datos de IFTA para simplificar la presentación de informes sobre impuestos sobre combustible para los transportistas interestatales.';

  @override
  String get setUpFleetNmanagerPortal => 'Configurar Fleet\\nManager Portal';

  @override
  String get useYourCredentialsToSignIntoTh =>
      'Utilice sus credenciales para iniciar sesión en el portal en línea, proporcionando información esencial sobre su empresa, usuarios de portales, conductores y vehículos.';

  @override
  String get monitorHosAndNfmcsaCompliance =>
      'Monitor HOS y\\nFMCSA-Compliance';

  @override
  String get stayOnTopOfDrivers =>
      'Manténgase en la parte superior de los conductores \\';

  @override
  String get preconfiguredStatuses => 'Estado preconfigurado';

  @override
  String get customizeDutyStatusesAccessByS =>
      'Personalizar el acceso de los estados de destino estableciendo Yard Move y Uso Personal como opciones válidas.';

  @override
  String get driverAndVehicleInformation => 'Driver and Vehicle Information';

  @override
  String get trackYourDrivers => 'Rastrea tus conductores';

  @override
  String get downloadAndTransferLogs => 'Descargar y transferir Logs';

  @override
  String get downloadAnyDrivers => 'Descargar cualquier controladores\\';

  @override
  String get filterLogs => 'Registros de filtros';

  @override
  String get saveTimeByQuicklyFindingLogsBy =>
      'Ahorre tiempo encontrando rápidamente registros por fecha, conductor o vehículo utilizando la opción de filtro.';

  @override
  String get installEldHardware => 'Instala el hardware ELD';

  @override
  String get beginByLocatingTheEcmDiagnosti =>
      'Comience localizando el puerto ECM (diagnóstico) en su vehículo. Este puerto se encuentra típicamente en o cerca del panel, debajo de la columna de dirección, o cerca del conductor\\';

  @override
  String get installEldSoftware => 'Instala el software ELD';

  @override
  String get beforeYouStartUsingTheEldEnsur =>
      'Antes de comenzar a utilizar el ELD, asegúrese de que su dispositivo móvil está conectado a Internet y Bluetooth está habilitado:\\n\\n• Instalación del software ELD: Descarga la aplicación ELD de tu dispositivo\\';

  @override
  String get hoursOfService1 => 'Horas de servicio';

  @override
  String get onceTheEldIsSetUpItAutomatical =>
      'Una vez que se establece el ELD, se registra automáticamente el tiempo de conducción. Cualquier movimiento a 5 mph o más rápido se registra como conducción. Cuando es estacionario, el conductor puede seleccionar un estado de servicio diferente. El sistema calcula y muestra:\\n\\n• Límites en servicio\\n• Tiempo de conducción disponible\\n• Romperes obligatorios y Períodos fuera de servicio\\n\\nEsta información se muestra en la aplicación\\';

  @override
  String get accessingLogs => 'Acceso a los registros';

  @override
  String get logInToTheEldAppWithYourUnique =>
      'Inicie sesión en la aplicación ELD con sus credenciales únicas y visite la sección \"Logs\" para acceder a sus registros electrónicos HOS.';

  @override
  String get viewingLogs1 => 'Ver los registros';

  @override
  String get viewDetailedRodsForDifferentDa =>
      'View detailed RODS for different dates, including time, duration, and location of each duty status change.';

  @override
  String get editingLogs => 'Edición de registros';

  @override
  String get editDutyStatusEntriesExceptFor =>
      'Editar las entradas de estado de destino (excepto los registros de conducción automáticamente registrados) para garantizar la exactitud. Simplemente toque en una fecha, utilice el icono del lápiz para hacer cambios y guardar sus ediciones.';

  @override
  String get certifyingLogs => 'Registros de certificación';

  @override
  String get certifyingLogsEndYourShiftByDi =>
      'Registros de certificación: Termina tu turno certificando digitalmente tus registros para la precisión y el cumplimiento del grifo de un botón.';

  @override
  String get duringARoadsideInspectionFollo =>
      'Durante una inspección por carretera, siga estos pasos:\\n\\n• Accede al modo \"Inspección de DOT\" desde el menú principal.\\n• Pulse \"Iniciar la inspección\" para mostrar sus registros de estado de deber (RODS) al oficial.\\n• Utilice las flechas de navegación para revisar los registros por fecha.\\n• Si se solicita, envíe su RODS a través de servicios web o correo electrónico seleccionando el botón \"Enviar\".\\n• Una vez que la inspección esté completa, pulse \"Volver\" para volver a sus registros regulares.';

  @override
  String get hosComplianceAlerts => 'HOS Compliance Alerts';

  @override
  String get stayCompliantWithHosRegulation =>
      'Mantenerse en conformidad con las regulaciones de HOS mediante alertas de monitoreo:\\n\\n• En la pantalla principal de registros, observe el icono de exclamación roja, lo que indica una violación HOS o advertencia de forma/calificación.\\n• Revisar una lista de violaciones HOS al desplazarse por debajo del gráfico de registro. Tapping on a violation provides more details.';

  @override
  String get createDvir => 'Crear DVIR';

  @override
  String get createANewInspectionReportNNAc =>
      'Crear un nuevo informe de inspección:\\n\\n• Accede al menú y selecciona DVIR.\\n• Pulsa el signo más para iniciar una nueva inspección.\\n• Revise la lista de componentes del vehículo y marque cualquiera con defectos detectados.\\n• Añadir notas en la sección Observaciones si es necesario.\\n• Pulse Iniciar sesión para finalizar y guardar el informe en la historia de DVIR.';

  @override
  String get editDvir => 'Editar DVIR';

  @override
  String get editAnExistingReportNNGoToDvir =>
      'Editar un informe existente:\\n\\n• Ir a la historia de DVIR y seleccionar el informe que desea editar.\\n• Haga clic en el botón \"...\".\\n• Seleccione Editar para hacer cambios.';

  @override
  String get deleteDvir => 'Suprímase DVIR';

  @override
  String get deleteAnExistingReportNNInDvir =>
      'Eliminar un informe existente:\\n\\n• En DVIR History, seleccione el informe para eliminar.\\n• Haga clic en el botón \"...\".\\n• Seleccione Eliminar y confirme la eliminación.';

  @override
  String get infoPacketManualBlurb =>
      'El manual del usuario, la hoja de instrucciones y la hoja de instrucciones de mal funcionamiento pueden estar en forma electrónica. Esto se ajusta al registro federal titulado \"Guía normativa relativa a las firmas y documentos electrónicos\" (76 FR 411).';

  @override
  String get infoPacketInstructionsBlurb =>
      'Además de lo anterior, un suministro de registros de estado de derecho de conductor en blanco (RODS) de gráficos suficientes para registrar el estado de servicio del conductor y otra información relacionada por un mínimo de 8 días debe estar a bordo del vehículo de motor comercial (CMV).';

  @override
  String packetIncompleteMissing(String missing) {
    return 'Packet incomplete: $missing';
  }

  @override
  String get recordsOfDutyStatus => 'Actas\nEstado de derecho';

  @override
  String get availableHoursAndRequiredBreaks =>
      'Horas disponibles y\nRomperes requeridos';

  @override
  String get interAndIntrastateHosRules => 'Inter- and Intrastate\nHOS Rules';

  @override
  String get roadsideInspectionFunction => 'Inspección de carreteras\nFunción';

  @override
  String get vehicleInspectionReports => 'Inspección de vehículos\nInformes';

  @override
  String get onlineFleetManagerPortal => 'Flota en línea\nManager Portal';

  @override
  String get trackYourVehicleSLocationIn =>
      'Seguimiento de la ubicación de su vehículo en tiempo real para mejorar la gestión de flotas y la seguridad.';

  @override
  String get setUpFleetManagerPortal => 'Configurar la flota\nManager Portal';

  @override
  String get monitorHosAndFmcsaCompliance => 'Monitor HOS y\nFMCSA-Compliance';

  @override
  String get stayOnTopOfDriversDuty =>
      'Mantente al tanto del estado de servicio de los conductores y horas restantes en tiempo real. Recibir notificaciones sobre violaciones del HOS y acceder a registros de violación archivados.';

  @override
  String get trackYourDriversCurrentOrLast =>
      'Rastree la ubicación actual o última de sus conductores, el vehículo impulsado, y su información de contacto sin esfuerzo.';

  @override
  String get downloadAnyDriversLogsInPdf =>
      'Descargue los registros de cualquier controlador en formato PDF con unos pocos clics. En caso de inspección por carretera, envíe fácilmente registros a un oficial de FMCSA desde el portal en línea.';

  @override
  String get beginByLocatingTheEcmDiagnostic =>
      'Comience localizando el puerto ECM (diagnóstico) en su vehículo. Este puerto se encuentra típicamente en o cerca del panel, debajo de la columna de dirección, o cerca del asiento del conductor. Dependiendo del tipo de vehículo, utilice la conexión adecuada:\n\n• Conector de 6 pines: Común en vehículos comerciales antiguos.\n• Conector de 9 pines: Estándar en la mayoría de los camiones comerciales modernos.\n• Conector OBDII: Típicamente encontrado en vehículos comerciales ligeros y coches de pasajeros.\n\nUna vez que haya identificado el conector correcto, adjunte de forma segura el hardware ELD al puerto utilizando el cable apropiado proporcionado. Asegúrese de que el dispositivo ELD está firmemente montado en su panel de control donde permanece visible y accesible para la operación. Esta colocación es crucial para facilitar el uso durante sus procesos de conducción e inspección.';

  @override
  String get beforeYouStartUsingTheEld =>
      'Antes de comenzar a utilizar el ELD, asegúrese de que su dispositivo móvil está conectado a Internet y Bluetooth está habilitado:\n\n• Instalación del software ELD: Descargue la aplicación ELD de la tienda de aplicaciones de su dispositivo y siga las instrucciones en pantalla para completar la instalación.\n• Iniciar sesión: Utilice sus credenciales proporcionadas para acceder a la aplicación. Si encuentra problemas de login, verifique sus credenciales con su administrador de flotas o contacte con el cliente.\n• Sincronizar su dispositivo con el hardware ELD: Después de iniciar sesión, seleccione su vehículo de la lista para sincronizar su dispositivo móvil con el hardware ELD.';

  @override
  String get onceTheEldIsSetUp =>
      'Una vez que se establece el ELD, se registra automáticamente el tiempo de conducción. Cualquier movimiento a 5 mph o más rápido se registra como conducción. Cuando es estacionario, el conductor puede seleccionar un estado de servicio diferente. El sistema calcula y muestra:\n\n• Límites en servicio\n• Tiempo de conducción disponible\n• Períodos requeridos y fuera de servicio\n\nEsta información se muestra en la sección Estado de la aplicación para conductores y en el portal en línea para gestores de flotas, asegurando el cumplimiento de las regulaciones HOS.';

  @override
  String get duringARoadsideInspectionFollowThese =>
      'Durante una inspección por carretera, siga estos pasos:\n\n• Acceso al modo \"Inspección de DOT\" del menú principal.\n• Pulse \"Iniciar la Inspección\" para mostrar sus Registros de Estado de deber (RODS) al oficial.\n• Utilice las flechas de navegación para revisar los registros por fecha.\n• Si se solicita, envíe su RODS a través de servicios web o correo electrónico seleccionando el botón \"Enviar\".\n• Una vez que la inspección esté completa, pulse \"Volver\" para volver a sus registros regulares.';

  @override
  String get stayCompliantWithHosRegulationsBy =>
      'Mantenerse en conformidad con las regulaciones de HOS mediante alertas de monitoreo:\n\n• En la pantalla principal de registros, observe el icono de exclamación roja, lo que indica una violación HOS o advertencia de forma/calificación.\n• Revisar una lista de violaciones de HOS por debajo del gráfico de registro. Tapping on a violation provides more details.';

  @override
  String get createANewInspectionReportAccess =>
      'Crear un nuevo informe de inspección:\n\n• Accede al menú y selecciona DVIR.\n• Pulse el signo plus para iniciar una nueva inspección.\n• Revisar la lista de componentes del vehículo y marcar cualquiera con defectos detectados.\n• Agregue notas en la sección Observaciones si es necesario.\n• Pulse Sign para finalizar y guardar el informe en la historia de DVIR.';

  @override
  String get editAnExistingReportGoTo =>
      'Editar un informe existente:\n\n• Ir a DVIR Historia y seleccionar el informe que desea editar.\n• Haga clic en el botón \"...\".\n• Elige Editar para hacer cambios.';

  @override
  String get deleteAnExistingReportInDvir =>
      'Suprimir un informe existente:\n\n• En DVIR History, seleccione el informe para borrar.\n• Haga clic en el botón \"...\".\n• Elige Eliminar y confirmar la eliminación.';

  @override
  String get pleaseContactYourFleetManagerTo =>
      'Por favor contacte con su gerente de flota para cambiar su\ninformación de la cuenta.';

  @override
  String todayLogDate(Object date) {
    return 'Hoy - $date';
  }

  @override
  String get enterTheTrailerNumber => 'Introduzca el número de remolque.';

  @override
  String get trailerNumberMustBeLettersNumbers =>
      'El número de remolque debe ser letras, números o hyphens (max 50).';

  @override
  String get enterTheDocumentNumber => 'Introduzca el número de documento.';

  @override
  String get shippingDocumentNumberIsTooLong =>
      'El número de documento de envío es demasiado largo (max 100).';

  @override
  String get enterOneDocumentAtATime =>
      'Introduzca un documento a la vez (sin coma).';

  @override
  String get reasonForChange => 'Razón del cambio';

  @override
  String get enterReasonRequired => 'Introducir razón (Requirido)';

  @override
  String get aReasonForTheChangeIs => 'Se requiere una razón para el cambio.';

  @override
  String get cannotSaveDriverSessionNotFound =>
      'No se puede guardar: sesión de conductor no encontrada.';

  @override
  String get automaticDrivingTimeCannotBeShortened =>
      'El tiempo de conducción automático no puede ser acortado o eliminado.';

  @override
  String get eventSavedSuccessfully => 'Evento guardado con éxito';

  @override
  String get reCertificationRequiredEditsWereMade =>
      'Recertificación requerida: Las ediciones fueron hechas después de su última firma.';

  @override
  String get typeHere => 'Tipo aquí';

  @override
  String get noDocumentsAdded => 'No se han añadido documentos';

  @override
  String get delete => 'DELETE';

  @override
  String get carrierProposedEdits39530Are =>
      'Las ediciones propuestas por el transportista (§395.30) se revisan dentro de cada registro en la pestaña Certificar (Aceptar / Rechazar).';

  @override
  String get unidentifiedDrivingIsReviewedInUnidentified =>
      'La conducción no identificada se revisa en eventos no identificados.';

  @override
  String get noTrailersAdded => 'No hay trailers añadidos';

  @override
  String get noVehicleIsSelected => 'No se selecciona ningún vehículo.';

  @override
  String get anAnnotationIsRequired => 'Se requiere una anotación.';

  @override
  String get yourRecordWasUpdatedReviewThe =>
      'Su registro fue actualizado. Revise el registro diario; puede necesitar recertificación.';

  @override
  String get assume => 'ASSUME';

  @override
  String get requiredAnnotationThisTimeIsAssumed =>
      'Anotación necesaria. Esta vez se supone que conduce.';

  @override
  String get notMine => 'NO MINE';

  @override
  String get requiredRejectionReason => 'Razón de rechazo requerido';

  @override
  String get overdue => 'Overdue';

  @override
  String get originalRecordPreserved => 'Registro original conservado';

  @override
  String get byDate => 'Hasta la fecha...';

  @override
  String get currentVehicleOnly => 'Vehículos corrientes únicamente';

  @override
  String get clearFilters => 'Filtros claros';

  @override
  String get currentVehicle => 'Vehículos corrientes';

  @override
  String get responseWasInterrupted => 'La respuesta fue interrumpida.';

  @override
  String get pleaseDrawASignatureFirst =>
      'Por favor, dibuje una firma primero.';

  @override
  String get logSuccessfullyCertified => 'Certificación exitosa.';

  @override
  String get notReadyForCertification => 'No está listo para la certificación';

  @override
  String get pleaseResolveTheFollowingIssuesBefore =>
      'Por favor, resuelva los siguientes problemas antes de certificar su registro:';

  @override
  String get carrierEditsMustBeAcceptedOr =>
      'Las ediciones del transportista deben ser aceptadas o rechazadas antes de la certificación.';

  @override
  String get carrierEditAcceptedReCertifyThe =>
      'Se acepta la edición de Carrier. Re-certificar el registro.';

  @override
  String get carrierEditRejected => 'La edición de Carrier rechazó.';

  @override
  String get sessionMissingPleaseLogInAgain =>
      'Falta la sesión. Por favor, vuelva a entrar.';

  @override
  String get carrierProposedEdit => 'Carrier propuso la edición';

  @override
  String get reject => 'REJECT';

  @override
  String get accept => 'ACCEPT';

  @override
  String get selectAVehicleBeforeSavingThe =>
      'Seleccione un vehículo antes de guardar el formulario.';

  @override
  String get coDriverMustBeAServer =>
      'Co-driver debe ser un servidor id antes de que pueda ser guardado.';

  @override
  String get keepAPaperLogForThatDayAndUnti =>
      'Mantenga un registro de papel para ese día y hasta que el dispositivo sea reparado o reemplazado. En caso de inspección, muestre los 7 días anteriores de la aplicación.';

  @override
  String get inTheEventOfAnEldMalfunctionTh =>
      'En caso de mal funcionamiento del ELD, el motor debe tomar acciones para corregir el mal funcionamiento dentro de los 8 días de descubrimiento.';

  @override
  String get anInspectorMayViewTheLogFormTh =>
      'Un inspector puede ver el formulario de registro, el gráfico de registro y los eventos de registro con notas.';

  @override
  String get theEventCouldNotBeSaved => 'El evento no pudo ser salvado.';

  @override
  String get theEventWasSavedButThe =>
      'El evento se salvó, pero la auditoría de cambio no se pudo registrar.';

  @override
  String get transferAuditTitle => 'Auditoría de las transferencias';

  @override
  String get noTransfersFromServer => 'El servidor no devolvió transferencias.';

  @override
  String transferAuditNotLoaded(Object error) {
    return 'No se cargó la auditoría de transferencia: $error';
  }

  @override
  String get driving24h => '24 horas';

  @override
  String pendingDays(Object days) {
    return 'Pending $days día(s)';
  }

  @override
  String get enterTrailerNumber => 'Introduzca el número de remolque.';

  @override
  String get trailerNumberFormatError =>
      'El número de remolque debe ser letras, números o hyphens (max 50).';

  @override
  String get enterDocumentNumber => 'Introduzca el número de documento.';

  @override
  String get documentNumberTooLong =>
      'El número de documento de envío es demasiado largo (max 100).';

  @override
  String get oneDocumentAtATime =>
      'Introduzca un documento a la vez (sin coma).';

  @override
  String get selectVehicleBeforeSavingForm =>
      'Seleccione un vehículo antes de guardar el formulario.';

  @override
  String get coDriverMustBeServerId =>
      'Co-driver debe ser un servidor id antes de que pueda ser guardado.';

  @override
  String get serverSavedFormIncomplete =>
      'El servidor guardó el formulario y lo dejó incompleto.';

  @override
  String get serverSavedFormNoStatus =>
      'El servidor guardó el formulario pero no devolvió un estado de formulario.';

  @override
  String get responseInterrupted => 'La respuesta fue interrumpida.';

  @override
  String get drawSignatureFirst => 'Por favor, dibuje una firma primero.';

  @override
  String get drawYourSignatureHere => 'Dibuja tu firma aquí';

  @override
  String get certifyLegalStatement =>
      'Por la presente certifico que mis entradas de datos y mi historial de estado de servicio para este período de 24 horas son verdaderas y correctas.';

  @override
  String get errNoInternet =>
      'Sin conexión a internet. Revisa la red e intenta de nuevo.';

  @override
  String get errRequestFailed =>
      'La solicitud no puede completarse. Prueba otra vez.';

  @override
  String get errRequestFailedNetwork =>
      'La solicitud no puede completarse. Revisa la red e intenta de nuevo.';

  @override
  String get errCannotReachServer =>
      'No podía llegar al servidor. Revisa la red e intenta de nuevo.';

  @override
  String get errServerRejected => 'El servidor rechazó esta solicitud.';

  @override
  String get errSessionExpiredAction =>
      'El período de sesiones venció. Firma de nuevo.';

  @override
  String get errPermissionDenied => 'No se te permite hacer esto.';

  @override
  String get errNotFound => 'El servidor no encontró este artículo.';

  @override
  String get errServerError =>
      'El servidor devolvió un error. Prueba otra vez.';

  @override
  String get errGeneric => 'La solicitud no puede completarse.';

  @override
  String get enterAReasonForManualRecording =>
      'Introduzca una razón para la grabación manual.';

  @override
  String get couldNotUpdateManualRecordingM =>
      'No podía actualizar el modo de grabación manual. Prueba otra vez.';

  @override
  String get unableToConnectToEld => 'Incapaz de conectarse al ELD.';

  @override
  String get checkBluetoothAndRetry =>
      'Comprueba que el dispositivo y Bluetooth están encendidos, y luego prueba de nuevo.';

  @override
  String get checkNetworkAndRetry =>
      'Revise la red y el dispositivo, luego vuelva a intentarlo.';

  @override
  String get driverSessionMissingSignIn =>
      'Falta la sesión del conductor. Inicie nuevamente antes de la inspección.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'NEXT';

  @override
  String get onboardingGetStarted => 'Empieza';

  @override
  String get onboardingTitle1 => 'Sus horas, grabadas automáticamente';

  @override
  String get onboardingBody1 =>
      'El ELD rastrea su estado de conducción contra FMCSA limita el momento en que el vehículo se mueve —sin papeleo, sin adivinación.';

  @override
  String get onboardingTitle2 => 'Inspeccione su vehículo con confianza';

  @override
  String get onboardingBody2 =>
      'DVIR diario antes y después del viaje, rastreo de defectos con certificaciones de reparación, y revisión §396.13 — todo en un lugar.';

  @override
  String get onboardingTitle3 => 'Siempre listo para el inspector';

  @override
  String get onboardingBody3 =>
      'Sus registros, paquetes de información y opciones de transferencia viven en el dispositivo, incluso cuando no hay Internet en la carretera.';

  @override
  String startedOnDate(Object date) {
    return 'Inicio: $date';
  }

  @override
  String get tableTimeEt => 'Hora ET';

  @override
  String certEventStatus(Object status) {
    return 'Cert · $status';
  }

  @override
  String eventCodeNote(Object code) {
    return 'Código: $code';
  }

  @override
  String originNote(Object origin) {
    return 'Origen: $origin';
  }

  @override
  String notesNote(Object notes) {
    return 'Notas: $notes';
  }

  @override
  String get inspectionCommentErrorLength =>
      'El comentario debe ser de 4 a 60 caracteres.';

  @override
  String get enterValidEmail => 'Introduzca un correo electrónico válido.';

  @override
  String get transferAccepted =>
      'El servidor aceptó la solicitud de transferencia.';

  @override
  String get sendLogsViaEmail => 'Enviar registros vía correo electrónico';

  @override
  String get send8Logs => 'Enviar 8 registros';

  @override
  String get recipientEmail => 'Recipiente Email';

  @override
  String get comment => 'Comentario';

  @override
  String get dataTransferType => 'Tipo de transferencia de datos';

  @override
  String get sendAction => 'FIN';

  @override
  String get inspectLogs24 =>
      'Registros de inspección para el período de 24 horas y los días anteriores para un ciclo HOS';

  @override
  String get setPinGuidance =>
      'Establecer un PIN, seleccione \"Iniciar la Inspección\", y dar su dispositivo al oficial';

  @override
  String get eldCertifies =>
      'Este ELD certifica que el uso de la aplicación con el dispositivo ELD cumple con todos los requisitos para ELD definidos en la regulación Federal Motor Carrier Safety 49 CFR part 395 Subpart B.';

  @override
  String get notAllowedByServer =>
      'No disponible para esta cuenta por el servidor.';

  @override
  String get startInspectionUpper => 'START INSPECTION';

  @override
  String get serverDoesNotAllow =>
      'El servidor no permite iniciar una inspección ahora mismo.';

  @override
  String get sendLogsFor24 =>
      'Enviar registros durante el período de 24 horas y los días anteriores para un ciclo HOS';

  @override
  String get sendLogsToOfficer =>
      'Enviar sus registros al oficial si lo solicitan';

  @override
  String get sendLogsUpper => 'SEND LOGS';

  @override
  String get emailLogs24Pdf =>
      'Registros de correo electrónico para el período de 24 horas y los días anteriores para un ciclo HOS como PDF';

  @override
  String get emailLogsPdf => 'Envíe sus registros en formato PDF';

  @override
  String get emailLogsUpper => 'LOGS EMAIL';

  @override
  String get infoPacketUpper => 'INFORMATION PACKET';

  @override
  String get inspectionPinTitle => 'Inspección PIN';

  @override
  String get enter4Digits => 'PIN debe ser 4 dígitos.';

  @override
  String get pinsDoNotMatch => 'Los PIN no coinciden.';

  @override
  String get pinLabel => 'PIN';

  @override
  String get confirmPinLabel => 'Confirme PIN';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get enterInspectionPin => 'Ingrese la inspección PIN.';

  @override
  String get incorrectPin => 'Incorrecto.';

  @override
  String get driverExit => 'Salida del conductor';

  @override
  String get exitAction => 'Exit';

  @override
  String get enterNewPinOfficer =>
      'Ingrese un nuevo PIN de inspección para ser dado al oficial';

  @override
  String get enterSamePinToExit =>
      'Introduzca el mismo PIN para salir del modo de inspección';

  @override
  String get setPinGuidanceDialog =>
      'Establecer un PIN de 4 dígitos para bloquear la pantalla. El oficial sólo puede ver registros y no puede salir sin la contraseña del conductor.';

  @override
  String get enterPinToExitGuidance =>
      'Ingrese el PIN de inspección que se establece al comenzar. El oficial no puede salir de aquí.';

  @override
  String get menuTitle => 'Menú';

  @override
  String get vehicleInMotionTitle => 'Vehículo en movimiento';

  @override
  String get vehicleInMotionDesc =>
      'Para cumplir con los reglamentos de FMCSA y las normas de seguridad, la aplicación está bloqueada mientras conduce. Se desbloqueará cuando el vehículo se detenga.';

  @override
  String get weakConnectionDelayedData =>
      'Conexión débil. Algunos datos pueden retrasarse.';

  @override
  String get noInternetConnection => 'Sin conexión a internet.';

  @override
  String get connectionStatusUnknown => 'Se desconoce el estado de conexión.';

  @override
  String driveLimitFormat(String drive) {
    return '$drive-Hour Driving Limit';
  }

  @override
  String shiftLimitFormat(String shift) {
    return '$shift-Hour On Duty Limit';
  }

  @override
  String breakLimitFormat(String rest) {
    return '$rest Minute Rest Break';
  }

  @override
  String usedFormat(String description) {
    return '$description · Usado';
  }

  @override
  String get noticeTitle => 'Aviso';

  @override
  String get gpsTurnedOff => 'El GPS está apagado.';

  @override
  String get serverReportsEldAlert =>
      'El servidor informa de una alerta operacional ELD. Abra la pantalla de Conexión para obtener detalles.';

  @override
  String get operationalAlertTooltip => 'Alerta operacional';

  @override
  String get noInternetBanner =>
      'Sin internet. Puede continuar con datos guardados.';

  @override
  String get dvirSatisfactory => 'Condición del vehículo Satisfactoria';

  @override
  String get dvirHasDefects => 'Tiene defectos';

  @override
  String get dvirDefectsCorrected => 'Defectos corregidos';

  @override
  String get dvirDefectsNotCorrected =>
      'Los defectos no necesitan ser corregidos';

  @override
  String get dvirDefectRecorded => '- un defecto se registra';

  @override
  String get dvirNoRepairCert => 'No hay certificación de reparación todavía';

  @override
  String get dvirSetByCarrier => 'fijado por el transportista, no el conductor';

  @override
  String get dvirTimeUnavailable =>
      'El tiempo de inspección no está disponible. Conecta e intenta de nuevo.';

  @override
  String get dvirSavedCannotEdit =>
      'Un informe guardado no puede ser editado en este dispositivo.';

  @override
  String get dvirSignatureRequired => 'Se requiere una firma.';

  @override
  String get dvirDriverSessionMissing =>
      'Falta la sesión del conductor. Inicie sesión nuevamente antes de firmar el informe.';

  @override
  String get dvirVehicleIdMissing =>
      'El vehículo está desaparecido. Seleccione un vehículo antes de firmar.';

  @override
  String get dvirPrevNoServerId =>
      'El informe anterior no tiene id servidor y no puede ser revisado.';

  @override
  String get dvirPreviousInspection => 'Inspección anterior';

  @override
  String get dvirReviewBeforeDriving =>
      'Revisar y firmar el informe anterior antes de conducir.';

  @override
  String get dvirRecordedDefects => 'Defectos registrados:';

  @override
  String get dvirNone => 'Ninguno.';

  @override
  String get dvirRepairStatus => 'Estado de reparación:';

  @override
  String get dvirReviewed => 'Reviewed';

  @override
  String get dvirLocationUnavailable => 'Ubicación no disponible';

  @override
  String get dvirCompanyUnavailable => 'Empresa no disponible';

  @override
  String get dvirTimeUnavailableShort => 'Tiempo indisponible';

  @override
  String get dvirInsertDvir => 'Insertar DVIR';

  @override
  String get dvirPreviousReviewNotice =>
      'Anterior DVIR Review — §396.13. La apertura del informe no es un examen.';

  @override
  String get dvirTimeET => 'Tiempo (ET)';

  @override
  String get dvirOdometerMi => 'Odómetro (mi)';

  @override
  String get dvirOdometerHint => 'Odometer';

  @override
  String get company => 'Company';

  @override
  String get remarks => 'Observaciones';

  @override
  String get dvirImageNotAvailable => 'Imagen no disponible.';

  @override
  String get dvirClearSignature => 'Firma clara';

  @override
  String get dvirSigned => 'SIGNED';

  @override
  String get dvirSign => 'SIGN';

  @override
  String get removeAction => 'Retirar';

  @override
  String get addDefects => 'Añadir defectos';

  @override
  String get dvirDefects396_11 => 'Defectos (§396.11)';

  @override
  String get dvirLoadDefectsFail =>
      'No podía cargar la lista de defectos del servidor.';

  @override
  String get retryAction => 'RETRY';

  @override
  String get dvirCatalogEmpty => 'El catálogo está vacío.';

  @override
  String get dvirSafetyAffecting => 'Seguridad que afecta';

  @override
  String get dvirDescriptionOptional => 'Descripción (opcional)';

  @override
  String get eldDiagnosticReading => 'Estado de conexión de lectura...';

  @override
  String eldDiagnosticDiagnosticFormat(String diagnostics) {
    return 'Diagnóstico: $diagnostics';
  }

  @override
  String eldDiagnosticMalfunctionFormat(String malfunctions) {
    return 'Malfuncionamiento: $malfunctions';
  }

  @override
  String eldDiagnosticLastValidDataFormat(String lastHeartbeat) {
    return 'Últimos datos válidos: $lastHeartbeat';
  }

  @override
  String eldDiagnosticDataAgeFormat(String dataAgeSeconds) {
    return 'Edad de los datos: $dataAgeSeconds segundos';
  }

  @override
  String get eldDiagnosticNotReady =>
      'No está listo para una operación normal.';

  @override
  String get eldDiagnosticDataNotReliable => 'Los datos no son fiables.';

  @override
  String get eldDiagnosticConnected => 'Conectado';

  @override
  String get eldDiagnosticDisconnected => 'Desconectado';

  @override
  String get eldDiagnosticUnavailable => 'No disponible';

  @override
  String get eldDiagnosticMalfunction => 'Mal funcionamiento';

  @override
  String get eldDiagnosticNoConnectionStatus =>
      'El servidor no devolvió un estado de conexión.';

  @override
  String get eldReadinessTitle => 'Pre-operation preparedness';

  @override
  String get eldReadinessChecking => 'Comprobando la preparación...';

  @override
  String get eldReadinessReady => 'Listo para la operación';

  @override
  String get eldReadinessNotReady => 'No está listo para la operación';

  @override
  String eldReadinessRecommendedActionFormat(String action) {
    return 'Acción recomendada: $action';
  }

  @override
  String get eldReadinessDevicePaired => 'Dispositivo emparejado';

  @override
  String get eldReadinessConnectionActive => 'Conexión activa';

  @override
  String get eldReadinessMotionData => 'Datos de movimiento';

  @override
  String get eldReadinessLocationData => 'Datos de ubicación';

  @override
  String get eldReadinessEngineTelemetry => 'Telemetría del motor (ECM)';

  @override
  String get eldMalfunctionTitle => 'Si el ELD funciona mal (§395.34)';

  @override
  String get eldMalfunctionStep1 =>
      'Observe el mal funcionamiento y notifique por escrito al transportista dentro de 24 horas.';

  @override
  String get eldMalfunctionStep2 =>
      'Reconstruir las 24 horas actuales y los 7 días anteriores sobre papel si el ELD no puede proporcionarlos.';

  @override
  String get eldMalfunctionStep3 =>
      'Continúe los registros de papel hasta que el dispositivo esté reparado.';

  @override
  String get eldMalfunctionManualActive => 'La grabación manual está activa.';

  @override
  String eldMalfunctionManualActiveWithReason(String reason) {
    return 'La grabación manual es activa — $reason.';
  }

  @override
  String get eldMalfunctionEndManual => 'FIN MANUAL RECORDING';

  @override
  String get eldMalfunctionServerNotAllow =>
      'El servidor no permite la grabación manual para este vehículo.';

  @override
  String get eldMalfunctionStartManual => 'START MANUAL RECORDING';

  @override
  String get eldMalfunctionStartSuccess =>
      'El inicio de grabación manual se registró en el servidor.';

  @override
  String get eldMalfunctionEndSuccess =>
      'Se terminó la grabación manual; se reanudó la grabación electrónica.';

  @override
  String get eldMalfunctionReasonStart => 'Razón de grabación manual';

  @override
  String get eldMalfunctionReasonEnd =>
      'Motivo para terminar la grabación manual';

  @override
  String get eldMalfunctionHintStart =>
      'por ejemplo, pérdida de conexión con el ELD';

  @override
  String get eldMalfunctionHintEnd => 'por ejemplo, la conexión ELD restaurada';

  @override
  String get dvirListNoRecords => 'No Records';

  @override
  String get dvirListTotal => 'Total';

  @override
  String get dvirListOpen => 'Abierto';

  @override
  String get dvirListSigned => 'Signed';

  @override
  String get dvirListOos => 'OOS';

  @override
  String get serverAcceptedDisconnected =>
      'El servidor aceptó el modo desconectado. No se creó ningún evento de servicio local.';

  @override
  String get macAddressRequired => 'Se requiere dirección MAC.';

  @override
  String get coDriverSelectLabel => 'Seleccione Co-driver';

  @override
  String get coDriverSelectHint => 'Seleccione su copiloto';

  @override
  String get coDriverSwitchDrivers => 'Controladores de interruptores';

  @override
  String get coDriverSwitchHint =>
      'Te convertirás en copiloto. Tu copiloto seguirá siendo conductor.';

  @override
  String get coDriverSwitching => 'Cambiar...';

  @override
  String get coDriverSwitchAction => 'SWITCH';

  @override
  String get coDriverConfirmSwitchTitle => 'Cambiar de confirmación';

  @override
  String get coDriverConfirmSwitchBody =>
      'Esto pide al servidor que cambie los roles. Las horas no se copian y el estado de servicio no se cambia.';

  @override
  String get coDriverRolesSwitchedTitle => 'Funciones conmutadas';

  @override
  String coDriverRolesSwitchedBody(String newPrimary) {
    return 'Ahora eres el copiloto.\n$newPrimary es ahora el conductor principal.\n\nNo se copiaron las horas y no se cambió el estado de servicio. El nuevo conductor se pone de servicio antes de moverse.';
  }

  @override
  String get coDriverDefaultNewPrimary => 'El copiloto';

  @override
  String get coDriverNone => 'Sin copiloto';

  @override
  String get coDriverRefusalSessionMissing =>
      'Falta la sesión del conductor. Inicie sesión antes de cambiar.';

  @override
  String get coDriverRefusalStillDriving =>
      'Cambiar el estado de derecho antes de la entrega. El interruptor no lo cambia.';

  @override
  String get coDriverRefusalMotionUnknown =>
      'El movimiento del vehículo es desconocido. Eso no se trata como detenido.';

  @override
  String get coDriverRefusalThresholdMissing =>
      'El umbral de movimiento no está disponible.';

  @override
  String get coDriverRefusalVehicleMoving =>
      'Las funciones sólo se pueden cambiar cuando se detiene el vehículo.';

  @override
  String get coDriverRefusalCoDriverMissing =>
      'Seleccione un copiloto antes de cambiar.';

  @override
  String get coDriverRefusalSameDriver =>
      'La cuenta actual no puede ser seleccionada como el copiloto.';

  @override
  String get coDriverLinkedTitle => 'Co-driver vinculado';

  @override
  String get coDriverLinkNotRead => 'El enlace no ha sido leído.';

  @override
  String get coDriverLinkNone => 'Ningún copiloto vinculado.';

  @override
  String get coDriverTeamDrivingActive => 'Equipo que conduce activo';

  @override
  String get coDriverTeamDrivingInactive => 'Equipo que conduce inactivo';

  @override
  String get coDriverHosIsolationReadError =>
      'No se podía leer el estado de aislamiento del HOS.';

  @override
  String get coDriverHosIsolated => 'Registros aislados de HOS';

  @override
  String get coDriverHosNotIsolated => 'HOS records not isolated';

  @override
  String get coDriverVehicleMissing =>
      'Seleccione un vehículo antes de conectar un copiloto.';

  @override
  String get dvirDefectsNone => 'No hay defectos que reportar.';

  @override
  String dvirDefectsCount(int defectCount) {
    return '$defectCount defectos seleccionados.';
  }

  @override
  String get languageSpanish => 'Español';

  @override
  String get reCertificationRequiredMsg =>
      'Recertificación requerida: Se realizaron ediciones después de su última firma.';

  @override
  String get statusOff => 'Fuera de servicio';

  @override
  String get statusSb => 'Litera';

  @override
  String get statusD => 'Conduciendo';

  @override
  String get statusOn => 'De servicio';

  @override
  String get statusPc => 'Uso personal';

  @override
  String get statusYm => 'Movimiento en patio';

  @override
  String get dvirPreTrip => 'Pre-Viaje';

  @override
  String get dvirPostTrip => 'Post-Viaje';

  @override
  String get dvirSafeToDrive => 'Seguro para Conducir';

  @override
  String get dvirNeedsRepair => 'Necesita Reparación';

  @override
  String get dvirUnsafe => 'Inseguro';

  @override
  String get dvirBrakes => 'Frenos';

  @override
  String get dvirTires => 'Llantas';

  @override
  String get dvirLights => 'Luces';

  @override
  String get dvirSteering => 'Dirección';

  @override
  String get dvirTrailerCoupling => 'Acoplamiento del remolque';

  @override
  String get dvirEmergencyEquipment => 'Equipo de Emergencia';

  @override
  String get dvirEngine => 'Motor';

  @override
  String get dvirFuelSystem => 'Sistema de Combustible';

  @override
  String get dvirExhaustSystem => 'Sistema de Escape';

  @override
  String get dvirSuspension => 'Suspensión';

  @override
  String get dvirMirrors => 'Espejos';

  @override
  String get dvirWindshield => 'Parabrisas';

  @override
  String get routingCode => 'Código de enrutamiento';

  @override
  String get routingCodeHint =>
      'Ingrese el código de enrutamiento del inspector';

  @override
  String get tooManyPinAttempts =>
      'Demasiados intentos incorrectos. Espere e intente de nuevo.';

  @override
  String get reviewedBy => 'Revisado por';

  @override
  String get companyName => 'Compañía';

  @override
  String get edit => 'Editar';

  @override
  String get diagnosticsScreen => 'Diagnósticos';

  @override
  String get diagnosticEvents => 'Eventos de diagnóstico de datos';
}
