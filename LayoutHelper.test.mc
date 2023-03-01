import Toybox.Test;
using Toybox.System;
using Toybox.Math;
import Toybox.Lang;
using MyModule.Layout;
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
