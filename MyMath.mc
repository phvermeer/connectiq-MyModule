using Toybox.Math;
import Toybox.Lang;

module MyModule{
	(:MyMath)
	module MyMath{
		
		function sgn(x as Numeric) as Number{
			return (x < 0) ? -1 :
				(x > 0) ? 1 : 0;
		}
		
		function sqr(x as Numeric) as Numeric{
			return x*x;
		}
		
		function max(values as Array<Numeric>) as Numeric{
			var v = values[0];
			for(var i=1; i<values.size(); i++){
				if(values[i] > v){
					v = values[i];
				}
			}
			return v;
		}
		
		function min(values as Array<Numeric>) as Numeric{
			var v = values[0];
			for(var i=1; i<values.size(); i++){
				if(values[i] < v){
					v = values[i];
				}
			}
			return v;
		}
		
		function abs(value as Numeric) as Numeric{
			return (value < 0) ? -value : value;
		}

		function ceil(value as Numeric, decimals as Number) as Numeric{
			var factor = Math.pow(10, decimals).toNumber();
			return Math.ceil(value * factor) / factor;
		}
		
		function floor(value as Numeric, decimals as Number) as Numeric{
			var factor = Math.pow(10, decimals).toNumber();
			return Math.floor(value * factor) / factor;
		}
		
		function getAbcFormulaResults(a as Numeric, b as Numeric, c as Numeric) as Array<Decimal> {
			var sqrtD = Math.sqrt(b*b - 4*a*c);
			return [(-b - sqrtD)/(2 * a), (-b + sqrtD)/(2 * a)] as Array<Decimal>;
		}

		function getBitsHigh(value as Integer) as Number{
			return getBitValues(value).size();
		}
		function getBitValues(value as Integer) as Array<Integer>{
			var bitValues = [] as Array<Integer>;
			for(var mask=1; mask-1 <= value; mask*=2){
				var bitValue = value & mask;
				if(bitValue > 0){
					bitValues.add(bitValue);
				}
			}
			return bitValues;
		}
	}
}