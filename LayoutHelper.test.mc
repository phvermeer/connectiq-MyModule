import Toybox.Test;
using Toybox.System;
using Toybox.Math;
import Toybox.Lang;
import MyModule.Layout;
using MyModule.MyMath;

(:test)
function layoutHelper_fitAreaWithRatio(logger as Logger) as Boolean{
	var deviceSettings = System.getDeviceSettings();
	System.println(Lang.format("screenShape: $1$", [deviceSettings.screenShape]));
	if(deviceSettings.screenShape == System.SCREEN_SHAPE_ROUND){
		// For now only round screens are supported
		var helper = new Layout.RoundScreenLayoutHelper(deviceSettings.screenWidth/2);

		var diameter = deviceSettings.screenWidth;
		var radius = diameter/2;
		System.println(Lang.format("screenSize: $1$", [diameter]));
		var stepSize = diameter / 4;

		for(var ratio = 0.5f; ratio <= 2.0; ratio += 0.25){
		// if(ratio != 2.0f) { continue; }
			System.println("Ratio: "+ ratio);
			for(var y=0; y < diameter; y+=stepSize){
				// if(y != 0) { continue; }
				for(var x=0; x < diameter; x+=stepSize){
					// if(x != 0) { continue; }
					for(var h=stepSize; y+h <= diameter; h+=stepSize){
						// if(h != 195) { continue; }
						for(var w=stepSize; x+w <= diameter; w+=stepSize){
							// if(w != 130) { continue; }

							// check valid
							var errorMessages = [] as Array<String>;
							var boundaries = new Layout.Area(x, y, w, h);
							var infoBoundaries = Lang.format("Boundaries: x,y,w,h = $1$,$2$,$3$,$4$", [boundaries.locX, boundaries.locY, boundaries.width, boundaries.height]);
							var infoRatio = Lang.format("Requested Ratio: $1$", [ratio]);
							var infoResult = "No result available";

							var area = new Layout.Area(x, y, w, h);
							helper.fitAreaWithRatio(area, boundaries, ratio);
							infoResult = Lang.format("Result: x,y,w,h = $1$,$2$,$3$,$4$", [area.locX, area.locY, area.width, area.height]);

							// boundaries:
							var xMin = helper.xMin(boundaries);
							var xMax = helper.xMax(boundaries);
							var yMin = helper.yMin(boundaries);
							var yMax = helper.yMax(boundaries);

							// result:
							var xMin_ = helper.xMin(area);
							var xMax_ = helper.xMax(area);
							var yMin_ = helper.yMin(area);
							var yMax_ = helper.yMax(area);

							// check within given boundaries
							if(xMin_ < xMin){ errorMessages.add("Outside left boundaries"); }
							if(yMax_ > yMax){ errorMessages.add("Outside top boundaries"); }
							if(xMax_ > xMax){ errorMessages.add("Outside right boundaries"); }
							if(yMin_ < yMin){ errorMessages.add("Outside bottom boundaries"); }

							// check within circle
							var radius2 = (1+radius)*(1+radius);
							var xMin2 = xMin_ * xMin_;
							var xMax2 = xMax_ * xMax_;
							var yMin2 = yMin_ * yMin_;
							var yMax2 = yMax_ * yMax_;

							// check if boundaries are ok
							var radius_top_right    = Math.sqrt(xMax2 + yMax2);
							var radius_top_left     = Math.sqrt(xMin2 + yMax2);
							var radius_bottom_left  = Math.sqrt(xMin2 + yMin2);
							var radius_bottom_right = Math.sqrt(xMax2 + yMin2);

							if(radius_top_right    > radius + 1){ errorMessages.add("Outside circle (top-right)"); }
							if(radius_top_left     > radius + 1){ errorMessages.add("Outside circle (top-left)"); }
							if(radius_bottom_left  > radius + 1){ errorMessages.add("Outside circle (bottom-left)"); }
							if(radius_bottom_right > radius + 1){ errorMessages.add("Outside circle (bottom-right)"); }

							// check if the maximum space is used
							var quality = 0;
							if(xMax == xMax_) { quality += 1.25; }
							if(xMin == xMin_) { quality += 1.25; }
							if(yMax == yMax_) { quality += 1.25; }
							if(yMin == yMin_) { quality += 1.25; }
							if(MyMath.abs(radius_top_right    - radius) <= 1){ quality += 1.5; }
							if(MyMath.abs(radius_top_left     - radius) <= 1){ quality += 1.5; }
							if(MyMath.abs(radius_bottom_left  - radius) <= 1){ quality += 1.5; }
							if(MyMath.abs(radius_bottom_right - radius) <= 1){ quality += 1.5; }
							if(quality < 4){
								errorMessages.add("The size of the area should be increased (quality="+quality+")");
							}

							if(errorMessages.size() > 0){
								// collect additional info
								var info = [];
								var corners = ["top-right", "top-left", "bottom-left", "bottom-right"] as Array<String>;
								for(var i=0; i<corners.size(); i++){
									var corner = corners[i];
									System.print(corner + ": ");

									var onVerticalBoundary = (i==0 || i==3)
										? (xMax == xMax_)
										: (xMin == xMin_);
									var onHorizontalBoundary = (i==0 || i==1)
										? (yMax == yMax_)
										: (yMin == yMin_);
									
									var onCircleEdge = false;
									if(i==0){
										onCircleEdge = (MyMath.abs(radius_top_right    - radius) <= 1);
									}else if(i==1){
										onCircleEdge = (MyMath.abs(radius_top_left     - radius) <= 1);
									}else if(i==2){
										onCircleEdge = (MyMath.abs(radius_bottom_left  - radius) <= 1);
									}else if(i==3){
										onCircleEdge = (MyMath.abs(radius_bottom_right - radius) <= 1);
									}

									if(onVerticalBoundary && onHorizontalBoundary){
										System.println("on boundary corner");
									}else if(onVerticalBoundary){
										if(onCircleEdge){
											System.println("on vertical boundary and circle");
										}else{
											System.println("ONLY on vertical boundary");
										}
									}else if(onHorizontalBoundary){
										if(onCircleEdge){
											System.println("on horizontal boundary and circle");
										}else{
											System.println("ONLY on horizontal boundary");
										}
									}else{
										if(onCircleEdge){
											System.println("on circle");
										}else{
											System.println("NOT ON CIRCLE OR BOUNDARY!!!");
										}
									}
								}

								System.println(infoRatio);
								System.println(infoBoundaries);
								System.println(infoResult);
								for(var i=0; i<errorMessages.size(); i++){
									logger.error(errorMessages[i]);
								}
								return false;
							}
						}
					}
				}
			}
		}
	}else{
		logger.warning("For now only Rounded screens are tested");
	}
	return true;
}

