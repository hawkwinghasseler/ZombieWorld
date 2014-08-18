package
{
	import flash.display.*;
	import flash.events.*;
	import flash.media.Sound;
	import flash.ui.MouseCursor;
	import flash.utils.*;
	import flash.net.*
	import flash.system.*;
	import flash.ui.*;
	
	public class Engine extends MovieClip
	{
		//Constants
		var MOVEMENT_SPEED:Number = 2;
		var GW_WIDTH:Number;
		var GW_HEIGHT:Number;
		var DISCONNECT_TIMER:Number = 3;
		var REMOVE_TIMER:Number = 2 * DISCONNECT_TIMER;
		var FIRE_RATE:Number = 10;
		var FORCE_RECONNECT_TIMER:Number = 3;
		var PLACE_DISTANCE:Number = 50;
		var ZOMBIE_HEALTH:Number = 10;
		var MAX_ELEMENTS:Number = 50;
		var PENETRATE_CHANCE:Number = 0;
		var AUTO_FIRE:Boolean = true;
		var ACCURACY:Number = 5;
		var ACCURACY_CHANGE_RUN:Number = .5;
		var ACCURACY_CHANGE_STOP:Number = .75;
		var ACCURACY_OFFSET_MAX:Number = 30;
		var KICK:Number = 12;
		var CLIP_SIZE:Number = 10;
		var CURRENT_CLIP_CONTAINS:Number = 0;
		var RELOAD_SPEED:Number = 10;
		var BULLET_DAMAGE:Number = 1;
		
		//Class specific variables
		var mp:Multiplayer = new Multiplayer();
		var gw:GameWindow = new GameWindow();
		var cl:Console = new Console();
		var listOfPlayers:Array = new Array();
		var myTimer:Timer = new Timer(3000);
		var sendForNUQ:Boolean = false;
		var loadingCompleteMark:Boolean = false;
		var shootCD:Number = 0;
		var iAmDisconnected:Boolean = false;
		var elementArray:Array = [];
		var map:Map = new Map();
		var holderArray:Array = new Array();
		var gwHUD:GameWindowHUD = new GameWindowHUD();
		var activated:Boolean = true;
		var currentWeapon:Weapon = new Weapon();
		var ammo:Ammo = new Ammo();
		var accuracyOffset:Number = 0;
		var cursor:Cursor = new Cursor();
		var reloadTimer:Timer = new Timer(100, RELOAD_SPEED);
		var reloading:Boolean = false;
		
		//Directional booleanss
		var goingDown = false;
		var goingUp = false;
		var goingLeft = false;
		var goingRight = false;
		
		//Dev HUD stuff
		var frames:int = 0;
		var prevTimer:Number = 0;
		var curTimer:Number = 0;
		var curSent, curReceived, prevSent, prevReceived:int;
		
		public function Engine()
		{
			//Obligatory Engine prep
			addChild(mp);
			addChild(cl);
			addChild(gw);
			addChild(gwHUD);
			gwHUD.addChild(cursor);
			cursor.addEventListener(Event.ENTER_FRAME, cursorFrame);
			function cursorFrame(e:Event)
			{
				cursor.x = mouseX - gwHUD.x;
				cursor.y = mouseY - gwHUD.y;
				cursor.setSize(ACCURACY + accuracyOffset);
			}
			
			gw.mapHolder.addChild(map);
			map.alpha = 0;
			gwHUD.playerHUD.indic_Ammo.reloader.visible = false;
			gwHUD.mouseEnabled = false;
			
			gw.x = 312;
			gw.y = 5;
			gwHUD.x = gw.x;
			gwHUD.y = gw.y;
			
			GW_WIDTH = gw.width;
			GW_HEIGHT = gw.height;
			
			//Mask the Game Window
			var gwMask:Shape = new Shape;
			gwMask.graphics.beginFill(0xFF0000);
			gwMask.graphics.drawRect(gw.x, gw.y, 480, 440);
			gwMask.graphics.endFill();
			addChild(gwMask);
			gw.mask = gwMask;
			
			//Show/Hide Mouse
			gw.addEventListener(MouseEvent.MOUSE_OVER, gwMouseOver);
			cl.addEventListener(MouseEvent.MOUSE_OVER, gwMouseOut);
			function gwMouseOver(e:Event)
			{
				cursor.visible = true;
				Mouse.hide();
			}
			function gwMouseOut(e:Event)
			{
				cursor.visible = false;
				Mouse.show();
			}
			
			//Set up Player
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			stage.addEventListener(Event.ACTIVATE, handlerActivate);
			stage.addEventListener(Event.DEACTIVATE, handlerDeactivate);
			addEventListener(Event.ENTER_FRAME, everyFrame);
			gw.addEventListener(MouseEvent.CLICK, anywhereGw);
			gw.addEventListener(MouseEvent.MOUSE_DOWN, anywhereGwDown);
			addEventListener(MouseEvent.MOUSE_UP, anywhereUp);
			gwHUD.addEventListener(MouseEvent.CLICK, anywhereGw);
			cl.addEventListener(MouseEvent.CLICK, anywhereCl);
			
			myTimer.addEventListener(TimerEvent.TIMER, timerListener);
			myTimer.start();
			gwHUD.lSheet.visible = true;
			gwHUD.fSheet.visible = true;
			
			reload();
			swapWeapon("M1911");
			
			holderArray = [gw.UIHolder, gw.mapVisualTop, gw.playerHolder, gw.zombieHolder, gw.staticAniHolder, gw.mapHolder];
		}
		
		public function printAmmo()
		{
			record(ammo.printEasy());
		}
		
		public function printWeapon()
		{
			record("Current weapon: " + currentWeapon.getName());
		}
		
		public function swapWeapon(s:String)
		{
			ammo.addAmmo(CURRENT_CLIP_CONTAINS, currentWeapon.getAmmoType());
			CURRENT_CLIP_CONTAINS = 0;
			
			currentWeapon.swap(s);
			
			//Set Engine stats to the weapon (read: Load the weapon stats)
			ACCURACY = currentWeapon.getAccuracy();
			CLIP_SIZE = currentWeapon.getClipSize();
			FIRE_RATE = currentWeapon.getFireRate();
			AUTO_FIRE = currentWeapon.getAutoFire();
			KICK = currentWeapon.getKick();
			PENETRATE_CHANCE = currentWeapon.getPenetrationChance();
			RELOAD_SPEED = currentWeapon.getReloadTime();
			reloadTimer = new Timer(100, RELOAD_SPEED);
			BULLET_DAMAGE = currentWeapon.getDamage();
			
			printWeapon();
			updatePlayerUI();
			reload();
		}
		
		public function iSay(s:String)
		{
			listOfPlayers[0].say(s);
		}
		
		public function toggleAutoFire()
		{
			if (AUTO_FIRE)
			{
				record("Automatic fire is OFF");
				AUTO_FIRE = false;
			}
			else
			{
				AUTO_FIRE = true;
				record("Automatic fire is ON");
			}
		}
		
		public function setFireRate(n:Number)
		{
			FIRE_RATE = n;
		}
		
		public function setAccuracy(n:Number)
		{
			ACCURACY = n;
		}
		
		public function handlerActivate(e:Event)
		{
			activated = true;
		}
		
		public function handlerDeactivate(e:Event)
		{
			activated = false;
		}
		
		public function addStaticAni(x_In:Number, y_In:Number, r_In:Number, type_In:String)
		{
			var someStaticAni:StaticAni = new StaticAni(type_In);
			gw.staticAniHolder.addChild(someStaticAni);
			someStaticAni.x = x_In;
			someStaticAni.y = y_In;
			someStaticAni.rotation = r_In;
		}
		
		public function disconnectMe()
		{
			gwHUD.lSheet.visible = true;
			gwHUD.lSheet.myText.text = "Disconnected";
			record("Use the command /reconnect to reconnect");
			iAmDisconnected = true;
		}
		
		public function sendForceReconnect()
		{
			mp.sendForceReconnectOrder();
		}
		
		public function forceReconnect(s:String)
		{
			var reconnectTimer:Timer = new Timer(1000, FORCE_RECONNECT_TIMER + 1);
			reconnectTimer.addEventListener(TimerEvent.TIMER, reconnectAuto);
			reconnectTimer.start();
			var counter:int = FORCE_RECONNECT_TIMER;
			record("Reconnect forced by " + s);
			function reconnectAuto(e:TimerEvent)
			{
				if (counter == 0)
				{
					reconnectMe();
				}
				record("Reconnecting in " + counter);
				counter--;
			}
		}
		
		public function reconnectMe()
		{
			var url:String = stage.loaderInfo.url;
			var request:URLRequest = new URLRequest(url);
			navigateToURL(request, "_level0");
		}
		
		public function readyToSendNUQ()
		{
			//Don't even remember what this is but it's an important method
			//loading indicator is invisible here because one day it just started popping up for no reason, not sure why, don't care to find out
			gwHUD.lSheet.visible = false;
			gwHUD.lSheet.myText.text = "Connecting...";
			sendForNUQ = true;
		}
		
		public function timerListener(e:TimerEvent):void
		{
			listOfPlayers[0].incrementTic();
			//gwHUD.myLag.text = "LAG CLOCK: " + listOfPlayers[0].getTic();
			if (listOfPlayers[0].getTic() == 1 && sendForNUQ)
			{
				mp.sendNewUserQuery();
				gwHUD.lSheet.myText.text = "Requesting a peer for game state verification...";
				sendForNUQ = false;
			}
			if (listOfPlayers[0].getTic() == 1 && !sendForNUQ && !loadingCompleteMark)
			{
				loadingComplete();
			}
			
			mp.sendTic();
			checkDisconnects();
		}
		
		public function isNew()
		{
			//var recordStr:String = "Is New? " + listOfPlayers[0].getTic() + " less than 5? " + (listOfPlayers[0].getTic() < 5);
			//record(recordStr);
			return (listOfPlayers[0].getTic() < 5);
		}
		
		public function loadingComplete()
		{
			if (!loadingCompleteMark)
			{
				loadingCompleteMark = true;
				record("Loading complete. Welcome to the game!");
				gwHUD.lSheet.visible = false;
			}
		}
		
		public function checkDisconnects()
		{
			if (!iAmDisconnected && activated)
			{
				for (var i:int = 0; i < listOfPlayers.length; i++)
				{
					var someP = listOfPlayers[i];
					//record("(Of " + listOfPlayers.length + ") " + someP.getTic() + " vs " + listOfPlayers[0].getTic());
					if ((someP.getTic() + DISCONNECT_TIMER) < listOfPlayers[0].getTic())
					{
						if (someP.isConnected())
						{
							mp.sendAliveQuery();
						}
						someP.disconnected();
							//record("" + someP.getName() + " is lagging. " + "<font color='#0099FF'>" + "Their lag clock is now being synced" + "</font>");
							//mp.sendTicSync(listOfPlayers[0].getTic());
					}
					if ((someP.getTic() + REMOVE_TIMER) < listOfPlayers[0].getTic())
					{
						//record("Desynch imminent: " + someP.getTic() + " / " + listOfPlayers[0].getTic());
						mp.sendDisconnectOrder("Desynched", someP.getID());
						listOfPlayers.splice(i, 1);
						someP.getPHUI().removeMe();
						record("<font color='#993399'>" + someP.getName() + " has disconnected" + "</font>");
						someP.removeMe();
						mp.decrementPlayers();
						garbageCollectElementArray();
					}
				}
			}
		}
		
		public function garbageCollectElementArray()
		{
			for (var i:int; i < elementArray.length; i++)
			{
				if (elementArray[i][0] == "Player")
				{
					//Player
					if (!elementArray[i][1].isConnected())
					{
						elementArray.splice(i, 1);
					}
				}
				if (elementArray[i][0] == "Zombie")
				{
					//Zombie
					if (elementArray[i][1].isDead())
					{
						elementArray.splice(i, 1);
					}
				}
			}
		}
		
		public function anywhereGw(e:Event)
		{
			if (!cl.isFocused() && listOfPlayers[0].isAlive() && !iAmDisconnected && !AUTO_FIRE)
			{
				//Shoot				
				if (canShoot())
				{
					shootCD = 0;
					var penetrates:Boolean = PENETRATE_CHANCE >= (Math.floor(Math.random() * 100));
					var tAccuracy:Number = (Math.floor(Math.random() * (ACCURACY + accuracyOffset)) - ((ACCURACY + accuracyOffset) / 2));
					
					if (accuracyOffset < ACCURACY_OFFSET_MAX)
					{
						accuracyOffset += KICK;
					}
					
					var b:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + tAccuracy, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE);
					mp.sendBullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE);
					gw.playerHolder.addChild(b);
					createMuzzleFlash(listOfPlayers[0].x, listOfPlayers[0].y, b.rotation);
				}
			}
			cl.unfocusMe();
		}
		
		public function anywhereGwDown(e:Event)
		{
			if (!cl.isFocused() && listOfPlayers[0].isAlive() && !iAmDisconnected && AUTO_FIRE)
			{
				addEventListener(Event.ENTER_FRAME, shootAutomatically);
			}
			cl.unfocusMe();
		}
		
		function shootAutomatically(e:Event)
		{
			//Shoot
			if (canShoot())
			{
				shootCD = 0;
				var penetrates:Boolean = PENETRATE_CHANCE >= (Math.floor(Math.random() * 100));
				var tAccuracy:Number = (Math.floor(Math.random() * (ACCURACY + accuracyOffset)) - ((ACCURACY + accuracyOffset) / 2));
				
				if (accuracyOffset < ACCURACY_OFFSET_MAX)
				{
					accuracyOffset += KICK;
				}
				
				var b:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + tAccuracy, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE);
				mp.sendBullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE);
				gw.playerHolder.addChild(b);
				createMuzzleFlash(listOfPlayers[0].x, listOfPlayers[0].y, b.rotation);
			}
		}
		
		public function anywhereUp(e:Event)
		{
			removeEventListener(Event.ENTER_FRAME, shootAutomatically);
		}
		
		public function canShoot()
		{
			if (reloading)
			{
				return false;
			}
			if (CURRENT_CLIP_CONTAINS == 0)
			{
				return false;
			}
			else if (shootCD >= FIRE_RATE)
			{
				CURRENT_CLIP_CONTAINS--;
				updatePlayerUI();
				return true;
			}
		}
		
		public function setTic(n:Number)
		{
			syncTics(n);
		}
		
		public function syncTics(n:Number)
		{
			record("Syncing tics...");
			for each (var someP in listOfPlayers)
			{
				someP.setInitTic(n);
				someP.reconnected();
			}
		}
		
		public function anywhereCl(e:Event)
		{
			cl.focusMe();
		}
		
		public function getAllPlayers()
		{
			return listOfPlayers;
		}
		
		public function newUserUpdate()
		{
			//Send the new user necessary data about the game state
			record("<font color='#0099FF'>" + "You are now providing the new user with data" + "</font>");
			changeMyName(listOfPlayers[0].getName());
			mp.sendTotalTic(listOfPlayers[0].getTic());
			
			//Send Elements
			var totalElements:int = elementArray.length;
			for (var i:int = 0; i < elementArray.length; i++)
			{
				var someE = elementArray[i];
				//record("Sending an element of type " + someE[0] + " (" + (i + 1) + " of " + totalElements + ")");
				mp.sendElement(someE[0], someE[1].getInfoArray());
			}
			mp.sendLoadingComplete();
		}
		
		public function changeMyName(s:String)
		{
			listOfPlayers[0].setName(s);
			mp.sendNameChange(s);
		}
		
		public function setNick(s:String)
		{
			cl.setNick(s);
		}
		
		public function isPlayerID(ID_In:String)
		{
			return mp.getMyID() == ID_In;
		}
		
		public function keyDown(e:KeyboardEvent)
		{
			if (e.charCode == 119)
			{
				goingUp = true;
				goingDown = false;
			}
			else if (e.charCode == 97)
			{
				goingLeft = true;
				goingRight = false;
			}
			else if (e.charCode == 115)
			{
				goingDown = true;
				goingUp = false;
			}
			else if (e.charCode == 100)
			{
				goingRight = true;
				goingLeft = false;
			}
			else if (e.charCode == 114)
			{
				reload();
			}
		}
		
		public function reload()
		{
			if (!reloading && CURRENT_CLIP_CONTAINS < CLIP_SIZE && ammo.getAmmo(currentWeapon.getAmmoType()) > 0)
			{
				gwHUD.playerHUD.indic_Ammo.reloader.visible = true;
				reloading = true;
				reloadTimer.reset();
				reloadTimer.start();
				reloadTimer.addEventListener(TimerEvent.TIMER_COMPLETE, reloadComplete);
				function reloadComplete(e:Event)
				{
					gwHUD.playerHUD.indic_Ammo.reloader.visible = false;
					reloading = false;
					CURRENT_CLIP_CONTAINS += ammo.takeAmmo(currentWeapon.getAmmoType(), (CLIP_SIZE - CURRENT_CLIP_CONTAINS));
					
					//Reset the accuracy offset
					accuracyOffset = 0;
					
					//Update the PlayerUI
					updatePlayerUI();
					reloadTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, reloadComplete);
				}
			}
		}
		
		public function updatePlayerUI()
		{
			var s:String = "<font color='#FFFFFF'>";
			if (CURRENT_CLIP_CONTAINS == 0)
			{
				s = "<font color='#FF0000'>";
			}
			gwHUD.playerHUD.indic_Ammo.currentAmmo.htmlText = s + CURRENT_CLIP_CONTAINS + "</font>";
			gwHUD.playerHUD.indic_Ammo.extraAmmo.text = ammo.getAmmo(currentWeapon.getAmmoType());
			gwHUD.playerHUD.indic_Ammo.indic_Gun.text = currentWeapon.getName();
		}
		
		public function printAllWeapons()
		{
			record(currentWeapon.easyPrint());
		}
		
		public function keyUp(e:KeyboardEvent)
		{
			if (e.charCode == 119)
			{
				goingUp = false;
			}
			else if (e.charCode == 97)
			{
				goingLeft = false;
			}
			else if (e.charCode == 115)
			{
				goingDown = false;
			}
			else if (e.charCode == 100)
			{
				goingRight = false;
			}
		}
		
		public function getCamOffsets()
		{
			return [holderArray[0].x, holderArray[0].y];
		}
		
		public function everyFrame(e:Event)
		{
			if (!cl.isFocused() && listOfPlayers[0].isAlive() && !iAmDisconnected)
			{
				moveMe();
				updateRotation();
			}
			
			//Increment ShootCD
			shootCD += 1;
			
			cl.updateCurrentConnections(mp.getCurrentConnections());
			
			//Update Memory
			gwHUD.myMemory.text = "MEMORY: " + int(System.totalMemory / 1024) + " KB";
			//Update FPS
			frames += 1;
			curTimer = getTimer();
			curSent = int(mp.getSentObjectCounter());
			curReceived = int(mp.getReceivedObjectCounter());
			if (curTimer - prevTimer >= 1000)
			{
				//Update Every second
				gwHUD.myFPS.text = "FPS: " + (Math.round(frames * 1000 / (curTimer - prevTimer)));
				prevTimer = curTimer;
				frames = 0;
				
				//Update SentCounter
				var sentObjs:int = curSent - prevSent;
				//Update ReceivedCounter
				var receivedObjs:int = curReceived - prevReceived;
				//Update Counter
				gwHUD.mySentAndReceived.text = "NETWORK: " + sentObjs + ", " + receivedObjs;
				
				//Save stats for the next second
				prevSent = int(mp.getSentObjectCounter());
				prevReceived = int(mp.getReceivedObjectCounter());
			}
		}
		
		public function syncGW(x_In:Number, y_In:Number)
		{
			//Loop through Holders and snap them all to the X and Y coordinates
			gw.x -= x_In;
			gw.y -= y_In;
		}
		
		public function getMap()
		{
			return map;
		}
		
		public function moveMe()
		{
			var speedX:Number = 0;
			var speedY:Number = 0;
			
			if (goingUp)
			{
				speedY -= MOVEMENT_SPEED;
			}
			if (goingLeft)
			{
				speedX -= MOVEMENT_SPEED;
			}
			if (goingDown)
			{
				speedY += MOVEMENT_SPEED;
			}
			if (goingRight)
			{
				speedX += MOVEMENT_SPEED;
			}
			
			var xHitSpace:Number = listOfPlayers[0].getHitSize();
			var yHitSpace:Number = listOfPlayers[0].getHitSize();
			var goingX:Boolean = false;
			var goingY:Boolean = false;
			
			if (speedX < 0)
			{
				xHitSpace *= -1;
			}
			if (speedY < 0)
			{
				yHitSpace *= -1;
			}
			
			//xHitSpace += getCamOffsets()[0];
			//yHitSpace += getCamOffsets()[1];
			xHitSpace += holderArray[0].x;
			yHitSpace += holderArray[0].y;
			
			if (!map.hitTestPoint(listOfPlayers[0].x + gw.x + xHitSpace + speedX, listOfPlayers[0].y + gw.y - yHitSpace, true))
			{
				goingX = true;
			}
			
			if (!map.hitTestPoint(listOfPlayers[0].x + gw.x - xHitSpace, listOfPlayers[0].y + gw.y + yHitSpace + speedY, true))
			{
				goingY = true;
			}
			
			if (goingX && goingY)
			{
				if (!map.hitTestPoint(listOfPlayers[0].x + gw.x + xHitSpace + speedX, listOfPlayers[0].y + gw.y + yHitSpace + speedY, true))
				{
					listOfPlayers[0].x += speedX;
					listOfPlayers[0].y += speedY;
					syncGW(speedX, speedY);
				}
			}
			else if (goingX)
			{
				listOfPlayers[0].x += speedX;
				syncGW(speedX, 0);
			}
			else if (goingY)
			{
				listOfPlayers[0].y += speedY;
				syncGW(0, speedY);
			}
			
			//Change the accuracy modifier if moving
			if (speedX != 0 || speedY != 0)
			{
				if (accuracyOffset < ACCURACY_OFFSET_MAX)
				{
					accuracyOffset += ACCURACY_CHANGE_RUN;
				}
			}
			else
			{
				if (accuracyOffset > 0)
				{
					accuracyOffset -= ACCURACY_CHANGE_STOP;
				}
				else
				{
					accuracyOffset = 0;
				}
			}
			
			mp.sendCharacterInfo(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation);
		}
		
		public function updateRotation()
		{
			var dist_Y:Number = mouseY - listOfPlayers[0].y - gw.y - getCamOffsets()[1];
			var dist_X:Number = mouseX - listOfPlayers[0].x - gw.x - getCamOffsets()[0];
			var angle:Number = Math.atan2(dist_Y, dist_X);
			var degrees:Number = angle * 180 / Math.PI;
			listOfPlayers[0].rotation = degrees + 90;
		}
		
		public function getAllElements()
		{
			return elementArray;
		}
		
		public function createPlayer(player_In:Player)
		{
			listOfPlayers.push(player_In);
			elementArray.push(["Player", player_In]);
			var generated_playerHUI:PlayerHUI = new PlayerHUI();
			generated_playerHUI.addEventListener(Event.ENTER_FRAME, playerHUIFollowsPlayer);
			function playerHUIFollowsPlayer(e:Event)
			{
				player_In.addPHUI(generated_playerHUI);
				generated_playerHUI.x = player_In.x;
				generated_playerHUI.y = player_In.y;
				generated_playerHUI.setText(mp.getNameFromID(player_In.getID()));
			}
			gw.playerHolder.addChild(player_In);
			gw.UIHolder.addChild(generated_playerHUI);
			player_In.x = (map.width / 2) - (player_In.width / 2);
			player_In.y = (map.height / 2) - (player_In.height / 2);
			
			player_In.setInitTic(listOfPlayers[0].getTic());
			
			record("Player added to Game Window");
			cl.updateCurrentConnections(mp.getCurrentConnections());
		}
		
		public function createZombieFromMe()
		{
			if (elementArray.length < MAX_ELEMENTS)
			{
				var startX:Number = listOfPlayers[0].x;
				var startY:Number = listOfPlayers[0].y;
				var startR:Number = (Math.floor(Math.random() * 180));
				
				startX += (Math.cos(startR) * PLACE_DISTANCE);
				startY += (Math.sin(startR) * PLACE_DISTANCE);
				
				mp.sendElement("Zombie", [startX, startY, startR, ZOMBIE_HEALTH]);
				createZombie(startX, startY, startR, ZOMBIE_HEALTH);
			}
			else
			{
				record("There are too many elements (Max: " + MAX_ELEMENTS + ")");
			}
		}
		
		public function createZombie(x_In:Number, y_In:Number, r_In:Number, zHP_In:int)
		{
			//Add a zombie to the stage
			var z:Zombie = new Zombie(x_In, y_In, r_In, zHP_In);
			elementArray.push(["Zombie", z]);
			gw.zombieHolder.addChild(z);
			z.checkForDeath();
		}
		
		public function createBullet(x_In:Number, y_In:Number, r_In:Number, immune_In:String, pen_In:Boolean, damage_In:Number)
		{
			//Shoot
			var b:Bullet = new Bullet(x_In, y_In, r_In, immune_In, pen_In, damage_In);
			gw.playerHolder.addChild(b);
			createMuzzleFlash(x_In, y_In, r_In);
		}
		
		public function createMuzzleFlash(x_In:Number, y_In:Number, r_In:Number)
		{
			var muzzleFlash:StaticAni = new StaticAni("MuzzleFlash");
			gw.staticAniHolder.addChild(muzzleFlash);
			muzzleFlash.x = x_In;
			muzzleFlash.y = y_In;
			muzzleFlash.rotation = r_In;
		}
		
		public function createBulletHole(x_In:Number, y_In:Number, r_In:Number)
		{
			var bulletHole:StaticAni = new StaticAni("BulletHole");
			gw.staticAniHolder.addChild(bulletHole);
			bulletHole.x = x_In;
			bulletHole.y = y_In;
			bulletHole.rotation = r_In;
		}
		
		public function getGWOffsets()
		{
			return [gw.x, gw.y];
		}
		
		public function getName()
		{
			return mp.getName();
		}
		
		public function sendStr(s:String)
		{
			mp.sendStr(s);
		}
		
		public function record(s:String)
		{
			cl.record(s);
		}
	}
}