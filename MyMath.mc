using Toybox.Math;

module MyModule{
	(:MyMath)
	module MyMath{
		
		function sgn(x as Numeric){
			return (x < 0) ? -1 :
				(x > 0) ? 1 : 0;
		}
		
		function sqr(x as Numeric) as Numeric{
			return x*x;
		}
		
		function max(values as Array){
			var v = values[0];
			for(var i=1; i<values.size(); i++){
				if(values[i] > v){
					v = values[i];
				}
			}
			return v;
		}
		
		function min(values as Array<Lang.Numeric>){
			var v = values[0];
			for(var i=1; i<values.size(); i++){
				if(values[i] < v){
					v = values[i];
				}
			}
			return v;
		}
		
		function abs(value as Lang.Numeric){
			return (value < 0) ? -value : value;
		}

		function ceil(value as Lang.Numeric, decimals as Lang.Number) as Lang.Numeric{
			var factor = Math.pow(10, decimals).toNumber();
			return Math.ceil(value * factor) / factor;
		}
		
		function floor(value as Lang.Numeric, decimals as Lang.Number) as Lang.Numeric{
			var factor = Math.pow(10, decimals).toNumber();
			return Math.floor(value * factor) / factor;
		}
		
		function getAbcFormulaResults(a as Float, b as Float, c as Float) as Array<Float> {
			var sqrtD = Math.sqrt(b*b - 4*a*c);
			return [(-b - sqrtD)/(2 * a), (-b + sqrtD)/(2 * a)];
		}	
	}
}