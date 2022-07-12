import 'package:flutter/material.dart';

// Taken from  https://github.com/letsdoit07/flutter_animated_fab_menu/blob/master/lib/main.dart

class SendFabMenu extends StatefulWidget {
  final Function(bool) onToggle;
  const SendFabMenu({Key? key, required this.onToggle}) : super(key: key);

  @override
  SendFabMenuState createState() => SendFabMenuState();
}

class SendFabMenuState extends State<SendFabMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation degOneTranslationAnimation,
      degTwoTranslationAnimation,
      degThreeTranslationAnimation;
  late Animation rotationAnimation;

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
    super.initState();
    animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        Transform.translate(
          offset: Offset.fromDirection(
              getRadiansFromDegree(0), degOneTranslationAnimation.value * 100),
          child: Transform(
            transform:
                Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value))
                  ..scale(degOneTranslationAnimation.value),
            alignment: Alignment.center,
            child: CircularButton(
              color: Colors.blueAccent,
              width: 50,
              height: 50,
              icon: const Icon(
                Icons.folder,
                color: Colors.white,
              ),
              onClick: () {
                debugPrint('First Button');
              },
            ),
          ),
        ),
        Transform.translate(
          offset: Offset.fromDirection(getRadiansFromDegree(-45),
              degTwoTranslationAnimation.value * 100),
          child: Transform(
            transform:
                Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value))
                  ..scale(degTwoTranslationAnimation.value),
            alignment: Alignment.center,
            child: CircularButton(
              color: Colors.blueAccent,
              width: 50,
              height: 50,
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
              onClick: () {
                debugPrint('Second button');
              },
            ),
          ),
        ),
        Transform.translate(
          offset: Offset.fromDirection(getRadiansFromDegree(-90),
              degThreeTranslationAnimation.value * 100),
          child: Transform(
            transform:
                Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value))
                  ..scale(degThreeTranslationAnimation.value),
            alignment: Alignment.center,
            child: CircularButton(
              color: Colors.blueAccent,
              width: 50,
              height: 50,
              icon: const Icon(
                Icons.mic,
                color: Colors.white,
              ),
              onClick: () {
                debugPrint('Third Button');
              },
            ),
          ),
        ),
        Transform(
          transform:
              Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value)),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              if (animationController.isCompleted) {
                widget.onToggle(false);
                animationController.reverse();
              } else {
                widget.onToggle(true);
                animationController.forward();
              }
            },
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
      ],
    );
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
