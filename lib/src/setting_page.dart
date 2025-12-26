import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.devicePath = 'devices/esp32-iris-01',
  });

  final String devicePath;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final DatabaseReference _base;

  @override
  void initState() {
    super.initState();
    _base = FirebaseDatabase.instance.ref(widget.devicePath);
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('iris.onboarded');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Halaman penjelasan akan ditampilkan lagi.')),
    );
    await Future.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/open', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    const cardRadius = 14.0;
    const borderColorLight = Color(0xFFE7ECF3);
    const iconTintLight = Color(0xFF0D2342);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const LinearGradient(
      colors: [Color(0xFF46799D), Color(0xB30C202E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.36, 0.86],
    )
        : const LinearGradient(
      colors: [Color(0xFF90B7C6), Color(0xFF8CA44D)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.33, 0.9],
    );

    // ====== REFS (SKEMA SC) ======
    final modeRef = _base.child('controls/mode'); // "auto" / "manual"
    final pumpManualRef = _base.child('controls/pump_manual'); // bool
    final powerRef = _base.child('controls/power'); // bool

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
          ),
          title: const Text(
            'Pengaturan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          centerTitle: false,
          actions: [
            if (!kReleaseMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) {
                  if (v == 'reset') _resetOnboarding(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'reset',
                    child: Text('Tampilkan ulang Halaman Penjelasan'),
                  ),
                ],
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Mode Auto/Manual
            _ModeDropdownTile(
              modeRef: modeRef,
              pumpManualRef: pumpManualRef,
              cardRadius: cardRadius,
              borderColor: borderColorLight,
              iconColor: iconTintLight,
            ),
            const SizedBox(height: 12),

            // Pompa Manual: toggle akan paksa mode=manual lalu set pump_manual
            _SwitchTile(
              title: 'Pompa (Manual)',
              icon: Icons.opacity,
              iconColor: iconTintLight,
              ref: pumpManualRef,
              enabled: true,
              cardRadius: cardRadius,
              borderColor: borderColorLight,
              modeRef: modeRef,
              setModeValueOnToggle: 'manual',
            ),
            const SizedBox(height: 12),

            // Power Supply
            _SwitchTile(
              title: 'Power Supply',
              icon: Icons.power_settings_new_rounded,
              iconColor: iconTintLight,
              ref: powerRef,
              enabled: true,
              cardRadius: cardRadius,
              borderColor: borderColorLight,
            ),
            const SizedBox(height: 12),

            // Theme
            _ThemeDropdownTile(
              ref: _base.child('settings/theme'),
              cardRadius: cardRadius,
              borderColor: borderColorLight,
              iconColor: iconTintLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.ref,
    required this.enabled,
    required this.cardRadius,
    required this.borderColor,
    this.modeRef,
    this.setModeValueOnToggle,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final DatabaseReference ref;
  final bool enabled;
  final double cardRadius;
  final Color borderColor;

  final DatabaseReference? modeRef;
  final String? setModeValueOnToggle;

  bool _coerceBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is int) return raw != 0;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final effectiveBorderColor =
    isDark ? Colors.white.withOpacity(0.12) : borderColor;
    final titleColor = isDark ? Colors.white : const Color(0xFF2A2F3A);
    final leadingBg =
    isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEFF4FB);
    final leadingIconColor = isDark ? Colors.white : iconColor;
    final activeTrackColor = const Color(0xFF243A63);

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snap) {
        final bool value = _coerceBool(snap.data?.snapshot.value);

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: effectiveBorderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _LeadingIcon(
                icon: icon,
                color: leadingIconColor,
                bgColor: leadingBg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
              Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Switch.adaptive(
                  value: value,
                  onChanged: enabled
                      ? (v) async {
                    try {
                      // jika tile ini butuh set mode dulu (khusus Pompa Manual)
                      if (modeRef != null &&
                          setModeValueOnToggle != null) {
                        await modeRef!.set(setModeValueOnToggle);
                      }
                      await ref.set(v);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal memperbarui nilai.'),
                          ),
                        );
                      }
                    }
                  }
                      : null,
                  activeColor: Colors.white,
                  activeTrackColor: activeTrackColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeDropdownTile extends StatelessWidget {
  const _ModeDropdownTile({
    required this.modeRef,
    required this.pumpManualRef,
    required this.cardRadius,
    required this.borderColor,
    required this.iconColor,
  });

  final DatabaseReference modeRef;
  final DatabaseReference pumpManualRef;
  final double cardRadius;
  final Color borderColor;
  final Color iconColor;

  String _labelFromValue(String v) {
    switch (v.toLowerCase()) {
      case 'manual':
        return 'Manual';
      default:
        return 'Otomatis';
    }
  }

  IconData _iconFromValue(String v) {
    switch (v.toLowerCase()) {
      case 'manual':
        return Icons.front_hand_outlined;
      default:
        return Icons.autorenew_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final effectiveBorderColor =
    isDark ? Colors.white.withOpacity(0.12) : borderColor;
    final labelColor = isDark ? Colors.white : const Color(0xFF1A2743);
    final dropdownBg = isDark ? const Color(0xFF1B2B45) : Colors.white;
    final itemTextColor = isDark ? Colors.white : const Color(0xFF1A2743);
    final iconClr = isDark ? Colors.white : iconColor;

    return StreamBuilder<DatabaseEvent>(
      stream: modeRef.onValue,
      builder: (context, snap) {
        final String current =
            (snap.data?.snapshot.value as String?)?.toLowerCase() ?? 'auto';
        final items = <String>['auto', 'manual'];
        final safeCurrent = items.contains(current) ? current : 'auto';

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: effectiveBorderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              value: safeCurrent,
              onChanged: (v) async {
                if (v == null) return;
                try {
                  await modeRef.set(v);

                  // saat pindah ke AUTO, matikan manual supaya UI tidak misleading
                  if (v == 'auto') {
                    await pumpManualRef.set(false);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mode diset ke ${_labelFromValue(v)}'),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal menyimpan mode.')),
                    );
                  }
                }
              },
              customButton: Row(
                children: [
                  Icon(
                    _iconFromValue(safeCurrent),
                    size: 20,
                    color: iconClr,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mode',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ),
                  Text(
                    _labelFromValue(safeCurrent),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: labelColor.withOpacity(isDark ? 0.90 : 0.85),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down_rounded, color: labelColor),
                ],
              ),
              items: items
                  .map(
                    (val) => DropdownMenuItem<String>(
                  value: val,
                  child: Row(
                    children: [
                      Icon(
                        _iconFromValue(val),
                        size: 18,
                        color: iconClr,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _labelFromValue(val),
                        style: TextStyle(
                          fontSize: 14,
                          color: itemTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  color: dropdownBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeDropdownTile extends StatelessWidget {
  const _ThemeDropdownTile({
    required this.ref,
    required this.cardRadius,
    required this.borderColor,
    required this.iconColor,
  });

  final DatabaseReference ref;
  final double cardRadius;
  final Color borderColor;
  final Color iconColor;

  String _labelFromValue(String v) {
    switch (v.toLowerCase()) {
      case 'light':
        return 'Terang';
      case 'dark':
        return 'Gelap';
      default:
        return 'Terang';
    }
  }

  IconData _iconFromValue(String v) {
    switch (v.toLowerCase()) {
      case 'dark':
        return Icons.nightlight_round;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final effectiveBorderColor =
    isDark ? Colors.white.withOpacity(0.12) : borderColor;
    final labelColor = isDark ? Colors.white : const Color(0xFF1A2743);
    final dropdownBg = isDark ? const Color(0xFF1B2B45) : Colors.white;
    final itemTextColor = isDark ? Colors.white : const Color(0xFF1A2743);
    final iconClr = isDark ? Colors.white : iconColor;

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snap) {
        final String current =
            (snap.data?.snapshot.value as String?)?.toLowerCase() ?? 'light';
        final items = <String>['light', 'dark'];
        final safeCurrent = items.contains(current) ? current : 'light';

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: effectiveBorderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              value: safeCurrent,
              onChanged: (v) async {
                if (v == null) return;
                try {
                  await ref.set(v);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tema diset ke ${_labelFromValue(v)}'),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menyimpan tema.'),
                      ),
                    );
                  }
                }
              },
              customButton: Row(
                children: [
                  Icon(
                    _iconFromValue(safeCurrent),
                    size: 20,
                    color: iconClr,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tema',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: labelColor,
                  ),
                ],
              ),
              items: items
                  .map(
                    (v) => DropdownMenuItem<String>(
                  value: v,
                  child: Row(
                    children: [
                      Icon(
                        _iconFromValue(v),
                        size: 18,
                        color: iconClr,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _labelFromValue(v),
                        style: TextStyle(
                          fontSize: 14,
                          color: itemTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  color: dropdownBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}