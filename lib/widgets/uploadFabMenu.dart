import 'package:flutter/material.dart';
import 'package:gasconchat/utils.dart';

// Taken from  https://github.com/letsdoit07/flutter_animated_fab_menu/blob/master/lib/main.dart

class FabSendMenu extends StatefulWidget {
  final Function(bool) onToggle;
  final double bottom;
  final double left;
  const FabSendMenu({
    Key? key,
    required this.onToggle,
    this.bottom = 0,
    this.left = 0,
  }) : super(key: key);

  @override
  FabSendMenuState createState() => FabSendMenuState();
}

class FabSendMenuState extends State<FabSendMenu>
    with SingleTickerProviderStateMixin {
  bool isOpen = false;
  late AnimationController animationController;
  late Animation degOneTranslationAnimation,
      degTwoTranslationAnimation,
      degThreeTranslationAnimation;
  late Animation rotationAnimation;
  late Animation<Color?> darkenAnimation;

  double getRadiansFromDegree(double degree) {
    double unitRadian = 57.295779513;
    return degree / unitRadian;
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    degOneTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.2), weight: 75.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.2, end: 1.0), weight: 25.0),
    ]).animate(animationController);
    degTwoTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.4), weight: 55.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.4, end: 1.0), weight: 45.0),
    ]).animate(animationController);
    degThreeTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.75), weight: 35.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.75, end: 1.0), weight: 65.0),
    ]).animate(animationController);
    rotationAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut));

    darkenAnimation = ColorTween(
      begin: Colors.black.withOpacity(0.0),
      end: Colors.black.withOpacity(0.6),
    ).animate(animationController);

    super.initState();
    animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var bottom = widget.bottom;
    var left = widget.left;
    return Stack(children: <Widget>[
      IgnorePointer(
        ignoring: !isOpen,
        child: GestureDetector(
          onTap: () {
            toggleFab();
          },
          child: Container(
            width: width,
            height: height,
            color: darkenAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: <Widget>[
                buildMenuButton(
                  context,
                  degOneTranslationAnimation,
                  0,
                  const Icon(
                    Icons.folder,
                    color: Colors.white,
                  ),
                  () {
                    notImplemented(context);
                    toggleFab();
                  },
                ),
                buildMenuButton(
                  context,
                  degTwoTranslationAnimation,
                  -45,
                  const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                  () {
                    notImplemented(context);
                    toggleFab();
                  },
                ),
                buildMenuButton(
                  context,
                  degThreeTranslationAnimation,
                  -90,
                  const Icon(
                    Icons.mic,
                    color: Colors.white,
                  ),
                  () {
                    notImplemented(context);
                    toggleFab();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: bottom,
        left: left,
        child: Transform(
          transform:
              Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value)),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: toggleFab,
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: animationController.isCompleted
                    ? Colors.black12
                    : Colors.lightBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                animationController.isCompleted ? Icons.close : Icons.add,
                color:
                    animationController.isCompleted ? Colors.red : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Positioned buildMenuButton(
      BuildContext context, Animation animation, double angle, Icon icon, Function()? onClick) {
    var bottom = widget.bottom;
    var left = widget.left;
    return Positioned(
      bottom: bottom,
      left: left,
      child: Transform.translate(
        offset: Offset.fromDirection(getRadiansFromDegree(angle),
            animation.value * 100),
        child: Transform(
          transform:
              Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value))
                ..scale(animation.value),
          alignment: Alignment.center,
          child: CircularButton(
            color: Colors.blueAccent,
            width: 50,
            height: 50,
            icon: icon,
            onClick: onClick,
          ),
        ),
      ),
    );
  }

  void toggleFab() {
    if (animationController.isCompleted) {
      isOpen = false;
      animationController.reverse();
    } else {
      isOpen = true;
      animationController.forward();
    }
    widget.onToggle(isOpen);
  }

  void notImplemented(context) {
    showToast(context, 'Not Implemented', 2);
  }
}

class CircularButton extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Icon icon;
  final void Function()? onClick;

  const CircularButton({
    Key? key,
    required this.color,
    required this.width,
    required this.height,
    required this.icon,
    required this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      width: width,
      height: height,
      child: IconButton(icon: icon, enableFeedback: true, onPressed: onClick),
    );
  }
}
