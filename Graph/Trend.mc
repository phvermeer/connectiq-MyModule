import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

module MyModule{
	(:Graph)
	module Graph{
		class Trend extends WatchUi.Drawable{
			enum Alignment{
				HALIGN_LEFT = 0x1,
				HALIGN_CENTER = 0x2,
				HALIGN_RIGHT = 0x4,
				VALIGN_TOP = 0x8,
				VALIGN_CENTER = 0x10,
				VALIGN_BOTTOM = 0x20,
			}

			hidden var series as Array<Graph.Serie> = [] as Array<Graph.Serie>;
			hidden var align as Alignment or Number = HALIGN_LEFT | VALIGN_CENTER;
			hidden var xRangeMin as Numeric = 20.0f;
			hidden var xCurrent as Numeric or Null;
			hidden var yCurrent as Numeric or Null;

			public var frameColor as Graphics.ColorType = Graphics.COLOR_BLACK;
			public var textColor as Graphics.ColorType = Graphics.COLOR_BLACK;
			public var xyMarkerColor as Graphics.ColorType = Graphics.COLOR_BLACK;
			public var maxMarkerColor as Graphics.ColorType = Graphics.COLOR_RED;
			public var minMarkerColor as Graphics.ColorType = Graphics.COLOR_GREEN;

			function initialize(options as {
				:locX as Number, 
				:locY as Number,
				:width as Number, 
				:height as Number,
				:align as Alignment, 
				:series as Array<Serie>,
				:darkMode as Boolean,
				:xRangeMin as Float,
			}){
				if(!options.hasKey(:identifier)){ options.put(:identifier, "Graph"); }
				Drawable.initialize(options);

				if(options.hasKey(:align)){ setAlignment(options.get(:align) as Number); }
				if(options.hasKey(:series)){ series = options.get(:series); }
				if(options.hasKey(:darkMode)){ setDarkMode(options.get(:darkMode) as Boolean); }
				if(options.hasKey(:xRangeMin)){ xRangeMin = options.get(:xRangeMin) as Numeric; }
			}

