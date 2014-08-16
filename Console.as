package
{
	import flash.events.*;
	import flash.display.*;
	
	public class Console extends MovieClip
	{
		//Init Constants
		var HELP_MESSAGE:String = "Some notable commands include\n/nick (changes your name)\n/reconnect (resets your connection)";
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
				case "/spawn-zombie":
					(parent as MovieClip).createZombieFromMe();
					break;
				default: 
					//record("<font color='#CC0000'>" + s + " is not a recognized command. Type HELP for a list of commands.</font>");
					if (command.substring(0, 6) == "/nick ")
					{
						if (command.substring(6).length < 10 && command.substring(6).length > 0 && command.substring(6).indexOf(" ") < 0)
						{
							var tNickChange:String = NICK + " has changed their name to " + command.substring(6);
							setNick(command.substring(6));
							record(tNickChange);
							(parent as MovieClip).sendStr(tNickChange);
						}
						else if (command.substring(6).length >= 10)
						{
							record("Pick a shorter name.");
						}
						else if (command.substring(6).length == 0)
						{
							record("Come on, I'm sure you can think of something.");
						}
						else if (command.substring(6).indexOf(" ") >= 0)
						{
							record("Your name can't include spaces.");
						}
					}
					else
					{
						(parent as MovieClip).sendStr(NICK + ": " + command);
					}
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
		}
	}
}