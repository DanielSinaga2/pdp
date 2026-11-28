import 'package:material_ui/material_ui.dart';

import '../../../presentation/padi_style.dart';
import 'landing_page.dart';

/// Navigasi utama yang konsisten di seluruh fitur inti aplikasi.
class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.current});

  final AppDestination current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: GlassSurface(
              radius: 24,
              padding: const EdgeInsets.all(4),
              child: Material(
                type: MaterialType.transparency,
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
            ),
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.onSurface : colors.onSurfaceVariant,
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
