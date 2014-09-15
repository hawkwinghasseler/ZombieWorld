package
{
	import flash.events.*;
	import flash.display.*;
	
	public class Console extends MovieClip
	{
		//Init Constants
		var HELP_MESSAGE:String = "Some notable commands include\n/nick (changes your name)\n/reconnect (resets your connection)\n/add-zombie (he won't hurt a fly, honest!)";
		var NICK:String = "";
		
		//Init Variables
		var recordArray = new Array();
		var focused = true;
		
		public function Console()
		{
			myInput.text = "";
			myInput.restrict = "^`";
			myHistory.htmlText = "";
			addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		}
		
		public function isFocused()
		{
			return focused;
		}
		
		public function focusMe()
		{
			focused = true;
			(parent as MovieClip).gwHUD.fSheet.visible = true;
		}
		
		public function unfocusMe()
		{
			focused = false;
			(parent as MovieClip).gwHUD.fSheet.visible = false;
			stage.focus = null;
		}
		
		public function setNick(nick_In:String)
		{
			NICK = nick_In;
			(parent as MovieClip).changeMyName(nick_In);
		}
		
		public function keyHandler(event:KeyboardEvent)
		{
			//Triggered when the user presses ENTER within the Console
			if (event.charCode == 13)
			{
				var s:String = myInput.text;
				s = s.replace(/^\s+|\s+$/g, '');
				if (s.length > 0)
				{
					record("<font color='#339900'>" + NICK + ": " + myInput.text + "</font>");
					processCommand(myInput.text);
				}
				myInput.text = "";
			}
		}
		
		public function processCommand(s:String)
		{
			var command:String = s;
			var entry:String = "";
			if (s.indexOf("/") == 0)
			{
				entry = s.substring(command.indexOf(" ") + 1);
				if (s.indexOf(" ") >= 0)
				{
					command = s.substring(0, command.indexOf(" "));
				}
				switch (command.toLowerCase())
				{
					case "/help": 
						record(HELP_MESSAGE);
						break;
					case "/reconnect": 
						(parent as MovieClip).reconnectMe();
						break;
					case "/reconnect-all": 
						(parent as MovieClip).sendForceReconnect();
						break;
					case "/add-zombie": 
						(parent as MovieClip).createZombieFromMe();
						break;
					case "/add-pickup":
						(parent as MovieClip).createPickupFromMe();
						break;
					case "/toggle-autofire": 
						(parent as MovieClip).toggleAutoFire();
						break;
					case "/set-firerate": 
						(parent as MovieClip).setFireRate(int(entry));
						record("Fire rate set to " + int(entry));
						break;
					case "/set-accuracy": 
						(parent as MovieClip).setAccuracy(int(entry));
						record("Accuracy set to " + int(entry));
						break;
					case "/print-weapon": 
						(parent as MovieClip).printWeapon();
						break;
					case "/print-ammo": 
						(parent as MovieClip).printAmmo();
						break;
					case "/set-weapon": 
						(parent as MovieClip).swapWeapon(entry);
						break;
					case "/print-allweapons": 
						(parent as MovieClip).printAllWeapons();
						break;
					case "/nick": 
						if (entry.length < 10 && entry.length > 0 && entry.indexOf(" ") < 0)
						{
							var tNickChange:String = NICK + " has changed their name to " + entry;
							setNick(entry);
							record(tNickChange);
							(parent as MovieClip).sendStr(tNickChange);
						}
						else if (entry.length >= 10)
						{
							record("Pick a shorter name.");
						}
						else if (entry.length == 0)
						{
							record("Come on, I'm sure you can think of something.");
						}
						else if (entry.indexOf(" ") >= 0)
						{
							record("Your name can't include spaces.");
						}
						break;
					case "/print-inventory":
						(parent as MovieClip).printInventory();
						break;
					default: 
						record("<font color='#CC0000'>" + s + " is not a recognized command. Type /help for a list of commands.</font>");
						break;
				}
			}
			else
			{
				(parent as MovieClip).sendStr(NICK + ": " + command);
				(parent as MovieClip).iSay(command);
			}
		}
		
		public function updateCurrentConnections(n:Number)
		{
			currentConnections.text = "CURRENTLY CONNECTED: " + n;
		}
		
		public function record(s:String)
		{
			recordArray.push(s);
			myHistory.htmlText += s + "\n";
			myHistory.scrollV = myHistory.maxScrollV;
			scroller.update();
			trace(s);
			
			//Update chat log
			(parent as MovieClip).chatlogRecord(s);
		}
	}
}