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
	import QuickB2.stock.*;
	import revent.rEvent;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2TripSensorEvent extends rEvent
	{
		public static const SENSOR_TRIPPED:String = "sensorTripped";
		public static const SENSOR_ENTERED:String = "sensorEntered";
		public static const SENSOR_EXITED:String  = "sensorExited";
		
		qb2_friend var _sensor:qb2TripSensor;
		
		qb2_friend var _visitingObject:qb2Tangible;
		
		qb2_friend var _startTime:Number;
		
		public function qb2TripSensorEvent(type:String = null) 
		{
			super(type);
		}
		
		public function get sensor():qb2TripSensor
		{
			return _sensor;
		}
		
		public function get visitingObject():qb2Tangible
		{
			return _visitingObject;
		}
		
		public function get startTime():Number
		{
			return _startTime;
		}
		
		public override function clone():rEvent
		{
			var evt:qb2TripSensorEvent = super.clone() as qb2TripSensorEvent;
			evt._sensor = _sensor;
			evt._visitingObject = _visitingObject;
			evt._startTime = _startTime;
			return evt;
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2TripSensorEvent");  }
	}
}