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

package QuickB2.effects 
{
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Contacts.*;
	import flash.display.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.drawing.qb2_debugDrawSettings;
	import QuickB2.debugging.logging.qb2_errors;
	import QuickB2.debugging.logging.qb2_throw;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2EffectField extends qb2Body
	{
		private var instanceFilter:Dictionary = null;
		private var typeFilter:Dictionary = null;
		
		public var applyPerShape:Boolean = false;
		
		public function qb2EffectField()
		{
			super();
			init();
		}
		
		private static const CONTAINER_EVENTS:Array =
		[
			qb2ContainerEvent.DESCENDANT_ADDED_OBJECT,
			qb2ContainerEvent.DESCENDANT_REMOVED_OBJECT,
			qb2ContainerEvent.ADDED_OBJECT,
			qb2ContainerEvent.REMOVED_OBJECT
		];
		
		private static const CONTAINER_WORLD_EVENTS:Array =
		[
			qb2ContainerEvent.ADDED_TO_WORLD, qb2ContainerEvent.REMOVED_FROM_WORLD
		];
		
		private function init():void
		{
			isGhost = true;
			
			addEventListenerForTypes(CONTAINER_EVENTS, childrenChanged, null, true);
			
			addContainerEventListeners();
			
			if ( (this as Object).constructor == qb2EffectField )  qb2_throw(qb2_errors.ABSTRACT_CLASS_ERROR);
		}
		
		public function apply(toTangible:qb2Tangible):void
		{
			utilTraverser.root = toTangible;
			
			while (utilTraverser.hasNext )
			{
				var currObject:qb2Object = utilTraverser.currentObject;
				
				if ( !(currObject is qb2Tangible) )
				{
					utilTraverser.next(false);
					continue;
				}
				else if ( isDisabledFor(currObject as qb2Tangible) )
				{
					utilTraverser.next(false);
					continue;
				}
				else if ( currObject is qb2IRigidObject )
				{
					var asRigid:qb2IRigidObject = currObject as qb2IRigidObject;
					var isBody:Boolean = asRigid is qb2Body;
					
					if ( isBody && !applyPerShape || !isBody /*(isShape)*/ && applyPerShape )
					{
						applyToRigid(asRigid);
					}
					
					utilTraverser.next(isBody && applyPerShape);
				}
				else
				{
					utilTraverser.next(true);
				}
			}
		}
		
		public virtual function applyToRigid(rigid:qb2IRigidObject):void
		{
			
		}
		
		protected function postUpdate(evt:qb2UpdateEvent):void
		{
			if ( !_shapeCount )  return;
			
			var contactDict:Dictionary = applyPerShape ? shapeContactDict : bodyContactDict;
			
			for ( var key:* in contactDict )
			{
				var rigid:qb2IRigidObject = key as qb2IRigidObject;
				
				if ( !this.isDisabledFor(rigid as qb2Tangible, true) )
				{
					this.applyToRigid(rigid);
				}
			}
		}
		
		private var _shapeCount:uint = 0;
		
		private function childrenChanged(evt:qb2ContainerEvent):void
		{
			var addEvent:Boolean = evt.type == qb2ContainerEvent.ADDED_OBJECT || evt.type == qb2ContainerEvent.DESCENDANT_ADDED_OBJECT;
			
			utilTraverser.root = evt.child;
			
			while ( utilTraverser.hasNext )
			{
				var descendant:qb2Object = utilTraverser.next();
				if ( descendant is qb2Shape )
				{
					if ( addEvent )
					{
						if ( _shapeCount == 0 )
						{
							removeContainerEventListeners();
							addContactEventListeners();
						}
						
						_shapeCount++;
					}
					else
					{
						if ( _shapeCount == 1 )
						{
							addContainerEventListeners();
							removeContactEventListeners();
						}
						
						_shapeCount--;
					}
				}
			}
		}
		
		private static const WEAK_KEYS:Boolean = true;
		
		public function disableFor(instanceOrClass:*):void
		{
			if ( instanceOrClass is Class )
			{
				typeFilter = typeFilter ? typeFilter : new Dictionary(WEAK_KEYS);
				typeFilter[instanceOrClass] = true;
			}
			else
			{
				instanceFilter = instanceFilter ? instanceFilter : new Dictionary(WEAK_KEYS);
				instanceFilter[instanceOrClass] = true;
			}
		}
		
		public function enableFor(instanceOrClass:*):void
		{
			if ( instanceOrClass is Class )
			{
				if ( !typeFilter )  return;
				
				if ( typeFilter[instanceOrClass] )
				{
					delete typeFilter[instanceOrClass];
				}
			}
			else
			{
				instanceFilter = instanceFilter ? instanceFilter : new Dictionary(WEAK_KEYS);
				instanceFilter[instanceOrClass] = false;
			}
		}
		
		public final function isDisabledFor(tang:qb2Tangible, checkAncestry:Boolean = true):Boolean
		{
			if ( !instanceFilter && !typeFilter )  return false;
			
			var currObject:qb2Tangible = tang;
			do
			{
				if ( instanceFilter && instanceFilter[currObject] != null )
				{
					return instanceFilter[currObject] as Boolean;
				}
				
				if ( typeFilter )
				{
					for ( var key:* in typeFilter )
					{
						if ( currObject is (key as Class) )
						{
							return typeFilter[key] as Boolean
						}
					}
				}
				
				currObject = currObject.parent;
			}
			while (checkAncestry && currObject)
			
			return false;
		}
		
		private function addSelfToSystem():void
		{
			if ( parent && world )
			{
				parent._effectFields = parent._effectFields ? parent._effectFields : new Vector.<qb2EffectField>();
				parent._effectFields.push(this);
			}
		}
		
		private function removeSelfFromSystem(thisParent:qb2ObjectContainer, thisWorld:qb2World):void
		{
			if ( !thisParent )  return;
			
			if ( thisParent._effectFields )
			{
				var index:int = thisParent._effectFields.indexOf(this);
				
				if ( index >= 0 )
				{
					thisParent._effectFields.splice(index, 1);
				}
			}
		}
		
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				addSelfToSystem();
			}
			else
			{
				removeSelfFromSystem(parent ? parent : evt.ancestor, evt.ancestor.world);
			}
		}
			
		private function addContainerEventListeners():void
		{
			addSelfToSystem();
			
			addEventListenerForTypes(CONTAINER_WORLD_EVENTS, addedOrRemoved, null, true);
		}
		
		private function removeContainerEventListeners():void
		{
			removeSelfFromSystem(parent, world);
			
			removeEventListenerForTypes(CONTAINER_WORLD_EVENTS, addedOrRemoved);
		}
		
		private function addContactEventListeners():void
		{
			addEventListener(qb2UpdateEvent.POST_UPDATE, postUpdate, null, true);
			
			//--- Create (and fill) contact dictionary.
			shapeContactDict = new Dictionary(WEAK_KEYS);
			bodyContactDict  = new Dictionary(WEAK_KEYS);
			
			if ( world )
			{
				var worldB2:b2World = world.b2_world;
				
				var contactB2:b2Contact = worldB2.GetContactList();
				while ( contactB2 )
				{
					if ( contactB2.IsTouching() )
					{
						var shape1:qb2Shape = contactB2.GetFixtureA().m_userData as qb2Shape;
						var shape2:qb2Shape = contactB2.GetFixtureB().m_userData as qb2Shape;
						
						if ( shape1 && shape2 )
						{
							var otherShape:qb2Shape = null;
							
							if ( shape1.isDescendantOf(this) )
							{
								otherShape = shape2;
							}
							else if ( shape2.isDescendantOf(this) )
							{
								otherShape = shape1;
							}
							
							if ( otherShape )
							{
								shapeContactDict[otherShape] = shapeContactDict[otherShape] ? shapeContactDict[otherShape] :  0 as int;
								shapeContactDict[otherShape]++;
								
								var otherBody:qb2IRigidObject = otherShape.ancestorBody ? otherShape.ancestorBody : otherShape;
								bodyContactDict[otherBody] = bodyContactDict[otherBody] ? bodyContactDict[otherBody] :  0 as int;
								bodyContactDict[otherBody]++;
							}
						}
					}
					
					contactB2 = contactB2.GetNext();
				}
			}
			
			addEventListener(qb2ContactEvent.CONTACT_STARTED, contact, null, true);
			addEventListener(qb2ContactEvent.CONTACT_ENDED,   contact, null, true);
		}
		
		private function removeContactEventListeners():void
		{			
			removeEventListener(qb2UpdateEvent.POST_UPDATE, postUpdate);
			
			//--- Clean up contact dictionary, removing this effects from all shapes in contact.
			if ( shapeContactDict )
			{
				for ( var key:* in shapeContactDict )
				{
					delete shapeContactDict[key];
				}
			}
			
			if ( bodyContactDict )
			{
				for ( key in bodyContactDict )
				{
					delete bodyContactDict[key];
				}
			}
			
			shapeContactDict = bodyContactDict = null;
			
			removeEventListener(qb2ContactEvent.CONTACT_STARTED, contact);
			removeEventListener(qb2ContactEvent.CONTACT_ENDED,   contact);
		}
		
		private var shapeContactDict:Dictionary = null;
		private var bodyContactDict:Dictionary = null;
		
		private function contact(evt:qb2ContactEvent):void
		{
			var otherShape:qb2Shape = evt.otherShape;
			var otherBody:qb2IRigidObject = otherShape.ancestorBody ? otherShape.ancestorBody : otherShape;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				if ( !shapeContactDict[otherShape] )
				{
					shapeContactDict[otherShape] = 0 as int;
					
					if ( !bodyContactDict[otherBody] )
					{
						bodyContactDict[otherBody] = 0 as int;
					}
					bodyContactDict[otherBody]++;
				}
				
				shapeContactDict[otherShape]++;
			}
			else
			{
				shapeContactDict[otherShape]--;
				
				if ( shapeContactDict[otherShape] == 0 ) 
				{
					delete shapeContactDict[otherShape];
					
					bodyContactDict[otherBody]--;
					if ( bodyContactDict[otherBody] == 0 )
					{
						delete bodyContactDict[otherBody];
					}
				}
			}
		}
		
		private static var utilTraverser:qb2TreeTraverser = new qb2TreeTraverser();
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2EffectField = super.clone(deep) as qb2EffectField;
			
			cloned.applyPerShape = this.applyPerShape;
			
			if ( instanceFilter )
			{
				cloned.instanceFilter = new Dictionary(WEAK_KEYS);
				
				for ( var key:* in instanceFilter )
				{
					cloned.instanceFilter[key] = this.instanceFilter[this];
				}
			}
			
			if ( typeFilter )
			{
				cloned.typeFilter = new Dictionary(WEAK_KEYS);
				
				for ( key in typeFilter )
				{
					cloned.typeFilter[key] = this.typeFilter[key];
				}
			}
			
			return cloned;
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			pushDebugFillColor(qb2_debugDrawSettings.effectFieldFillColor);
				super.drawDebug(graphics);
			popDebugFillColor();
		}

		public override function toString():String 
			{  return qb2_toString(this, "qb2EffectField");  }
	}
}