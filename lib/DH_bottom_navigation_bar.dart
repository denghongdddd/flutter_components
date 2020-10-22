import 'package:flutter/material.dart';
import 'dart:math' as math;

class bottomNavigationBar extends StatefulWidget {
  List<IconData> icons;
  double index;
  final ValueChanged<int> change;

  bottomNavigationBar(@required this.icons, {this.index=1,this.change});
  @override
  _bottomNavigationBarState createState() => _bottomNavigationBarState();
}

class _bottomNavigationBarState extends State<bottomNavigationBar> with TickerProviderStateMixin {
  AnimationController animationController ;
  double lastIndex = 0;
  double animationValue=0;

	@override
	void initState(){
		animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500) )
			..addListener(() {
				setState(() {
				  animationValue=animationController.value;
				});
			})
			..forward();
		super.initState();
	}
	@override
	void dispose(){
		animationController.dispose();
		super.dispose();
	}

  @override
  Widget build (BuildContext context){
	  double margin = (MediaQuery.of(context).size.width - 20*2*(widget.icons.length.ceilToDouble()-1) - 30*2)/(widget.icons.length.ceilToDouble()+1);

    return  SizedBox(
		height:50,
		child: Stack(
			children: <Widget>[
				AnimatedBuilder(
					animation: animationController,
					builder: (ctx,i)=>PhysicalShape(
						shadowColor: Colors.lightBlue[100],
						elevation: 10,
						color: Colors.white,
						clipper: clipper(
							position:lastIndex>0? Tween(begin: (margin+20*2)*(lastIndex - 1)+margin,end: (margin+20*2)*(widget.index - 1)+margin).animate( CurvedAnimation(parent: animationController, curve: Curves.easeOut) ).value : (margin+20*2)*(widget.index - 1)+margin,
							activeDiam:30.0,
							diam: 20,
							number: widget.icons.length.ceilToDouble()
						),
						child:Container(),
					),
				),
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceEvenly,
					children: getIconList(),
				),
			],
		)
	);
  }

	List<Widget> getIconList(){
		List<Widget> list=[];
		for(int i=1;i<=widget.icons.length;i++){
			list.add(Transform(
				transform: Matrix4.translationValues(0.0,widget.index.floor()==i? -20.0*animationValue: (lastIndex==i? -20.0*(1-animationValue) : 0.0), 0.0),
				child: GestureDetector(
					onTap: (){
						setState(() {
              if(widget.change != null){
                widget.change(widget.index.floor()); 
              }
							lastIndex=widget.index;
						  	widget.index=i.ceilToDouble();
						});
						animationValue=0;
						animationController.reset();
						animationController.forward();
					},
					child: AnimatedBuilder(
						animation: animationController,
						builder: (context, child) => CircleAvatar(
							backgroundColor:widget.index.floor()==i? Colors.blueAccent.withOpacity(0.5): Colors.transparent,
							radius: widget.index.floor()==i?(20+10.0*animationController.value): (lastIndex.floor()==i?(30.0-10.0*animationController.value):20.0),
							child:Icon(
								widget.icons[i-1],
								size: widget.index.floor()==i? 34.0: 20.0,
								color:widget.index.floor()==i? Colors.white: Colors.black45,
							),
						),
					),
					
				)
				
			));
		}
		return list;
	}

}

class clipper extends CustomClipper<Path> {
	///选中的元素直径
	double activeDiam;
	///未选择的元素直径
	double diam;

	double index;
	///底部按钮数量
	double number;
	///放大百分比
	double porent = 0.3;
	///上升高度
	double h = 10;
  ///位置
	double position;
	clipper({@required this.position,@required this.activeDiam,@required this.diam,@required this.number});

	@override
  	Path getClip(Size size) {
		//   ///边距
		//   double margin=(size.width-diam*2*(number-1)-activeDiam*2)/(number+1);
		//   ///位置
		//   double position=(margin+diam*2)*(index-1)+margin;
      ///上升后的半径
      double radiou=math.sqrt(activeDiam*activeDiam-h*h) - activeDiam;
		Path path = Path();
		path.lineTo(0, 0);
    path.arcTo(Rect.fromLTWH(0, 0, activeDiam ,activeDiam), degreeToRadians(180), degreeToRadians(90), false);

    path.arcTo(Rect.fromLTWH(position - activeDiam*1, 0, activeDiam ,activeDiam), degreeToRadians(270), degreeToRadians(90) -math.tan(h/activeDiam), false);
    path.arcTo(Rect.fromLTWH(position +radiou, -activeDiam/2 - h, activeDiam*2 -radiou*2,activeDiam*2), degreeToRadians(180)-math.tan(h/activeDiam), degreeToRadians(-180) + math.tan(h/activeDiam)*2, false);
    path.arcTo(Rect.fromLTWH(position + activeDiam*2, 0, activeDiam ,activeDiam), degreeToRadians(180) +math.tan(h/activeDiam), degreeToRadians(90) -math.tan(h/activeDiam), false);

    path.arcTo(Rect.fromLTWH(size.width - activeDiam, 0, activeDiam ,activeDiam), degreeToRadians(270), degreeToRadians(90), false);

		path.lineTo(size.width, 0);
		path.lineTo(size.width, size.height);
		path.lineTo(0, size.height);
		path.close();
		return path;
	}

	@override
	bool shouldReclip(CustomClipper<Path> oldClipper) => true;
	  
	double degreeToRadians(double degree) {
		return (math.pi / 180) * degree;
	}
}