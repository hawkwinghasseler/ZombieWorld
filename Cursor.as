package
{
	import flash.display.MovieClip;
	
	public class Cursor extends MovieClip
	{
		//Initiate Constants
		var MIN_SCALE:Number = 2;
		var MAX_SCALE:Number = 99;
		
		public function Cursor()
		{
		
		}
		
		public function setSize(n:Number)
		{
			if (n < MIN_SCALE)
			{
				n = MIN_SCALE;
			}
			if (n > MAX_SCALE)
			{
				n = MAX_SCALE;
			}
			nested0.y = -n;
			nested1.x = n;
			nested2.y = n;
			nested3.x = -n;
		}
	}
}