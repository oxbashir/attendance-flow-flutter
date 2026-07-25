import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, Set<DateTime>> attendance = {};

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? startMonth;
  bool isEditMode = false;
  bool _loaded = false;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg         = Color(0xFFF8F7F4);
  static const _surface    = Color(0xFFFFFFFF);
  static const _surfaceAlt = Color(0xFFF0EEE9);
  static const _accent     = Color(0xFF4F7EFF);
  static const _accentSoft = Color(0xFFEBF0FF);
  static const _success    = Color(0xFF34C47C);
  static const _textHigh   = Color(0xFF1A1A2E);
  static const _textMid    = Color(0xFF6B6B80);
  static const _textLow    = Color(0xFFB0AEBF);
  static const _border     = Color(0xFFE8E6E1);

  final List<String> _weekDays = ["M", "T", "W", "T", "F", "S", "S"];

  // ── Persistence ──────────────────────────────────────────────────────────

  String _key(DateTime d) => "${d.year}-${d.month}";
  Set<DateTime> _monthData(DateTime d) => attendance[_key(d)] ?? {};

  Future<void> _loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('attendance_data');
    if (raw != null) {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      setState(() {
        attendance.clear();
        decoded.forEach((key, value) {
          final list = (value as List<dynamic>).map((s) {
            final parts = s.toString().split('-');
            return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          }).toSet();
          attendance[key] = list;
        });

        // Restore startMonth
        final sm = prefs.getString('start_month');
        if (sm != null) {
          final p = sm.split('-');
          startMonth = DateTime(int.parse(p[0]), int.parse(p[1]));
        }
        _loaded = true;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<String>> serialized = {};
    attendance.forEach((key, dates) {
      serialized[key] = dates.map((d) => "${d.year}-${d.month}-${d.day}").toList();
    });
    await prefs.setString('attendance_data', jsonEncode(serialized));
    if (startMonth != null) {
      await prefs.setString('start_month', "${startMonth!.year}-${startMonth!.month}");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  // ── Logic ────────────────────────────────────────────────────────────────

  void _initStartMonth(DateTime date) {
    startMonth ??= DateTime(date.year, date.month);
  }

  List<DateTime?> _buildGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final totalDays = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = firstDay.weekday - 1;
    return [
      ...List.filled(offset, null),
      ...List.generate(totalDays, (i) => DateTime(month.year, month.month, i + 1)),
    ];
  }

  void _toggle(DateTime date) {
    if (!isEditMode) return;
    _initStartMonth(date);
    final key = _key(date);
    attendance.putIfAbsent(key, () => {});
    final normalized = DateTime(date.year, date.month, date.day);
    setState(() {
      if (attendance[key]!.contains(normalized)) {
        attendance[key]!.remove(normalized);
      } else {
        attendance[key]!.add(normalized);
      }
    });
    _saveAttendance();
  }

  bool _isPresent(DateTime date) =>
      (_monthData(date)).contains(DateTime(date.year, date.month, date.day));

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _nextMonth() =>
      setState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1));

  void _prevMonth() {
    final prev = DateTime(selectedMonth.year, selectedMonth.month - 1);
    if (startMonth != null &&
        prev.isBefore(DateTime(startMonth!.year, startMonth!.month))) {
      return;
    }
    setState(() => selectedMonth = prev);
  }

  String _monthName(int m) => const [
    "January", "February", "March",    "April",
    "May",     "June",     "July",      "August",
    "September","October", "November", "December"
  ][m - 1];

  int get _totalDays =>
      DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);

  int get _presentCount => _monthData(selectedMonth).length;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    final grid = _buildGrid(selectedMonth);
    final pct = _totalDays > 0 ? (_presentCount / _totalDays * 100).round() : 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMonthNav(),
                    _buildWeekdayHeader(),
                    _buildCalendarGrid(grid),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: _buildFooter(pct),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 17,
                color: _accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "Attendance",
            style: TextStyle(
              color: _textHigh,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => isEditMode = !isEditMode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isEditMode ? _accentSoft : _surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: isEditMode
                    ? Border.all(color: _accent.withOpacity(0.4), width: 1.5)
                    : Border.all(color: _border),
              ),
              child: Icon(
                isEditMode ? Icons.edit_rounded : Icons.edit_outlined,
                size: 16,
                color: isEditMode ? _accent : _textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Month Nav ─────────────────────────────────────────────────────────────

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
      child: Row(
        children: [
          _NavButton(onTap: _prevMonth, icon: Icons.chevron_left_rounded),
          const Spacer(),
          Column(
            children: [
              Text(
                _monthName(selectedMonth.month),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textHigh,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                "${selectedMonth.year}",
                style: const TextStyle(
                  fontSize: 12,
                  color: _textMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          _NavButton(onTap: _nextMonth, icon: Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  // ── Weekday Header ────────────────────────────────────────────────────────

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: _weekDays
            .map((d) => Expanded(
          child: Center(
            child: Text(
              d,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textLow,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ))
            .toList(),
      ),
    );
  }

  // ── Calendar Grid ─────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(List<DateTime?> grid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: grid.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final date = grid[index];
          if (date == null) return const SizedBox();

          final isPresent = _isPresent(date);
          final isToday   = _isToday(date);

          Color bgColor;
          Border cellBorder;

          if (isPresent) {
            bgColor = _success;
            cellBorder = Border.all(color: _success, width: 1);
          } else if (isToday) {
            bgColor = _accentSoft;
            cellBorder = Border.all(color: _accent, width: 1.5);
          } else if (isEditMode) {
            bgColor = _surface;
            cellBorder = Border.all(color: _border, width: 1);
          } else {
            bgColor = _surface;
            cellBorder = Border.all(color: _border, width: 1);
          }

          return GestureDetector(
            onTap: () => _toggle(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: cellBorder,
                boxShadow: isPresent
                    ? [BoxShadow(color: _success.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : isToday
                    ? [BoxShadow(color: _accent.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Stack(
                children: [
                  if (isPresent)
                    Center(
                      child: CustomPaint(
                        size: const Size(13, 13),
                        painter: _CheckPainter(color: Colors.white),
                      ),
                    ),
                  Positioned(
                    bottom: 5,
                    right: 6,
                    child: Text(
                      "${date.day}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPresent
                            ? Colors.white.withOpacity(0.95)
                            : isToday
                            ? _accent
                            : _textMid,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(int pct) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "PRESENT",
                style: TextStyle(
                  fontSize: 10,
                  color: _textLow,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$_presentCount days",
                style: const TextStyle(
                  fontSize: 26,
                  color: _textHigh,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$pct% this month",
                style: const TextStyle(
                  fontSize: 13,
                  color: _accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _MiniProgressBar(value: pct / 100),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _NavButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE8E6E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double value;
  const _MiniProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 90,
        height: 6,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: const Color(0xFFEBF0FF),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F7EFF)),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final Color color;
  const _CheckPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.85, size.height * 0.24);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}