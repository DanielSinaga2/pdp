import 'package:material_ui/material_ui.dart';

import 'landing_page.dart';

/// Navigasi utama yang konsisten di seluruh fitur inti aplikasi.
class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.current});

  final AppDestination current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavigationItem(
                label: 'Beranda',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: current == AppDestination.home,
                onTap: () => _go(context, AppDestination.home),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                label: 'Scan',
                icon: Icons.document_scanner_outlined,
                selectedIcon: Icons.document_scanner_rounded,
                selected: current == AppDestination.scan,
                onTap: () => _go(context, AppDestination.scan),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                label: 'Riwayat',
                icon: Icons.history_outlined,
                selectedIcon: Icons.history_rounded,
                selected: current == AppDestination.history,
                onTap: () => _go(context, AppDestination.history),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                label: 'Pengaturan',
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                selected: current == AppDestination.settings,
                onTap: () => _go(context, AppDestination.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, AppDestination destination) {
    if (destination == current) return;
    final route = switch (destination) {
      AppDestination.home => LandingPage.homeRoute,
      AppDestination.scan => LandingPage.scanRoute,
      AppDestination.history => LandingPage.historyRoute,
      AppDestination.settings => LandingPage.settingsRoute,
    };
    Navigator.of(context).pushReplacementNamed(route);
  }
}

enum AppDestination { home, scan, history, settings }

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
