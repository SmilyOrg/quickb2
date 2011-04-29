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

package QuickB2.events 
{
	import flash.events.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.objects.*;
	import revent.rEvent;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2UpdateEvent extends rEvent
	{
		public static const PRE_UPDATE:String     = "preUpdate";
		public static const POST_UPDATE:String    = "postUpdate";
		
		public static const ALL_EVENT_TYPES:Array = [PRE_UPDATE, POST_UPDATE];
		
		qb2_friend var _object:qb2Object;
		
		public function qb2UpdateEvent(type:String = null) 
		{
			super(type);
		}
		
		public override function clone():rEvent
		{
			var evt:qb2UpdateEvent = super.clone() as qb2UpdateEvent;
			evt._object = this._object;
			return evt;
		}
		
		public function get object():qb2Object
		{
			return _object;
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2UpdateEvent");  }
	}
}