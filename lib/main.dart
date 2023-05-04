import 'dart:developer';
import 'dart:io' show Platform;

import 'package:contacts_plus_plus/clients/neos_hub.dart';
import 'package:contacts_plus_plus/clients/settings_client.dart';
import 'package:contacts_plus_plus/widgets/friends_list.dart';
import 'package:contacts_plus_plus/widgets/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';
import 'clients/api_client.dart';
import 'models/authentication_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await Workmanager().initialize(
        callbackDispatcher, // The top level function, aka callbackDispatcher
        isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
    );
  }

  Logger.root.onRecord.listen((event) => log(event.message, name: event.loggerName));
  final settingsClient = SettingsClient();
  await settingsClient.loadSettings();
  runApp(Phoenix(child: ContactsPlusPlus(settingsClient: settingsClient,)));
}

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    debugPrint("Native called background task: $task"); //simpleTask will be emitted here.
    if (task == NeosHub.taskName) {
      final unreads = NeosHub.backgroundCheckUnreads(inputData);
    }
    return Future.value(true);
  });
}

class ContactsPlusPlus extends StatefulWidget {
  const ContactsPlusPlus({required this.settingsClient, super.key});

  final SettingsClient settingsClient;

  @override
  State<ContactsPlusPlus> createState() => _ContactsPlusPlusState();
}

class _ContactsPlusPlusState extends State<ContactsPlusPlus> {
  final Typography _typography = Typography.material2021(platform: TargetPlatform.android);
  AuthenticationData _authData = AuthenticationData.unauthenticated();

  @override
  Widget build(BuildContext context) {
    return ClientHolder(
      settingsClient: widget.settingsClient,
      authenticationData: _authData,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Contacts++',
        theme: ThemeData(
            useMaterial3: true,
            textTheme: _typography.white,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark)
        ),
        home: _authData.isAuthenticated ?
        const FriendsList() :
        LoginScreen(
          onLoginSuccessful: (AuthenticationData authData) async {
            if (authData.isAuthenticated) {
              setState(() {
                _authData = authData;
              });
            }
          },
        ),
      ),
    );
  }
}
