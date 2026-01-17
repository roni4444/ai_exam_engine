import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load notification preference
    setState(() {
      _notificationsEnabled = true; // Load from secure storage
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(title: 'Appearance', children: [_buildThemeModeSelector(), const Divider(), _buildColorSelector()]),
          const SizedBox(height: 24),
          _buildSection(title: 'Notifications', children: [_buildNotificationToggle(), const Divider(), _buildTestNotificationButton()]),
          const SizedBox(height: 24),
          _buildSection(title: 'Account', children: [_buildAccountInfo(), const Divider(), _buildSignOutButton()]),
          const SizedBox(height: 24),
          _buildSection(title: 'About', children: [_buildAboutTile()]),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 255 * 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color, letterSpacing: 1.2),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(value: AppThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: AppThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                  ButtonSegment(value: AppThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (Set<AppThemeMode> selected) {
                  themeProvider.setThemeMode(selected.first);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Primary Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ThemeProvider.availableColors.map((color) {
                  final isSelected = themeProvider.primaryColor.colorSpace == color.colorSpace;
                  return GestureDetector(
                    onTap: () => themeProvider.setPrimaryColor(color),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 255 * 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 28) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationToggle() {
    return SwitchListTile(
      title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Get notified about exam processing updates', style: TextStyle(fontSize: 12)),
      value: _notificationsEnabled,
      onChanged: (value) {
        setState(() => _notificationsEnabled = value);
        // Save to secure storage
      },
    );
  }

  Widget _buildTestNotificationButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () {
          NotificationService().showNotification(title: 'Test Notification', body: 'This is a test notification from AI Exam Engine');
        },
        icon: const Icon(Icons.notifications_outlined),
        label: const Text('Send Test Notification'),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              authProvider.profile?.fullName[0].toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(authProvider.profile?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(authProvider.user?.email ?? '', style: const TextStyle(fontSize: 12)),
        );
      },
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthProvider>().signOut();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
      ),
      title: const Text('AI Exam Engine', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Version 1.0.0\nPowered by Gemini 3', style: TextStyle(fontSize: 12)),
      isThreeLine: true,
    );
  }
}
