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

package QuickB2.internals
{
	import As3Math.geo2d.*;
	import Box2DAS.Collision.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Contacts.*;
	import flash.utils.*;
	import QuickB2.debugging.logging.qb2_assert;
	import QuickB2.debugging.logging.qb2_notifications;
	import QuickB2.debugging.logging.qb2_notify;
	import QuickB2.debugging.QB2_DEBUG;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;

	import QuickB2.*;
	use namespace qb2_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 * @private
	 */
	public class qb2InternalContactListener extends b2ContactListener
	{
		private static const eventFlagToCachedEventMap:Dictionary = new Dictionary();
		
		private var CONTACT_STARTED:String, CONTACT_ENDED:String, PRE_SOLVE:String, POST_SOLVE:String;
		private var SUB_CONTACT_STARTED:String, SUB_CONTACT_ENDED:String, SUB_PRE_SOLVE:String, SUB_POST_SOLVE:String;
		
		public function qb2InternalContactListener()
		{
			CONTACT_STARTED = qb2ContactEvent.CONTACT_STARTED;
			CONTACT_ENDED   = qb2ContactEvent.CONTACT_ENDED;
			PRE_SOLVE       = qb2ContactEvent.PRE_SOLVE;
			POST_SOLVE      = qb2ContactEvent.POST_SOLVE;
			
			SUB_CONTACT_STARTED = qb2SubContactEvent.SUB_CONTACT_STARTED;
			SUB_CONTACT_ENDED   = qb2SubContactEvent.SUB_CONTACT_ENDED;
			SUB_PRE_SOLVE       = qb2SubContactEvent.SUB_PRE_SOLVE;
			SUB_POST_SOLVE      = qb2SubContactEvent.SUB_POST_SOLVE;
		}
		
		private function dispatchSubContactEvent(shape1:qb2Shape, shape2:qb2Shape, contact:b2Contact, type:String):void
		{		
			var currParent:qb2ObjectContainer = shape1._lastParent;
			while ( currParent )
			{
				if ( shape2.isDescendantOf(currParent)  )
				{
					var subEvent:qb2SubContactEvent = qb2_cachedEvents.SUB_CONTACT_EVENT;
					subEvent.type = type;
					subEvent._shape1 = shape1;
					subEvent._shape2 = shape2;
					subEvent._ancestorGroup = currParent as qb2Group;
					subEvent._contactB2 = contact;
					subEvent._world = shape1.world;
					
					currParent.dispatchEvent(subEvent);
				}
				
				currParent = currParent._lastParent;
			}
		}
		
		private function dispatchContactEvent(shape1:qb2Shape, shape2:qb2Shape, contact:b2Contact, type:String):void
		{
			var currParent:qb2Tangible = shape1;
			
			while ( currParent && !(currParent is qb2World) )
			{
				if( currParent.hasEventListener(type) )
				{
					if ( currParent is qb2Group )
					{
						var asGroup:qb2Group = currParent as qb2Group;
						if ( shape1.isDescendantOf(asGroup) && shape2.isDescendantOf(asGroup ) )
						{
							currParent = currParent._lastParent;
							continue; // contact events aren't dispatched when the dispatcher is a group containing the two shapes that contacted.
						}
					}
					
					var event:qb2ContactEvent = qb2_cachedEvents.CONTACT_EVENT;
					event.type = type;
					event._localShape = shape1;
					event._otherShape = shape2;
					event._localObject = currParent;
					qb2Object.setAncestorPair(currParent, shape2, true);
					event._otherObject = qb2Object.setAncestorPair_other as qb2Tangible; // TADA!!!
					qb2Object.setAncestorPair_local = null;
					qb2Object.setAncestorPair_other = null;
					event._contactB2 = contact;
					event._world = shape1.world;
					
					currParent.dispatchEvent(event);
				}
				
				currParent = currParent._lastParent;
			}
		}
		
		public override function BeginContact(contact:b2Contact):void
		{
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;

			if ( QB2_DEBUG )
			{
				qb2_notify(qb2_notifications.CONTACT_BEGIN);
				qb2_assert(shape1 && shape2);
			}
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_CONTACT_STARTED);
			dispatchContactEvent(shape1, shape2, contact, CONTACT_STARTED);
			dispatchContactEvent(shape2, shape1, contact, CONTACT_STARTED);
		}
		
		public override function EndContact(contact:b2Contact):void
		{
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;
			
			if ( QB2_DEBUG )
			{
				qb2_notify(qb2_notifications.CONTACT_END);
				qb2_assert(shape1 && shape2);
			}
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_CONTACT_ENDED);
			dispatchContactEvent(shape1, shape2, contact, CONTACT_ENDED);
			dispatchContactEvent(shape2, shape1, contact, CONTACT_ENDED);
		}
		
		public override function PreSolve(contact:b2Contact, oldManifold:b2Manifold):void
		{
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;
			
			if ( QB2_DEBUG )
			{
				qb2_notify(qb2_notifications.CONTACT_PRE_SOLVE);
				qb2_assert(shape1 && shape2);
			}
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_PRE_SOLVE);
			dispatchContactEvent(shape1, shape2, contact, PRE_SOLVE);
			dispatchContactEvent(shape2, shape1, contact, PRE_SOLVE);
		}
		
		public override function PostSolve(contact:b2Contact, impulse:b2ContactImpulse):void
		{
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;
			
			if ( QB2_DEBUG )
			{
				qb2_notify(qb2_notifications.CONTACT_POST_SOLVE);
				qb2_assert(shape1 && shape2);
			}
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_POST_SOLVE);
			dispatchContactEvent(shape1, shape2, contact, POST_SOLVE);
			dispatchContactEvent(shape2, shape1, contact, POST_SOLVE);
		}
	}
}