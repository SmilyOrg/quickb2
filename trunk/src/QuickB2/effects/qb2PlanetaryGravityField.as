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
	import As3Math.general.amUtils;
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import Box2DAS.Common.V2;
	import flash.utils.Dictionary;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.events.qb2UpdateEvent;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2IRigidObject;
	import QuickB2.objects.tangibles.qb2Tangible;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2PlanetaryGravityField extends qb2EffectField
	{
		/// A constant by which to multiply the force.
		public var gravConstant:Number = 1000;
		
		public function qb2PlanetaryGravityField()
		{
			addEventListener(qb2UpdateEvent.POST_UPDATE, processAccumulator, null, true);
		}
		
		private var accumArray:Vector.<qb2IRigidObject> = new Vector.<qb2IRigidObject>();
		private var accumDict:Dictionary = new Dictionary(true);
		
		private function processAccumulator(evt:qb2UpdateEvent):void
		{
			for (var i:int = 0; i < accumArray.length; i++) 
			{
				var ithRigid:qb2IRigidObject = accumArray[i];
				
				for (var j:int = i+1; j < accumArray.length; j++)
				{
					var jthRigid:qb2IRigidObject = accumArray[j];
			
					var ithWorldPoint:amPoint2d = ithRigid.ancestorBody  ? ithRigid.parent.getWorldPoint(ithRigid.centerOfMass, ancestorBody.parent) : ithRigid.centerOfMass;
					var jthWorldPoint:amPoint2d = jthRigid.ancestorBody  ? jthRigid.parent.getWorldPoint(jthRigid.centerOfMass, ancestorBody.parent) : jthRigid.centerOfMass;
					
					var vector:amVector2d = ithWorldPoint.minus(jthWorldPoint);
					
					var force:Number = gravConstant * ( (ithRigid.mass * jthRigid.mass) / vector.lengthSquared);
					
					var forceVec:amVector2d = vector.normalize().scaleBy(force);
					
					if ( jthRigid.ancestorBody )
					{
						jthRigid.ancestorBody.applyForce(jthWorldPoint, forceVec);
					}
					else
					{
						jthRigid.applyForce(jthWorldPoint, forceVec);
					}
					
					if ( ithRigid.ancestorBody )
					{
						ithRigid.ancestorBody.applyForce(ithWorldPoint, forceVec.negate());
					}
					else
					{
						ithRigid.applyForce(ithWorldPoint, forceVec.negate());
					}
				}
				
				delete accumDict[ithRigid];
			}
			
			accumArray.length = 0;
		}
		
		public override function apply(toTangible:qb2Tangible):void
		{
			super.apply(toTangible);
			processAccumulator(null);
		}
		
		public override function applyToRigid(rigid:qb2IRigidObject):void
		{
			if ( accumDict[rigid] )  return;
			
			accumDict[rigid] = true;
			accumArray.push(rigid);
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2PlanetaryGravityField = super.clone(deep) as qb2PlanetaryGravityField;
			
			cloned.gravConstant = this.gravConstant;
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2PlanetaryGravityField");  }
		
	}
}