/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package TopDown.ai.brains
{
	import TopDown.*;
	import TopDown.ai.*;
	import TopDown.ai.controllers.*;
	import TopDown.objects.*;
	
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdControllerBrain extends tdBrain
	{
		private var controllers:Vector.<tdController> = new Vector.<tdController>();
		
		public function tdControllerBrain()
		{
		}
		
		protected function blendPortData():void
		{
			var numControllers:int = controllers.length;
			
			for (var i:int = 0; i < numControllers; i++) 
			{
				var controller:tdController = controllers[i];
				var controllerPort:tdBrainPort = controller.brainPort;
				
				if ( !controllerPort.open )  continue;
				
				controller.relay_update();
				
				var hostPort:tdBrainPort = host.brainPort;
				
				hostPort.BOOLEAN_PORT_1 = !hostPort.BOOLEAN_PORT_1 ? controllerPort.BOOLEAN_PORT_1 : true;
				hostPort.BOOLEAN_PORT_2 = !hostPort.BOOLEAN_PORT_1 ? controllerPort.BOOLEAN_PORT_2 : true;
				hostPort.BOOLEAN_PORT_3 = !hostPort.BOOLEAN_PORT_1 ? controllerPort.BOOLEAN_PORT_3 : true;
				hostPort.BOOLEAN_PORT_4 = !hostPort.BOOLEAN_PORT_1 ? controllerPort.BOOLEAN_PORT_4 : true;
				
				hostPort.INTEGER_PORT_1 += controllerPort.INTEGER_PORT_1;
				hostPort.INTEGER_PORT_2 += controllerPort.INTEGER_PORT_2;
				hostPort.INTEGER_PORT_3 += controllerPort.INTEGER_PORT_3;
				hostPort.INTEGER_PORT_4 += controllerPort.INTEGER_PORT_4;
				
				hostPort.NUMBER_PORT_1 += controllerPort.NUMBER_PORT_1;
				hostPort.NUMBER_PORT_2 += controllerPort.NUMBER_PORT_2;
				hostPort.NUMBER_PORT_3 += controllerPort.NUMBER_PORT_3;
				hostPort.NUMBER_PORT_4 += controllerPort.NUMBER_PORT_4;
				
				hostPort.STRING_PORT += controllerPort.STRING_PORT;
				
				hostPort.BITMASK_PORT |= controllerPort.BITMASK_PORT;
			}
		}

		protected override function update():void
		{
			host.brainPort.clear();
			blendPortData();
		}
		
		protected override function addedToWorld():void
		{
			for ( var i:int = 0; i < controllers.length; i++ )
			{
				controllers[i].relay_activated();
			}
		}
		
		protected override function removedFromWorld():void
		{
			for ( var i:int = 0; i < controllers.length; i++ )
			{
				controllers[i].relay_deactivated();
			}
		}
		
		public function addController(controller:tdController):void
		{
			controller.setControllerBrain(this);
			if ( host && host.world )
			{
				controller.relay_activated();
			}
			controllers.push(controller);
		}
			
		public function get numControllers():uint
			{  return controllers.length;  }
			
		public function getControllerAt(index:uint):tdController
			{  return controllers[index];  }
			
		public function removeController(controller:tdController):tdController
			{  return removeControllerAt(controllers.indexOf(controller));  }
			
		public function removeControllerAt(index:uint):tdController
		{
			var controller:tdController = controllers.splice(index, 1)[0];
			controller.setControllerBrain(null);
			controller.relay_deactivated();
			return controller;
		}
	}
}