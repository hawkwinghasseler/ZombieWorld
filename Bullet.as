package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class Bullet extends MovieClip
	{
		var MOVEMENT_SPEED:Number = 10;
		var MAX_DISTANCE:Number = 200;
		var MAX_HEIGHT:Number = 440;
		var MAX_WIDTH:Number = 480;
		var LETHAL_DISTANCE:Number = 1;
		
		var immuneToPlayer:String;
		
		public function Bullet(x_In:Number, y_In:Number, r_In:Number, immune_In:String)
		{
			x = x_In;
			y = y_In;
			rotation = r_In;
			
			immuneToPlayer = immune_In;
			
			addEventListener(Event.ENTER_FRAME, everyFrame);
			gotoAndStop("Non-Lethal");
		}
		
		public function everyFrame(e:Event)
		{
			moveMe();
		}
		
		public function moveMe()
		{
			var radians = (rotation - 90) / (180 / Math.PI);
			
			x += (Math.cos(radians) * MOVEMENT_SPEED);
			y += (Math.sin(radians) * MOVEMENT_SPEED);
			MAX_DISTANCE--;
			
			//Make the bullet lethal after a certain distance
			if (LETHAL_DISTANCE > 0)
			{
				LETHAL_DISTANCE--;
			}
			
			if (LETHAL_DISTANCE == 0)
			{
				gotoAndStop("Lethal");
			}
			
			//Hit test with all characters
			if (isLethal())
			{
				for each (var someP in(parent.parent.parent as MovieClip).getAllPlayers())
				{
					if (someP.hitTestObject(this))
					{
						if (someP.getID() != immuneToPlayer)
						{
							//record("A Player was hit!");
							someP.takeDamage();
							removeMe();
						} else {
							//record("ID check: " + someP.getID() + " vs " + immuneToPlayer);
						}
					}
				}
			}
			
			//Remove after a certain distance or the Bullet exceeds constraints
			if (MAX_DISTANCE <= 0 || x < 0 || y < 0 || x > MAX_WIDTH || y > MAX_HEIGHT)
			{
				removeMe();
			}
		}
		
		public function removeMe()
		{
			removeEventListener(Event.ENTER_FRAME, everyFrame);
			(parent as MovieClip).removeChild(this);
		}
		
		public function isLethal()
		{
			return LETHAL_DISTANCE == 0;
		}
		
		public function record(s:String)
		{
			(parent.parent.parent as MovieClip).record(s);
		}
	}
}