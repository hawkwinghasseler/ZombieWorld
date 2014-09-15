package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.media.*;
	
	public class Bullet extends MovieClip
	{
		var MOVEMENT_SPEED:Number = 30;
		var MAX_DISTANCE:Number = 1000;
		var LETHAL_DISTANCE:Number = 1;
		var PENETRATES:Boolean = false;
		var DAMAGE:Number = 1;
		
		var immuneToPlayer:String;
		
		public function Bullet(x_In:Number, y_In:Number, r_In:Number, immune_In:String, PENETRATES_In:Boolean, DAMAGE_In:Number)
		{
			x = x_In;
			y = y_In;
			rotation = r_In;
			PENETRATES = PENETRATES_In;
			DAMAGE = DAMAGE_In;
			
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
			
			//Hit test with appropriate elements
			if (isLethal())
			{
				for each (var someE in(parent.parent.parent as MovieClip).getAllElements())
				{
					if (someE[1].hitTestObject(this))
					{
						if ((someE[0] == "Player" && someE[1].getID() != immuneToPlayer) || someE[0] == "Zombie")
						{
							someE[1].takeDamage(rotation, DAMAGE);
							(parent.parent.parent as MovieClip).createBulletBlood(x, y, rotation + 180);
							if (PENETRATES)
							{
								PENETRATES = false;
							}
							else
							{
								removeMe();
							}
						}
						else
						{
							//record("ID check: " + someP.getID() + " vs " + immuneToPlayer);
						}
					}
				}
			}
			
			if ((parent.parent.parent as MovieClip).getMap().hitTestPoint(x + (parent.parent.parent as MovieClip).getGWOffsets()[0], y + (parent.parent.parent as MovieClip).getGWOffsets()[1], true))
			{
				(parent.parent.parent as MovieClip).createBulletHole(x, y, rotation);
				removeMe();
			}
			
			//Remove after a certain distance or the Bullet exceeds constraints
			if (MAX_DISTANCE <= 0)
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