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
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2IRigidObject;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2GravityWellField extends qb2EffectField
	{
		/// A unitless constant by which to multiply the force.  In nature, this constant is extremely small, because gravity
		/// is an extremely weak force.  Here it will generally be quite large because your objects will usually have human-scale masses.
		public var gravConstant:Number = 50000;
		
		/// The minimum horizon keeps the force from blowing up at small distances.
		public var minHorizon:Number = 10;
		
		/// Cancels forces past a maximum distance.
		public var maxHorizon:Number = Number.MAX_VALUE;
		
		/// An imaginary mass for the well itself, independent of the well's actual mass, which will usually be zero.
		public var wellMass:Number = 1;
		
		/// Should the force be multiplied by the inverse square of the distance?
		public var useInverseSquare:Boolean = true;
		
		public override function applyToRigid(rigid:qb2IRigidObject):void
		{
			var thisWorldPoint:amPoint2d  = this.parent  ? this.parent.getWorldPoint(this.position)       : this.position;
			var rigidWorldPoint:amPoint2d = rigid.parent ? rigid.parent.getWorldPoint(rigid.centerOfMass) : rigid.centerOfMass;
			var vector:amVector2d = thisWorldPoint.minus(rigidWorldPoint);
			
			if ( !amUtils.isWithin(vector.length, Math.max(.1, minHorizon), maxHorizon) )  return;
			
			var force:Number = gravConstant * ( (rigid.mass * wellMass));// / vector.lengthSquared);
			
			if ( useInverseSquare )
			{
				force /= vector.lengthSquared;
			}
			
			var forceVec:amVector2d = vector.normalize().scaleBy(force);
			
			if ( rigid.ancestorBody )
			{
				rigid.ancestorBody.applyForce(rigidWorldPoint, forceVec);
			}
			else
			{
				rigid.applyForce(rigidWorldPoint, forceVec);
			}
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2GravityWellField = super.clone(deep) as qb2GravityWellField;
			
			cloned.gravConstant = this.gravConstant;
			cloned.minHorizon   = this.minHorizon;
			cloned.maxHorizon   = this.maxHorizon;
			cloned.wellMass     = this.wellMass;			
			
			return cloned;
		}

		public override function toString():String 
			{  return qb2_toString(this, "qb2GravityWellField");  }
	}
}