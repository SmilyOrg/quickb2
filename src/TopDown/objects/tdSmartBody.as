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

package TopDown.objects
{
	import QuickB2.*;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import TopDown.*;
	import TopDown.ai.*;
	import TopDown.ai.brains.*;
	
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdSmartBody extends qb2Body
	{
		public const brainPort:tdBrainPort = new tdBrainPort();
		
		public function tdSmartBody()
		{
			if ( Object(this).constructor == tdSmartBody )
			{
				throw qb2_errors.ABSTRACT_CLASS_ERROR;
			}
			
			addEventListener(qb2ContainerEvent.ADDED_OBJECT,   justAddedObject);
			addEventListener(qb2ContainerEvent.REMOVED_OBJECT, justRemovedObject);
		}
		
		private function justAddedObject(evt:qb2ContainerEvent):void
		{
			var object:qb2Object = evt.child;
			
			if ( object is tdBrain )
			{
				setBrain(object as tdBrain);
			}
		}
		
		private function justRemovedObject(evt:qb2ContainerEvent):void
		{
			var object:qb2Object = evt.child;
			
			if ( object is tdBrain )
			{
				setBrain(null);
			}
		}

		private function setBrain(newBrain:tdBrain):void
		{
			if ( newBrain && newBrain.host )  throw td_errors.BRAIN_ALREADY_HAS_HOST_ERROR;
		
			if ( newBrain == _brain )  return;
			
			if ( _brain )  _brain.setHost(null);

			_brain = newBrain;
			
			if ( _brain )   _brain.setHost(this);
		}
		
		public function get brain():tdBrain
			{  return _brain;  }
		td_friend var _brain:tdBrain;
		
		public function swapBrainsWith(otherSmartBody:tdSmartBody):void
		{
			var otherBrain:tdBrain = otherSmartBody.brain;
			var thisBrain:tdBrain = this.brain;
			otherSmartBody.removeObject(otherBrain);
			this.removeObject(thisBrain);
			
			otherSmartBody.addObject(thisBrain);
			this.addObject(otherBrain);
		}
		
		public function transferBrainTo(smartBody:tdSmartBody):void
		{
			var thisBrain:tdBrain = this.brain;
			this.removeObject(thisBrain);
			smartBody.addObject(thisBrain);
		}
		
		public function transferBrainFrom(smartBody:tdSmartBody):void
		{
			var otherBrain:tdBrain = smartBody.brain;
			smartBody.removeObject(otherBrain);
			this.addObject(otherBrain);
		}
	}
}