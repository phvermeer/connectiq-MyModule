import Toybox.Lang;
import Toybox.Graphics;

module MyModule{
	(:Tools)
	module Tools{

		function colorToRGB(color as ColorType) as Array<Number>{
			var R = (color & (255 << 16)) >> 16;
			var G = (color & (255 << 8)) >> 8;
			var B = (color & 255);
			return [R,G,B];
		}

		function formatDistance(distance as Float) as String{
			var units = System.getDeviceSettings().distanceUnits;
			if(units == System.UNIT_METRIC){
				var m = distance;
				if(m < 1000){
					return m.format("%.0f") + "m";
				}else{
					var km = m/1000f;
					if(km < 10){
						return km.format("%.2f") + "km";
					}else if(km < 100){
						return km.format("%.1f") + "km";
					}else{
						return km.format("%.0f") + "km";
					}
				}
			}else{
				var feet = distance * 3.280839895f;
				var miles = distance * 0.000621371f;
				if(miles < 1){
					return feet.format("%.0f") + "ft";
				}else if(miles < 10){
					return miles.format("%.2f") + "mi";
				}else if(miles < 100){
					return miles.format("%.1f") + "mi";
				}else{
					return miles.format("%.0f") + "mi";
				}
			}
		}

		function adjustFont(dc as Graphics.Dc, baseFont as Graphics.FontDefinition, text as Lang.String, width as Lang.String) as Graphics.FontDefinition{
			// This function will decrease the font until the text fits in the available width
			var fontMin =
				(baseFont <= Graphics.FONT_NUMBER_THAI_HOT) ? Graphics.FONT_XTINY :
				(baseFont <= Graphics.FONT_SYSTEM_NUMBER_THAI_HOT) ? Graphics.FONT_SYSTEM_XTINY :
				Graphics.FONT_GLANCE;
		
			for(var f=baseFont; f>=fontMin; f--){
				var w = dc.getTextWidthInPixels(text, f);
				if(w <= width){
					return f;
				}
			}
			return fontMin;
		}
	}
}