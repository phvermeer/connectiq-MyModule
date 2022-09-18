using Toybox.System;
using Toybox.Math;
using Toybox.Lang;
using MyModule.MyMath;
import MyModule.Tools;

module MyModule{

	(:Layout)
	module Layout {
		class LayoutHelper{
			enum Alignment {
				ALIGN_TOP = 1,
				ALIGN_BOTTOM = 2,
				ALIGN_LEFT = 3,
				ALIGN_RIGHT = 4,
			}
		
			protected var deviceSettings as System.DeviceSettings;
			protected var radius as Lang.Float;
			protected var xMin as Lang.Float;
			protected var xMax as Lang.Float;
			protected var yMin as Lang.Float;
			protected var yMax as Lang.Float;
		
			function initialize(boundaries as {:x as Lang.Numeric, :y as Lang.Numeric, :width as Lang.Numeric, :heigth as Lang.Numeric} or Null ){
				me.deviceSettings = System.getDeviceSettings();
				me.radius = 0.5f * MyMath.max([deviceSettings.screenHeight, deviceSettings.screenWidth]);
		
				if(boundaries != null){
					var x = boundaries.hasKey(:x) ? boundaries.get(:x) : 0;
					var y = boundaries.hasKey(:y) ? boundaries.get(:y) : 0;
					var w = boundaries.hasKey(:width) ? boundaries.get(:width) : deviceSettings.screenWidth - x;
					var h = boundaries.hasKey(:height) ? boundaries.get(:height) : deviceSettings.screenHeight - y;
					setBoundaries(x, y, w, h);
				}else{
					setBoundaries(0, 0, deviceSettings.screenWidth, deviceSettings.screenHeight);
				}
			}
		
			function setBoundaries(x as Lang.Numeric, y as Lang.Numeric, w as Lang.Numeric, h as Lang.Numeric) as Void{
				me.xMin = x - me.radius;
				me.xMax = x + w - me.radius;
				me.yMin = me.radius - (y + h);
				me.yMax = me.radius - y;
			}
		
