import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_automation_tools/all.dart';

export 'package:home_automation_tools/all.dart'
    show
        BitDemultiplexer,
        CloudBit,
        debouncer,
        Remy,
        RemyNotification,
        RemyUi,
        RemyMessage,
        RemyButton,
        RemyToDo,
        TelevisionRemote,
        TelevisionChannel,
        TelevisionSource,
        TelevisionOffTimer;

SunPowerMonitor get solar => _solar;
SunPowerMonitor _solar;

LittleBitsCloud get cloud => _cloud;
LittleBitsCloud _cloud;

Television get television => _television;
Television _television;

const String houseSensorsId = '243c201de435';
const String laundryId = '00e04c02bd93';
const String solarDisplayId = '243c201ddaf1';
const String cloudBitTest1Id = '243c201dc805';
const String cloudBitTest2Id = '243c201dcdfd';
const String thermostatId = '00e04c0355d0';

typedef ErrorReporter = void Function(String message);

ErrorReporter onError;

/// Credentials go in this order:
///   0. Littlebits authToken
///   1. Sunpower username
///   2. Sunpower password
///   3. Remy password
///   4. Television username
///   5. Television password
List<String> _credentials;
SecurityContext _securityContext;

Future<void> init() async {
  _credentials = await rootBundle.loadStructuredData('credentials.cfg', (String value) async {
    return value.split('\n');
  });
  if (_credentials.length < 5)
    throw Exception('credentials file incomplete or otherwise corrupted');
  _solar = SunPowerMonitor(
    customerUsername: _credentials[1],
    customerPassword: _credentials[2],
    onLog: (Object error) {
      if (onError != null)
        onError('SunPower: $error');
    },
  );
  _cloud = LittleBitsCloud(
    authToken: _credentials[0],
    onError: (Object error) async {
      if (onError != null)
        onError('CloudBits: $error');
    },
  );
  _television = Television(
    username: _credentials[4],
    password: _credentials[5],
  );
  _securityContext = SecurityContext()
    ..setTrustedCertificatesBytes((await rootBundle.load('ca.cert.pem')).buffer.asUint8List());
}

Remy openRemy(NotificationHandler onNotification, UiUpdateHandler onUiUpdate) {
  assert(_credentials != null);
  return Remy(
    username: 'house-of-rooves app on ${Platform.localHostname} (${Platform.operatingSystem})',
    password: _credentials[3],
    securityContext: _securityContext,
    onNotification: onNotification,
    onUiUpdate: onUiUpdate,
    onLog: (Object error) {
      if (onError != null)
        onError('Remy: $error');
    },
  );
}

void dispose() {
  _solar.dispose();
  _cloud.dispose();
}
