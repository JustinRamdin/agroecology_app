import 'package:flutter/material.dart';

import '../map/map_screen.dart';
import '../contributions/my_contributions_screen.dart';
import '../community/community_screen.dart';
import '../species/species_library_screen.dart';
import '../missions/missions_screen.dart';
import '../impact/impact_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon 👀'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // nice readable greens for light background
    const deepText = Color(0xFF1B5E20);
    const midText = Color(0xFF2F5D3A);

    return Scaffold(
      body: Container(
        // Light theme-friendly background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE9F7EF), // mint
              Color(0xFFD6F5E3), // fresh green
              Color(0xFFBEEAD6), // deeper base
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              // Header / brand block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.70),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFB7E4C7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.primary.withOpacity(0.25)),
                      ),
                      child: Icon(Icons.eco, color: cs.primary, size: 30),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Make "Agroecology" noticeable, but on a light theme
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [
                                Color(0xFF1B5E20),
                                Color(0xFF2E7D32),
                                Color(0xFF66BB6A),
                              ],
                            ).createShader(rect),
                            child: const Text(
                              'Agroecology',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Colors.white, // used as mask base
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Track plantings • Map impact • Build food & habitat security',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: deepText,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _Pill(text: 'Offline-first'),
                              _Pill(text: 'Supabase Sync'),
                              _Pill(text: '1 km Grid'),
                              _Pill(text: 'T&T Tabs'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Primary actions
              Row(
                children: [
                  Expanded(
                    child: _PrimaryActionCard(
                      title: 'Open Map',
                      subtitle: 'Long-press to log • “Add Here” for GPS',
                      icon: Icons.map,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryActionCard(
                      title: 'My Plantings',
                      subtitle: 'View, export CSV, manage contributions',
                      icon: Icons.inventory_2,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyContributionsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Status strip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFB7E4C7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sync ready • Local-first storage enabled • Photos upload when online',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: midText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Coming Soon',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: deepText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 122, // 👈 key: fixed height to match top cards
                ),
                itemCount: 6,
                itemBuilder: (context, i) {
                  final items = [
                    (
                      'Species Library',
                      'Search, filter, native indicators',
                      Icons.book,
                    ),
                    (
                      'Missions',
                      'Monthly targets + planting goals',
                      Icons.flag,
                    ),
                    (
                      'Impact Dashboard',
                      'Heatmaps • survival rate • growth',
                      Icons.insights,
                    ),
                    (
                      'Community',
                      'Live activity • leaderboards • events',
                      Icons.groups,
                    ),
                    (
                      'Offline Packs',
                      'Preload maps for fieldwork',
                      Icons.download_for_offline,
                    ),
                    (
                      'QR / Tagging',
                      'Tag trees & scan on revisit',
                      Icons.qr_code_2,
                    ),
                  ];

                  final item = items[i];

                  return _FeatureCard(
                    title: item.$1,
                    subtitle: item.$2,
                    icon: item.$3,
                    onTap: () {
                      if (item.$1 == 'Species Library') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpeciesLibraryScreen(),
                          ),
                        );
                        return;
                      }

                      if (item.$1 == 'Missions') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MissionsScreen(),
                          ),
                        );
                        return;
                      }

                      if (item.$1 == 'Community') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CommunityScreen(),
                          ),
                        );
                        return;
                      }

                      if (item.$1 == 'Impact Dashboard') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ImpactDashboardScreen(),
                          ),
                        );
                        return;
                      }
                      _comingSoon(context, item.$1);
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              // Wild CTA panel — but light-theme friendly
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: cs.primary.withOpacity(0.10),
                  border: Border.all(color: cs.primary.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.rocket_launch, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next phase: “National Food & Habitat Security”',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: deepText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We’re building a field toolkit for NGOs, schools, hunters, hikers & communities — '
                            'with better species data, smarter verification, and reports that actually matter.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: midText,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () => _comingSoon(context, 'Project Roadmap'),
                              icon: const Icon(Icons.timeline),
                              label: const Text('Project Roadmap'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Center(
                child: Text(
                  'v0.1 • Trinidad & Tobago',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: midText.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withOpacity(0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF1B5E20),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB7E4C7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1B5E20),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF2F5D3A),
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.78), // match PrimaryActionCard
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB7E4C7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 28), // match PrimaryActionCard
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1B5E20),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF2F5D3A),
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

