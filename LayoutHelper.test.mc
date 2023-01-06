import Toybox.Test;
using Toybox.System;
using Toybox.Math;
import Toybox.Lang;
using MyModule.Layout;

function arrayToExcel(array as Array<Numeric>) as String{
	var delimiter = (9).toChar();
	var decimal_separator = ",";
	var result = "";
	for(var i = 0; i < array.size(); i++){
		var str = array[i].toString();
		var found = str.find(".");
		if(found != null){
			str = str.substring(0, found) + decimal_separator + str.substring(found+1, str.length());
		}
		result += (i==0) ? str : delimiter + str;
	}
	return result;
}

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
System.println("-------------------------------------------------------------------------------");

							var boundaries = new Layout.Area(x, y, w, h);
							System.println(Lang.format("Boundaries: (x,y) = ($1$, $2$), (width, height) = ($3$, $4$)", [x,y,w,h]));						
							System.println("Boundaries: " + boundaries);

							var result = helper.getAreaWithRatio(boundaries, ratio);
							System.println("Result: " + result);
							System.println(arrayToExcel([
								boundaries.xMin, boundaries.yMin, boundaries.xMax, boundaries.yMax,
								result.xMin, result.yMin, result.xMax, result.yMax,
							] as Array<Numeric>));
							

							// check valid
							var errorMessages = [] as Array<String>;

							if((result.xMin >= result.xMax) || (result.yMin >= result.yMax)){
								// invalid area
								errorMessages.add("result has no valid content");
							}

/*
							var xMin = x - radius;
							var xMax = (x + w) - radius;
							var yMax = radius - y;
							var yMin = radius - (y + h);
							var infoBoundaries = Lang.format("Boundaries: x=$1$..$2$, y=$3$..$4$", [xMin, xMax, yMin, yMax]);
							var infoRatio = Lang.format("Requested Ratio: $1$", [ratio]);
							var infoResult = "No result available";
							var errorMessages = [] as Array<String>;
							System.println(infoBoundaries);
							System.println(infoRatio);

							helper.setBoundaries(x, y, w, h);
							var xywh = helper.getAreaByRatio(ratio);
							if(xywh != null){
								var xMin_ = xywh[0] - radius;
								var xMax_ = xMin_ + xywh[2];
								var yMax_ = radius - xywh[1];
								var yMin_ = yMax_ - xywh[3];

								infoResult = Lang.format("Result: x = $1$..$2$, y = $3$..$4$", [xMin_, xMax_, yMin_, yMax_]);

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

								if(xMin2 + yMin2 > radius2){ errorMessages.add("Outside circle (bottom-left)"); }
								if(xMin2 + yMax2 > radius2){ errorMessages.add("Outside circle (top-left)"); }
								if(xMax2 + yMax2 > radius2){ errorMessages.add("Outside circle (top-right)"); }
								if(xMax2 + yMin2 > radius2){ errorMessages.add("Outside circle (bottom-right)"); }
							}else{
								// null is a valid result when....
							}

*/							
							if(errorMessages.size() > 0){
//								System.println("Ratio: "+ ratio);
//								System.println("Boundaries: " + boundaries.toString());
//								System.println("Result: " + result.toString());
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