			function getAreaByRatio(ratio as Float) as Array<Lang.Number>{
				// Make sure the dimensions of the DataField are initialized
				if(me.xMin == null || me.xMax ==null || me.yMin == null || me.yMax == null){
					throw new Tools.MyException("getAreaByRatio can only be called with known boundaries");
				}
		
				// not ok untill ok is proven
				var ok = false;
				// placeholders  for final result
				var xMaxC = null;
				var xMinC = null;
				var yMaxC = null;
				var yMinC = null;
				
				// Check if the screen is circle shaped, otherwise the area is easier to calculate
				if(deviceSettings.screenShape == System.SCREEN_SHAPE_ROUND){
					// use x,y values based upon the circle center point x→ y↑
					var radius = 0.5f * MyMath.min([deviceSettings.screenWidth, deviceSettings.screenHeight]); // screen radius
		
					// check where the edge could go outside the circle
					//           ―――――
					//        │ q2 │ q1 │
					//        ├────┼────┤
					//        │ q3 │ q4 │
					//          ───────
		
					var q1 = (yMax > 0) && (xMax > 0);
					var q2 = (yMax > 0) && (xMin < 0);
					var q3 = (yMin < 0) && (xMin < 0);
					var q4 = (yMin < 0) && (xMax > 0);
		
					if(q1 && q2 && q3 && q4){
						// All quadrants -> calculate rectangle in all quadrants -> calculate rectangle with given ratio that will touch the cirle edge at all corners
						var results = getLimitsForRatio_4Corners(ratio as Float, radius as Float);
			
						// determine the x,y based upon circle edge:
						xMaxC = results.get(:xMax);
						xMinC = -xMaxC;
						yMaxC = results.get(:yMax);
						yMinC = -yMaxC;
			
						// Check if these circle edge values are within the limits
						ok = true;
						if(xMaxC > xMax) { ok = false; q1 = false; q4 = false; }
						if(xMinC < xMin) { ok = false; q2 = false; q3 = false; }
						if(yMaxC > yMax) { ok = false; q1 = false; q2 = false; }
						if(yMinC < yMin) { ok = false; q3 = false; q4 = false; }
					}
			
					if(!ok){
						ok = true;
						if(q1 && q2){
							// determine the bigest rectangle with given ratio within a circle (top)
							var result = getLimitsForRatio_2Corners(ratio, yMin, radius);
			
							// determine the x,y based upon these results for given quadrants
							xMaxC = result.get(:range);
							xMinC = -xMaxC;
							yMaxC = result.get(:max);
							yMinC = yMin;
			
						}else if(q3 && q4){
							// determine the bigest rectangle with given ratio within a circle (top)
							var result = getLimitsForRatio_2Corners(ratio, -yMax, radius);
			
							// determine the x,y based upon these results for given quadrants
							xMaxC = result.get(:range);
							xMinC = -xMaxC;
							yMaxC = yMax;
							yMinC = -result.get(:max);
			
						}else if(q1 && q4){
							// determine the bigest rectangle with given ratio within a circle (top)
							var result = getLimitsForRatio_2Corners(1/ratio, xMin, radius);
			
							// determine the x,y based upon these results for given quadrants
							xMaxC = result.get(:max);
							xMinC = xMin;
							yMaxC = result.get(:range);
							yMinC = -yMaxC;
			
						}else if(q2 && q3){
							// determine the bigest rectangle with given ratio within a circle (top)
							var result = getLimitsForRatio_2Corners(1/ratio, -xMax, radius);
			
							// determine the x,y based upon these results for given quadrants
							xMaxC = xMax;
							xMinC = -result.get(:max);
							yMaxC = result.get(:range);
							yMinC = -yMaxC;
						}else{
							ok = false;
						}
			
						// Check if the calculated circle edge values are within the given limits
						if(ok){
							if(yMaxC > yMax) { ok = false; q1 = false; q2 = false;}
							if(yMinC < yMin) { ok = false; q3 = false; q4 = false;}
							if(xMaxC > xMax) { ok = false; q1 = false; q4 = false;}
							if(xMinC < xMin) { ok = false; q2 = false; q3 = false;}
						}
					}
		
					if(!ok){
						// Now check if the rectangle is limited at a single corner
						if(q1){
							//	q1 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, xMin as Float, yMin as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMaxC = results.get(:yMax);
							yMinC = yMin;
							xMaxC = results.get(:xMax);
							xMinC = xMin;
						}else if(q2){
							//	q2 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, -xMax as Float, yMin as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMinC = yMin;
							yMaxC = results.get(:yMax);
							xMinC = -results.get(:xMax);
							xMaxC = xMax;
						}else if(q3){
							//	q3 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, -xMax as Float, -yMax as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMinC = -results.get(:yMax);
							yMaxC = yMax;
							xMinC = -results.get(:xMax);
							xMaxC = xMax;
						}else if(q4){
							//	q4 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, xMin as Float, -yMax as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMinC = -results.get(:yMax);
							yMaxC = yMax;
							xMinC = xMin;
							xMaxC = results.get(:xMax);
						}
					}
				}
					
				if(!ok){
					xMinC = xMin;
					xMaxC = xMax;
					yMinC = yMin;
					yMaxC = yMax;
		
					var w = xMax - xMin;
					var h = yMax - yMin;
					if(ratio * h > w){
						// trim height to get the correct ratio
						var ∆y = (h - (w / ratio))/2;
						yMinC += ∆y;
						yMaxC -= ∆y;
					}else{
						// trim width to get the correct ratio
						var ∆x = (w - (h * ratio))/2;
						xMinC += ∆x;
						xMaxC -= ∆x;
					}
					ok = true;
				}
				// convert to real xy coordinates:
				var x1 = Math.ceil(xMinC + radius).toNumber();
				var x2 = Math.floor(xMaxC + radius).toNumber();
				var y1 = Math.ceil(radius - yMaxC).toNumber();
				var y2 = Math.floor(radius - yMinC).toNumber();
				return [
					x1, // x
					y1, // y
					x2-x1, // width
					y2-y1, // height
				];
			}
		
