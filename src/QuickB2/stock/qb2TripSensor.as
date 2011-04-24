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

package QuickB2.stock
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.events.*;
	import QuickB2.internals.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	[Event(name="sensorTripped", type="QuickB2.events.qb2TripSensorEvent")]
	[Event(name="sensorEntered", type="QuickB2.events.qb2TripSensorEvent")]
	[Event(name="sensorExited",  type="QuickB2.events.qb2TripSensorEvent")]
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2TripSensor extends qb2Body
	{
		public var triggers:Array = null;
		
		public var tripTime:Number = 0;
		
		private const contactList:Dictionary = new Dictionary();
		
		private var _numVisitors:uint = 0;
		private var _numTrippedVisitors:uint  = 0;
		
		public function qb2TripSensor()
		{
			super();
			init();
		}
		
		private function init():void
		{
			addEventListener(qb2ContactEvent.CONTACT_STARTED, started,    null, true);
			addEventListener(qb2ContactEvent.CONTACT_ENDED,   ended,      null, true);
			addEventListener(qb2UpdateEvent.POST_UPDATE,      postUpdate, null, true);
			
			isGhost = true;
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2TripSensor = super.clone(deep) as qb2TripSensor;
			
			cloned.tripTime = this.tripTime;
			
			return cloned;
		}
		
		private function ignore(tang:qb2Tangible):Boolean
		{
			if ( !triggers )  return false;
			
			for (var i:int = 0; i < triggers.length; i++) 
			{
				var trigger:Object = triggers[i];
				
				if ( trigger is Class )
				{
					if ( tang is (trigger as Class) )
					{
						return false;
					}
				}
				else
				{
					if ( tang == trigger )
					{
						return false;
					}
				}
			}
			
			return true;
		}
		
		private function started(evt:qb2ContactEvent):void
		{
			var visitingObject:qb2Tangible = evt.otherObject;
			var visitingShape:qb2Shape = evt.otherShape;
			
			if ( ignore(visitingObject) )  return;
			
			var firstContact:Boolean = false;
			var theContact:qb2InternalTripSensorContact;
			if ( !contactList[visitingObject] )
			{
				const newContact:qb2InternalTripSensorContact = new qb2InternalTripSensorContact(world.clock);
				newContact.visitingObject = visitingObject;
				theContact = newContact;
				contactList[visitingObject] = newContact;
				newContact.shapeList[visitingShape] = 1;
				_numVisitors++;
				newContact.shapeCount++;
				
				firstContact = true;
			}
			else
			{
				const contact:qb2InternalTripSensorContact = contactList[visitingObject];
				theContact = contact;
				if ( contact.shapeList[visitingShape] )
					contact.shapeList[visitingShape]++;
				else
				{
					contact.shapeCount++;
					contact.shapeList[visitingShape] = 1;
				}
			}
			
			if ( firstContact )
			{
				fireEvent(qb2TripSensorEvent.SENSOR_ENTERED, theContact, false);
				
				if ( tripTime == 0 )
				{
					fireEvent(qb2TripSensorEvent.SENSOR_TRIPPED, theContact, true);
				}
			}
		}
		
		private function ended(evt:qb2ContactEvent):void
		{
			var visitingObject:qb2Tangible = evt.otherObject;
			var visitingShape:qb2Shape = evt.otherShape;
	
			if ( ignore(visitingObject) && !contactList[visitingObject] )
			{
				return;
			}
			
			if ( !contactList[visitingObject] )
			{
				throw new Error("Leaving object never entered.");
			}
			
			var contact:qb2InternalTripSensorContact = contactList[visitingObject];
			
			if ( !contact.shapeList[visitingShape] )  throw new Error("Oops, visiting shape wasn't found");
			
			contact.shapeList[visitingShape]--;
			
			if ( contact.shapeList[visitingShape] == 0 )
			{
				contact.shapeCount--;
				delete contact.shapeList[visitingShape];
				
				if ( contact.shapeCount == 0 )
				{
					delete contactList[visitingObject];
					_numVisitors--;
					
					if ( contact.trippedSensor )
						_numTrippedVisitors--;
					
					fireEvent(qb2TripSensorEvent.SENSOR_EXITED, contact, false);
				}
			}
		}
		
		private function fireEvent(type:String, contact:qb2InternalTripSensorContact, tripper:Boolean):void
		{
			var event:qb2TripSensorEvent = qb2_cachedEvents.TRIP_SENSOR_EVENT;
			event.type = type;
			event._sensor = this;
			event._visitingObject = contact.visitingObject;
			event._startTime = contact.startTime;
			dispatchEvent(event);
			
			if ( tripper )
			{
				contact.trippedSensor = true;
				_numTrippedVisitors++;
			}
		}
		
		private function postUpdate(evt:qb2UpdateEvent):void
		{
			var clock:Number = world.clock;
			
			for ( var key:* in contactList )
			{
				var contact:qb2InternalTripSensorContact = contactList[key];
				if ( !contact.trippedSensor )
				{
					if ( clock - contact.startTime > tripTime )
					{
						fireEvent(qb2TripSensorEvent.SENSOR_TRIPPED, contact, true);
					}
				}
			}
		}
		
		public function get numVisitors():uint
		{
			return _numVisitors;
		}
		
		public function get numTrippedVisitors():uint
		{
			return _numTrippedVisitors;
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			pushDebugFillColor(qb2_debugDrawSettings.tripSensorFillColor);
				super.drawDebug(graphics);
			popDebugFillColor();
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2TripSensor");  }
	}
}