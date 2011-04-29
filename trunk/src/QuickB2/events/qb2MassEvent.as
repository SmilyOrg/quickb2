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
	import QuickB2.objects.tangibles.*;
	import revent.rEvent;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2MassEvent extends rEvent
	{
		public static const MASS_PROPS_CHANGED:String  = "massPropsChanged";
		
		qb2_friend var _affectedObject:qb2Tangible;
		
		qb2_friend var _massChange:Number    = 0;
		qb2_friend var _densityChange:Number = 0;
		qb2_friend var _areaChange:Number    = 0;
		
		public function qb2MassEvent(type:String = null) 
			{  super(type);  }
		
		public override function clone():rEvent
		{
			var evt:qb2MassEvent = super.clone() as qb2MassEvent;
			evt._affectedObject = this._affectedObject;
			evt._massChange     = this._massChange;
			evt._densityChange  = this._densityChange;
			evt._areaChange     = this._areaChange;
			return evt;
		}
		
		public function get affectedObject():qb2Tangible
			{  return _affectedObject;  }
		
		public function get massChange():Number
			{  return _massChange;  }
			
		public function get areaChange():Number
			{  return _areaChange;  }
			
		public function get densityChange():Number
			{  return _densityChange;  }
			
		public override function toString():String 
			{  return qb2_toString(this, "qb2MassEvent");  }
	}
}