			function getAlignedPosition(align as Aligment, width as Lang.Numeric, height as Lang.Numeric) as Array<Lang.Number> or Null {
				// This function will calculate the position (x,y) of a given rectangle (width, height) within a circle aligned to a direction within the circle and given boundaries
		
		// check if the rectangle fits with boundaries, otherwise align without looking at circle shape
		if(width > (xMax-xMin)){
			var y = radius - (yMin + yMax)/2 - height/2;
			if(align == ALIGN_LEFT){
				var x = xMin + radius;
				return [x, y];
			}else if(align == ALIGN_RIGHT){
				var x = xMax - width + radius;
				return [x, y];
			}		
		}
		if(height > (yMax-yMin)){
			var x = (xMin + xMax)/2 + radius - width/2;
			if(align == ALIGN_TOP){
				var y = radius - yMax;
				return [x, y];
			}else if(align == ALIGN_BOTTOM){
				var y = radius - (yMin + height);
				return [x, y];
			}		
				}
		
		// transpose the aligmnent direction to ALIGN_TOP
				var ok = false;
				var gap = null;
				var r² = radius*radius;
		
				var xMin = null, xMax = null, yMax = null, size = null; // all floats
				if(align == ALIGN_TOP){
					xMin = me.xMin;
					xMax = me.xMax;
					yMax = me.yMax;
					size = width;
				}else if(align == ALIGN_BOTTOM){
					xMin = -me.xMax;
					xMax = -me.xMin;
					yMax = -me.yMin;
					size = width;
				}else if(align == ALIGN_LEFT){
					xMin = me.yMin;
					xMax = me.yMax;
					yMax = -me.xMin;
					size = width;
				}else if(align == ALIGN_RIGHT){
					xMin = -me.yMax;
					xMax = -me.yMin;
					yMax = me.xMax;
					size = width;
				}else{
					xMin = null;
					xMax = null;
					yMax = null;
					size = null;
				}
		
				// get space at max and check if the size already fits
				// y² + x² = radius²
				// x = ± √ (radius² - yMax²)
				var xMinC = MyMath.max([-Math.sqrt(r² - yMax*yMax), xMin]);
				var xMaxC = MyMath.min([Math.sqrt(r² - yMax*yMax), xMax]);
				var yMaxC = yMax;
				var space = xMaxC - xMinC;
				gap = space - size;
				ok = (gap >= 0);
		
				if(!ok){
					// now check where in the circle the rectangle fits.
					// check if the rectangle will hit the boundary on a side
		
					var size2 = size/2;
					xMinC = null;
					xMaxC = null;
					if(size2 > -xMin){
						// the rectangle will hit the circle at the right side and the boundary on the left
						size2 = size + xMin;
						xMinC = xMin;
					}else if(size2 > xMax){
						// the rectangle will hit the circle at the left side and the boundary on the right
						size2 = size - xMax;
						xMaxC = xMax;
					}
		
					// y² + x² = radius²
					// yMax² + size2² = radius²
					// yMax = ± √ (radius² - size2²)
					yMaxC = Math.sqrt(r² - size2*size2);
					xMinC = (xMinC == null) ? -size2 : xMinC;
					xMaxC = (xMaxC == null) ? size2 : xMaxC;
					gap = 0;
				}
		
				// transpose back to original direction
				var x = null;
				var y = null;
				if(align == ALIGN_TOP){
					x = radius + xMinC + gap/2;
					y = radius - yMaxC;
				}else if(align == ALIGN_BOTTOM){
					x = radius - xMaxC + gap/2;
					y = radius + yMaxC - height;
				}else if(align == ALIGN_LEFT){
					x = radius - yMaxC;
					y = radius - xMaxC + gap/2;
				}else if(align == ALIGN_RIGHT){
					x = radius + yMaxC - height;
					y = radius + xMinC + gap/2;
				}else{
					return null;
				}
				return [
					Math.round(x).toNumber(),
					Math.round(y).toNumber()
				];
			}
		
