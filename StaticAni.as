package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class StaticAni extends MovieClip
	{
		//Initiate Constants
		var RANDOMIZED_TYPES:Array = ["Blood"];
		var STATIC_TYPES:Array = ["Blood"];
		var REMOVE_AFTER_ANI:Array = ["MuzzleFlash", "BulletHole", "BulletBlood"];
		
		public function StaticAni(type:String)
		{
			//trace("Static type " + type + " created");
			gotoAndStop(type);
			if (RANDOMIZED_TYPES.indexOf(type) >= 0)
			{
				//Pick a random static animation
				var randomNum:int = int(Math.random() * nested.totalFrames) + 1;
				nested.gotoAndStop(randomNum);
			}
			
			if (REMOVE_AFTER_ANI.indexOf(type) >= 0)
			{
				addEventListener(Event.ENTER_FRAME, everyFrameRemoveCheck);
			}
			
			if (STATIC_TYPES.indexOf(type) >= 0)
			{
				this.cacheAsBitmap = true;
			}
		}
		
		public function everyFrameRemoveCheck(e:Event)
		{
			if (nested.currentFrame == nested.totalFrames)
			{
				removeEventListener(Event.ENTER_FRAME, everyFrameRemoveCheck);
				removeMe();
			}
		}
		
		public function removeMe()
		{
			(parent as MovieClip).removeChild(this);
		}
	}
}