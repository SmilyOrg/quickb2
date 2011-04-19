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

package TopDown.ai.controllers 
{	
	import QuickB2.*;
	import QuickB2.misc.qb2_errors;
	import TopDown.*;
	import TopDown.ai.*;
	import TopDown.ai.brains.*;
	import TopDown.objects.*;
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdController
	{
		public const brainPort:tdBrainPort = new tdBrainPort();
		
		public function tdController():void
		{
			if ( (this as Object).constructor == tdController )
			{
				throw qb2_errors.ABSTRACT_CLASS_ERROR;
			}
		}
		
		protected virtual function activated():void {}
			
		protected virtual function deactivated():void { }
		
		protected virtual function update():void { }
		
		td_friend function relay_update():void
		{
			if( brainPort.open )
				update();
		}

		td_friend function relay_activated():void
		{
			brainPort.clear();
			activated();
		}
		
		td_friend function relay_deactivated():void
		{
			deactivated();
			brainPort.clear();
		}
		
		td_friend function setControllerBrain(aBrain:tdControllerBrain):void
			{  _controllerBrain = aBrain;  }
		public function get controllerBrain():tdControllerBrain
			{  return _controllerBrain;  }
		private var _controllerBrain:tdControllerBrain = null;
		
		public function get host():tdSmartBody
			{  return _controllerBrain ? _controllerBrain.host : null;  }
	}
}