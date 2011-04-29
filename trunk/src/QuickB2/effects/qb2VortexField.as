/**
 * Copyright (c) 2010 Doug Koellmer
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
	import As3Math.consts.TO_RAD;
	import As3Math.general.amUtils;
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import QuickB2.debugging.*;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2IRigidObject;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2VortexField extends qb2EffectField
	{
		/**
		 * How fast the vortex is spinning.  This is measured near its center if isFreeVortex==true, near its maxHorizon if isFreeVortex==false.
		 */
		public var vortexSpeed:Number = 15;
		
		public var airDensity:Number = 3;
		public var minHorizon:Number = 1;
		public var maxHorizon:Number = 500;
		public var vortexAngle:Number;
		public var simulateDrag:Boolean = true;
		
		/**
		 * Is this a free vertex like a toilet flushing, where the water drains down freely?  Or is this an induced vortex, like stirring your tea?
		 * A free vertex applies the most force at its center, while a non-free vortex applies the most force at its outer horizon.
		 */
		public var isFreeVortex:Boolean = true;
		
		public function qb2VortexField()
		{
			vortexAngle = 135 * TO_RAD;
		}
		
		private static const utilWindField:qb2WindField = new qb2WindField();
		
		public override function applyToRigid(rigid:qb2IRigidObject):void
		{
			var thisWorldPoint:amPoint2d  = this.parent  ? this.parent.getWorldPoint(this.position)       : this.position;
			var rigidWorldPoint:amPoint2d = rigid.parent ? rigid.parent.getWorldPoint(rigid.centerOfMass) : rigid.centerOfMass;
			var rigidWorldVel:amVector2d = rigid.getLinearVelocityAtPoint(rigid.centerOfMass);
			
			var vector:amVector2d = rigidWorldPoint.minus(thisWorldPoint);
			var distanceToCenter:Number = vector.length;
			
			if ( !amUtils.isWithin(distanceToCenter, Math.max(.1, minHorizon), maxHorizon) )  return;
			
			var ratio:Number = (distanceToCenter - minHorizon) / (maxHorizon - minHorizon);
			ratio = isFreeVortex ? 1 - ratio : ratio;
			trace(ratio);
			vector.rotateBy(vortexAngle).setLength(vortexSpeed * ratio);
			
			utilWindField.simulateDrag = this.simulateDrag;
			utilWindField.airDensity = this.airDensity;
			utilWindField.vector.copy(vector);
			utilWindField.applyToRigid(rigid);
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2VortexField = super.clone(true) as qb2VortexField;
			
			cloned.vortexSpeed       = this.vortexSpeed;
			cloned.airDensity        = this.airDensity;
			cloned.minHorizon        = this.minHorizon;
			cloned.maxHorizon        = this.maxHorizon;
			cloned.vortexAngle       = this.vortexAngle;
			cloned.simulateDrag      = this.simulateDrag;
			cloned.isFreeVortex      = this.isFreeVortex;
			
			return cloned;
		}
		
		public override function toString():String
			{  return qb2_toString.formatToString(this, "qb2VortexField");  }
		
	}
}