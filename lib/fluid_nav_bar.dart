import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/animation.dart';


typedef void FluidNavBarChangeCallback(int selectedIndex);

class FluidNavBar extends StatefulWidget {
	static const double nominalHeight = 56.0;

	final FluidNavBarChangeCallback onChange;

	FluidNavBar({ this.onChange });

	@override
	State createState() => _FluidNavBarState();
}

class _FluidNavBarState extends State<FluidNavBar> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  AnimationController _xController;
  AnimationController _yController;

  @override
  void initState() {
    _xController = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve
    );
    _yController = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve
    );

    Listenable.merge([ _xController, _yController ]).addListener(() {
      setState(() {
      });
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _xController.value = _indexToPosition(_selectedIndex) / MediaQuery.of(context).size.width;
    _yController.value = 1.0;

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    // The fluid nav bar consists of two components, the liquid background pane and the buttons
    // Build a stack with the buttons overlayed on top of the background pane
    final appSize = MediaQuery.of(context).size;
    final height = FluidNavBar.nominalHeight;
    return Container(
      width: appSize.width,
      height: FluidNavBar.nominalHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: appSize.width,
            height: height,
            child: _buildBackground(),
          ),
          Positioned(
            left: (appSize.width - _getButtonContainerWidth()) / 2,
            top: 0,
            width: _getButtonContainerWidth(),
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildButtons(),
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildBackground() {
    // This widget acts purely as a container that controlls how the `_BackgroundCurvePainter` draws
    final inCurve = ElasticOutCurve(0.38);
    return CustomPaint(
      painter: _BackgroundCurvePainter(
        _xController.value * MediaQuery.of(context).size.width,
        Tween<double>(
          begin: Curves.easeInExpo.transform(_yController.value),
          end: inCurve.transform(_yController.value),
        ).transform(_yController.velocity.sign * 0.5 + 0.5),
        Colors.white,
      ),
    );
  }

  List<FluidNavBarButton> _buildButtons() {
    List<FluidFillIconData> icons = [
      FluidFillIcons.home,
      FluidFillIcons.user,
      FluidFillIcons.window,
    ];
    var buttons = List<FluidNavBarButton>(3);
    for (var i = 0; i < 3; ++i) {
      buttons[i] = FluidNavBarButton(icons[i], _selectedIndex == i, () => _handlePressed(i));
    }
    return buttons;
  }

  double _getButtonContainerWidth() {
    double width = MediaQuery.of(context).size.width;
    if (width > 400.0) {
      width = 400.0;
    }
    return width;
  }

  double _indexToPosition(int index) {
    // Calculate button positions based off of their
    // index (works with `MainAxisAlignment.spaceAround`)
    const buttonCount = 3.0;
    final appWidth = MediaQuery.of(context).size.width;
    final buttonsWidth = _getButtonContainerWidth();
    final startX = (appWidth - buttonsWidth) / 2;
    return startX
        + index.toDouble() * buttonsWidth / buttonCount
        + buttonsWidth / (buttonCount * 2.0);
  }

  void _handlePressed(int index) {
    if (_selectedIndex == index || _xController.isAnimating)
      return;

    setState(() {
      _selectedIndex = index;
    });


    _yController.value = 1.0;
    _xController.animateTo(
        _indexToPosition(index) / MediaQuery.of(context).size.width,
        duration: Duration(milliseconds: 620));
    Future.delayed(
      Duration(milliseconds: 500),
      () {
        _yController.animateTo(1.0, duration: Duration(milliseconds: 1200));
      },
    );
    _yController.animateTo(0.0, duration: Duration(milliseconds: 300));

    if (widget.onChange != null) {
      widget.onChange(index);
    }
  }
}

class _BackgroundCurvePainter extends CustomPainter {
  // Top: 0.6 point, 0.35 horizontal
  // Bottom:

  static const _radiusTop = 54.0;
  static const _radiusBottom = 44.0;
  static const _horizontalControlTop = 0.6;
  static const _horizontalControlBottom = 0.5;
  static const _pointControlTop = 0.35;
  static const _pointControlBottom = 0.85;
  static const _topY = -10.0;
  static const _bottomY = 54.0;
  static const _topDistance = 0.0;
  static const _bottomDistance = 6.0;

  final double _x;
  final double _normalizedY;
  final Color _color;

  _BackgroundCurvePainter(double x, double normalizedY, Color color)
      : _x = x, _normalizedY = normalizedY, _color = color;

  @override
  void paint(canvas, size) {
    // Paint two cubic bezier curves using various linear interpolations based off of the `_normalizedY` value
    final norm = LinearPointCurve(0.5, 2.0).transform(_normalizedY) / 2;

    final radius = Tween<double>(
        begin: _radiusTop,
        end: _radiusBottom
      ).transform(norm);
    // Point colinear to the top edge of the background pane
    final anchorControlOffset = Tween<double>(
        begin: radius * _horizontalControlTop,
        end: radius * _horizontalControlBottom
      ).transform(LinearPointCurve(0.5, 0.75).transform(norm));
    // Point that slides up and down depending on distance for the target x position
    final dipControlOffset = Tween<double>(
        begin: radius * _pointControlTop,
        end: radius * _pointControlBottom
      ).transform(LinearPointCurve(0.5, 0.8).transform(norm));
    final y = Tween<double>(
        begin: _topY,
        end: _bottomY
        ).transform(LinearPointCurve(0.2, 0.7).transform(norm));
    final dist = Tween<double>(
        begin: _topDistance,
        end: _bottomDistance
        ).transform(LinearPointCurve(0.5, 0.0).transform(norm));
    final x0 = _x - dist / 2;
    final x1 = _x + dist / 2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(x0 - radius, 0)
      ..cubicTo(x0 - radius + anchorControlOffset, 0, x0 - dipControlOffset, y, x0, y)
      ..lineTo(x1, y)
      ..cubicTo(x1 + dipControlOffset, y, x1 + radius - anchorControlOffset, 0, x1 + radius, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);

    final paint = Paint()
        ..color = _color;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BackgroundCurvePainter oldPainter) {
    return _x != oldPainter._x
        || _normalizedY != oldPainter._normalizedY
        || _color != oldPainter._color;
  }
}

class CenteredElasticOutCurve extends Curve {

  final double period;

  CenteredElasticOutCurve([this.period = 0.4]);

  @override
  double transform(double x) {
    // Bascially just a slightly modified version of the built in ElasticOutCurve
    return math.pow(2.0, -10.0 * x) * math.sin(x * 2.0 * math.pi / period) + 0.5;
  }
}

class CenteredElasticInCurve extends Curve {

  final double period;

  CenteredElasticInCurve([this.period = 0.4]);

  @override
  double transform(double x) {
    // Bascially just a slightly modified version of the built in ElasticInCurve
    return -math.pow(2.0, 10.0 * (x - 1.0)) * math.sin((x - 1.0) * 2.0 * math.pi / period) + 0.5;
  }
}

class LinearPointCurve extends Curve {
  final double pIn;
  final double pOut;

  LinearPointCurve(this.pIn, this.pOut);

  @override
  double transform(double x) {
    // Just a simple bit of linear interpolation math
    final lowerScale = pOut / pIn;
    final upperScale = (1.0 - pOut) / (1.0 - pIn);
    final upperOffset = 1.0 - upperScale;
    return x < pIn ? x * lowerScale : x * upperScale + upperOffset;
  }
}

typedef void FluidNavBarButtonPressedCallback();

class FluidNavBarButton extends StatefulWidget {
  static const nominalExtent = const Size(64, 64);

  final FluidFillIconData _iconData;
  final bool _selected;
  final FluidNavBarButtonPressedCallback _onPressed;

  FluidNavBarButton(FluidFillIconData iconData, bool selected, FluidNavBarButtonPressedCallback onPressed)
      : _iconData = iconData, _selected = selected, _onPressed = onPressed;

  @override
  State createState() {
    return _FluidNavBarButtonState(_iconData, _selected, _onPressed);
  }
}

class _FluidNavBarButtonState extends State<FluidNavBarButton> with SingleTickerProviderStateMixin {
	static const double _activeOffset = 16;
	static const double _defaultOffset = 0;
	static const double _radius = 25;

	FluidFillIconData _iconData;
	bool _selected;
	FluidNavBarButtonPressedCallback _onPressed;

	AnimationController _animationController;
	Animation<double> _animation;

	_FluidNavBarButtonState(FluidFillIconData iconData, bool selected, FluidNavBarButtonPressedCallback onPressed)
		: _iconData = iconData,
		_selected = selected,
		_onPressed = onPressed;

  @override
	void initState() {
		_animationController = AnimationController(
			duration: const Duration(milliseconds: 1666),
			reverseDuration: const Duration(milliseconds: 833),
			vsync: this);
		_animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
		..addListener(() {
			setState(() {
			});
		});
		_startAnimation();

		super.initState();
	}

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    const ne = FluidNavBarButton.nominalExtent;
    final offsetCurve = _selected ? ElasticOutCurve(0.38) : Curves.easeInQuint;
    final scaleCurve = _selected ? CenteredElasticOutCurve(0.6) : CenteredElasticInCurve(0.6);

    final progress = LinearPointCurve(0.28, 0.0).transform(_animation.value);

    final offset = Tween<double>(
        begin: _defaultOffset,
        end: _activeOffset
        ).transform(offsetCurve.transform(progress));
    final scaleCurveScale = 0.50;
    final scaleY = 0.5 + scaleCurve.transform(progress) * scaleCurveScale + (0.5 - scaleCurveScale / 2);

    // Create a parameterizable flat button with a fluid fill icon
    return GestureDetector(
      // We wan't to know when this button was tapped, don't bother letting out children know as well
      onTap: _onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Alignment container to the circle
        constraints: BoxConstraints.tight(ne),
        alignment: Alignment.center,
        child: Container(
          // This container just draws a circle with a certain radius and offset
          margin: EdgeInsets.all(ne.width / 2 - _radius),
          constraints: BoxConstraints.tight(Size.square(_radius * 2)),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: CircleBorder(),
          ),
          transform: Matrix4.translationValues(0, -offset, 0),
          // Create a fluid fill icon that get's filled in with a slight delay to the buttons animation
          child: FluidFillIcon(
              _iconData,
              LinearPointCurve(0.25, 1.0).transform(_animation.value),
              scaleY,
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(oldWidget) {
    setState(() {
      _selected = widget._selected;
    });
    _startAnimation();
    super.didUpdateWidget(oldWidget);
  }

  void _startAnimation() {
    if (_selected) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

}

class FluidFillIcon extends StatelessWidget {

	static const double iconDataScale = 0.9;

	final FluidFillIconData _iconData;

	/// A normalzied value between 0 and 1
	final double _fillAmount;

	final double _scaleY;

	FluidFillIcon(FluidFillIconData iconData, double fillAmount, double scaleY)
		: _iconData = iconData, _fillAmount = fillAmount, _scaleY = scaleY;

	@override
	Widget build(context) {
		return CustomPaint(
			painter: _FluidFillIconPainter(_iconData.paths, _fillAmount, _scaleY),
		);
	}
}

class _FluidFillIconPainter extends CustomPainter {

  List<ui.Path> _paths;
  double _fillAmount;
  double _scaleY;

  _FluidFillIconPainter(List<ui.Path> paths, double fillAmount, double scaleY)
      : _paths = paths, _fillAmount = fillAmount, _scaleY = scaleY;

	@override
	void paint(canvas, size) {
		final paintBackground = Paint()
			..style = PaintingStyle.stroke
			..strokeWidth = 2.4
			..strokeCap = StrokeCap.round
			..strokeJoin = StrokeJoin.round
			..color = Colors.grey;

		final paintForeground = Paint()
			..style = PaintingStyle.stroke
			..strokeWidth = 2.4
			..strokeCap = StrokeCap.round
			..strokeJoin = StrokeJoin.round
			..color = Colors.black;

		// Scale around (0, height / 2)
		canvas.translate(0.0, size.height / 2);
		canvas.scale(1.0, _scaleY);
		// Center around (width / 2, height / 2) and apply the icon data scale
		canvas.translate(size.width / 2, 0.0);
		canvas.scale(FluidFillIcon.iconDataScale, FluidFillIcon.iconDataScale);

		// Draw the background greyed out path
		for (final path in _paths) {
			canvas.drawPath(path, paintBackground);
		}

		// Draw the black foreground path to simulate a filling effect
		if (_fillAmount > 0.0) {
			for (final path in _paths) {
				canvas.drawPath(extractPartialPath(path, 0.0, _fillAmount), paintForeground);
			}
		}
	}

	@override
	bool shouldRepaint(_FluidFillIconPainter oldWidget) {
		return _fillAmount != oldWidget._fillAmount;
	}
}

ui.Path extractPartialPath(ui.Path path, double start, double end) {
	assert(0.0 <= start && start <= 1.0);
	assert(0.0 <= end && end <= 1.0);
	assert(start < end);
	var result = ui.Path();
	final metrics = path.computeMetrics().toList();
	var totalLength = 0.0;
	for (var m in metrics) {
		totalLength += m.length;
	}
	final startPos = start * totalLength;
	final endPos = end * totalLength;
	var l = 0.0;
	for (var m in metrics) {
		final localStartPos = (startPos - l).clamp(0.0, m.length);
		final localEndPos = (endPos - l).clamp(0.0, m.length);

		if (localStartPos < localEndPos)
		result.addPath(m.extractPath(localStartPos, localEndPos), ui.Offset.zero);
		l += m.length;
	}

	return result;
}

class FluidFillIconData {
  final List<ui.Path> paths;
  FluidFillIconData(this.paths);
}

class FluidFillIcons {
  static final platform = FluidFillIconData([
    ui.Path()..moveTo(0, -6)..lineTo(10, -6),
    ui.Path()..moveTo(5, 0)..lineTo(-5, 0),
    ui.Path()..moveTo(-10, 6)..lineTo(0, 6),
  ]);
  static final window = FluidFillIconData([
    ui.Path()..addRRect(RRect.fromLTRBXY(-12, -12, -2, -2, 2, 2)),
    ui.Path()..addRRect(RRect.fromLTRBXY(2, -12, 12, -2, 2, 2)),
    ui.Path()..addRRect(RRect.fromLTRBXY(-12, 2, -2, 12, 2, 2)),
    ui.Path()..addRRect(RRect.fromLTRBXY(2, 2, 12, 12, 2, 2)),
  ]);
  static final arrow = FluidFillIconData([
    ui.Path()..moveTo(-10, 6)..lineTo(10, 6)..moveTo(10, 6)..lineTo(3, 0)..moveTo(10, 6)..lineTo(3, 12),
    ui.Path()..moveTo(10, -6)..lineTo(-10, -6)..moveTo(-10, -6)..lineTo(-3, 0)..moveTo(-10, -6)..lineTo(-3, -12),
  ]);
  static final user = FluidFillIconData([
    ui.Path()..arcTo(Rect.fromLTRB(-5, -16, 5, -6), 0, 1.9 * math.pi, true),
    ui.Path()..arcTo(Rect.fromLTRB(-10, 0, 10, 20), 0, -1.0 * math.pi, true),
  ]);
  static final home = FluidFillIconData([
    ui.Path()..addRRect(RRect.fromLTRBXY(-10, -2, 10, 10, 2, 2)),
    ui.Path()..moveTo(-14, -2)..lineTo(14, -2)..lineTo(0, -16)..close(),
  ]);
}