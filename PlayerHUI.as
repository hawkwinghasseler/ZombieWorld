package
{
	import flash.display.MovieClip;
	
	public class PlayerHUI extends MovieClip
	{
		var myID:String;
		var myHealth:int;
		var dead:Boolean = false;
		
		public function PlayerHUI()
		{
		}
		
		public function changePosition(x_In:Number, y_In:Number)
		{
			x = x_In;
			y = y_In;
		}
		
		public function setText(s:String) {
			playerName.text = s;
		}
		
		public function removeMe() {
			(parent as MovieClip).removeChild(this);
		}
	}
}