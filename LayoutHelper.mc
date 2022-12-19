import Toybox.System;
import Toybox.Math;
import Toybox.Lang;
import MyModule.MyMath;
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
		
			hidden var deviceSettings as DeviceSettings;
			hidden var radius as Float;
			hidden var xMin as Float = 0.0f;
			hidden var xMax as Float = 0.0f;
			hidden var yMin as Float = 0.0f;
			hidden var yMax as Float = 0.0f;
		
			function initialize(boundaries as {
				:x as Numeric,
				:y as Numeric,
				:width as Numeric, 
				:heigth as Numeric
			} or Null ){
				self.deviceSettings = System.getDeviceSettings();
				self.radius = 0.5f * MyMath.max([deviceSettings.screenHeight, deviceSettings.screenWidth]  as Array<Number>).toFloat();
		
				if(boundaries != null){
					var x = boundaries.hasKey(:x) ? boundaries.get(:x) as Numeric : 0;
					var y = boundaries.hasKey(:y) ? boundaries.get(:y) as Numeric : 0;
					var w = boundaries.hasKey(:width) ? boundaries.get(:width) as Numeric : deviceSettings.screenWidth - x;
					var h = boundaries.hasKey(:height) ? boundaries.get(:height) as Numeric : deviceSettings.screenHeight - y;
					setBoundaries(x, y, w, h);
				}else{
					setBoundaries(0, 0, deviceSettings.screenWidth, deviceSettings.screenHeight);
				}
			}
		
			function setBoundaries(x as Numeric, y as Numeric, w as Numeric, h as Numeric) as Void{
				self.xMin = (x - self.radius).toFloat();
				self.xMax = (x + w - self.radius).toFloat();
				self.yMin = (self.radius - (y + h)).toFloat();
				self.yMax = (self.radius - y).toFloat();
			}

			function getBoundaries() as Array<Numeric>{
				return [
					xMin + radius, // x
					yMin + radius, // y
					xMax - xMin, // width
					yMax - yMin, // height
				] as Array<Numeric>;
			}

			function getAreaByRatio(ratio as Float) as Array<Number> or Null{
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
						xMaxC = results.get(:xMax) as Float;
						xMinC = -xMaxC;
						yMaxC = results.get(:yMax) as Float;
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
							yMaxC = result.get(:max) as Float;
							yMinC = yMin;

							// Check max limit
							if(yMaxC > yMax){
								yMaxC = yMax;
								xMaxC = Math.sqrt(radius*radius - yMax*yMax);
							}else{
								xMaxC = result.get(:range) as Float;
							}
							xMinC = -xMaxC;

						}else if(q3 && q4){
							// determine the bigest rectangle with given ratio within a circle (top)
							var result = getLimitsForRatio_2Corners(ratio, -yMax, radius);
			
							// determine the x,y based upon these results for given quadrants
							yMinC = -(result.get(:max) as Float);
							yMaxC = yMax;

							// Check max limit
							if(yMinC < yMin){
								yMinC = yMin;
								xMaxC = Math.sqrt(radius*radius - yMin*yMin);
							}else{
								xMaxC = result.get(:range) as Float;
							}
							xMinC = -xMaxC;


						}else if(q1 && q4){
							// determine the bigest rectangle with given ratio within a circle (top)
							var result = getLimitsForRatio_2Corners(1/ratio, xMin, radius);
			
							// determine the x,y based upon these results for given quadrants
							xMaxC = result.get(:max) as Float;
							xMinC = xMin;

							// Check max limit
							if(xMaxC > xMax){
								xMaxC = xMax;
								yMaxC = Math.sqrt(radius*radius - xMax*yMax);
							}else{
								yMaxC = result.get(:range) as Float;
							}
							yMinC = -yMaxC;

						}else if(q2 && q3){
							// determine the bigest rectangle with given ratio within a circle (top)
							var result = getLimitsForRatio_2Corners(1/ratio, -xMax, radius);
			
							// determine the x,y based upon these results for given quadrants
							xMinC = -(result.get(:max) as Float);
							xMaxC = xMax;

							if(xMinC < xMin){
								xMinC = xMin;
								yMaxC = Math.sqrt(radius*radius - xMin*xMin);
							}else{
								yMaxC = result.get(:range) as Float;
							}
							yMinC = -yMaxC;

						}else{
							ok = false;
						}
			
						// Check if the calculated circle edge values are within the given limits
						if(ok){
							if(yMaxC as Float > yMax) { ok = false; q1 = false; q2 = false;}
							if(yMinC as Float < yMin) { ok = false; q3 = false; q4 = false;}
							if(xMaxC as Float > xMax) { ok = false; q1 = false; q4 = false;}
							if(xMinC as Float < xMin) { ok = false; q2 = false; q3 = false;}
						}
					}
		
					if(!ok){
						ok = true;
						// Now check if the rectangle is limited at a single corner
						if(q1){
							//	q1 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, xMin as Float, yMin as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMaxC = results.get(:yMax) as Float;
							xMaxC = results.get(:xMax) as Float;
							xMinC = xMin;
							yMinC = yMin;
						}else if(q2){
							//	q2 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, -xMax as Float, yMin as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMinC = yMin;
							yMaxC = results.get(:yMax) as Float;
							xMinC = -(results.get(:xMax) as Float);
							xMaxC = xMax;
						}else if(q3){
							//	q3 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, -xMax as Float, -yMax as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMinC = -(results.get(:yMax) as Float);
							yMaxC = yMax;
							xMinC = -(results.get(:xMax) as Float);
							xMaxC = xMax;
						}else if(q4){
							//	q4 =>
							var results = getLimitsForRatio_1Corner(ratio as Float, xMin as Float, -yMax as Float, radius as Float);
			
							// determine the x,y for this quadrant
							yMinC = -(results.get(:yMax) as Float);
							yMaxC = yMax;
							xMinC = xMin;
							xMaxC = results.get(:xMax) as Float;
						}else{
							ok = false;
						}
						// Check if the calculated circle edge values are within the given limits
						if(ok){
							if(yMaxC as Float > yMax) {
								yMaxC = yMax;
								if(q1){
									xMaxC = Math.sqrt(radius*radius - yMax*yMax);
								}else if(q2){
									xMinC = - Math.sqrt(radius*radius - yMax*yMax);
								}
							}
							if(yMinC as Float < yMin) {
								yMinC = yMin;
								if(q4){
									xMaxC = Math.sqrt(radius*radius - yMin*yMin);
								}else if(q3){
									xMinC = - Math.sqrt(radius*radius - yMin*yMin);
								}
							}
							if(xMaxC as Float > xMax) {
								xMaxC = xMax;
								if(q1){
									yMaxC = Math.sqrt(radius*radius - xMax*xMax);
								}else if(q4){
									yMinC = - Math.sqrt(radius*radius - xMax*xMax);
								}
							}
							if(xMinC as Float < xMin) {
								xMinC = xMin;
								if(q2){
									yMaxC = Math.sqrt(radius*radius - xMin*xMin);
								}else if(q3){
									yMinC = - Math.sqrt(radius*radius - xMin*xMin);
								}
							}
						}
					}
				}

				if(!ok){
					xMinC = xMin;
					xMaxC = xMax;
					yMinC = yMin;
					yMaxC = yMax;
					ok = true;
				}

				// convert to real xy coordinates:
				var x1 = Math.ceil((xMinC as Float) + radius).toNumber();
				var x2 = Math.floor((xMaxC as Float) + radius).toNumber();
				var y1 = Math.ceil(radius - (yMaxC as Float)).toNumber();
				var y2 = Math.floor(radius - (yMinC as Float)).toNumber();
				var w = x2 - x1;
				var h = y2 - y1;

				if(w<0 || h<0){
					return null;
/*				}else if(ratio * h > w){
					var dh = (h - (w / ratio));
					h -= dh;
					y1 += dh/2;
				}else if(ratio * h < w){
					var dw = (w - (h * ratio));
					w -= dw;
					x1 += dw/2;
*/				}

				return [
					x1, // x
					y1, // y
					w, // width
					h, // height
				] as Array<Number>;
			}

			public function getAlignedPosition(align as Alignment, width as Numeric, height as Numeric) as Array<Number> or Null {
				// This function will calculate the position (x,y) of a given rectangle (width, height) within a circle aligned to a direction within the circle and given boundaries
		
				// check if the rectangle fits with boundaries, otherwise align without looking at circle shape
				if(width > (xMax-xMin)){
					var y = Math.round(radius - (yMin + yMax)/2 - height/2);
					if(align == ALIGN_LEFT){
						var x = Math.round(xMin + radius);
						return [x, y] as Array<Number>;
					}else if(align == ALIGN_RIGHT){
						var x = Math.round(xMax - width + radius);
						return [x, y] as Array<Number>;
					}
				}
				if(height > (yMax-yMin)){
					var x = Math.round((xMin + xMax)/2 + radius - width/2);
					if(align == ALIGN_TOP){
						var y = Math.round(radius - yMax);
						return [x, y] as Array<Number>;
					}else if(align == ALIGN_BOTTOM){
						var y = Math.round(radius - (yMin + height));
						return [x, y] as Array<Number>;
					}
				}
		
				// transpose the aligmnent direction to ALIGN_TOP
				var ok = false;
				var gap = null;
				var rr = radius*radius;
		
				var xMin = null, xMax = null, yMax = null, size = null; // all floats
				if(align == ALIGN_TOP){
					xMin = self.xMin;
					xMax = self.xMax;
					yMax = self.yMax;
					size = width;
				}else if(align == ALIGN_BOTTOM){
					xMin = -self.xMax;
					xMax = -self.xMin;
					yMax = -self.yMin;
					size = width;
				}else if(align == ALIGN_LEFT){
					xMin = self.yMin;
					xMax = self.yMax;
					yMax = -self.xMin;
					size = height;
				}else if(align == ALIGN_RIGHT){
					xMin = -self.yMax;
					xMax = -self.yMin;
					yMax = self.xMax;
					size = height;
				}else{
					return null;
				}
		
				// get space at max and check if the size already fits
				// y² + x² = radius²
				// x = ± √ (radius² - yMax²)
				var xMinC = MyMath.max([-Math.sqrt(rr - yMax*yMax), xMin] as Array<Numeric>);
				var xMaxC = MyMath.min([Math.sqrt(rr - yMax*yMax), xMax] as Array<Numeric>);
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
					yMaxC = Math.sqrt(rr - size2*size2);
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
					x = radius + yMaxC - width;
					y = radius + xMinC + gap/2;
				}else{
					return null;
				}
				return [
					Math.round(x).toNumber(),
					Math.round(y).toNumber()
				] as Array<Number>;
			}
		
			private static function getLimitsForRatio_4Corners(ratio as Float, radius as Float) as {
				:xMax as Float,
				:yMax as Float
			}{
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

			private static function getLimitsForRatio_2Corners(ratio as Float, offset as Float, radius as Float) as {
				:max as Float, 
				:range as Float
			} {
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

			private static function getLimitsForRatio_1Corner(ratio as Float, xOffset as Float, yOffset as Float, radius as Float) as { 
				:xMax as Float, 
				:yMax as Float
			}{
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
				//	xOffset -> x
				//	yOffset -> y
				//	radius -> r
				//	ratio -> C
				//
				//	(x+w)²+(y+h)²=r²
				//	h=w/C	→	(x+w)²+(y+w/C)²=r²	
				//	(x²+2wx+w²) + (y²+(2y/C)w+(1/C²)w²) = r²
				//	(1+1/C²)*w² + (2x+2y/C)*w + (x²+y²-r²) = 0
				//
				//	w? -> use abc formula where w->x
				//
				//	ax² + bx + c = 0
				//
				//	a = (1+1/C²)
				//	b = (2x+2y/C)
				//	c = (x²+y²-r²)

				var a = 1 + 1/(ratio*ratio);
				var b = 2 * xOffset + 2 * yOffset / ratio;
				var c = xOffset * xOffset + yOffset * yOffset - radius * radius;
				var results = MyMath.getAbcFormulaResults(a, b, c);
				var w = MyMath.max(results); // use the positive result
				var h = w / ratio;
				var yMax = yOffset + h;
				var xMax = xOffset + w;
				return {
					:xMax => xMax,
					:yMax => yMax,
				};
			}
		}
	}
}