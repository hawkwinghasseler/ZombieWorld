package
{
	import flash.display.MovieClip;
	
	public class Ammo extends MovieClip
	{
		var names:Array = [".45 Auto", "12 Gauge Shell"];
		var amounts:Array = [40, 0];
		
		public function Ammo()
		{
		}
		
		public function addAmmo(n:Number, s:String)
		{
			amounts[names.indexOf(s)] += n;
		}
		
		public function takeAmmo(s:String, n:Number)
		{
			if (amounts[names.indexOf(s)] >= n)
			{
				amounts[names.indexOf(s)] -= n;
				return n;
			}
			else
			{
				amounts[names.indexOf(s)] = 0;
				return amounts[names.indexOf(s)];
			}
		}
		
		public function getAmmo(s:String)
		{
			return amounts[names.indexOf(s)];
		}
		
		public function printEasy()
		{
			var s:String = "Ammo/Amounts";
			for (var i:int = 0; i < names.length; i++)
			{
				s += "\n" + names[i] + "= " + amounts[i];
			}
			return s;
		}
	}
}