			private static function getLimitsForRatio_4Corners(ratio as Float, radius as Float) as { :xMax as Float, :yMax as Float }{
				// this functions returns 2 Float values: xMax, yMax which indicate the top left corner of the found rectangle with given ratio
				//         radius   ↑      ┌─────────┐
				//	(from center)   ·    ┌─○· · · · ·○─┐   ↑ yMax (from vertical center)
				//	                ·  ┌─┘ ·         · └─┐ · 
				//	                ·  │   ·         ·   │ ·
				//	                ─  │   ·    +    ·   │ ─
				//	                   │   ·         ·   │ 
				//	                   └─┐ ·         · ┌─┘
				//	                     └─○· · · · ·○─┘
				//	                       └─────────┘
				//                         <----|---->
				//	                      -xMax | xMax  (from horizontal center)
		
				//	formula1:	radius² = x² + y²
				//		=> radius² = xMax² + yMax²
				//
				//	formula2: ratio = width / height
				//		=> ratio = (2 * xMax) / (2 * yMax)
				//		=> ratio = xMax / yMax
				//		=> xMax = ratio * yMax
				//
				//	radius² = (ratio * yMax)² + yMax²
				//	radius² = ratio² * yMax² + yMax²
				//	radius² = (ratio² + 1) * yMax²
				//	yMax² = radius² / (ratio² + 1)
				//	yMax = √(radius² / (ratio² + 1))
				var yMax = Math.sqrt(radius*radius / (ratio*ratio + 1));
				var xMax = ratio * yMax;
				return {
					:xMax => xMax,
					:yMax => yMax,
				};
			}
			private static function getLimitsForRatio_2Corners(ratio as Float, offset as Float, radius as Float) as { :max as Float, :range as Float } {
				// this functions returns 2 Float values: max and range
				//		max: the distance from the center to the outer rectangel side
				//		range: the distance from the center to both sides of the rectangle
				//
				//         radius   ↑      ┌─────────┐
				//	(from center)   ·    ┌─○· · · · ·○─┐   ↑ max (from vertical center)
				//	                ·  ┌─┘ ·         · └─┐ · 
				//	                ·  │   ·         ·   │ ·
				//	                ─  │   ·    +    ·   │ ─
				//	                   │---• · · · · •---│ ↓ offset (from vertical center)
				//	                   └─┐             ┌─┘
				//	                     └─┐         ┌─┘
				//	                       └─────────┘
				//       						       <----|---->
				//	                     -range | +range  (from horizontal center)
				//	                       <--------->
				//                          2 * range
		
				//	formula1:	radius² = x² + y²
				//		radius² = range² + max²
				//	formula2: ratio = width / height
				//		ratio = 2*range / (max - offset)
				//	=> range = ratio * (max - offset) / 2
		
				//	combine: radius² = range² + max² AND range = ratio * (max - offset) / 2
				//	=> radius² = (ratio * (max - offset) / 2)² + max²
				//	use abc formula where max is the value to be calculated: (all other variables are known)
				//	=> (ratio/2 * (max - offset))² + max² - radius² = 0
				//	=> (ratio/2 * max - ratio/2*offset)² + max² - radius² = 0
				//	=> (ratio/2)² * max² -2 * ratio/2 * max * ratio/2*offset + (ratio/2*offset)² + max² - radius² = 0
				//	=> (1+(ratio/2)²) * max² + (-2 * ratio/2 * ratio/2*offset) * max + (ratio/2*offset)² - radius² = 0
				//	=>	a = 1+(ratio/2)²
				//			b = -2 * ratio/2 * ratio/2 * offset = -ratio²/2 * offset
				//			c = (ratio/2*offset)² - radius²
				//	=>	D = b² - 4*a*c
				//	=>	max = (-b ± √D)/(2 * a)
		
				var a = 1+Math.pow(ratio/2, 2);
				var b = -ratio*ratio/2 * offset;
				var c = Math.pow(ratio/2*offset, 2) - radius*radius;
				var results = MyMath.getAbcFormulaResults(a, b, c);
				var max = results[1];
				var range = ratio * (max - offset) / 2;
				return {
					:max => max,
					:range => range,
				};
			}
			private static function getLimitsForRatio_1Corner(ratio as Float, xOffset as Float, yOffset as Float, radius as Float) as { :xMax as Float, :yMax as Float } {
				// this functions returns 2 Float values: xMax, yMax which indicate the top left corner of the found rectangle with given ratio
				//         radius   ↑      ┌─┬───────┐
				//	(from center)   ·    ┌─┘ •· · · ·○─┐   ↑ yMax (from vertical center)
				//	                ·  ┌─┘   │       · └─┐ · 
				//	                ·  │     │       ·   │ ·
				//	                ─  │     │  +    ·   │ ─
				//	                   │     •───────•───│ ↓ yOffset (from vertical center)
				//	                   └─┐             ┌─┘
				//	                     └─┐         ┌─┘
				//	                       └─────────┘
				//       						         <--|---->
				//	                     xOffset| xMax  (from horizontal center)
				//
				//	radius² = xMax² + yMax²
				//	ratio = (xMax + xOffset) / (yMax + yOffset)
				//	=>	ratio * (yMax + yOffset) = (xMax + xOffset)
				//	=>	xMax = ratio * (yMax + yOffset) - xOffset 
				//
				//	radius² = (ratio * (yMax + yOffset) - xOffset)² + yMax²
				//	=> (ratio * (yMax + yOffset) - xOffset)² + yMax² - radius² = 0
				//	=> (ratio * yMax + ratio * yOffset - xOffset)² + yMax² - radius² = 0
		
				//	=> (ratio * yMax)² + 2 * (ratio * yMax) * (ratio * yOffset - xOffset) + (ratio * yOffset - xOffset)² + yMax² - radius² = 0
				//	=> (ratio² + 1) * yMax²	+ (2 * ratio * (ratio * yOffset - xOffset))	* yMax + (ratio * yOffset - xOffset)² - radius² = 0
		
				//	a = (ratio² + 1)
				//	b = (2 * ratio * (ratio * yOffset - xOffset))
				//	c = (ratio * yOffset - xOffset)² - radius²
				var a = ratio*ratio + 1;
				var b = 2 * ratio * (ratio * yOffset - xOffset);
				var c = Math.pow(ratio * yOffset - xOffset, 2) - radius*radius;
				var results = MyMath.getAbcFormulaResults(a, b, c);
				var yMax = results[1];
				var xMax = ratio * (yMax + yOffset) - xOffset;
				return {
					:xMax => xMax,
					:yMax => yMax,
				};
			}	
		}
	}
}