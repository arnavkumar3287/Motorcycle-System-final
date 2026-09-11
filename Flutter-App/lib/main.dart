import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/telemetry_simulator_service.dart';
import 'screens/dashboard_hud_screen.dart';
import 'screens/post_ride_analytics_screen.dart';
import 'screens/ubi_insurance_screen.dart';
import 'screens/predictive_maintenance_screen.dart';
import 'screens/blackbox_sos_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar / immersive cockpit mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0E14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final telemetryService = TelemetrySimulatorService();
  await telemetryService.loadDataset();

  runApp(MotorcycleSystemApp(telemetryService: telemetryService));
}

class MotorcycleSystemApp extends StatelessWidget {
  final TelemetrySimulatorService telemetryService;

  const MotorcycleSystemApp({super.key, required this.telemetryService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motorcycle Edge AI Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00FF66),
          surface: Color(0xFF14171F),
          error: Color(0xFFFF3333),
        ),
        fontFamily: 'Roboto',
      ),
      home: MainNavigationContainer(telemetryService: telemetryService),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  final TelemetrySimulatorService telemetryService;

  const MainNavigationContainer({super.key, required this.telemetryService});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardHudScreen(telemetryService: widget.telemetryService),
      PostRideAnalyticsScreen(telemetryService: widget.telemetryService),
      UbiInsuranceScreen(telemetryService: widget.telemetryService),
      PredictiveMaintenanceScreen(telemetryService: widget.telemetryService),
      BlackboxSosScreen(telemetryService: widget.telemetryService),
      SettingsScreen(telemetryService: widget.telemetryService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF14171F),
          border: Border(top: BorderSide(color: Color(0xFF222938))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF14171F),
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: Colors.white38,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_rounded),
              label: 'Cockpit HUD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Ride Score',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_rounded),
              label: 'UBI Risk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_circle_rounded),
              label: 'Maintenance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_rounded),
              label: 'SOS Box',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Config',
            ),
          ],
        ),
      ),
    );
  }
}
