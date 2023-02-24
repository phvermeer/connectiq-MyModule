import Toybox.Test;
using Toybox.System;
using Toybox.Math;
import Toybox.Lang;
using MyModule.Layout;
using MyModule.MyMath;

(:test)
function layoutHelper_getAreaByRatio(logger as Logger) as Boolean{
	var deviceSettings = System.getDeviceSettings();
	System.println(Lang.format("screenShape: $1$", [deviceSettings.screenShape]));
	if(deviceSettings.screenShape == System.SCREEN_SHAPE_ROUND){
		// For now only round screens are supported
		var helper = new Layout.RoundScreenLayoutHelper(deviceSettings.screenWidth/2);

		var diameter = deviceSettings.screenWidth;
		var radius = diameter/2;
		System.println(Lang.format("screenSize: $1$", [diameter]));
		var stepSize = diameter / 4;

		for(var ratio = 0.5f; ratio <= 2.0; ratio *= 2){
//		if(ratio != 2.0f) { continue; }
			System.println("Ratio: "+ ratio);
			for(var y=0; y < diameter; y+=stepSize){
//				if(y != 0) { continue; }
				for(var x=0; x < diameter; x+=stepSize){
//					if(x != 0) { continue; }
					for(var h=stepSize; y+h <= diameter; h+=stepSize){
//						if(h != 195) { continue; }
						for(var w=stepSize; x+w <= diameter; w+=stepSize){
//							if(w != 130) { continue; }

							// check valid
							var errorMessages = [] as Array<String>;
							var xMin = x - radius;
							var xMax = (x + w) - radius;
							var yMax = radius - y;
							var yMin = radius - (y + h);
							var infoBoundaries = Lang.format("Boundaries: x,y=$1$,$2$, w,h=$3$,$4$", [x, y, yMin, yMax]);
							var infoRatio = Lang.format("Requested Ratio: $1$", [ratio]);
							var infoResult = "No result available";

							var boundaries = new Layout.Area(x, y, w, h);
							var area = helper.getAreaWithRatio(boundaries, ratio);

							if(area != null){
								var xMin_ = area.locX() - radius;
								var xMax_ = xMin_ + area.width();
								var yMax_ = radius - area.locY();
								var yMin_ = yMax_ - area.height();

								infoResult = Lang.format("Result: x,y = $1$,$2$, w,h = $3$,$4$", [area.locX(), area.locY(), area.width(), area.height()]);

								// check within given boundaries
								if(xMin_ < xMin){ errorMessages.add("Outside left boundaries"); }
								if(yMax_ > yMax){ errorMessages.add("Outside top boundaries"); }
								if(xMax_ > xMax){ errorMessages.add("Outside right boundaries"); }
								if(yMin_ < yMin){ errorMessages.add("Outside bottom boundaries"); }

								// check within circle
								var radius2 = radius*radius;
								var xMin2 = xMin_ * xMin_;
								var xMax2 = xMax_ * xMax_;
								var yMin2 = yMin_ * yMin_;
								var yMax2 = yMax_ * yMax_;

								// check if boundaries are ok
								if(xMin2 + yMin2 > radius2){ errorMessages.add("Outside circle (bottom-left)"); }
								if(xMin2 + yMax2 > radius2){ errorMessages.add("Outside circle (top-left)"); }
								if(xMax2 + yMax2 > radius2){ errorMessages.add("Outside circle (top-right)"); }
								if(xMax2 + yMin2 > radius2){ errorMessages.add("Outside circle (bottom-right)"); }

								// check if the maximum space is used
								var quality = 0;
								if(xMax == xMax_) { quality += 1.25; }
								if(xMin == xMin_) { quality += 1.25; }
								if(yMax == yMax_) { quality += 1.25; }
								if(yMin == yMin_) { quality += 1.25; }
								if(MyMath.abs(xMax2 + yMax2 - radius2)/radius <= 2){ quality += 1.5; }
								if(MyMath.abs(xMin2 + yMax2 - radius2)/radius <= 2){ quality += 1.5; }
								if(MyMath.abs(xMin2 + yMin2 - radius2)/radius <= 2){ quality += 1.5; }
								if(MyMath.abs(xMax2 + yMin2 - radius2)/radius <= 2){ quality += 1.5; }
								if(quality < 4){
									errorMessages.add("The size of the area should be increased (quality="+quality+")");
								}

								if(errorMessages.size() > 0){
									System.println(infoRatio);
									System.println(infoBoundaries);
									System.println(infoResult);
									for(var i=0; i<errorMessages.size(); i++){
										logger.error(errorMessages[i]);
									}
									return false;
								}
							}else{
								// null is a valid result when....
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
