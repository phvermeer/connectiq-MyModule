import Toybox.Test;
using Toybox.System;
using Toybox.Math;
import Toybox.Lang;
using MyModule.Layout;

(:test)
function layoutHelper_getAreaByRatio(logger as Logger) as Boolean{
	var deviceSettings = System.getDeviceSettings();
	System.println(Lang.format("screenShape: $1$", [deviceSettings.screenShape]));
	if(deviceSettings.screenShape == System.SCREEN_SHAPE_ROUND){
		// For now only round screens are supported
		var helper = new Layout.LayoutHelper({});

		var diameter = deviceSettings.screenWidth;
		var radius = diameter/2;
		System.println(Lang.format("screenSize: $1$", [diameter]));
		var stepSize = diameter / 10;

		for(var ratio = 0.75; ratio < 2.0; ratio *= 2){
			for(var y1=0; y1 < diameter; y1+=stepSize){
				for(var x1=0; x1 < diameter; x1+=stepSize){
					for(var y2=y1+stepSize; y2 <= diameter; y2+=stepSize){
						for(var x2=x1+stepSize; x2 <= diameter; x2+=stepSize){
							var infoBoundaries = Lang.format("Boundaries: (x1,y1)=($1$,$2$), (x2,y2)=($3$,$4$)", [x1, y1, x2, y2]);
							var infoRatio = Lang.format("Requested Ratio: $1$", [ratio]);
							var infoResult = "No result available";
							var errorMessages = [] as Array<String>;
							System.println(infoBoundaries);
							System.println(infoRatio);

							helper.setBoundaries(x1, y1, x2-x1, y2-y1);
							var xywh = helper.getAreaByRatio(ratio);
							if(xywh != null){
								var x1_ = xywh[0];
								var y1_ = xywh[1];
								var x2_ = x1_ + xywh[2];
								var y2_ = y1_ + xywh[3];
								infoResult = Lang.format("Result: (x1,y1)=($1$,$2$), (x2,y2)=($3$,$4$)", [x1_, y1_, x2_, y2_]);

								// check within given boundaries
								if(x1_ < x1){ errorMessages.add("Outside left boundaries"); }
								if(y1_ < y1){ errorMessages.add("Outside top boundaries"); }
								if(x2_ > x2){ errorMessages.add("Outside right boundaries"); }
								if(y2_ > y2){ errorMessages.add("Outside bottom boundaries"); }

								// check within circle
								var radius2 = radius*radius;
								x1_ -= radius;							
								x2_ -= radius;							
								y1_ -= radius;							
								y2_ -= radius;							

								if(x1_*x1_ + y1_*y1_ > radius2){ errorMessages.add("Outside circle (bottom-left)"); }
								if(x1_*x1_ + y2_*y2_ > radius2){ errorMessages.add("Outside circle (top-left)"); }
								if(x2_*x2_ + y2_*y2_ > radius2){ errorMessages.add("Outside circle (top-right)"); }
								if(x2_*x2_ + y1_*y1_ > radius2){ errorMessages.add("Outside circle (bottom-right)"); }
							}else{
								// null is a valid result when....
							}
							if(errorMessages.size() > 0){
								System.println(infoBoundaries);
								System.println(infoRatio);
								System.println(infoResult);
								for(var i=0; i<errorMessages.size(); i++){
									logger.error(errorMessages[i]);
								}
								return false;
							}
							System.print(".");
						}
					}
				}
			}
		}
	}else{
		logger.warning("For now only Rounded screens are tested");
	}

/*
	var dx = Math.floor(r / Math.sqrt(2)).toNumber();
	var results = [
		[r-dx, r-dx, 2*dx, 2*dx] as Array<Number> ,
		[r-dx, r, 2*dx, dx] as Array<Number>,
		[r, 19, 66, 33] as Array<Number>,

	] as Array< Array<Number> >;
	var args = ["x", "y", "width", "height"];
	var helper = new Layout.LayoutHelper({});

	for(var i=0; i<testCase.size(); i++){
		logger.debug("LayoutHelper.getAreaByRatio()");
		var params = testCase[i] as Array<Numeric>;
		helper.setBoundaries(params[1], params[2], params[3], params[4]);
		var area = helper.getAreaByRatio(params[0] as Float) as Array<Number>;
		
		for(var i2=0; i2<4; i2++){
			//logger.debug(Lang.format("TestCase $1$: $2$ = $3$ should be $4$", [i+1, args[i2], area[i2], results[i][i2] ]));
			Test.assertEqualMessage(area[i2], results[i][i2], Lang.format("TestCase $1$: $2$ = $3$ should be $4$", [i+1, args[i2], area[i2], results[i][i2] ]));
		}
	}
*/
	return true;
}
