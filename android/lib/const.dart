const String _kControlRef = 'control';
const String _kStatusRef = 'status';
const String _kStartupRef = 'startup';
const String _kTokenIDsRef = 'FCM_Registration_IDs';
const String _kFunctionsRef = 'Functions';
const String _kGraphRef = 'graph';
const String _kLogsReportsRef = 'logs/Reports';
const String _kTHRef = 'logs/TH';

String dControlRef;
String dStatusRef;
String dStartupRef;
String dTokenIDsRef;
String dFunctionsRef;
String dGraphRef;
String dLogsReportsRef;
String dTHRef;

const int kNodeReboot = 1;
const int kNodeFlash = 2;
const int kNodeUpdate = 3;

void initDefs(Map config) {
  String prefix = 'users/' +
      config['uid'] +
      '/' +
      config['domain'] +
      '/' +
      config['nodename'];

  dControlRef = prefix + _kControlRef;
  dStatusRef = prefix + _kStatusRef;
  dStartupRef = prefix + _kStartupRef;
  dTokenIDsRef = prefix + _kTokenIDsRef;
  dFunctionsRef = prefix + _kFunctionsRef;
  dGraphRef = prefix + _kGraphRef;
  dLogsReportsRef = prefix + _kLogsReportsRef;
  dTHRef = prefix + _kTHRef;
}
