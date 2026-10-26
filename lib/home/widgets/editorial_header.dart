import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class EditorialHeader extends StatefulWidget {
  const EditorialHeader({super.key});

  @override
  State<EditorialHeader> createState() => _EditorialHeaderState();
}

class _EditorialHeaderState extends State<EditorialHeader>
    with SingleTickerProviderStateMixin {
  static const _quotes = [
    'Music is the silence between the notes.',
    'Feel it before you hear it.',
    'Some songs live longer than people.',
    'Not all wounds bleed. Some hum.',
    'The right song at the wrong time still heals.',
    'Rhythm is the soul\'s native language.',
    'Every raaga knows what words forget.',
    'Silence is just music holding its breath.',
    'Tere bina zindagi bhi koi zindagi hai kya.',
    'Dil dhoondta hai, aawaz nahin milti.',
    'Jo gaya woh sur bhi yaad rehta hai.',
    'Kabhi khushi, kabhi gham — hamesha ek dhun.',
    'Kuch toh hai tujhse raabta.',
    'Aankhon mein teri, ajab si raahein.',
    'Pal do pal ka shayar hoon main.',
    'Woh lamhe woh baatein — abhi bhi gaate hain.',
  ];

  int _currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _opacity;
  Timer? _timer;

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return 'Morning Melodies';
    if (hour >= 12 && hour < 17) return 'Afternoon Mix';
    if (hour >= 17 && hour < 20) return 'Evening Unplugged';
    if (hour >= 20 && hour < 22) return 'Late Night Vibes';
    return 'Midnight Sessions';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌤';
    if (hour < 17) return '☀️';
    if (hour < 20) return '🌆';
    return '🌙';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _controller.reverse().then((_) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _quotes.length;
        });
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_greetingEmoji, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 6),
              Text(
                _greeting.toUpperCase(),
                style: AppTypography.labelSm(
                  color: AppColors.secondaryAccent,
                ).copyWith(letterSpacing: 0.24 * 10, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Melodies of Cinema',
            style: AppTypography.headlineLgMobile(color: AppColors.primaryText),
          ),
          const SizedBox(height: 6),
          FadeTransition(
            opacity: _opacity,
            child: Text(
              '"${_quotes[_currentIndex]}"',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                  .copyWith(
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
