import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry margin;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.margin = EdgeInsets.zero,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseColor = widget.baseColor ??
        (brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade300);
    final highlightColor = widget.highlightColor ??
        (brightness == Brightness.dark
            ? Colors.white24
            : Colors.grey.shade100);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: baseColor,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final shimmerPosition = _controller.value * 2 - 0.5;
              return LinearGradient(
                begin: Alignment(-1.0, -0.3),
                end: Alignment(1.0, 0.3),
                colors: [baseColor, highlightColor, baseColor],
                stops: [shimmerPosition, shimmerPosition + 0.2, shimmerPosition + 0.4],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                color: baseColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  const SkeletonCard({super.key, this.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : Colors.grey.shade100,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(height: 16, width: 120, borderRadius: BorderRadius.all(Radius.circular(10))),
          SizedBox(height: 12),
          SkeletonBox(height: 14, width: 180),
          SizedBox(height: 12),
          SkeletonBox(height: 200, borderRadius: BorderRadius.all(Radius.circular(14))),
          SizedBox(height: 12),
          SkeletonBox(height: 14),
          SizedBox(height: 8),
          SkeletonBox(height: 14, width: 200),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool scrollable;

  const SkeletonList({
    super.key,
    this.itemCount = 4,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: !scrollable,
      physics: scrollable ? null : const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      itemBuilder: (context, index) {
        return const SkeletonCard();
      },
    );
  }
}

class SkeletonArticleDetail extends StatelessWidget {
  const SkeletonArticleDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            height: 280,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: SkeletonBox(width: 120, height: 16),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: SkeletonBox(width: double.infinity, height: 32),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: SkeletonBox(width: 200, height: 20),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: const [
                SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
                SizedBox(width: 12),
                Expanded(
                  child: SkeletonBox(width: double.infinity, height: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: SkeletonBox(width: double.infinity, height: 200),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: SkeletonBox(width: double.infinity, height: 20),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: SkeletonBox(width: double.infinity, height: 100),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class SkeletonChips extends StatelessWidget {
  final int itemCount;
  final double height;
  final double spacing;

  const SkeletonChips({
    super.key,
    this.itemCount = 5,
    this.height = 32.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          return SkeletonBox(
            width: 80,
            height: height,
            borderRadius: BorderRadius.circular(20),
          );
        },
      ),
    );
  }
}
