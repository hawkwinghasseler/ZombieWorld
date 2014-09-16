package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.*;
	
	public class Zombie extends MovieClip
	{
		//Initiate Constants
		var MOVEMENT_SPEED:Number = .5;
		var SENSOR_RANGE:Number = 200;
		
		//Initiate variables
		var health:Number;
		var dead:Boolean = false;
		var moving:Boolean = false;
		var impact_Angle:Number = 0;
		
		public function Zombie(x_In:Number, y_In:Number, r_In:Number, h_In:Number)
		{
			x = x_In;
			y = y_In;
			rotation = r_In;
			health = h_In;
			
			addEventListener(Event.ENTER_FRAME, everyFrame);
			gotoAndStop("Alive");
		}
		
		public function everyFrame(e:Event)
		{
			if (!dead)
			{
				//Decide which direction to face (toward player)
				decideDirection();
				
				//Move in that direction
				if (moving)
				{
					moveMe();
				}
			}
		}
		
		public function moveMe()
		{
			if (!(parent.parent.parent as MovieClip).getMap().hitTestPoint(x + (parent.parent.parent as MovieClip).getGWOffsets()[0], y + (parent.parent.parent as MovieClip).getGWOffsets()[1], true))
			{
				var radians = (rotation - 90) / (180 / Math.PI);
				
				x += (Math.cos(radians) * MOVEMENT_SPEED);
				y += (Math.sin(radians) * MOVEMENT_SPEED);
			}
		}
		
		public function decideDirection()
		{
			var closestPlayer:Player = getClosestPlayerWithinRange();
			if (closestPlayer == null)
			{
				//No players are nearby
				sensor.visible = false;
				moving = false;
			}
			else
			{
				//Closest Player is targeted
				sensor.visible = true;
				var targetX:Number = closestPlayer.x;
				var targetY:Number = closestPlayer.y;
				
				var dist_Y:Number = targetY - this.y;
				var dist_X:Number = targetX - this.x;
				var angle:Number = Math.atan2(dist_Y, dist_X);
				var degrees:Number = angle * 180 / Math.PI;
				this.rotation = degrees + 90;
				
				if (Math.sqrt((dist_Y * dist_Y) + (dist_X * dist_X)) < 30)
				{
					moving = false;
				}
				else
				{
					moving = true;
				}
			}
		}
		
		public function takeDamage(impact_Angle_In:Number, damage_In:Number, knock_In:Number)
		{
			impact_Angle = impact_Angle_In;
			health -= damage_In;
			checkForDeath();
			var radians = (impact_Angle - 90) / (180 / Math.PI);
			x += (Math.cos(radians) * knock_In);
			y += (Math.sin(radians) * knock_In);
		}
		
		public function checkForDeath()
		{
			if (health <= 0)
			{
				die();
			}
		}
		
		public function isDead()
		{
			return dead;
		}
		
		public function die()
		{
			(parent.parent.parent as MovieClip).addStaticAni(x, y, impact_Angle, "Blood");
			dead = true;
			gotoAndStop("Dead");
			removeMe();
		}
		
		public function getClosestPlayerWithinRange()
		{
			//Returns the closest player within range
			var tempList = new Array();
			for each (var someE in(parent.parent.parent as MovieClip).getAllElements())
			{
				var distance:Number = Math.sqrt(((someE[1].y - this.y) * (someE[1].y - this.y)) + ((someE[1].x - this.x) * (someE[1].x - this.x)));
				if (distance < SENSOR_RANGE)
				{
					if (someE[0] == "Player")
					{
						//I see a Player
						tempList.push([someE[1], distance]);
					}
				}
			}
			
			if (tempList.length > 0)
			{
				//Get the closest player
				var playerToSend:Player;
				var closestDistance:Number = tempList[0][1];
				for (var i = 0; i < tempList.length; i++)
				{
					if (closestDistance >= tempList[i][1])
					{
						closestDistance = tempList[i][1];
						playerToSend = tempList[i][0];
					}
				}
			}
			else
			{
				return null;
			}
			
			if (dead)
			{
				playerToSend = null;
			}
			return playerToSend;
		}
		
		public function getInfoArray()
		{
			return [x, y, rotation, health];
		}
		
		public function removeMe()
		{
			trace("REMOVING A ZOMBIE");
			removeEventListener(Event.ENTER_FRAME, everyFrame);
			(parent.parent.parent as MovieClip).garbageCollectElementArray();
			(parent as MovieClip).removeChild(this);
		}
		
		public function record(s:String)
		{
			(parent.parent.parent as MovieClip).record(s);
		}
	}
}