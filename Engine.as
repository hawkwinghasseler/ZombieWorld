package
{
	import flash.display.*;
	import flash.events.*;
	import flash.globalization.NumberFormatter;
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
		var KNOCK_CHANCE:Number = 0;
		var AUTO_FIRE:Boolean = true;
		var ACCURACY:Number = 5;
		var KNOCK_DISTANCE:Number = 12;
		var ACCURACY_CHANGE_RUN:Number = .5;
		var ACCURACY_CHANGE_STOP:Number = .75;
		var ACCURACY_OFFSET_MAX:Number = 30;
		var KICK:Number = 12;
		var CLIP_SIZE:Number = 10;
		var CURRENT_CLIP_CONTAINS:Number = 0;
		var RELOAD_SPEED:Number = 10;
		var BULLET_DAMAGE:Number = 1;
		var PLAYER_HEALTH:Number = 100;
		var INVENTORY_CATEGORY:String = "Weapons";
		var PICKUP_RANGE:Number = 50;
		var LIST_OF_SPREAD_WEAPONS:Array = ["Shotgun"];
		var torch_power:int = 500;
		var torch_step:int = 100;
		
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
		var inventory:Inventory = new Inventory();
		var pickingUp:Boolean = false;
		var light:Sprite = new Sprite();
		var torch_angle:int = 100;
		var torch_angle_step:int = 90;
		
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
			addChild(inventory);
			gw.lightHolder.addChild(light);
			gwHUD.addChild(cursor);
			cursor.mouseEnabled = false;
			cursor.mouseChildren = false;
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
			cursor.gotoAndStop("Target");
			
			//Show/Hide Mouse
			gwHUD.playerHUD.mouseField.addEventListener(MouseEvent.MOUSE_OVER, gwMouseOver);
			gwHUD.playerHUD.mouseField.addEventListener(MouseEvent.MOUSE_OUT, gwMouseOut);
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
			
			//Set up Inventory Window
			hideInventory();
			gwHUD.playerHUD.btnInventory.addEventListener(MouseEvent.CLICK, btnInvClick);
			gwHUD.playerHUD.inventory.btnClose.addEventListener(MouseEvent.CLICK, btnInvClose);
			gwHUD.playerHUD.btnInventory.gotoAndStop("Inventory");
			
			//Set up Chat Window
			hideChat();
			gwHUD.playerHUD.btnChat.addEventListener(MouseEvent.CLICK, btnChatClick);
			gwHUD.playerHUD.chat.btnClose.addEventListener(MouseEvent.CLICK, btnChatclose);
			gwHUD.playerHUD.btnChat.gotoAndStop("Chat");
			
			//Set up Player
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			stage.addEventListener(Event.ACTIVATE, handlerActivate);
			stage.addEventListener(Event.DEACTIVATE, handlerDeactivate);
			addEventListener(Event.ENTER_FRAME, everyFrame);
			gw.addEventListener(MouseEvent.CLICK, anywhereGw);
			gwHUD.playerHUD.mouseField.addEventListener(MouseEvent.MOUSE_DOWN, anywhereGwDown);
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
		
		public function updateVisualInventory(a:Array)
		{
			gwHUD.playerHUD.inventory.itemText.htmlText = "";
			for each (var e in a)
			{
				gwHUD.playerHUD.inventory.itemText.htmlText += e.getName() + " (" + e.getQuantity() + ")\n";
			}
		}
		
		public function chatlogRecord(s:String)
		{
			gwHUD.playerHUD.chat.myText.htmlText += s;
			gwHUD.playerHUD.chat.myText.scrollV = gwHUD.playerHUD.chat.myText.maxScrollV;
			gwHUD.playerHUD.chat.scroller.update();
		}
		
		public function btnInvClick(e:Event)
		{
			if (gwHUD.playerHUD.inventory.visible)
			{
				hideInventory();
			}
			else
			{
				showInventory();
			}
		}
		
		public function btnChatClick(e:Event)
		{
			if (gwHUD.playerHUD.chat.visible)
			{
				hideChat();
			}
			else
			{
				showChat();
			}
		}
		
		public function btnInvClose(e:Event)
		{
			hideInventory();
		}
		
		public function btnChatclose(e:Event)
		{
			hideChat();
		}
		
		public function iAmReady()
		{
			//listOfPlayers[0].setMaxHealth(PLAYER_HEALTH);
			setHealthTotal(PLAYER_HEALTH);
			updateHealthBar(PLAYER_HEALTH);
			inventory.consolidateInventory();
			
			//Snap Character to a spawn point
			listOfPlayers[0].x = gw.mapVisualTop.spawn.x;
			listOfPlayers[0].y = gw.mapVisualTop.spawn.y;
			
			syncGW();
		}
		
		public function showInventory()
		{
			gwHUD.playerHUD.btnInventory.clickField.gotoAndStop("Pressed");
			gwHUD.playerHUD.inventory.visible = true;
			hideChat();
		}
		
		public function hideInventory()
		{
			gwHUD.playerHUD.btnInventory.clickField.gotoAndStop("Unpressed");
			gwHUD.playerHUD.inventory.visible = false;
		}
		
		public function showChat()
		{
			gwHUD.playerHUD.btnChat.clickField.gotoAndStop("Pressed");
			gwHUD.playerHUD.chat.visible = true;
			hideInventory();
		}
		
		public function hideChat()
		{
			gwHUD.playerHUD.btnChat.clickField.gotoAndStop("Unpressed");
			gwHUD.playerHUD.chat.visible = false;
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
			if (CURRENT_CLIP_CONTAINS > 0)
			{
				ammo.addAmmo(CURRENT_CLIP_CONTAINS, currentWeapon.getAmmoType());
				inventory.add(new InvItem("Ammo", currentWeapon.getAmmoType(), 0, 100, CURRENT_CLIP_CONTAINS));
			}
			CURRENT_CLIP_CONTAINS = 0;
			
			currentWeapon.swap(s);
			
			//Set Engine stats to the weapon (read: Load the weapon stats)
			ACCURACY = currentWeapon.getAccuracy();
			CLIP_SIZE = currentWeapon.getClipSize();
			FIRE_RATE = currentWeapon.getFireRate();
			AUTO_FIRE = currentWeapon.getAutoFire();
			KICK = currentWeapon.getKick();
			PENETRATE_CHANCE = currentWeapon.getPenetrationChance();
			KNOCK_CHANCE = currentWeapon.getKnockChance();
			RELOAD_SPEED = currentWeapon.getReloadTime();
			reloadTimer = new Timer(100, RELOAD_SPEED);
			BULLET_DAMAGE = currentWeapon.getDamage();
			
			//printWeapon();
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
			//record("Garbage Collecting Element Array\nBefore: [" + elementArray + "]");
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
				if (elementArray[i][0] == "Pickup")
				{
					//Pickup
					if (elementArray[i][1].isPickedUp())
					{
						elementArray[i][1].removeMe();
						elementArray.splice(i, 1);
					}
				}
			}
			//record("After: [" + elementArray + "]");
		}
		
		public function anywhereGw(e:Event)
		{
			if (pickingUp)
			{
				var pickedUp:Boolean = false;
				for each (var p in getPickupsNearMe())
				{
					if (p[1].hitTestPoint(mouseX, mouseY))
					{
						if (!pickedUp)
						{
							pickedUp = true;
							mp.sendRemoveElement(p[1].getGID());
							//trace("-----------------------\nINVE Adding type " + p[1].getItem().getName());
							inventory.add(p[1].getItem());
							if (p[1].getItem().getCategory() == "Ammo")
							{
								//trace("AMMO Adding type " + p[1].getItem().getName());
								ammo.addAmmo(p[1].getItem().getQuantity(), p[1].getItem().getName());
							}
							p[1].pickUp();
							garbageCollectElementArray();
							updatePlayerUI();
						}
					}
				}
			}
			else if (!cl.isFocused() && listOfPlayers[0].isAlive() && !iAmDisconnected && !AUTO_FIRE)
			{
				//Shoot				
				if (canShoot())
				{
					shootCD = 0;
					var penetrates:Boolean = PENETRATE_CHANCE >= (Math.floor(Math.random() * 100));
					var knock:Number = 0;
					var tAccuracy:Number = (Math.floor(Math.random() * (ACCURACY + accuracyOffset)) - ((ACCURACY + accuracyOffset) / 2));
					if (KNOCK_CHANCE >= (Math.floor(Math.random() * 100)))
					{
						knock = KNOCK_DISTANCE;
					}
					
					if (accuracyOffset < ACCURACY_OFFSET_MAX)
					{
						accuracyOffset += KICK;
					}
					
					var spread:Boolean = false;
					for each (var someName in LIST_OF_SPREAD_WEAPONS)
					{
						if (currentWeapon.getName() == someName)
						{
							spread = true;
						}
					}
					
					if (spread)
					{
						//Add extra bullets
						var b1:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + (tAccuracy * -2), listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
						var b2:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + (tAccuracy * .2), listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
						var b3:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + (tAccuracy * -.2), listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
						var b4:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + (tAccuracy * .6), listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
						var b5:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + (tAccuracy * -.6), listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
						var bArr:Array = [b1, b2, b3, b4, b5];
						for each (var tBullet in bArr)
						{
							gw.playerHolder.addChild(tBullet);
							mp.sendBullet(listOfPlayers[0].x, listOfPlayers[0].y, tBullet.rotation, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
						}
					}
					var b:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + tAccuracy, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
					mp.sendBullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + tAccuracy, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
					gw.playerHolder.addChild(b);
					createMuzzleFlash(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation);
				}
			}
			cl.unfocusMe();
		}
		
		public function getPickupsNearMe()
		{
			var a:Array = new Array();
			for each (var p in elementArray)
			{
				if (p[0] == "Pickup")
				{
					var xCalc:Number = (listOfPlayers[0].x - p[1].x) * (listOfPlayers[0].x - p[1].x);
					var yCalc:Number = (listOfPlayers[0].y - p[1].y) * (listOfPlayers[0].y - p[1].y);
					var dist:Number = Math.sqrt(xCalc + yCalc);
					//trace("Distance from player: " + dist);
					if (dist < PICKUP_RANGE)
					{
						a.push(p);
					}
				}
			}
			return a;
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
				var knock:Number = 0;
				var tAccuracy:Number = (Math.floor(Math.random() * (ACCURACY + accuracyOffset)) - ((ACCURACY + accuracyOffset) / 2));
				if (KNOCK_CHANCE >= (Math.floor(Math.random() * 100)))
				{
					knock = 5;
				}
				
				if (accuracyOffset < ACCURACY_OFFSET_MAX)
				{
					accuracyOffset += KICK;
				}
				
				var b:Bullet = new Bullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation + tAccuracy, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
				mp.sendBullet(listOfPlayers[0].x, listOfPlayers[0].y, listOfPlayers[0].rotation, listOfPlayers[0].getID(), penetrates, BULLET_DAMAGE, knock);
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
			if (cursor.visible && !pickingUp)
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
			else if (e.charCode == 32)
			{
				pickingUp = true;
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
					var toTake:int = ammo.takeAmmo(currentWeapon.getAmmoType(), (CLIP_SIZE - CURRENT_CLIP_CONTAINS));
					CURRENT_CLIP_CONTAINS += toTake;
					inventory.remove(new InvItem("Ammo", currentWeapon.getAmmoType(), 0, 100, toTake));
					
					//Update the PlayerUI
					updatePlayerUI();
					reloadTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, reloadComplete);
				}
			}
		}
		
		public function updateHealthBar(n:Number)
		{
			gwHUD.playerHUD.indic_Health.myBar.update(n);
			gwHUD.playerHUD.indic_Health.myText.text = n;
		}
		
		public function setHealthTotal(n:Number)
		{
			gwHUD.playerHUD.indic_Health.myBar.setTotal(n);
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
		
		public function printInventory()
		{
			inventory.printItems();
		}
		
		public function updateInventory()
		{
			switch (INVENTORY_CATEGORY)
			{
				case "Weapons": 
					gwHUD.playerHUD.inventory.itemText.text = inventory.getItemsByCategory("Weapons")[0];
					gwHUD.playerHUD.inventory.weightText.text = inventory.getItemsByCategory("Weapons")[1];
					gwHUD.playerHUD.inventory.valueText.text = inventory.getItemsByCategory("Weapons")[2];
					break;
				case "Ammo": 
					gwHUD.playerHUD.inventory.itemText.text = inventory.getItemsByCategory("Ammo")[0];
					gwHUD.playerHUD.inventory.weightText.text = inventory.getItemsByCategory("Ammo")[1];
					gwHUD.playerHUD.inventory.valueText.text = inventory.getItemsByCategory("Ammo")[2];
					break;
				case "Clothing": 
					break;
				case "Aid": 
					break;
			}
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
			else if (e.charCode == 32)
			{
				pickingUp = false;
			}
		}
		
		public function getCamOffsets()
		{
			return [holderArray[0].x, holderArray[0].y];
		}
		
		public function everyFrame(e:Event)
		{
			if (pickingUp)
			{
				cursor.pickingOn();
			}
			else
			{
				cursor.pickingOff();
			}
			if (!cl.isFocused() && listOfPlayers[0].isAlive() && !iAmDisconnected)
			{
				moveMe();
				updateRotation();
			}
			
			//Increment ShootCD
			shootCD += 1;
			
			cl.updateCurrentConnections(mp.getCurrentConnections());
			
			//Update Memory
			//gwHUD.myMemory.text = "MEMORY: " + int(System.totalMemory / 1024) + " KB";
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
				//gwHUD.mySentAndReceived.text = "NETWORK: " + sentObjs + ", " + receivedObjs;
				gwHUD.mySentAndReceived.text = "";
				gwHUD.myMemory.text = "";
				
				//Save stats for the next second
				prevSent = int(mp.getSentObjectCounter());
				prevReceived = int(mp.getReceivedObjectCounter());
			}
		}
		
		/*public function syncGW(x_In:Number, y_In:Number)
		   {
		   //Snap GW X and Y coordinates to new positions (actually just change them!)
		   gw.x -= x_In;
		   gw.y -= y_In;
		 }*/
		
		public function syncGW()
		{
			gw.x = int(gwHUD.x - (listOfPlayers[0].x - (gwHUD.fSheet.width / 2)));
			gw.y = int(gwHUD.y - (listOfPlayers[0].y - (gwHUD.fSheet.height / 2)));
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
				listOfPlayers[0].y -= MOVEMENT_SPEED;
				speedY = MOVEMENT_SPEED;
			}
			if (goingLeft)
			{
				listOfPlayers[0].x -= MOVEMENT_SPEED;
				speedX = -MOVEMENT_SPEED;
			}
			if (goingDown)
			{
				listOfPlayers[0].y += MOVEMENT_SPEED;
				speedY = -MOVEMENT_SPEED;
			}
			if (goingRight)
			{
				listOfPlayers[0].x += MOVEMENT_SPEED;
				speedX = MOVEMENT_SPEED;
			}
			
			var radius:Number = listOfPlayers[0].getHitSize();
			
			while (map.hitTestPoint(listOfPlayers[0].x + gw.x, listOfPlayers[0].y + gw.y + radius, true))
			{
				listOfPlayers[0].y--;
			}
			while (map.hitTestPoint(listOfPlayers[0].x + gw.x, listOfPlayers[0].y + gw.y - radius, true))
			{
				listOfPlayers[0].y++;
			}
			while (map.hitTestPoint(listOfPlayers[0].x + gw.x - radius, listOfPlayers[0].y + gw.y, true))
			{
				listOfPlayers[0].x++;
			}
			while (map.hitTestPoint(listOfPlayers[0].x + gw.x + radius, listOfPlayers[0].y + gw.y, true))
			{
				listOfPlayers[0].x--;
			}
			
			syncGW();
			
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
			
			//Flashlight
			light.graphics.clear();
			light.graphics.beginFill(0xffffff, 100);
			light.graphics.moveTo(listOfPlayers[0].x, listOfPlayers[0].y);
			for (var i:int = 0; i <= torch_angle; i += (torch_angle / torch_angle_step))
			{
				var ray_angle = to_radians(((listOfPlayers[0].rotation) - 90 - (torch_angle / 2) + i));
				for (var j:int = 1; j <= torch_step; j++)
				{
					if (map.hitTestPoint((listOfPlayers[0].x + (torch_power / torch_step * j) * Math.cos(ray_angle)) + gw.x, (listOfPlayers[0].y + (torch_power / torch_step * j) * Math.sin(ray_angle)) + gw.y, true))
					{
						break;
					}
				}
				light.graphics.lineTo(listOfPlayers[0].x + (torch_power / torch_step * j) * Math.cos(ray_angle), listOfPlayers[0].y + (torch_power / torch_step * j) * Math.sin(ray_angle));
			}
			light.graphics.lineTo(listOfPlayers[0].x, listOfPlayers[0].y);
			light.graphics.endFill();
			
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
		
		public function removeElementByID(id:Number)
		{
			for (var i = 0; i < elementArray.length; i++)
			{
				if (elementArray[i][0] == "Pickup")
				{
					if (elementArray[i][1].getGID() == id)
					{
						elementArray[i][1].pickUp();
						garbageCollectElementArray();
					}
				}
			}
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
		
		public function createPickupFromMe()
		{
			if (elementArray.length >= MAX_ELEMENTS)
			{
				garbageCollectElementArray();
			}
			if (elementArray.length < MAX_ELEMENTS)
			{
				var startX:Number = listOfPlayers[0].x;
				var startY:Number = listOfPlayers[0].y;
				var startR:Number = (Math.floor(Math.random() * 180));
				
				//Eventually there will have to be different inputs for what's created, but for now this will do
				var itemChoose:Number = (Math.floor(Math.random() * 3));
				var item1:InvItem = new InvItem("Ammo", ".45 Auto", .5, 100, 20);
				var item2:InvItem = new InvItem("Ammo", "12 Gauge Shell", .5, 100, 20);
				var item3:InvItem = new InvItem("Ammo", ".357", .5, 100, 20);
				var tArr:Array = [item1, item2, item3];
				var itemIn:InvItem = tArr[itemChoose];
				var tGID = (Math.floor(Math.random() * 999999999999999999));
				
				startX += (Math.cos(startR) * PLACE_DISTANCE);
				startY += (Math.sin(startR) * PLACE_DISTANCE);
				
				createPickup(startX, startY, startR, itemIn, tGID);
				mp.sendElement("Pickup", [startX, startY, startR, [itemIn.getCategory(), itemIn.getName(), itemIn.getWeight(), itemIn.getCondition(), itemIn.getQuantity()], tGID]);
			}
			else
			{
				record("There are too many elements (Max: " + MAX_ELEMENTS + ")");
			}
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
		
		public function createPickup(x_In:Number, y_In:Number, r_In:Number, item_In:InvItem, GID_In:Number)
		{
			//Add a pickup to the stage
			var p:Pickup = new Pickup(item_In);
			p.setGID(GID_In);
			p.x = x_In;
			p.y = y_In;
			p.rotation = r_In;
			elementArray.push(["Pickup", p]);
			gw.pickupHolder.addChild(p);
			trace("Added Pickup: " + p.getGID());
			return p;
		}
		
		public function createZombie(x_In:Number, y_In:Number, r_In:Number, zHP_In:int)
		{
			//Add a zombie to the stage
			var z:Zombie = new Zombie(x_In, y_In, r_In, zHP_In);
			elementArray.push(["Zombie", z]);
			gw.zombieHolder.addChild(z);
			z.checkForDeath();
		}
		
		public function createBullet(x_In:Number, y_In:Number, r_In:Number, immune_In:String, pen_In:Boolean, damage_In:Number, knock_In:Number)
		{
			//Shoot
			var b:Bullet = new Bullet(x_In, y_In, r_In, immune_In, pen_In, damage_In, knock_In);
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
		
		public function createBulletBlood(x_In:Number, y_In:Number, r_In:Number)
		{
			var bulletBlood:StaticAni = new StaticAni("BulletBlood");
			gw.staticAniHolder.addChild(bulletBlood);
			bulletBlood.x = x_In;
			bulletBlood.y = y_In;
			bulletBlood.rotation = r_In;
		}
		
		public function getGWOffsets()
		{
			return [gw.x, gw.y];
		}
		
		public function getName()
		{
			return mp.getName();
		}
		
		public function to_radians(n:Number)
		{
			return (n * 0.0174532925);
		}
		
		public function to_degrees(n:Number)
		{
			return (n * 57.2957795);
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