			function draw(dc as Dc){
				// collect data
				if(series == null){ return; }

				// draw frame
				var font = Graphics.FONT_XTINY;
				var labelHeight = dc.getFontHeight(font);
				var topMargin = labelHeight + 6; // space for the markers
				var bottomMargin = 0; // space for the min/max distance 
				var axisWidth = 2;
				var axisMargin = 0.5f + Math.ceil(0.5f * axisWidth); // space for the axis width
				var innerHeight = height - (topMargin + bottomMargin + axisMargin);
				var innerWidth = width - (2 * axisMargin);

				// draw the xy-axis frame
				dc.setPenWidth(axisWidth);
				dc.setColor(frameColor, Graphics.COLOR_TRANSPARENT);
				dc.drawLine(locX, locY+topMargin, locX, locY+height-bottomMargin);
				dc.drawLine(locX, locY+height-bottomMargin, locX+width, locY+height-bottomMargin);
				dc.drawLine(locX+width, locY+topMargin, locX+width, locY+height-bottomMargin);
				
				// determine the generic limits (xMin, xMax, yMin, yMax)
				if(series.size() > 0){
					var data = series[0].data;
					var xMin = data.xMin;
					var xMax = data.xMax;
					var yMin = data.yMin;
					var yMax = data.yMax;
					for(var s=0; s<series.size(); s++){
						data = series[s].data;
						if(data.xMin < xMin) { xMin = data.xMin; }
						if(data.xMax > xMax) { xMax = data.xMax; }
						if(data.yMin < yMin) { yMin = data.yMin; }
						if(data.yMax > yMax) { yMax = data.yMax; }
					}
					if(xMin >= xMax) { return; }
					if(yMin >= yMax) { return; }

					var xFactor = innerWidth / (xMax - xMin);
					var yFactor = -1 * innerHeight / (yMax - yMin);
					var xOffset = axisMargin + locX - xMin * xFactor;
					var yOffset = locY + topMargin + innerHeight - yMin * yFactor;

					for(var s=0; s<series.size(); s++){
						var serie = series[s];
						if(serie.data != null){
							var pts = serie.data.pts;
							if(pts.size() < 2){ return; }

							var ptFirst = pts[0];
							var ptLast = pts[pts.size()-1];
						
							var yRangeMin = serie.yRangeMin; // minimal vertical range

							if((pts.size() > 1) && (xMax > xMin)){

								if((xMax - xMin) < xRangeMin){
									var xExtra = xRangeMin - (xMax - xMin);
									xMax += 1.0 * xExtra;
									xMin -= 0.0 * xExtra;
								}

								if((yMax - yMin) < yRangeMin){
									var yExtra = yRangeMin - (yMax - yMin);
									yMax += 0.8 * yExtra;
									yMin -= 0.2 * yExtra;
								}

								// Create an array of point with screen xy
								var color = (serie.color != null) ? serie.color as ColorType : textColor;
								dc.setColor(color, Graphics.COLOR_TRANSPARENT);
								
								if(serie.style == DRAW_STYLE_FILLED){
									var screenPts = [
										[xOffset + xFactor * ptLast[0], locY + topMargin + innerHeight] as Array<Numeric>,
										[xOffset + xFactor * ptFirst[0], locY + topMargin + innerHeight] as Array<Numeric>
									] as Array< Array< Numeric> >;
									for(var i=0; i<pts.size(); i++){
										var pt=pts[i];
										var x = xOffset + xFactor * pt[0] as Numeric;
										var y = yOffset + yFactor * pt[1] as Numeric;
										screenPts.add([x, y] as Array<Numeric>);
									}
									dc.fillPolygon(screenPts);
								}else if(serie.style == DRAW_STYLE_LINE){
									var xPrev = 0;
									var yPrev = 0; 
									for(var i=0; i<pts.size(); i++){
										var pt=pts[i];
										var x = xOffset + xFactor * pt[0] as Numeric;
										var y = yOffset + yFactor * pt[1] as Numeric;
										if(i>0){
											dc.drawLine(xPrev, yPrev, x, y);
										}
										xPrev = x;
										yPrev = y;
									}
								}

								// Min value
								if((serie.markers != null) && (serie.data.ptMin != null) && (MARKER_MIN == MARKER_MIN)){
									var ptMin = serie.data.ptMin as Array<Numeric>;
									dc.setColor(minMarkerColor, Graphics.COLOR_TRANSPARENT);

									drawMarker(
										dc, 
										xOffset + xFactor * ptMin[0], 
										yOffset + yFactor * ptMin[1], 
										axisMargin, 
										ptMin[1].format("%d")
									);
								}
								// Max value
								if((serie.markers != null) && (serie.data.ptMax != null) && (MARKER_MAX == MARKER_MAX)){
									var ptMax = serie.data.ptMax as Array<Numeric>;
									dc.setColor(maxMarkerColor, Graphics.COLOR_TRANSPARENT);
									drawMarker(
										dc, 
										xOffset + xFactor * ptMax[0], 
										yOffset + yFactor * ptMax[1], 
										axisMargin, 
										ptMax[1].format("%d")
									);
								}
							}
						}
					}
					// draw current x and y markers
					if(xCurrent != null){
						var x = xOffset + xFactor * xCurrent;
						dc.setColor(xyMarkerColor, Graphics.COLOR_TRANSPARENT);
						dc.setPenWidth(1);
						dc.drawLine(x, locY, x, locY + height);
					}
					if(yCurrent != null){
						var y = yOffset + yFactor * yCurrent;
						dc.setColor(xyMarkerColor, Graphics.COLOR_TRANSPARENT);
						dc.setPenWidth(1);
						dc.drawLine(xOffset, y, xOffset + xMax * xFactor, y);
					}
				}
			}
			
			public function setCurrentX(x as Numeric or Null) as Void{
				// This will draw the current X marker in the graph
				self.xCurrent = x;			
			}
			public function setCurrentY(y as Numeric or Null) as Void{
				// This will draw the current X marker in the graph
				self.yCurrent = y;			
			}
			
			protected function drawMarker(dc as Graphics.Dc, x as Numeric, y as Numeric, margin as Numeric, text as String) as Void{
				var font = Graphics.FONT_XTINY;
				var w2 = dc.getTextWidthInPixels(text, font)/2;
				var h = dc.getFontHeight(font);
				var xText = x;
				if((x-w2) < (locX + margin)){
					xText = locX + margin + w2;
				}else if((x+w2) > (locX + width - margin)){
					xText = locX + width - margin - w2;
				}
				dc.fillPolygon([
					[x, y] as Array<Numeric>,
					[x-5, y-6] as Array<Numeric>,
					[x+5, y-6] as Array<Numeric>
				] as Array< Array<Numeric> >);
				dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
				dc.drawText(xText, y-6-h, font, text, Graphics.TEXT_JUSTIFY_CENTER);
			}

			public function setDarkMode(darkMode as Boolean) as Void{
				self.textColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
				self.frameColor = darkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
				self.xyMarkerColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
				self.minMarkerColor = darkMode ? Graphics.COLOR_RED : Graphics.COLOR_DK_RED;
				self.maxMarkerColor = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
			}

			public function setAlignment(align as Alignment or Number) as Void{
				self.align = align;
			}
			public function addSerie(serie as Graph.Serie) as Void{
				series.add(serie);
			}
			public function removeSerie(serie as Graph.Serie) as Void{
				series.remove(serie);
			}
		}
	}
}