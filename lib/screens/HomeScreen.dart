import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

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

  static const _bgDark = Color(0xFF1A1714);
  static const _bgPage = Color(0xFFF7F5F2);
  static const _bgCell = Color(0xFFF2F0EB);
  static const _gold = Color(0xFFC8A96E);
  static const _textMuted = Color(0xFF9C9890);
  static const _textBody = Color(0xFF4A4740);

  final List<String> _weekDays = ["M", "T", "W", "T", "F", "S", "S"];

  String _key(DateTime d) => "${d.year}-${d.month}";
  Set<DateTime> _monthData(DateTime d) => attendance[_key(d)] ?? {};

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
  }

  bool _isPresent(DateTime date) =>
      (_monthData(date)).contains(DateTime(date.year, date.month, date.day));

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _nextMonth() => setState(
          () => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1));

  void _prevMonth() {
    final prev = DateTime(selectedMonth.year, selectedMonth.month - 1);
    if (startMonth != null && prev.isBefore(DateTime(startMonth!.year, startMonth!.month))) return;
    setState(() => selectedMonth = prev);
  }

  String _monthName(int m) => const [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ][m - 1];

  int get _totalDays => DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);

  int get _presentCount => _monthData(selectedMonth).length;

  @override
  Widget build(BuildContext context) {
    final grid = _buildGrid(selectedMonth);
    final pct = _totalDays > 0 ? (_presentCount / _totalDays * 100).round() : 0;

    return Scaffold(
      backgroundColor: _bgPage,
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
    );
  }

  Widget _buildAppBar() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android icons
        statusBarBrightness: Brightness.dark, // iOS icons
      ),
      child: Container(
        color: _bgDark,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 20,
          bottom: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Center(
                  child: Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 16,                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Attendance",
              style: TextStyle(
                color: _bgPage,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => isEditMode = !isEditMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isEditMode
                      ? _gold.withOpacity(0.25)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: isEditMode
                      ? Border.all(color: _gold.withOpacity(0.6))
                      : null,
                ),
                child: Icon(
                  isEditMode ? Icons.edit : Icons.edit_outlined,
                  size: 16,
                  color: isEditMode ? _gold : _bgPage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          _NavButton(onTap: _prevMonth, icon: Icons.chevron_left),
          const Spacer(),
          Column(
            children: [
              Text(
                _monthName(selectedMonth.month),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, color: _bgDark, letterSpacing: -0.3),
              ),
              Text(
                "${selectedMonth.year}",
                style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          _NavButton(onTap: _nextMonth, icon: Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: _weekDays.map((d) => Expanded(
          child: Center(
            child: Text(d,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                    letterSpacing: 0.5)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime?> grid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: grid.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final date = grid[index];
          if (date == null) return const SizedBox();
          final isPresent = _isPresent(date);
          final isToday = _isToday(date);

          return GestureDetector(
            onTap: () => _toggle(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isPresent ? _bgDark : _bgCell,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isPresent
                    ? Border.all(color: _gold, width: 1.5)
                    : isEditMode && !isPresent
                    ? Border.all(color: _textMuted.withOpacity(0.4), width: 1)
                    : null,
              ),
              child: Stack(
                children: [
                  if (isPresent)
                    Center(
                      child: CustomPaint(
                        size: const Size(12, 12),
                        painter: _CheckPainter(color: _gold),
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    right: 5,
                    child: Text(
                      "${date.day}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPresent
                            ? Colors.white.withOpacity(0.9)
                            : isToday
                            ? const Color(0xFF8B6A2E)
                            : _textBody,
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

  Widget _buildFooter(int pct) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PRESENT",
                  style: TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text("$_presentCount days",
                  style: const TextStyle(
                      fontSize: 22, color: _bgPage, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$pct% this month",
                  style: const TextStyle(fontSize: 12, color: _gold, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _MiniProgressBar(value: pct / 100),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _NavButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F0EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1714)),
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
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 80,
        height: 5,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withOpacity(0.12),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8A96E)),
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
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.42, size.height * 0.75)
      ..lineTo(size.width * 0.85, size.height * 0.25);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}