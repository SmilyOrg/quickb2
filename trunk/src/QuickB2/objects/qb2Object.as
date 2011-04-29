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

package QuickB2.objects 
{
	import Box2DAS.Common.*;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.logging.qb2_errors;
	import QuickB2.debugging.logging.qb2_throw;
	import QuickB2.events.*;
	import QuickB2.internals.*;
	import QuickB2.loaders.proxies.qb2ProxyObject;
	import QuickB2.misc.*;
	import QuickB2.misc.acting.qb2IActor;
	import QuickB2.misc.acting.qb2IActorContainer;
	import QuickB2.objects.joints.*;
	import QuickB2.objects.tangibles.*;
	import revent.rEventDispatcher;
	import revent.rReflectionEvent;
	import surrender.srGraphics2d;
	import surrender.srIDebugDrawable2d;
	use namespace qb2_friend;
	
	[Event(name="preUpdate",        type="QuickB2.events.qb2UpdateEvent")]
	[Event(name="postUpdate",       type="QuickB2.events.qb2UpdateEvent")]
	
	[Event(name="addedToWorld",     type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="removedFromWorld", type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="indexChanged",     type="QuickB2.events.qb2ContainerEvent")]
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Object extends rEventDispatcher implements srIDebugDrawable2d
	{
		/// A place to put any kind of data you want to be associated with this object.
		public var userData:*;
		
		public function qb2Object()
		{
			init();
		}
		
		private function init():void
		{
			if ( (this as Object).constructor == qb2Object )  qb2_throw(qb2_errors.ABSTRACT_CLASS_ERROR);
			
			turnFlagOn(qb2_flags.JOINS_IN_DEBUG_DRAWING | qb2_flags.JOINS_IN_DEEP_CLONING | qb2_flags.JOINS_IN_UPDATE_CHAIN, false);
			
			addEventListenerForTypes(rReflectionEvent.ALL_EVENT_TYPES, reflectionEvent, null, true);
		}
		
		private function reflectionEvent(evt:rReflectionEvent):void
		{
			var eventTypesAdded:Boolean = evt.type == rReflectionEvent.EVENT_TYPES_ADDED;
			
			if ( evt.concernsTypes(qb2UpdateEvent.ALL_EVENT_TYPES) )
			{
				if ( _world )
				{
					if ( eventTypesAdded )
					{
						if ( evt.concernsType(qb2UpdateEvent.PRE_UPDATE) )
						{
							if ( !_world.preEventers[this] )
							{
								_world.preEventers[this] = true;
							}
						}
						if ( evt.concernsType(qb2UpdateEvent.POST_UPDATE) )
						{
							if ( !_world.postEventers[this] )
							{
								_world.postEventers[this] = true;
							}
						}
					}
					else
					{
						if ( evt.concernsType(qb2UpdateEvent.PRE_UPDATE) )
						{
							if ( _world.preEventers[this] )
								delete _world.preEventers[this];
						}
						if ( evt.concernsType(qb2UpdateEvent.POST_UPDATE) )
						{
							if ( _world.postEventers[this] )
								delete _world.postEventers[this];
						}
					}
				}
			}
			else
			{
				var asTang:qb2Tangible = this as qb2Tangible;
				
				if ( asTang )
				{
					var concernsContactListening:Boolean = false;
					var doubledArray:Vector.<Array> = qb2BaseContactEvent.DOUBLED_ARRAY;
					
					for (var i:int = 0; i < 4; i++) 
					{
						if ( evt.concernsTypes(doubledArray[i]) )
						{
							var reportingBit:uint = REPORTING_BITS[i];
							concernsContactListening = true;
							
							if ( eventTypesAdded )
							{
								//this._flags                     |=  reportingBit;
								this._ownershipFlagsForBooleans |=  reportingBit;
							}
							else
							{
								//this._flags                     &= ~reportingBit;
								this._ownershipFlagsForBooleans &= ~reportingBit;
							}
						}
					}
					
					if ( concernsContactListening )
					{
						var CONTACT_REPORTING_FLAGS:uint = qb2_flags.CONTACT_REPORTING_FLAGS;
						var currParent:qb2ObjectContainer = this._parent;
						var flagsToSendDown:uint = 0;
						while ( currParent )
						{
							flagsToSendDown |= currParent._flags & (CONTACT_REPORTING_FLAGS & currParent._ownershipFlagsForBooleans);
							
							currParent = currParent._parent;
						}
						
						updateContactReportingFlags(flagsToSendDown);
					}
				}
			}
		}
		
		qb2_friend function updateContactReportingFlags(flags:uint):void
		{
			var asContainer:qb2ObjectContainer = this as qb2ObjectContainer;
			var CONTACT_REPORTING_FLAGS:uint = qb2_flags.CONTACT_REPORTING_FLAGS;
			
			var oldFlags:uint = this._flags;
			
			this._flags &= ~CONTACT_REPORTING_FLAGS;
			this._flags |=  CONTACT_REPORTING_FLAGS & flags;
			this._flags |=  CONTACT_REPORTING_FLAGS & this._ownershipFlagsForBooleans;
			
			flags       |=  CONTACT_REPORTING_FLAGS & this._flags;
			
			if ( asContainer )
			{
				for (var i:int = 0; i < asContainer._objects.length; i++) 
				{
					asContainer._objects[i].updateContactReportingFlags(flags);
				}
			}
			else
			{
				var asShape:qb2Shape = this as qb2Shape;
				if ( asShape )
				{
					asShape.flagsChanged(oldFlags ^ this._flags);
				}
			}
		}
		
		qb2_friend static const REPORTING_BITS:Vector.<uint> = Vector.<uint>
		([
			qb2_flags.REPORTS_CONTACT_STARTED, qb2_flags.REPORTS_CONTACT_ENDED, qb2_flags.REPORTS_PRE_SOLVE, qb2_flags.REPORTS_POST_SOLVE
		]);
		
		
		qb2_friend var _ownershipFlagsForProperties:uint = 0;
		qb2_friend var _ownershipFlagsForBooleans:uint   = 0;
		
		/**
		 * Returns the bitwise flags assigned to this object.
		 * @default qb2_flags.JOINS_IN_DEBUG_DRAWING | qb2_flags.JOINS_IN_DEEP_CLONING | qb2_flags.JOINS_IN_UPDATE_CHAIN
		 */
		public function get flags():uint
			{  return _flags;  }
		qb2_friend var _flags:uint = 0;
		
		/**
		 * Turns a flag (or flags) off.  For example turnFlagOff(qb2_flags.JOINS_IN_DEBUG_DRAWING)
		 * will tell this object not to draw debug graphics.
		 */
		public final function turnFlagOff(flagOrFlags:uint, takeOwnership:Boolean = true):qb2Object
		{
			setFlag(false, flagOrFlags, takeOwnership);
			
			return this;
		}
		
		/**
		 * Turns a flag(s) on.  For example turnFlagOn(qb2_flags.JOINS_IN_DEBUG_DRAWING)
		 * will tell this object to draw debug graphics.
		 */
		public final function turnFlagOn(flagOrFlags:uint, takeOwnership:Boolean = true):qb2Object
		{
			setFlag(true, flagOrFlags, takeOwnership);
			
			return this;
		}
	
		/**
		 * Sets a flag(s) on or off based on a boolean value.
		 */
		public final function setFlag(bool:Boolean, flagOrFlags:uint, takeOwnership:Boolean = true):qb2Object
		{
			if ( flagOrFlags & qb2_flags.RESERVED_FLAGS )
			{
				qb2_throw(qb2_errors.ILLEGAL_FLAG_ASSIGNMENT);
			}
			
			var oldFlags:uint = _flags;
			
			if ( bool )
			{
				_flags |= flagOrFlags;
			}
			else
			{
				_flags &= ~flagOrFlags;
			}
			
			var asContainer:qb2ObjectContainer = this as qb2ObjectContainer;
			
			if ( !takeOwnership )
			{
				/*var ownershipFlagsThatWillBeCleared:uint = flagOrFlags & _ownershipFlagsForBooleans;
				var flagsOwnedByAncestors:uint = 0;
				
				if ( ownershipFlagsThatWillBeWiped )
				{
					var currParent:qb2ObjectContainer = this._parent;
					
					while ( currParent )
					{
						var allFlagsOwnedByCurrParentPlusPreviousAncestors:uint = flagsOwnedByAncestors | (ownershipFlagsThatWillBeCleared & currParent._ownershipFlagsForBooleans);
						var flagsOwnedByCurrParentThatAreNotYetTaken:uint = flagsOwnedByAncestors ^ allFlagsOwnedByCurrParentPlusPreviousAncestors;
						_flags     |= flagsOwnedByCurrParentThatAreNotYetTaken & currParent._flags;
						flagsOwnedByAncestors |= flagsOwnedByCurrParentThatAreNotYetTaken;
						
						currParent = currParent._parent;
					}
				}
				
				_ownershipFlagsForBooleans &= ~flagOrFlags;
				
				flagsChanged(oldFlags ^ _flags);
				
				if ( flagsTaken )
				{
					var asContainer:qb2ObjectContainer = this as qb2ObjectContainer;
					if ( asContainer )
					{
						cascadeOwnedFlags(asContainer, flagsOwnedByAncestors & flagOrFlags);
					}
				}*/
				
				_ownershipFlagsForBooleans &= ~flagOrFlags;
				flagsChanged(oldFlags ^ _flags);
			}
			else
			{
				_ownershipFlagsForBooleans |= flagOrFlags;
				flagsChanged(oldFlags ^ _flags);
				
				if ( asContainer )
				{
					cascadeOwnedFlags(asContainer, flagOrFlags);
				}
			}
			
			return this;
		}
		
		/**
		 * Tells whether a bitwise flag(s) is on or off.
		 */
		public final function isFlagOn(flagOrFlags:uint):Boolean
		{
			return flagOrFlags && ((_flags & flagOrFlags) == flagOrFlags);
		}
		
		/**
		 * Tells whether this object owns a given flag(s).
		 */
		public final function ownsFlag(flagOrFlags:uint):Boolean
		{
			return flagOrFlags && ((_ownershipFlagsForBooleans & flagOrFlags) == flagOrFlags);
		}
		
		/**
		 * Tells whether this object owns a given property.
		 */
		public final function ownsProperty(propertyName:String):Boolean
		{
			var propertyBit:uint = _propertyMap[propertyName];
			return _ownershipFlagsForProperties & propertyBit ? true : false;
		}
		
		/**
		 * Gets the property value for a given property name.
		 * @return Generally a Number, uint, or int.
		 */
		public final function getProperty(propertyName:String):*
		{
			return _propertyMap[propertyName];
		}
		
		/**
		 * Sets the property value for a given property name.
		 * 
		 * @param value The value associated with the property name.  This is generally a Number, int, uint, or qb2CustomProperty.
		 * @return this
		 */
		public final function setProperty(propertyName:String, value:*, takeOwnership:Boolean = true):qb2Object
		{
			//--- Check if this property has been registered yet by any object.
			if ( !_propertyBits[propertyName] )
			{
				if ( !_currPropertyBit )
				{
					qb2_throw(qb2_errors.NUMBER_PROPERTY_SLOTS_FULL);
				}
				
				_propertyBits[propertyName] = _currPropertyBit;
				_currPropertyBit = _currPropertyBit << 1;
			}
			
			if ( !takeOwnership )
			{
				_propertyMap[propertyName] = value;
				_ownershipFlagsForProperties &= ~_propertyBits[propertyName];
				propertyChanged(propertyName);
			}
			else
			{
				cascadeProperty(this, propertyName, value);
			}
			
			return this;
		}
		
		qb2_friend var _propertyMap:Object = { };
		
		qb2_friend static var _propertyBits:Object = { };
		private static var _currPropertyBit:uint = 0x00000001;
		
		private static function cascadeProperty(root:qb2Object, propertyName:String, value:*):void
		{
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.push(root);
			
			while ( queue.length )
			{
				var subObject:qb2Object = queue.shift();
				
				if ( subObject != root )
				{
					//--- This sub-object loses ownership of this property...it is now considered "inherited" from the root.
					subObject._ownershipFlagsForProperties &= ~_propertyBits[propertyName];
				}
				else
				{
					subObject._ownershipFlagsForProperties |= _propertyBits[propertyName];
				}
				
				subObject._propertyMap[propertyName] = value;
				subObject.propertyChanged(propertyName);
				
				if ( subObject is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = subObject as qb2ObjectContainer;
					var numObjects:int = asContainer.numObjects;
					
					for ( var i:int = 0; i < numObjects; i++) 
					{
						queue.push(asContainer._objects[i]);
					}
				}
			}
		}
		
		private static function cascadeGatedFlags(root:qb2ObjectContainer, affectedFlags:uint):void
		{
			
		}
		
		private static function cascadeOwnedFlags(root:qb2ObjectContainer, affectedFlags:uint):void
		{
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			var numObjects:int = root.numObjects
			for ( var i:int = 0; i < numObjects; i++) 
			{
				queue.push(root._objects[i]);
			}
			
			var rootsFlags:uint = root._flags;
			while ( queue.length )
			{
				var subObject:qb2Object = queue.shift();
				
				var subObjectsOldFlags:uint = subObject._flags;
				
				//--- This sub-object loses ownership of this property...it is now considered "inherited" from the root.
				subObject._ownershipFlagsForBooleans &= ~affectedFlags;
				
				//--- Clear the subobjects flags using affectedFlags, then reset them using affectedFlags as the filter.
				subObject._flags &= ~affectedFlags;
				subObject._flags |=  affectedFlags & rootsFlags;
				
				subObject.flagsChanged(subObjectsOldFlags ^ subObject._flags);
				
				if ( subObject is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = subObject as qb2ObjectContainer;
					numObjects = asContainer.numObjects;
					
					for ( i = 0; i < numObjects; i++) 
					{
						queue.push(asContainer._objects[i]);
					}
				}
			}
		}
		
		/**
		 * Whether or not this object joins in deep clones, i.e. when an ancestor gets its clone() function called with deep==true.
		 * Direct calls to this object's clone() method will still work regardless.
		 * @default true
		 */
		public function get joinsInDeepCloning():Boolean
			{  return _flags & qb2_flags.JOINS_IN_DEEP_CLONING ? true : false;  }
		public function set joinsInDeepCloning(bool:Boolean):void
			{  setFlag(bool, qb2_flags.JOINS_IN_DEEP_CLONING, false);  }
		
		/**
		 * Whether or not this object joins in world debug drawing.  Direct calls to drawDebug() will still work regardless.
		 * @default true
		 */
		public function get joinsInDebugDrawing():Boolean
			{  return _flags & qb2_flags.JOINS_IN_DEBUG_DRAWING ? true : false;  }
		public function set joinsInDebugDrawing(bool:Boolean):void
			{  setFlag(bool, qb2_flags.JOINS_IN_DEBUG_DRAWING, false);  }
		
		/**
		 * Whether or not this object joins in the update chain.  Setting this to false means that overriding qb2Object::update() is meaningless.
		 * @default true
		 */
		public function get joinsInUpdateChain():Boolean
			{  return _flags & qb2_flags.JOINS_IN_UPDATE_CHAIN ? true : false;  }
		public function set joinsInUpdateChain(bool:Boolean):void
			{  setFlag(bool, qb2_flags.JOINS_IN_UPDATE_CHAIN, false);  }
		
		protected virtual function propertyChanged(propertyName:String):void {}
		
		protected virtual function flagsChanged(affectedFlags:uint):void              {}
		
		/** The parent of this object, if any.
		 * @default null
		 */
		public function get parent():qb2ObjectContainer
			{  return _parent;  }
		qb2_friend var _parent:qb2ObjectContainer = null;
		qb2_friend var _lastParent:qb2ObjectContainer = null;

		/** The world this object resides in, if any.
		 * @default null
		 */
		public function get world():qb2World
			{  return _world;  }
		qb2_friend var _world:qb2World = null;
		
		/** Removes this object from its parent.
		 */
		public function removeFromParent():void
			{  this._parent.removeObject(this);  }
			
		/** Determines if this object is a descendant of the given ancestor.
		*/
		public function isDescendantOf(possibleAncestor:qb2ObjectContainer):Boolean
		{
			var object:qb2ObjectContainer = this._parent;
			while ( object )
			{
				if ( object == possibleAncestor )  return true;
				
				object = object._parent;
			}
			return false;
		}
		
		/** Determines whether this object has an ancestor of a certain class.
		 */
		public function isDescendantOfType(possibleAncestorType:Class):Boolean
		{
			var object:qb2ObjectContainer = this._parent;
			while ( object )
			{
				if ( object is possibleAncestorType )  return true;
				
				object = object._parent;
			}
			return false;
		}
		
		/** Returns the first ancestor of this object that is of a certain class.
		 */
		public function getAncestorOfType(ancestorType:Class):qb2ObjectContainer
		{
			var object:qb2ObjectContainer = this._parent;
			while ( object )
			{
				if ( object is ancestorType )  return object;
				
				object = object._parent;
			}
			
			return null;
		}
		
		/**
		 * Gets the first common ancestor of this and another object, if any.
		 * If the two objects are in the same world, at the very least this function will return the world.
		 */
		public function getCommonAncestor(otherObject:qb2Object):qb2ObjectContainer
		{
			setAncestorPair(this, otherObject);
			
			var currentLocalObject:qb2Object = setAncestorPair_local;
			
			setAncestorPair_local = null;
			setAncestorPair_other = null;
			
			return currentLocalObject._parent;
		}
		
		//--- These three members act in place of "passing by reference".
		qb2_friend static function setAncestorPair(local:qb2Object, other:qb2Object, useLastParents:Boolean = false):void
		{
			if ( local._parent != other._parent )
			{
				var localParentPath:Dictionary = new Dictionary(true);
				
				if ( !useLastParents )
				{
					while ( local._parent )
					{
						localParentPath[local.parent] = local;
						local = local._parent;
					}
					
					while ( other._parent )
					{
						if ( localParentPath[other._parent] )
						{
							local = localParentPath[other._parent];
							break;
						}
						
						other = other._parent;
					}
				}
				else
				{
					while ( local._lastParent )
					{
						localParentPath[local._lastParent] = local;
						local = local._lastParent;
					}
					
					while ( other._parent )
					{
						if ( localParentPath[other._lastParent] )
						{
							local = localParentPath[other._lastParent];
							break;
						}
						
						other = other._lastParent;
					}
				}
			}
			
			setAncestorPair_local = local;
			setAncestorPair_other = other;
		}
		qb2_friend static var setAncestorPair_local:qb2Object = null;
		qb2_friend static var setAncestorPair_other:qb2Object = null;
		
		/// Determines if this object is "above" otherObject.  If it returns true, it means for example
		/// that this object will be drawn on top of otherObject for debug drawing.
		public function isAbove(otherObject:qb2Object):Boolean
		{
			setAncestorPair(this, otherObject);
			
			var currentLocalObject:qb2Object = setAncestorPair_local;
			var currentOtherObject:qb2Object = setAncestorPair_other;
			
			setAncestorPair_local = null;
			setAncestorPair_other = null;
			
			var common:qb2ObjectContainer = currentLocalObject._parent;
			
			if ( !common )
			{
				throw new Error("Objects don't share a common ancestor!");
			}
			
			var array:Vector.<qb2Object> = common._objects;
			var numObjects:int = array.length;
			for (var i:int = 0; i < numObjects; i++) 
			{
				var item:qb2Object = array[i];
				
				if ( item == currentLocalObject )
				{
					return false;
				}
				else if ( item == currentOtherObject )
				{
					return true;
				}
			}
			
			return false;
		}
		
		/// Determines if this object is "below" otherObject.  If it returns true, it means for example
		/// that this object will be drawn below otherObject for debug drawing.
		public function isBelow(otherObject:qb2Object):Boolean
		{
			return !isAbove(otherObject);
		}
		
		/// Override this in subclasses to process class-specific changes that should be made immediately after the physics time step.
		/// This function is called after qb2UpdateEvent.PRE_UPDATE and before qb2UpdateEvent.POST_UPDATE.
		protected function update():void { }
		
		//--- Need this relay function because qb2ObjectContainer can't call protected functions directly.
		qb2_friend function relay_update():void
			{  update();  }
		
		qb2_friend static function walkDownTree(theObject:qb2Object, theWorld:qb2World, theAncestorBody:qb2Body, propStacks:Object, booleanFlags:uint, booleanOwnershipFlags:uint, theAncestor:qb2ObjectContainer, adding:Boolean):void
		{
			//--- (1) Set the ancestor body for object.
			var asTang:qb2Tangible = theObject as qb2Tangible
			if ( asTang )
			{
				if ( !theAncestorBody )
				{
					var asBody:qb2Body = theObject as qb2Body;
					if ( asBody )
					{
						theAncestorBody = asBody;
					}
				}
				
				asTang._ancestorBody = theAncestorBody == asTang ? null : theAncestorBody;
			}
			
			//--- (2) Propagate the values of properties and flags that are owned by ancestors and not owned by theObject.
			var CONTACT_REPORTING_FLAGS:uint = qb2_flags.CONTACT_REPORTING_FLAGS;
			if ( adding && propStacks )
			{
				//--- (2a) Propagate properties.
				var redundantProps:Vector.<String> = null;
				for ( var propertyName:String in propStacks )
				{
					var propertyMapStack:Array = propStacks[propertyName];
					
					if ( theObject._ownershipFlagsForProperties & _propertyBits[propertyName] )
					{
						if ( !redundantProps )  redundantProps = new Vector.<String>();
						redundantProps.push(propertyName);
						propertyMapStack.push( theObject._propertyMap[propertyName] );
					}
					else
					{
						var propertyValue:Number = propertyMapStack[propertyMapStack.length - 1];
						theObject._propertyMap[propertyName] = propertyValue;
						theObject.propertyChanged(propertyName);
					}
				}
				
				booleanOwnershipFlags   &= ~theObject._ownershipFlagsForBooleans;
				theObject._flags        &= ~booleanOwnershipFlags;
				theObject._flags        |=  booleanOwnershipFlags & booleanFlags;
				
				theObject._flags        &= ~CONTACT_REPORTING_FLAGS;
				theObject._flags        |=  CONTACT_REPORTING_FLAGS & booleanFlags;
				theObject._flags        |=  CONTACT_REPORTING_FLAGS & theObject._ownershipFlagsForBooleans;
				
				booleanFlags            |=  CONTACT_REPORTING_FLAGS & theObject._flags;
			}
			
			//--- (3) Process added-to-world-type stuff if applicable.
			if ( adding && theWorld )
			{
				theObject._world = theWorld
				
				theObject.makeWrapper(theWorld);
				
				if ( theObject.hasEventListener(qb2UpdateEvent.PRE_UPDATE) )
				{
					theWorld.preEventers[theObject] = true;
				}
				if ( theObject.hasEventListener(qb2UpdateEvent.POST_UPDATE) )
				{
					theWorld.postEventers[theObject] = true;
				}
				
				var evt:qb2ContainerEvent = qb2_cachedEvents.CONTAINER_EVENT.inUse ? new qb2ContainerEvent() : qb2_cachedEvents.CONTAINER_EVENT;
				evt.type = qb2ContainerEvent.ADDED_TO_WORLD;
				evt._ancestor = theAncestor;
				evt._child    = theObject;
				theObject.dispatchEvent(evt);
			}
			
			//--- (4) Process removed-from-world-type stuff if applicable.
			else if ( !adding && theWorld )
			{
				theObject._world = null;
				
				theObject.destroyWrapper(theWorld);
				
				if ( theWorld.preEventers[theObject] )
					delete theWorld.preEventers[theObject];
				if ( theWorld.postEventers[theObject] )
					delete theWorld.postEventers[theObject];
				
				evt = qb2_cachedEvents.CONTAINER_EVENT.inUse ? new qb2ContainerEvent() : qb2_cachedEvents.CONTAINER_EVENT;
				evt.type = qb2ContainerEvent.REMOVED_FROM_WORLD;
				evt._ancestor = theAncestor;
				evt._child    = theObject;
				theObject.dispatchEvent(evt);
			}
			
			var madeBody:Boolean = adding && asTang && !asTang._ancestorBody && (asTang is qb2IRigidObject);
			if ( madeBody )
			{
				asTang.pushEditSession();
			}
			
			//--- (5) Continue walking down the tree if theObject is a container.
			var asContainer:qb2ObjectContainer = theObject as qb2ObjectContainer;
			if ( asContainer )
			{
				var num:int = asContainer._objects.length;
				for (var i:int = 0; i < num; i++) 
				{
					var ithObject:qb2Object = asContainer._objects[i];
					walkDownTree(ithObject, theWorld, theAncestorBody, propStacks, booleanFlags, booleanOwnershipFlags, theAncestor, adding);
				}
			}
			
			if ( madeBody )
			{
				asTang.popEditSession();
				
				var delayedApplies:Vector.<qb2InternalDelayedApply> = qb2Tangible.delayedAppliesDict[asTang];
				if ( delayedApplies )
				{
					for (var j:int = 0; j < delayedApplies.length; j++) 
					{
						var item:qb2InternalDelayedApply = delayedApplies[j];
						if ( item.torque )
						{
							asTang.applyTorque(item.torque);
						}
						else if ( item.point && item.vector )
						{
							if ( item.isForce )
							{
								asTang.applyForce(item.point, item.vector);
							}
							else
							{
								asTang.applyImpulse(item.point, item.vector);
							}
						}
					}
					delete qb2Tangible.delayedAppliesDict[asTang];
				}
			}
			
			//--- (7) Clear any properties pushed onto the stack, cause we don't want them bleeding into peers' properties.
			if ( adding && redundantProps )
			{
				for ( i = 0; i < redundantProps.length; i++ )
				{
					propertyMapStack = propStacks[redundantProps[i]];
					propertyMapStack.pop();
				}
			}
		}
		
		qb2_friend function shouldMake():Boolean
			{  return false;  }
			
		qb2_friend function shouldDestroy():Boolean
			{  return false;  }
		
		qb2_friend virtual function make(theWorld:qb2World):void { }
		
		qb2_friend virtual function destroy(theWorld:qb2World):void { }
		
		qb2_friend function makeWrapper(theWorld:qb2World):void
		{
			if ( theWorld )
			{
				if ( theWorld.isLocked )
				{
					theWorld.addDelayedCall(this, makeWrapper, theWorld);
				}
				else if( shouldMake() )
				{
					make(theWorld);
				}
			}
		}
		
		qb2_friend function destroyWrapper(theWorld:qb2World):void
		{
			if ( theWorld )
			{
				if ( theWorld.isLocked )
				{
					theWorld.addDelayedCall(this, destroyWrapper, theWorld);
				}
				else if( shouldDestroy() )
				{
					destroy(theWorld);
				}
			}
		}
		
		/**
		 * Virtual method for drawing this object.  You can override this if you want, or leave it unimplemented.
		 */
		public virtual function draw(graphics:srGraphics2d):void      {}
		
		/**
		 * Virtual method for drawing debug graphics for this object.  You can override this if you want, or leave it unimplemented.
		 * A common use for this function is to set fill/line-style on the srGraphics2dObject object, and then call draw().
		 */
		public virtual function drawDebug(graphics:srGraphics2d):void { }
		
		qb2_friend function removeActor():void
		{
			if ( _actor && _actor.getParentActor() && _parent && _parent._actor == _actor.getParentActor() )
			{
				_actor.getParentActor().removeActor(_actor);
			}
		}
		
		qb2_friend function addActor():void
		{
			if ( _actor && !_actor.getParentActor() && _parent )
			{
				if( _parent._actor && (_parent._actor as qb2IActorContainer) )
					(_parent._actor as qb2IActorContainer).addActor(_actor);
			}
		}
		
		public function get actor():qb2IActor
			{  return _actor;  }
		public function set actor(newActor:qb2IActor):void
		{
			_actor = newActor;
			
			if ( _actor as qb2ProxyObject )
			{
				(_actor as qb2ProxyObject).actualObject = this;
			}
		}
		qb2_friend var _actor:qb2IActor;
		
		/**
		 * Returns a new instance that is a clone of this object.  Properties, flags, and their ownerships are copied to the new instance.
		 * Subclasses are responsible for overriding this function and ammending whatever they need to the clone.  It is up to subclasses
		 * to determine what "deep" means.  For example, calling clone(true) on a qb2ObjectContainer will also clone all of the container's
		 * descendants, whereas calling clone(false) on the same container will only copy the container's properties.
		 */
		public function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2Object = new (this as Object).constructor;
		
			cloned.copyPropertiesAndFlags(this);
			
			if ( deep && _actor )
			{
				cloned.actor = _actor.clone(deep);
			}
			
			return cloned;
		}
		
		qb2_friend function copyPropertiesAndFlags(source:qb2Object):void
		{
			//--- Save previous flags.
			var savedBooleanFlags:uint = this._flags;
			var savedBooleanOwnershipFlags:uint = this._ownershipFlagsForBooleans;
			
			//--- Copy ownership of flags/properties.
			this._ownershipFlagsForBooleans   = source._ownershipFlagsForBooleans;
			this._ownershipFlagsForProperties = source._ownershipFlagsForProperties;
			
			//--- Copy values for flags/properties.
			this._flags = source._flags;
			for ( var key:String in source._propertyMap )
			{
				this._propertyMap[key] = source._propertyMap[key];
			}
			
			//--- Always keep original flags for contact reporting, because these
			//--- are based on event listeners attached to the object.
			var CONTACT_REPORTING_FLAGS:uint = qb2_flags.CONTACT_REPORTING_FLAGS;
			this._ownershipFlagsForBooleans &= ~CONTACT_REPORTING_FLAGS;
			this._flags                     &= ~CONTACT_REPORTING_FLAGS;
			this._ownershipFlagsForBooleans |=  CONTACT_REPORTING_FLAGS & savedBooleanOwnershipFlags;
			this._flags                     |=  CONTACT_REPORTING_FLAGS & savedBooleanFlags;
		}
		
		/**
		 * A convenience function for getting the world's pixelsPerMeter property.
		 * If the object isn't in a world, function returns 1.
		 */
		public function get worldPixelsPerMeter():Number
			{  return _world ? _world.pixelsPerMeter : 1  }
	}
}