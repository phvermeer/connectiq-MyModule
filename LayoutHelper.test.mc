import Toybox.Test;
using Toybox.System;
using Toybox.Math;
import Toybox.Lang;
using MyModule.Layout;

(:test)
function layoutHelper(logger as Logger) as Boolean{
	var deviceSettings = System.getDeviceSettings();
	var r = deviceSettings.screenWidth/2;

	logger.debug("LayoutHelper.getAreaByRatio()");
	var testCase = [
		// ratio, x, y, width, height
		[1f, 0, 0, deviceSettings.screenWidth, deviceSettings.screenHeight],
		[2f, 0, r, deviceSettings.screenWidth, deviceSettings.screenHeight/2],
		[2f, r, 0, r, 52],  // single corner layout test
	];

	var dx = Math.floor(r / Math.sqrt(2)).toNumber();
	var results = [
		[r-dx, r-dx, 2*dx, 2*dx] as Array<Number> ,
		[r-dx, r, 2*dx, dx] as Array<Number>,
		[r, 19, 66, 33] as Array<Number>,

	] as Array< Array<Number> >;
	var args = ["x", "y", "width", "height"];
	var helper = new Layout.LayoutHelper({});

	for(var i=0; i<testCase.size(); i++){
		var params = testCase[i] as Array<Numeric>;
		helper.setBoundaries(params[1], params[2], params[3], params[4]);
		var area = helper.getAreaByRatio(params[0] as Float) as Array<Number>;
		
		for(var i2=0; i2<4; i2++){
			//logger.debug(Lang.format("TestCase $1$: $2$ = $3$ should be $4$", [i+1, args[i2], area[i2], results[i][i2] ]));
			Test.assertEqualMessage(area[i2], results[i][i2], Lang.format("TestCase $1$: $2$ = $3$ should be $4$", [i+1, args[i2], area[i2], results[i][i2] ]));
		}
	}
	Test.assert(true);
	return true;
}
