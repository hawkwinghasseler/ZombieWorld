package
{
	import flash.display.MovieClip;
	
	public class PlayerHUI extends MovieClip
	{
		var myID:String;
		var myHealth:int;
		var dead:Boolean = false;
		var said:Boolean = false;
		
		public function PlayerHUI()
		{
		}
		
		public function changePosition(x_In:Number, y_In:Number)
		{
			x = x_In;
			y = y_In;
		}
		
		public function setText(s:String)
		{
			playerName.text = s;
		}
		
		public function say(s:String)
		{
			bubble.gotoAndStop(1);
			bubble.myText.autoSize = "center";
			bubble.myText.text = s;
			bubble.sizer.interior.height = bubble.myText.textHeight + 10;
			bubble.myText.y = 0 - bubble.myText.textHeight - 5;
			bubble.play();
		}
		
		public function removeMe()
		{
			(parent as MovieClip).removeChild(this);
		}
	}
}