import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/device.dart';
import '../services/firebase_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/candle_graph.dart';
import '../widgets/wifi_warning_overlay.dart';
import 'add_device_screen.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseService firebaseService;
  final ConnectivityService connectivityService;

  const HomeScreen({
    Key? key,
    required this.firebaseService,
    required this.connectivityService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isWifiConnected = true;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkWifi();
    // Subscribe to Wi-Fi stream
    widget.connectivityService.isWifiStream.listen((isWifi) {
      if (mounted) {
        setState(() {
          _isWifiConnected = isWifi;
        });
      }
    });
  }

  Future<void> _checkWifi() async {
    final isWifi = await widget.connectivityService.isConnectedToWifi();
    setState(() {
      _isWifiConnected = isWifi;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  void _subscribeNewsletter() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Color(0xFFFF9500),
        ),
      );
      return;
    }

    _emailController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Subscribed to SureThingNet newsletter.'),
        backgroundColor: Color(0xFF34C759),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Sleek deep dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF34C759),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SureThingNet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.grey),
            onPressed: () => _launchUrl('https://surethingnet.com'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          StreamBuilder<List<Device>>(
            stream: widget.firebaseService.getDevicesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading inventory: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              final devices = snapshot.data ?? [];

              return RefreshIndicator(
                color: const Color(0xFF34C759),
                onRefresh: () async => _checkWifi(),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Network Security Summary Card
                    _buildSummaryCard(devices),
                    const SizedBox(height: 24),

                    // Devices Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AUDITED DEVICES (${devices.length})',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddDeviceScreen(
                                  firebaseService: widget.firebaseService,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16, color: Color(0xFF34C759)),
                          label: const Text(
                            'Add Device',
                            style: TextStyle(color: Color(0xFF34C759)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Device List
                    if (devices.isEmpty)
                      _buildEmptyState()
                    else
                      ...devices.map((device) => _buildDeviceCard(device)).toList(),

                    const SizedBox(height: 40),
                    // Newsletter & Footer Section
                    _buildFooterSection(),
                  ],
                ),
              );
            },
          ),

          // Connectivity Warning Overlay
          WifiWarningOverlay(isVisible: !_isWifiConnected),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Device> devices) {
    final warningCount = devices.where((d) => d.status == DeviceStatus.warning).length;
    final criticalCount = devices.where((d) => d.status == DeviceStatus.critical).length;
    final isNetworkHealthy = warningCount == 0 && criticalCount == 0;

    Color stateColor = const Color(0xFF34C759); // Green
    String stateTitle = "Network Secure";
    String stateSubtitle = "All audited devices passed active security policies.";

    if (criticalCount > 0) {
      stateColor = const Color(0xFFFF3B30); // Red
      stateTitle = "$criticalCount Severe Threats";
      stateSubtitle = "Immediate resolution required. Devices are vulnerable or EOL.";
    } else if (warningCount > 0) {
      stateColor = const Color(0xFFFF9500); // Orange
      stateTitle = "$warningCount Policy Warnings";
      stateSubtitle = "Outdated firmware or pending End-of-Life detected.";
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stateColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNetworkHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: stateColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stateTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stateSubtitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.devices_other_rounded, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'No Audited Devices',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your home routers, smart devices, or laptops to audit firmware and lifecycle safety.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    Color statusColor;
    Color borderHighlightColor;
    
    switch (device.status) {
      case DeviceStatus.critical:
        statusColor = const Color(0xFFFF3B30);
        borderHighlightColor = const Color(0xFFFF3B30).withOpacity(0.35);
        break;
      case DeviceStatus.warning:
        statusColor = const Color(0xFFFF9500);
        borderHighlightColor = const Color(0xFFFF9500).withOpacity(0.2);
        break;
      case DeviceStatus.healthy:
        statusColor = const Color(0xFF34C759);
        borderHighlightColor = Colors.transparent;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderHighlightColor,
          width: borderHighlightColor == Colors.transparent ? 0.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Status badge & Model
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.model,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, py: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.4), width: 0.5),
                ),
                child: Text(
                  device.statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),

          // MAC and Firmware details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MAC ADDRESS', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(device.mac, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('FIRMWARE', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(
                    '${device.firmwareCurrent} (Latest: ${device.firmwareLatest})',
                    style: TextStyle(
                      color: device.firmwareCurrent != device.firmwareLatest ? const Color(0xFFFF9500) : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (device.eolDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_note_rounded, 
                  size: 14, 
                  color: device.status == DeviceStatus.critical ? const Color(0xFFFF3B30) : Colors.grey
                ),
                const SizedBox(width: 6),
                Text(
                  device.status == DeviceStatus.critical
                      ? 'End of Life reached!'
                      : 'EOL Date: ${device.eolDate!.year}-${device.eolDate!.month.toString().padLeft(2, '0')}-${device.eolDate!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: device.status == DeviceStatus.critical ? const Color(0xFFFF3B30) : Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          // Candle Health Indicator
          CandleGraph(score: device.healthScore),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: Colors.white24, height: 40),
        const Text(
          'Keep Your Network Safe',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Subscribe to our newsletter to receive the latest EOL alerts and router vulnerability updates.',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Subscription Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _subscribeNewsletter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Subscribe', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Social and Website Links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _launchUrl('https://surethingnet.com'),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF34C759), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'surethingnet.com',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