(:test)
function layoutHelper_Alignment(logger as Logger) as Boolean{
	var deviceSettings = System.getDeviceSettings();
	var diameter = deviceSettings.screenWidth;
	var r = diameter / 2;
	var r2 = r*r;
	var helper = Layout.createLayoutHelper();

	// 4 different boundaries
	var boundariesList = [
		new Layout.Area(0             , 0             ,       diameter,       diameter),
		new Layout.Area(0             , 0             , 0.6 * diameter,       diameter),
		new Layout.Area(0             , 0             , 0.7 * diameter, 0.3 * diameter),
		new Layout.Area(0.2 * diameter, 0.1 * diameter, 0.6 * diameter, 0.6 * diameter),
	] as Array<Area>;
	// 2 different shapes [width, height]
	var shapeList = [
		[diameter/2, diameter/5] as Array<Numeric>,
		[diameter/7, diameter/3] as Array<Numeric>,
	] as Array< Array<Numeric> >;
	// 8 alignments
	var alignmentList = [
		Layout.TOP,
		Layout.TOP|Layout.RIGHT,
		Layout.RIGHT,
		Layout.BOTTOM|Layout.RIGHT,
		Layout.BOTTOM,
		Layout.BOTTOM|Layout.LEFT,
		Layout.LEFT,
		Layout.TOP|Layout.LEFT,
	] as Array<Direction|Number>;

	for(var b=0; b<boundariesList.size(); b++){
		var boundaries = boundariesList[b] as Area;
		for(var s=0; s<shapeList.size(); s++){
			var widthAndHeight = shapeList[s];
			for(var a=0; a<alignmentList.size(); a++){
				var shape = new Layout.Area(0, 0, widthAndHeight[0], widthAndHeight[1]);
				var alignment = alignmentList[a];
				var errorMessages = [] as Array<String>;
				var infoMessages = [] as Array<String>;

				infoMessages.add(Lang.format("Boundaries: x,y = $1$,$2$ w,h = $3$,$4$", [boundaries.locX, boundaries.locY, boundaries.width, boundaries.height]));
				infoMessages.add(Lang.format("Shape: x,y = $1$,$2$ w,h = $3$,$4$", [shape.locX, shape.locY, shape.width, shape.height]));
				infoMessages.add(Lang.format("Alignment: $1$", [alignment]));

				helper.setAreaAligned(shape, boundaries, alignment);

				// get the relevant corner(s) for the alignment
				var corners = [] as Array;
				if(alignment == Layout.TOP){
					corners.add([shape.locX, shape.locY]);
					corners.add([shape.locX + shape.width, shape.locY]);
				}else if(alignment == Layout.RIGHT){
					corners.add([shape.locX + shape.width, shape.locY]);
					corners.add([shape.locX + shape.width, shape.locY + shape.height]);
				}else if(alignment == Layout.BOTTOM){
					corners.add([shape.locX, shape.locY + shape.height]);
					corners.add([shape.locX + shape.width, shape.locY + shape.height]);
				}else if(alignment == Layout.LEFT){
					corners.add([shape.locX, shape.locY]);
					corners.add([shape.locX, shape.locY + shape.height]);
				}else if(alignment == (Layout.TOP|Layout.LEFT)){
					corners.add([shape.locX, shape.locY]);
				}else if(alignment == (Layout.TOP|Layout.RIGHT)){
					corners.add([shape.locX + shape.width, shape.locY]);
				}else if(alignment == (Layout.BOTTOM|Layout.RIGHT)){
					corners.add([shape.locX + shape.width, shape.locY + shape.height]);
				}else if(alignment == (Layout.BOTTOM|Layout.LEFT)){
					corners.add([shape.locX, shape.locY + shape.height]);
				}

				// check if the size of the shape is to big to align within the circle
				var shapeToBig = false;
				if(corners.size() == 2){
					var width = corners[1][0] - corners[0][0];
					var height = corners[1][1] - corners[0][1];
					if(width > boundaries.width){
						infoMessages.add("The width of the shape exceeds the boundaries");
						shapeToBig = true;
					}
					if(height > boundaries.height){
						infoMessages.add("The height of the shape exceeds the boundaries");
						shapeToBig = true;
					}
				}

				// see if the corners are on a boundary or circle edge
				for(var c=0; c<corners.size(); c++){
					var x = corners[c][0] as Numeric;
					var y = corners[c][1] as Numeric;

					var countOnBoundary = 0;
					var onCircle = false;

					// on a boundary
					if(boundaries.locX == x){ countOnBoundary++; }
					if(boundaries.locX + boundaries.width == x){ countOnBoundary++; }
					if(boundaries.locY == y){ countOnBoundary++; }
					if(boundaries.locY + boundaries.height == y){ countOnBoundary++; }

					infoMessages.add(Lang.format("corner$1$ ($2$, $3$): has $4$ points on a boundary", [c, x, y, countOnBoundary]));

					if(!shapeToBig){

						// on circle edge or outside circle
						var fromCenterHorizontal = x - r;
						var fromCenterVertical = y - r;
						var fromCenter = Math.sqrt(fromCenterHorizontal*fromCenterHorizontal + fromCenterVertical*fromCenterVertical);
						infoMessages.add(Lang.format("corner$1$ ($2$, $3$): radius from center: $4$", [c, x, y, fromCenter]));
						if(fromCenter > r + 1){
							// outside circle
							errorMessages.add(Lang.format("corner$1$: Outside circle!", [c, x, y, fromCenter]));
						}else if(fromCenter >= r - 1){
							// on circle
							onCircle = true;
							infoMessages.add(Lang.format("corner$1$): On the edge of the circle", [c, x, y]));
						}
					}

					// Now determine if the shape is aligned properly
					// each relevant corner should touch boundary or corner
					if(countOnBoundary == 0 && !onCircle){
						errorMessages.add(Lang.format("corner$1$ ($2$, $3$): is not on circle edge or a boundary", [c, x, y]));
					}
				}
				
				// final verdict
				if(errorMessages.size() > 0){
					// print info
					for(var i=0; i<infoMessages.size(); i++){
						System.println(infoMessages[i]);
					}

					// print errors
					for(var i=0; i<errorMessages.size(); i++){
						logger.error(errorMessages[i]);
					}
					return false;
				}
			}
		}
	}
	return true;
}